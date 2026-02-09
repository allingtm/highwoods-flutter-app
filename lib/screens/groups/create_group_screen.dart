import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/group/group.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';

/// Admin-only screen for creating a new group
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _termsController = TextEditingController();
  GroupVisibility _visibility = GroupVisibility.public_;
  bool _isCreating = false;
  bool _slugManuallyEdited = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_autoGenerateSlug);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _autoGenerateSlug() {
    if (_slugManuallyEdited) return;
    final slug = _nameController.text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    _slugController.text = slug;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _create,
            child: _isCreating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spacingLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'e.g. Health and Fitness',
                ),
                validator: (v) =>
                    v == null || v.trim().length < 2 ? 'Name too short' : null,
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: tokens.spacingMd),
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'Slug',
                  hintText: 'e.g. health-and-fitness',
                  helperText: 'URL-friendly identifier (auto-generated)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v)) {
                    return 'Only lowercase letters, numbers, and hyphens';
                  }
                  return null;
                },
                onChanged: (_) => _slugManuallyEdited = true,
              ),
              SizedBox(height: tokens.spacingMd),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What is this group about?',
                ),
                maxLines: 3,
                maxLength: 1000,
              ),
              SizedBox(height: tokens.spacingMd),
              DropdownButtonFormField<GroupVisibility>(
                initialValue: _visibility,
                decoration: const InputDecoration(
                  labelText: 'Visibility',
                ),
                items: GroupVisibility.values.map((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Text(v.displayName),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _visibility = v);
                },
              ),
              SizedBox(height: tokens.spacingMd),
              TextFormField(
                controller: _termsController,
                decoration: const InputDecoration(
                  labelText: 'Terms & Conditions',
                  hintText: 'Rules members must accept to join',
                ),
                maxLines: 5,
                maxLength: 5000,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);
    try {
      final group = await ref.read(groupActionsProvider.notifier).createGroup(
            name: _nameController.text.trim(),
            slug: _slugController.text.trim(),
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            visibility: _visibility,
            termsText: _termsController.text.trim().isNotEmpty
                ? _termsController.text.trim()
                : null,
          );
      if (!mounted) return;
      // Navigate to the new group
      context.pop();
      context.push('/group/${group.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create group: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}
