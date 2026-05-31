import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/service_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_card.dart';
import '../../../../shared/widgets/status_badge.dart';

import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardHome(),
          _OrdersPlaceholder(),
          _ProfilePlaceholder(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/orders/new'),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Pesan Sekarang'),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class _DashboardHome extends ConsumerWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).load(forceRefresh: true),
      color: AppTheme.primary,
      child: CustomScrollView(
        slivers: [
          // ─── Header ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeaderSection(user: state.user, activeCount: state.activeOrderCount),
          ),

          // ─── Cache banner ───────────────────────────────────────────────
          if (state.isFromCache)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, size: 16, color: AppTheme.warning),
                    const SizedBox(width: 8),
                    Text(
                      'Menampilkan data tersimpan (offline)',
                      style: TextStyle(fontSize: 12, color: AppTheme.warning),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Services ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ServicesSection(
              services: state.services,
              isLoading: state.status == DashboardStatus.loading && state.services.isEmpty,
            ),
          ),

          // ─── Active Orders Card ──────────────────────────────────────────
          if (state.activeOrderCount > 0)
            SliverToBoxAdapter(
              child: _ActiveOrdersCard(count: state.activeOrderCount),
            ),

          // ─── Recent Orders ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _RecentOrdersSection(
              orders: state.recentOrders,
              isLoading: state.status == DashboardStatus.loading && state.recentOrders.isEmpty,
              errorMessage: state.status == DashboardStatus.error ? state.errorMessage : null,
              onRetry: () => ref.read(dashboardProvider.notifier).load(forceRefresh: true),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final UserModel? user;
  final int activeCount;

  const _HeaderSection({this.user, required this.activeCount});

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.name ?? 'Pengguna',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Member badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: user?.isMember == true
                          ? const LinearGradient(
                              colors: [AppTheme.secondary, AppTheme.accent],
                            )
                          : null,
                      color: user?.isMember == true
                          ? null
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user?.isMember == true
                              ? Icons.workspace_premium
                              : Icons.person_outline,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user?.isMember == true ? 'Member' : 'Non-Member',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats row
              Row(
                children: [
                  _StatCard(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Pesanan Aktif',
                    value: activeCount.toString(),
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.local_offer_outlined,
                    label: 'Layanan',
                    value: 'Lihat Semua',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi 🌅';
    if (hour < 15) return 'Selamat Siang ☀️';
    if (hour < 18) return 'Selamat Sore 🌤';
    return 'Selamat Malam 🌙';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Services Section ─────────────────────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  final List<ServiceModel> services;
  final bool isLoading;

  const _ServicesSection({required this.services, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Layanan Kami',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (isLoading)
          const ShimmerChipRow()
        else if (services.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Tidak ada layanan tersedia.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: services.length,
              itemBuilder: (context, i) => _ServiceChip(service: services[i]),
            ),
          ),
      ],
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final ServiceModel service;

  const _ServiceChip({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/orders/new'),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.cardRadius,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cleaning_services, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              service.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            if (service.price != null) ...[
              const SizedBox(height: 2),
              Text(
                AppFormatters.formatCurrency(service.price),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Active Orders Card ───────────────────────────────────────────────────────

class _ActiveOrdersCard extends StatelessWidget {
  final int count;

  const _ActiveOrdersCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/orders'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.secondary, AppTheme.accent],
          ),
          borderRadius: AppTheme.cardRadius,
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count Pesanan Aktif',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Ketuk untuk melihat status pesanan',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Recent Orders Section ────────────────────────────────────────────────────

class _RecentOrdersSection extends StatelessWidget {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _RecentOrdersSection({
    required this.orders,
    required this.isLoading,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pesanan Terbaru', style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/orders'),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
        ),
        if (isLoading)
          const ShimmerList(itemCount: 2, itemHeight: 90)
        else if (errorMessage != null)
          ErrorView(message: errorMessage, onRetry: onRetry)
        else if (orders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.cardRadius,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 40, color: AppTheme.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  const Text(
                    'Belum ada pesanan',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ...orders.map((order) => _OrderCard(order: order)),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.cardRadius,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cleaning_services, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.serviceName ?? 'Layanan',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppFormatters.formatDate(order.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(status: order.status, isSmall: true),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Placeholders (navigate to separate screens) ─────────────────────────

class _OrdersPlaceholder extends StatelessWidget {
  const _OrdersPlaceholder();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/orders');
    });
    return const SizedBox.shrink();
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/profile');
    });
    return const SizedBox.shrink();
  }
}
