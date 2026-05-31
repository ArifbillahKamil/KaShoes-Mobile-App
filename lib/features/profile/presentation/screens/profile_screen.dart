import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _startEditing(String? phone, String? address) {
    _phoneController.text = phone ?? '';
    _addressController.text = address ?? '';
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(profileProvider.notifier).updateProfile(
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );
    if (mounted) setState(() => _isEditing = false);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    // Show save result
    ref.listen<ProfileState>(profileProvider, (_, next) {
      if (next.saveSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui ✓'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
      if (next.errorMessage != null && !next.saveSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          if (!_isEditing && state.user != null)
            TextButton.icon(
              onPressed: () => _startEditing(state.user?.phone, state.user?.address),
              icon: const Icon(Icons.edit, color: Colors.white, size: 18),
              label: const Text('Edit', style: TextStyle(color: Colors.white)),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _cancelEditing,
              child: const Text('Batal', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: SafeArea(
        child: state.status == ProfileStatus.loading && state.user == null
            ? const Center(child: CircularProgressIndicator())
            : state.status == ProfileStatus.error && state.user == null
                ? ErrorView(
                    message: state.errorMessage,
                    onRetry: () => ref.read(profileProvider.notifier).load(),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(profileProvider.notifier).load(),
                    color: AppTheme.primary,
                    child: ListView(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      children: [
                        // ─── Profile Header ────────────────────────────
                        _ProfileHeader(user: state.user),
                        const SizedBox(height: AppTheme.spacing24),

                        // ─── Editable Fields or Read-Only ──────────────
                        if (_isEditing)
                          _EditableSection(
                            formKey: _formKey,
                            phoneController: _phoneController,
                            addressController: _addressController,
                            onSave: _saveProfile,
                            isSaving: state.status == ProfileStatus.saving,
                          )
                        else ...[
                          _InfoCard(user: state.user),
                        ],

                        const SizedBox(height: AppTheme.spacing24),

                        // ─── Logout Button ─────────────────────────────
                        AppButton(
                          label: 'Keluar dari Akun',
                          onPressed: _logout,
                          isOutlined: true,
                          icon: Icons.logout_rounded,
                          color: AppTheme.error,
                        ),
                        const SizedBox(height: AppTheme.spacing16),

                        // App version footer
                        Center(
                          child: Text(
                            'KaShoes v1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                      ],
                    ),
                  ),
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final dynamic user;

  const _ProfileHeader({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: AppTheme.cardRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Text(
                user?.name?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Pengguna',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 8),
                if (user != null) MemberBadge(isMember: user!.isMember),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final dynamic user;

  const _InfoCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _ProfileInfoTile(
            icon: Icons.person_outline,
            label: 'Nama Lengkap',
            value: user?.name ?? '-',
          ),
          const Divider(height: 1),
          _ProfileInfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user?.email ?? '-',
          ),
          const Divider(height: 1),
          _ProfileInfoTile(
            icon: Icons.phone_outlined,
            label: 'Nomor Telepon',
            value: AppFormatters.formatPhone(user?.phone),
          ),
          const Divider(height: 1),
          _ProfileInfoTile(
            icon: Icons.location_on_outlined,
            label: 'Alamat',
            value: user?.address ?? '-',
          ),
          const Divider(height: 1),
          _ProfileInfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'Bergabung',
            value: AppFormatters.formatDate(user?.createdAt),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Editable Section ─────────────────────────────────────────────────────────

class _EditableSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final VoidCallback onSave;
  final bool isSaving;

  const _EditableSection({
    required this.formKey,
    required this.phoneController,
    required this.addressController,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AppTextField(
            label: 'Nomor Telepon',
            controller: phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: AppValidators.phone,
          ),
          const SizedBox(height: AppTheme.spacing12),
          AppTextField(
            label: 'Alamat',
            controller: addressController,
            maxLines: 3,
            prefixIcon: Icons.location_on_outlined,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => AppValidators.required(v, fieldName: 'Alamat'),
          ),
          const SizedBox(height: AppTheme.spacing20),
          AppButton(
            label: 'Simpan Perubahan',
            onPressed: onSave,
            isLoading: isSaving,
            icon: Icons.save_outlined,
          ),
        ],
      ),
    );
  }
}
