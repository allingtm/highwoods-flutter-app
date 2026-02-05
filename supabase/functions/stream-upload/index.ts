// Supabase Edge Function for Cloudflare Stream video uploads
// Deploy with: supabase functions deploy stream-upload

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Get environment variables
const CLOUDFLARE_ACCOUNT_ID = Deno.env.get("CLOUDFLARE_ACCOUNT_ID")!;
const CLOUDFLARE_API_TOKEN = Deno.env.get("CLOUDFLARE_API_TOKEN")!;

const STREAM_API_BASE = `https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/stream`;

// Maximum video duration in seconds (5 minutes)
const MAX_DURATION_SECONDS = 300;

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

    // ============================================================
    // Action: create-upload
    // Creates a Direct Creator Upload URL for Cloudflare Stream
    // ============================================================
    if (action === "create-upload") {
      const response = await fetch(`${STREAM_API_BASE}/direct_upload`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${CLOUDFLARE_API_TOKEN}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          maxDurationSeconds: MAX_DURATION_SECONDS,
          requireSignedURLs: false,
          meta: {
            userId: user.id,
            uploadedAt: new Date().toISOString(),
          },
        }),
      });

      const data = await response.json();

      if (!data.success) {
        const errorMsg = data.errors?.[0]?.message || "Failed to create upload URL";
        return new Response(
          JSON.stringify({ error: errorMsg }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          uploadUrl: data.result.uploadURL,
          videoUid: data.result.uid,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ============================================================
    // Action: get-status
    // Gets the processing status of a video
    // ============================================================
    if (action === "get-status") {
      const { videoUid } = body;

      if (!videoUid) {
        return new Response(
          JSON.stringify({ error: "videoUid is required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const response = await fetch(`${STREAM_API_BASE}/${videoUid}`, {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${CLOUDFLARE_API_TOKEN}`,
        },
      });

      const data = await response.json();

      if (!data.success) {
        const errorMsg = data.errors?.[0]?.message || "Failed to get video status";
        return new Response(
          JSON.stringify({ error: errorMsg }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const video = data.result;

      // Determine status
      let status = "processing";
      if (video.readyToStream) {
        status = "ready";
      } else if (video.status?.state === "error") {
        status = "error";
      }

      return new Response(
        JSON.stringify({
          videoUid: video.uid,
          status,
          thumbnailUrl: video.thumbnail || null,
          playbackUrl: video.playback?.hls || null,
          duration: video.duration ? Math.round(video.duration) : null,
          width: video.input?.width || null,
          height: video.input?.height || null,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ============================================================
    // Action: delete
    // Deletes a video from Cloudflare Stream
    // ============================================================
    if (action === "delete") {
      const { videoUid } = body;

      if (!videoUid) {
        return new Response(
          JSON.stringify({ error: "videoUid is required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Verify the video belongs to this user by checking metadata
      const statusResponse = await fetch(`${STREAM_API_BASE}/${videoUid}`, {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${CLOUDFLARE_API_TOKEN}`,
        },
      });

      const statusData = await statusResponse.json();

      if (statusData.success && statusData.result?.meta?.userId !== user.id) {
        return new Response(
          JSON.stringify({ error: "Unauthorized: Cannot delete videos owned by other users" }),
          { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const response = await fetch(`${STREAM_API_BASE}/${videoUid}`, {
        method: "DELETE",
        headers: {
          "Authorization": `Bearer ${CLOUDFLARE_API_TOKEN}`,
        },
      });

      if (response.status !== 200) {
        return new Response(
          JSON.stringify({ error: "Failed to delete video" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ success: true }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ error: "Invalid action. Use 'create-upload', 'get-status', or 'delete'" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
