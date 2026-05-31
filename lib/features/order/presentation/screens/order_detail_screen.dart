import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/order_status_model.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: orderAsync.when(
        loading: () => const ShimmerList(itemCount: 5, itemHeight: 80),
        error: (e, _) => ErrorView(
          message: 'Gagal memuat detail pesanan',
          onRetry: () => ref.refresh(orderDetailProvider(orderId)),
        ),
        data: (order) => _OrderDetailContent(order: order),
      ),
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  final OrderModel order;

  const _OrderDetailContent({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Order Header Card ────────────────────────────────────────
          _DetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (order.orderNumber != null)
                            Text(
                              order.orderNumber!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Text(
                            order.serviceName ?? 'Layanan Sepatu',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing12),
                const Divider(),
                const SizedBox(height: AppTheme.spacing12),
                _InfoRow(label: 'Tanggal', value: AppFormatters.formatDateTime(order.createdAt)),
                _InfoRow(label: 'Nama', value: order.customerName),
                _InfoRow(label: 'Telepon', value: order.customerPhone),
                _InfoRow(label: 'Alamat', value: order.customerAddress),
                if (order.notes != null && order.notes!.isNotEmpty)
                  _InfoRow(label: 'Catatan', value: order.notes!),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacing16),

          // ─── Status Timeline ──────────────────────────────────────────
          _SectionTitle(title: 'Riwayat Status', icon: Icons.timeline),
          const SizedBox(height: AppTheme.spacing8),
          _StatusTimeline(order: order),

          const SizedBox(height: AppTheme.spacing16),

          // ─── Location Map ─────────────────────────────────────────────
          if (order.hasLocation) ...[
            _SectionTitle(title: 'Lokasi Pesanan', icon: Icons.location_on_outlined),
            const SizedBox(height: AppTheme.spacing8),
            _LocationMapCard(
              lat: order.latitude!,
              lng: order.longitude!,
              orderId: order.id,
              isActive: order.isActive,
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],

          // ─── Action buttons ────────────────────────────────────────────
          if (order.isActive) ...[
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/location/${order.id}'),
              icon: const Icon(Icons.share_location),
              label: const Text('Bagikan Lokasi Real-Time'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ],
      ),
    );
  }
}

// ─── Status Timeline ──────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final OrderModel order;

  const _StatusTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    final histories = order.statusHistories ?? [];

    // If no histories, build a synthetic one from the current status flow
    if (histories.isEmpty) {
      return _SyntheticTimeline(currentStatus: order.status);
    }

    return _DetailCard(
      child: Column(
        children: histories
            .asMap()
            .entries
            .map((entry) {
              final isLast = entry.key == histories.length - 1;
              return _TimelineItem(
                statusHistory: entry.value,
                isLast: isLast,
              );
            })
            .toList(),
      ),
    );
  }
}

class _SyntheticTimeline extends StatelessWidget {
  final String currentStatus;

  const _SyntheticTimeline({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final currentIndex = orderStatusFlow.indexOf(currentStatus.toLowerCase());

    return _DetailCard(
      child: Column(
        children: orderStatusFlow.asMap().entries.map((entry) {
          final i = entry.key;
          final status = entry.value;
          final isDone = i <= currentIndex;
          final isCurrent = i == currentIndex;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppTheme.primary : AppTheme.divider,
                      border: isCurrent
                          ? Border.all(color: AppTheme.primary, width: 2)
                          : null,
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.circle,
                      size: isDone ? 14 : 8,
                      color: Colors.white,
                    ),
                  ),
                  if (i < orderStatusFlow.length - 1)
                    Container(
                      width: 2,
                      height: 32,
                      color: isDone ? AppTheme.primary.withOpacity(0.3) : AppTheme.divider,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Text(
                    orderStatusLabel(status),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                      color: isDone ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final OrderStatusModel statusHistory;
  final bool isLast;

  const _TimelineItem({required this.statusHistory, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: AppTheme.primary.withOpacity(0.3)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusHistory.label ?? orderStatusLabel(statusHistory.status),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (statusHistory.note != null)
                  Text(statusHistory.note!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text(
                  AppFormatters.formatDateTime(statusHistory.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Location Map Card ────────────────────────────────────────────────────────

class _LocationMapCard extends StatelessWidget {
  final double lat;
  final double lng;
  final int orderId;
  final bool isActive;

  const _LocationMapCard({
    required this.lat,
    required this.lng,
    required this.orderId,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
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
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin, color: AppTheme.error, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // OSM attribution (required)
          Text(
            '© OpenStreetMap contributors',
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.formatCoordinates(lat, lng),
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final Widget child;

  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
