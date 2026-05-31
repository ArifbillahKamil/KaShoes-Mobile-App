import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

/// Shimmer placeholder card for loading states.
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 100,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? AppTheme.cardRadius,
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a list of items.
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => ShimmerCard(height: itemHeight),
      ),
    );
  }
}

/// Shimmer for a horizontal row of chips/cards.
class ShimmerChipRow extends StatelessWidget {
  final int count;

  const ShimmerChipRow({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Row(
        children: List.generate(
          count,
          (i) => Container(
            margin: EdgeInsets.only(left: i == 0 ? AppTheme.spacing16 : 8, right: 4),
            height: 36,
            width: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.chipRadius,
            ),
          ),
        ),
      ),
    );
  }
}
