import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;
  final bool showBorder;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.displayName,
    this.radius = 24,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildInitials(),
                errorWidget: (_, __, ___) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    final initials = displayName.isNotEmpty
        ? displayName
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join()
        : '?';
    return Text(
      initials,
      style: TextStyle(
        fontSize: radius * 0.7,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}
