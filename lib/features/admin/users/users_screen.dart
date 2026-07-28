import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/async_error_view.dart';
import 'create_user_screen.dart';
import 'models.dart';
import 'users_provider.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateUserScreen())),
        child: const Icon(Icons.add),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(adminUsersProvider)),
        data: (users) {
          final pending = users.where((u) => u.status != 'APPROVED').toList();
          final approved = users.where((u) => u.status == 'APPROVED').toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminUsersProvider.future),
            child: ListView(
              children: [
                if (pending.isNotEmpty) ...[
                  const _SectionHeader('Pending / Rejected'),
                  ...pending.map((u) => _UserRow(user: u)),
                ],
                const _SectionHeader('Approved'),
                ...approved.map((u) => _UserRow(user: u)),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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

  Future<void> _editDialog() async {
    final name = TextEditingController(text: widget.user.name);
    final email = TextEditingController(text: widget.user.email);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _act(() => dio.patch('/admin/users/${widget.user.id}', data: {
                    'name': name.text.trim(),
                    'email': email.text.trim(),
                  }));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return ListTile(
      title: Text(u.name),
      subtitle: Text('${u.email} · ${u.role} · ${u.status}'),
      trailing: _busy
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'approve':
                    _act(() => dio.post('/admin/users/${u.id}/approve'));
                  case 'reject':
                    _act(() => dio.post('/admin/users/${u.id}/reject'));
                  case 'edit':
                    _editDialog();
                  case 'delete':
                    _act(() => dio.delete('/admin/users/${u.id}'));
                }
              },
              itemBuilder: (context) => [
                if (u.status != 'APPROVED') const PopupMenuItem(value: 'approve', child: Text('Approve')),
                if (u.status == 'PENDING') const PopupMenuItem(value: 'reject', child: Text('Reject')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
    );
  }
}
