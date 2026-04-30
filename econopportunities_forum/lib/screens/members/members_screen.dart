import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../providers/members_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/user_avatar.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchController = TextEditingController();
  UserRole? _selectedRole;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(filteredMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members Directory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search members...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon:
                    Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _RoleFilter(
            selectedRole: _selectedRole,
            onRoleSelected: (role) {
              setState(() => _selectedRole = role);
              ref.read(selectedRoleProvider.notifier).state = role;
            },
          ),
          Expanded(
            child: membersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateWidget(message: e.toString()),
              data: (members) {
                if (members.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.people_outline,
                    title: 'No members found',
                    subtitle: 'Try adjusting your search or filters',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: members.length,
                    itemBuilder: (_, i) =>
                        _MemberCard(member: members[i]),
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

  const _RoleFilter({
    required this.selectedRole,
    required this.onRoleSelected,
  });

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
          _Chip(
            label: 'Admin',
            selected: selectedRole == UserRole.admin,
            onSelected: () => onRoleSelected(UserRole.admin),
          ),
          _Chip(
            label: 'Moderator',
            selected: selectedRole == UserRole.moderator,
            onSelected: () => onRoleSelected(UserRole.moderator),
          ),
          _Chip(
            label: 'Member',
            selected: selectedRole == UserRole.member,
            onSelected: () => onRoleSelected(UserRole.member),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

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
          fontSize: 12,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final UserModel member;
  const _MemberCard({required this.member});

  Color get _roleColor {
    switch (member.role) {
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
        leading: UserAvatar(
          photoUrl: member.photoUrl,
          displayName: member.displayName,
          radius: 24,
        ),
        title: Text(
          member.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.department != null)
              Text(member.department!,
                  style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _roleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            member.roleDisplayName,
            style: TextStyle(
              color: _roleColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => context.push('/members/${member.uid}'),
      ),
    );
  }
}
