import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/service_model.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/order_provider.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  ServiceModel? _selectedService;

  @override
  void initState() {
    super.initState();
    // Auto-fill from user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _nameController.text = user.name;
        _phoneController.text = user.phone ?? '';
        _addressController.text = user.address ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    ref.read(createOrderProvider.notifier).reset();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih layanan terlebih dahulu'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    await ref.read(createOrderProvider.notifier).submitOrder(
          customerName: _nameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          customerAddress: _addressController.text.trim(),
          serviceId: _selectedService!.id,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createOrderProvider);
    final servicesAsync = ref.watch(servicesProvider);

    // Listen for success/error
    ref.listen<CreateOrderState>(createOrderProvider, (_, next) {
      if (next.status == CreateOrderStatus.success && next.createdOrder != null) {
        _showSuccessDialog(next.createdOrder!.id, next.createdOrder!.orderNumber);
      } else if (next.status == CreateOrderStatus.error && next.errorMessage != null) {
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
        title: const Text('Pesan Layanan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            children: [
              // ─── Customer Info Section ─────────────────────────────────
              _SectionHeader(title: 'Informasi Pelanggan', icon: Icons.person_outline),
              const SizedBox(height: AppTheme.spacing12),

              AppTextField(
                label: 'Nama Lengkap',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                readOnly: true, // Auto-filled, not editable
                validator: (v) => AppValidators.required(v, fieldName: 'Nama'),
              ),
              const SizedBox(height: AppTheme.spacing12),

              AppTextField(
                label: 'Nomor Telepon',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: AppValidators.phone,
              ),
              const SizedBox(height: AppTheme.spacing12),

              AppTextField(
                label: 'Alamat Pengiriman / Penjemputan',
                hint: 'Masukkan alamat lengkap',
                controller: _addressController,
                prefixIcon: Icons.location_on_outlined,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => AppValidators.required(v, fieldName: 'Alamat'),
              ),

              const SizedBox(height: AppTheme.spacing24),

              // ─── Service Selection ──────────────────────────────────────
              _SectionHeader(title: 'Pilih Layanan', icon: Icons.cleaning_services_outlined),
              const SizedBox(height: AppTheme.spacing12),

              servicesAsync.when(
                loading: () => const ShimmerServiceList(),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.05),
                    borderRadius: AppTheme.cardRadius,
                    border: Border.all(color: AppTheme.error.withOpacity(0.2)),
                  ),
                  child: Text(
                    'Gagal memuat layanan. Periksa koneksi internet.',
                    style: TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ),
                data: (services) => Column(
                  children: services
                      .map((s) => _ServiceTile(
                            service: s,
                            isSelected: _selectedService?.id == s.id,
                            onTap: () => setState(() => _selectedService = s),
                          ))
                      .toList(),
                ),
              ),

              const SizedBox(height: AppTheme.spacing24),

              // ─── Notes ──────────────────────────────────────────────────
              _SectionHeader(title: 'Catatan Tambahan', icon: Icons.note_outlined),
              const SizedBox(height: AppTheme.spacing12),

              AppTextField(
                label: 'Catatan (opsional)',
                hint: 'Contoh: Sepatu olahraga putih, kotor di bagian sol',
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: AppTheme.spacing24),

              // ─── Location Section ────────────────────────────────────────
              _SectionHeader(title: 'Lokasi Saat Ini', icon: Icons.my_location_outlined),
              const SizedBox(height: AppTheme.spacing12),

              _LocationSection(orderState: createState),

              const SizedBox(height: AppTheme.spacing32),

              // ─── Submit Button ───────────────────────────────────────────
              AppButton(
                label: 'Buat Pesanan',
                onPressed: _submit,
                isLoading: createState.status == CreateOrderStatus.loading,
                icon: Icons.send_rounded,
              ),

              const SizedBox(height: AppTheme.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(int orderId, String? orderNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppTheme.success, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pesanan Berhasil!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              orderNumber != null
                  ? 'Nomor Pesanan: $orderNumber'
                  : 'Pesanan ID: #$orderId',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tim kami akan segera memproses pesanan Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/orders/$orderId');
              },
              child: const Text('Lihat Status Pesanan'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Location Section ─────────────────────────────────────────────────────────

class _LocationSection extends ConsumerWidget {
  final CreateOrderState orderState;

  const _LocationSection({required this.orderState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = orderState.currentPosition;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          if (position != null) ...[
            // Map preview
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 180,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(position.latitude, position.longitude),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.kashoes.mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(position.latitude, position.longitude),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: AppTheme.error,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Lokasi diperoleh (${position.latitude.toStringAsFixed(5)}, '
                  '${position.longitude.toStringAsFixed(5)})',
                  style: const TextStyle(fontSize: 12, color: AppTheme.success),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else ...[
            const Icon(Icons.location_off_outlined, size: 36, color: AppTheme.textSecondary),
            const SizedBox(height: 8),
            const Text(
              'Lokasi belum diambil',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bagikan lokasi Anda agar tim kami bisa menjemput pesanan',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
          ],

          if (orderState.errorMessage != null &&
              orderState.status != CreateOrderStatus.error) ...[
            Text(
              orderState.errorMessage!,
              style: const TextStyle(color: AppTheme.error, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],

          AppButton(
            label: position != null ? 'Perbarui Lokasi' : 'Ambil Lokasi Saya',
            onPressed: () => ref.read(createOrderProvider.notifier).getCurrentLocation(),
            isLoading: orderState.isGettingLocation,
            isOutlined: position != null,
            icon: Icons.my_location,
            height: 44,
          ),
        ],
      ),
    );
  }
}

// ─── Service Tile ─────────────────────────────────────────────────────────────

class _ServiceTile extends StatelessWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.06) : Colors.white,
          borderRadius: AppTheme.cardRadius,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isSelected ? AppTheme.primary : AppTheme.textSecondary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.cleaning_services,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  if (service.description != null)
                    Text(
                      service.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
            if (service.price != null)
              Text(
                'Rp ${(service.price! / 1000).toStringAsFixed(0)}rb',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class ShimmerServiceList extends StatelessWidget {
  const ShimmerServiceList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 70,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: AppTheme.cardRadius,
          ),
        ),
      ),
    );
  }
}
