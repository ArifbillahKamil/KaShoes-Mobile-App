import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Colored badge for order status display.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: isSmall ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: config.textColor,
        ),
      ),
    );
  }

  _StatusConfig _getConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _StatusConfig(
          label: 'Menunggu',
          bgColor: AppTheme.warning.withOpacity(0.15),
          textColor: AppTheme.warning,
        );
      case 'confirmed':
        return _StatusConfig(
          label: 'Dikonfirmasi',
          bgColor: AppTheme.info.withOpacity(0.12),
          textColor: AppTheme.info,
        );
      case 'processing':
      case 'diproses':
        return _StatusConfig(
          label: 'Diproses',
          bgColor: AppTheme.primary.withOpacity(0.12),
          textColor: AppTheme.primary,
        );
      case 'ready':
        return _StatusConfig(
          label: 'Siap Diambil',
          bgColor: AppTheme.secondaryLight.withOpacity(0.25),
          textColor: AppTheme.accent,
        );
      case 'completed':
      case 'selesai':
        return _StatusConfig(
          label: 'Selesai',
          bgColor: AppTheme.success.withOpacity(0.12),
          textColor: AppTheme.success,
        );
      case 'cancelled':
      case 'dibatalkan':
        return _StatusConfig(
          label: 'Dibatalkan',
          bgColor: AppTheme.error.withOpacity(0.12),
          textColor: AppTheme.error,
        );
      default:
        return _StatusConfig(
          label: status,
          bgColor: AppTheme.textSecondary.withOpacity(0.12),
          textColor: AppTheme.textSecondary,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color bgColor;
  final Color textColor;
  const _StatusConfig({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });
}

/// Member / non-member status badge.
class MemberBadge extends StatelessWidget {
  final bool isMember;

  const MemberBadge({super.key, required this.isMember});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: isMember
            ? const LinearGradient(
                colors: [AppTheme.secondary, AppTheme.accent],
              )
            : null,
        color: isMember ? null : AppTheme.textSecondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMember ? Icons.workspace_premium : Icons.person_outline,
            size: 14,
            color: isMember ? Colors.white : AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            isMember ? 'Member' : 'Non-Member',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isMember ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
