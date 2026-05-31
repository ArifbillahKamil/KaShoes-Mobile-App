import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/order_provider.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderListProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.secondary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              text: 'Aktif${state.activeOrders.isNotEmpty ? " (${state.activeOrders.length})" : ""}',
            ),
            const Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(orderListProvider.notifier).load(),
        color: AppTheme.primary,
        child: TabBarView(
          controller: _tabController,
          children: [
            _OrderTab(
              orders: state.activeOrders,
              isLoading: state.status == OrderListStatus.loading,
              errorMessage: state.status == OrderListStatus.error ? state.errorMessage : null,
              emptyTitle: 'Tidak Ada Pesanan Aktif',
              emptyMessage: 'Buat pesanan baru untuk memulai',
              onRetry: () => ref.read(orderListProvider.notifier).load(),
              onLoadMore: null, // Active orders don't need load more
            ),
            _OrderTab(
              orders: state.historyOrders,
              isLoading: state.status == OrderListStatus.loading,
              errorMessage: state.status == OrderListStatus.error ? state.errorMessage : null,
              emptyTitle: 'Riwayat Kosong',
              emptyMessage: 'Pesanan yang sudah selesai akan muncul di sini',
              onRetry: () => ref.read(orderListProvider.notifier).load(),
              onLoadMore: state.hasMore
                  ? () => ref.read(orderListProvider.notifier).loadMore()
                  : null,
              isLoadingMore: state.status == OrderListStatus.loadingMore,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/orders/new'),
        icon: const Icon(Icons.add),
        label: const Text('Pesan Baru'),
      ),
    );
  }
}

class _OrderTab extends StatelessWidget {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? errorMessage;
  final String emptyTitle;
  final String emptyMessage;
  final VoidCallback onRetry;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  const _OrderTab({
    required this.orders,
    required this.isLoading,
    this.errorMessage,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onRetry,
    this.onLoadMore,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && orders.isEmpty) {
      return const ShimmerList(itemCount: 4, itemHeight: 100);
    }

    if (errorMessage != null && orders.isEmpty) {
      return ErrorView(message: errorMessage, onRetry: onRetry);
    }

    if (orders.isEmpty) {
      return EmptyView(
        title: emptyTitle,
        message: emptyMessage,
        icon: Icons.receipt_long_outlined,
        onAction: () => Navigator.of(context).pushNamed('/orders/new'),
        actionLabel: 'Buat Pesanan',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      itemCount: orders.length + (onLoadMore != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == orders.length) {
          // Load more button / indicator
          return isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : TextButton(
                  onPressed: onLoadMore,
                  child: const Text('Muat Lebih Banyak'),
                );
        }
        return _OrderListTile(order: orders[index]);
      },
    );
  }
}

class _OrderListTile extends StatelessWidget {
  final OrderModel order;

  const _OrderListTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: 6,
        ),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.cardRadius,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        order.serviceName ?? 'Layanan Sepatu',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (order.orderNumber != null)
                        Text(
                          order.orderNumber!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            const Divider(height: 1),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  text: AppFormatters.formatDate(order.createdAt),
                ),
                const SizedBox(width: 12),
                if (order.notes != null)
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.note_outlined,
                      text: order.notes!,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
            if (order.isActive) ...[
              const SizedBox(height: AppTheme.spacing12),
              // Status stepper mini
              _MiniStatusStepper(status: order.status),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _InfoChip({required this.icon, required this.text, this.maxLines = 2});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _MiniStatusStepper extends StatelessWidget {
  final String status;

  const _MiniStatusStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = ['pending', 'confirmed', 'processing', 'ready', 'completed'];
    final currentIndex = steps.indexOf(status.toLowerCase());

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepIndex < currentIndex ? AppTheme.primary : AppTheme.divider,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isDone = stepIndex <= currentIndex;
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppTheme.primary : AppTheme.divider,
          ),
          child: isDone
              ? const Icon(Icons.check, size: 10, color: Colors.white)
              : null,
        );
      }),
    );
  }
}
