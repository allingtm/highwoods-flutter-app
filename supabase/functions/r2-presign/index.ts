// Supabase Edge Function for generating Cloudflare R2 presigned URLs
// Deploy with: supabase functions deploy r2-presign

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { S3Client, PutObjectCommand, DeleteObjectCommand } from "https://esm.sh/@aws-sdk/client-s3@3.400.0";
import { getSignedUrl } from "https://esm.sh/@aws-sdk/s3-request-presigner@3.400.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Get environment variables
const R2_ACCOUNT_ID = Deno.env.get("R2_ACCOUNT_ID")!;
const R2_ACCESS_KEY_ID = Deno.env.get("R2_ACCESS_KEY_ID")!;
const R2_SECRET_ACCESS_KEY = Deno.env.get("R2_SECRET_ACCESS_KEY")!;
const R2_BUCKET_NAME = Deno.env.get("R2_BUCKET_NAME") || "highwoods-storage";
const R2_PUBLIC_URL = Deno.env.get("R2_PUBLIC_URL") || "https://pub-b231fcd02fbf463f8956d39a9b1a3e38.r2.dev";

// Create S3 client for R2
const s3Client = new S3Client({
  region: "auto",
  endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
  },
});

// Generate UUID v4
function generateUUID(): string {
  return crypto.randomUUID();
}

// Get file extension from content type
function getExtensionFromContentType(contentType: string): string {
  const mapping: Record<string, string> = {
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
    "image/gif": "gif",
  };
  return mapping[contentType] || "jpg";
}

interface UploadRequest {
  action: "upload";
  userId: string;
  postId: string;
  contentType: string;
  files?: Array<{ postId: string; contentType: string }>;
}

interface DeleteRequest {
  action: "delete";
  storagePath?: string;
  storagePaths?: string[];
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    // Verify the user is authenticated via Supabase JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Create Supabase client to verify the token
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const { action } = body;

    if (action === "upload") {
      const { postId, contentType, files } = body as UploadRequest;
      const userId = user.id; // Use authenticated user's ID

      const filesToProcess = files || [{ postId, contentType }];
      const results = [];

      for (const file of filesToProcess) {
        const filePostId = file.postId || postId;
        const fileContentType = file.contentType || contentType || "image/jpeg";

        if (!filePostId) {
          results.push({ error: "postId is required for each file" });
          continue;
        }

        const uuid = generateUUID();
        const extension = getExtensionFromContentType(fileContentType);
        const storagePath = `${userId}/${filePostId}/${uuid}.${extension}`;

        try {
          const command = new PutObjectCommand({
            Bucket: R2_BUCKET_NAME,
            Key: storagePath,
            ContentType: fileContentType,
          });

          const presignedUrl = await getSignedUrl(s3Client, command, { expiresIn: 300 });
          const publicUrl = `${R2_PUBLIC_URL}/${storagePath}`;

          results.push({
            presignedUrl,
            publicUrl,
            storagePath,
            contentType: fileContentType,
          });
        } catch (error) {
          results.push({ error: (error as Error).message, storagePath });
        }
      }

      return new Response(
        JSON.stringify({ files: results }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (action === "delete") {
      const { storagePath, storagePaths } = body as DeleteRequest;
      const pathsToDelete = storagePaths || (storagePath ? [storagePath] : []);

      if (pathsToDelete.length === 0) {
        return new Response(
          JSON.stringify({ error: "storagePath or storagePaths is required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const results = [];

      for (const path of pathsToDelete) {
        // Security: Verify the path belongs to the authenticated user
        if (!path.startsWith(`${user.id}/`)) {
          results.push({ error: "Unauthorized: Cannot delete files owned by other users", storagePath: path });
          continue;
        }

        try {
          const command = new DeleteObjectCommand({
            Bucket: R2_BUCKET_NAME,
            Key: path,
          });

          const presignedUrl = await getSignedUrl(s3Client, command, { expiresIn: 300 });
          results.push({ presignedUrl, storagePath: path });
        } catch (error) {
          results.push({ error: (error as Error).message, storagePath: path });
        }
      }

      return new Response(
        JSON.stringify({ files: results }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ error: "Invalid action. Use 'upload' or 'delete'" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
