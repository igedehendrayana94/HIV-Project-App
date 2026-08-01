import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/auth_state.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/async_error_view.dart';
import '../../../shared/confirm_dialog.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/i18n.dart';
import 'models.dart';
import 'users_provider.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('users'))),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(adminUsersProvider)),
        data: (users) {
          if (users.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.refresh(adminUsersProvider.future),
              child: ListView(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  // No key covers this empty state yet — left as plain English.
                  const EmptyState(icon: Icons.people_outline, message: 'No users yet.'),
                ],
              ),
            );
          }
          final q = _query.trim().toLowerCase();
          final filtered = q.isEmpty
              ? users
              : users
                  .where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
                  .toList();
          final pending = filtered.where((u) => u.status != 'APPROVED').toList();
          final approved = filtered.where((u) => u.status == 'APPROVED').toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminUsersProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // No i18n key for a users search hint — left as a plain English literal.
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(labelText: 'Search by name or email'),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: AppSpacing.md),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyState(icon: Icons.search_off, message: 'No users match your search.'),
                  )
                else ...[
                  if (pending.isNotEmpty) ...[
                    // No i18n keys exist for these section headers — left as plain English.
                    const _SectionHeader('Pending / Rejected'),
                    for (final u in pending) ...[
                      _UserRow(user: u),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (approved.isNotEmpty) ...[
                    const _SectionHeader('Approved'),
                    for (final u in approved) ...[
                      _UserRow(user: u),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _UserRow extends ConsumerStatefulWidget {
  final AdminUser user;
  const _UserRow({required this.user});

  @override
  ConsumerState<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends ConsumerState<_UserRow> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(adminUsersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _roleDialog() async {
    var selected = widget.user.role;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          // No dedicated i18n key for this dialog title — reuses the generic "role" label.
          title: Text(AppStrings.t('role')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in ['ADMIN', 'PROVIDER', 'PATIENT'])
                RadioListTile<String>(
                  title: Text(r),
                  value: r,
                  // ignore: deprecated_member_use
                  groupValue: selected,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setDialogState(() => selected = v!),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppStrings.t('cancel'))),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(AppStrings.t('save'))),
          ],
        ),
      ),
    );
    if (confirmed != true || selected == widget.user.role) return;
    if (!mounted) return;
    final ok = await confirmAction(
      context,
      title: AppStrings.t('areYouSure'),
      // No dedicated i18n key for this specific confirmation — reuses rejectConfirmMessage's
      // generic "are you sure" pattern via a plain literal instead of forcing an ill-fitting key.
      message: 'Change ${widget.user.name}\'s role from ${widget.user.role} to $selected?',
      confirmLabel: AppStrings.t('save'),
      destructive: true,
    );
    if (ok) _act(() => dio.patch('/admin/users/${widget.user.id}/role', data: {'role': selected}));
  }

  Future<void> _editDialog() async {
    final name = TextEditingController(text: widget.user.name);
    final email = TextEditingController(text: widget.user.email);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.t('editUser')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.t('cancel'))),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _act(() => dio.patch('/admin/users/${widget.user.id}', data: {
                    'name': name.text.trim(),
                    'email': email.text.trim(),
                  }));
            },
            child: Text(AppStrings.t('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    // Admin's PATCH /admin/users/[id] is self-only now (2026-07-31 policy change) — editing
    // another user's name/email/password is a 403 server-side, so the Edit action only makes
    // sense (and only appears) on the admin's own row. Everyone else's row is view-only plus
    // Approve/Reject/Delete, which are separate status/removal actions, not edits.
    final isSelf = u.id == ref.watch(authProvider).value?.userId;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${u.email} · ${u.role} · ${u.status}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'approve':
                        _act(() => dio.post('/admin/users/${u.id}/approve'));
                      case 'reject':
                        _act(() => dio.post('/admin/users/${u.id}/reject'));
                      case 'edit':
                        _editDialog();
                      case 'role':
                        _roleDialog();
                      case 'delete':
                        final ok = await confirmAction(
                          context,
                          title: AppStrings.t('areYouSure'),
                          message: AppStrings.t('deleteAccountConfirmMessage'),
                          confirmLabel: AppStrings.t('delete'),
                          destructive: true,
                        );
                        if (ok) _act(() => dio.delete('/admin/users/${u.id}'));
                    }
                  },
                  itemBuilder: (context) => [
                    if (u.status != 'APPROVED')
                      PopupMenuItem(value: 'approve', child: Text(AppStrings.t('approve'))),
                    if (u.status == 'PENDING')
                      PopupMenuItem(value: 'reject', child: Text(AppStrings.t('reject'))),
                    if (isSelf)
                      PopupMenuItem(value: 'edit', child: Text(AppStrings.t('edit')))
                    else ...[
                      PopupMenuItem(value: 'role', child: Text(AppStrings.t('role'))),
                      PopupMenuItem(value: 'delete', child: Text(AppStrings.t('delete'))),
                    ],
                  ],
                ),
        ],
      ),
    );
  }
}
