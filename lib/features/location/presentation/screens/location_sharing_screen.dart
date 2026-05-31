import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/location_provider.dart';

class LocationSharingScreen extends ConsumerStatefulWidget {
  final int orderId;

  const LocationSharingScreen({super.key, required this.orderId});

  @override
  ConsumerState<LocationSharingScreen> createState() =>
      _LocationSharingScreenState();
}

class _LocationSharingScreenState extends ConsumerState<LocationSharingScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Auto-start sharing on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationSharingProvider(widget.orderId).notifier).startSharing();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationSharingProvider(widget.orderId));
    final position = state.currentPosition;

    // Center map on position updates
    ref.listen(locationSharingProvider(widget.orderId), (_, next) {
      if (next.currentPosition != null) {
        try {
          _mapController.move(
            LatLng(next.currentPosition!.latitude, next.currentPosition!.longitude),
            _mapController.camera.zoom,
          );
        } catch (_) {}
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('Pesanan #${widget.orderId}'),
        actions: [
          if (state.isSharing)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.success.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PulsingDot(),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ─── Map ─────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: position != null
                  ? LatLng(position.latitude, position.longitude)
                  : const LatLng(-6.2088, 106.8456), // Default: Jakarta
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kashoes.mobile',
              ),
              if (position != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(position.latitude, position.longitude),
                      width: 60,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: AppTheme.elevatedShadow,
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                          CustomPaint(
                            size: const Size(14, 10),
                            painter: _TrianglePainter(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              // OSM Attribution
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('OpenStreetMap contributors')],
              ),
            ],
          ),

          // ─── Status Panel (bottom) ────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _StatusPanel(
              state: state,
              orderId: widget.orderId,
              onStart: () =>
                  ref.read(locationSharingProvider(widget.orderId).notifier).startSharing(),
              onStop: () {
                ref.read(locationSharingProvider(widget.orderId).notifier).stopSharing();
                Navigator.of(context).pop();
              },
            ),
          ),

          // ─── Loading overlay ──────────────────────────────────────────
          if (state.status == LocationSharingStatus.requesting)
            const ColoredBox(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Mengambil lokasi...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Status Panel ─────────────────────────────────────────────────────────────

class _StatusPanel extends StatelessWidget {
  final LocationSharingState state;
  final int orderId;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _StatusPanel({
    required this.state,
    required this.orderId,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (state.isSharing) ...[
            const Text(
              'Berbagi Lokasi Aktif',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (state.currentPosition != null)
              Text(
                '${state.currentPosition!.latitude.toStringAsFixed(5)}, '
                '${state.currentPosition!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            if (state.currentPosition != null)
              Text(
                'Akurasi: ±${state.currentPosition!.accuracy.toStringAsFixed(0)}m',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onStop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Hentikan Berbagi', style: TextStyle(fontSize: 16)),
              ),
            ),
          ] else if (state.status == LocationSharingStatus.error) ...[
            const Text(
              'Gagal Berbagi Lokasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              state.errorMessage ?? 'Pastikan GPS dan koneksi internet aktif.',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi', style: TextStyle(fontSize: 16)),
              ),
            ),
          ] else if (state.status == LocationSharingStatus.stopped) ...[
            const Text(
              'Berbagi Lokasi Dihentikan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lokasi Anda tidak lagi dikirimkan ke admin.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.primary;
    final path = ui.Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
