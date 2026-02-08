import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/group/group.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';

/// Admin screen for editing group settings
class GroupSettingsScreen extends ConsumerStatefulWidget {
  const GroupSettingsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _termsController;
  GroupVisibility _visibility = GroupVisibility.public_;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _termsController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _initFromGroup(Group group) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = group.name;
    _descriptionController.text = group.description ?? '';
    _termsController.text = group.termsText ?? '';
    _visibility = group.visibility;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load group')),
        data: (group) {
          if (group == null) return const Center(child: Text('Group not found'));
          _initFromGroup(group);

          return SingleChildScrollView(
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
                      hintText: 'Enter group name',
                    ),
                    validator: (v) =>
                        v == null || v.trim().length < 2 ? 'Name too short' : null,
                  ),
                  SizedBox(height: tokens.spacingMd),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the group',
                    ),
                    maxLines: 3,
                    maxLength: 1000,
                  ),
                  SizedBox(height: tokens.spacingMd),
                  DropdownButtonFormField<GroupVisibility>(
                    value: _visibility,
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
                      hintText: 'Group rules members must accept',
                    ),
                    maxLines: 5,
                    maxLength: 5000,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(groupActionsProvider.notifier).updateGroupSettings(
            groupId: widget.groupId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            visibility: _visibility,
            termsText: _termsController.text.trim().isNotEmpty
                ? _termsController.text.trim()
                : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group updated')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
