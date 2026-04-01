import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;
  final bool isActive;

  const RoleBadge({
    Key? key,
    required this.role,
    this.isActive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      if (!isActive) return AppColors.gray;

      switch (role) {
        case UserRole.admin:
          return AppColors.primaryBlue;
        case UserRole.employee:
          return AppColors.teal;
      }
    }

    String getText() {
      if (!isActive) return 'Inactif';
      return role.displayName;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        getText(),
        style: TextStyle(
          fontSize: 11,
          color: getColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}