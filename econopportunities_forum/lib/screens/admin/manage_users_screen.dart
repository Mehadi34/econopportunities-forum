import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../providers/members_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/user_avatar.dart';

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  UserRole? _roleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _changeRole(UserModel user, UserRole newRole) async {
    try {
      await ref.read(firestoreServiceProvider).updateUserRole(user.uid, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${user.displayName} is now ${newRole.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleActive(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(user.isActive ? 'Deactivate Account' : 'Activate Account'),
        content: Text(
          user.isActive
              ? 'Deactivate ${user.displayName}\'s account?'
              : 'Activate ${user.displayName}\'s account?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(user.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(firestoreServiceProvider).updateUser(user.uid, {
        'isActive': !user.isActive,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(user.isActive
                  ? '${user.displayName} deactivated'
                  : '${user.displayName} activated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showUserOptions(UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _UserOptionsSheet(
        user: user,
        onChangeRole: (role) => _changeRole(user, role),
        onToggleActive: () => _toggleActive(user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon:
                    Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _RoleFilter(
            selectedRole: _roleFilter,
            onRoleSelected: (role) => setState(() => _roleFilter = role),
          ),
          Expanded(
            child: membersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateWidget(message: e.toString()),
              data: (users) {
                var filtered = users;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = filtered
                      .where((u) =>
                          u.displayName.toLowerCase().contains(q) ||
                          u.email.toLowerCase().contains(q))
                      .toList();
                }
                if (_roleFilter != null) {
                  filtered = filtered
                      .where((u) => u.role == _roleFilter)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.people_outline,
                    title: 'No users found',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _UserCard(
                    user: filtered[i],
                    onTap: () => _showUserOptions(filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleFilter extends StatelessWidget {
  final UserRole? selectedRole;
  final ValueChanged<UserRole?> onRoleSelected;
  const _RoleFilter(
      {required this.selectedRole, required this.onRoleSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Chip(
            label: 'All',
            selected: selectedRole == null,
            onSelected: () => onRoleSelected(null),
          ),
          ...UserRole.values.map((r) => _Chip(
                label: r.name[0].toUpperCase() + r.name.substring(1),
                selected: selectedRole == r,
                onSelected: () => onRoleSelected(r),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 12),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  const _UserCard({required this.user, required this.onTap});

  Color get _roleColor {
    switch (user.role) {
      case UserRole.admin:
        return AppColors.error;
      case UserRole.moderator:
        return AppColors.warning;
      case UserRole.member:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            UserAvatar(
                photoUrl: user.photoUrl,
                displayName: user.displayName,
                radius: 22),
            if (!user.isActive)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(user.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email,
                style: const TextStyle(fontSize: 12)),
            if (!user.isActive)
              const Text('Inactive',
                  style: TextStyle(color: AppColors.error, fontSize: 11)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.roleDisplayName,
                style: TextStyle(
                    color: _roleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.more_vert, size: 18),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }
}

class _UserOptionsSheet extends StatelessWidget {
  final UserModel user;
  final ValueChanged<UserRole> onChangeRole;
  final VoidCallback onToggleActive;

  const _UserOptionsSheet({
    required this.user,
    required this.onChangeRole,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                    photoUrl: user.photoUrl,
                    displayName: user.displayName,
                    radius: 22),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(user.email,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Change Role',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: UserRole.values
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(r.name[0].toUpperCase() +
                              r.name.substring(1)),
                          selected: user.role == r,
                          onSelected: (_) {
                            Navigator.pop(context);
                            if (user.role != r) onChangeRole(r);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: user.role == r
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                user.isActive ? Icons.block : Icons.check_circle,
                color: user.isActive ? AppColors.error : AppColors.success,
              ),
              title: Text(
                user.isActive ? 'Deactivate Account' : 'Activate Account',
                style: TextStyle(
                    color: user.isActive
                        ? AppColors.error
                        : AppColors.success),
              ),
              onTap: () {
                Navigator.pop(context);
                onToggleActive();
              },
            ),
          ],
        ),
      ),
    );
  }
}
