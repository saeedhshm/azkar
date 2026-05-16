import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Loading Shimmer موحّد — يستبدل CircularProgressIndicator العادي
class AppLoadingShimmer extends StatefulWidget {
  const AppLoadingShimmer({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  final Widget child;
  final bool isLoading;

  @override
  State<AppLoadingShimmer> createState() => _AppLoadingShimmerState();
}

class _AppLoadingShimmerState extends State<AppLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;
    final colors = AppThemeColors.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colors.shimmerBase,
            colors.shimmerHighlight,
            colors.shimmerBase,
          ],
          stops: [
            (_animation.value - 0.3).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 0.3).clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        blendMode: BlendMode.srcATop,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Shimmer Box — صندوق shimmer لملء مكان المحتوى
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Grid Shimmer للـ Category Cards
class AppGridShimmer extends StatelessWidget {
  const AppGridShimmer({
    super.key,
    this.count = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.05,
  });

  final int count;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return AppLoadingShimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (_, __) => const _ShimmerCard(),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.shimmerBase,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 28, height: 28, radius: 8),
              const Spacer(),
              ShimmerBox(width: 36, height: 20, radius: 10),
            ],
          ),
          const Spacer(),
          ShimmerBox(width: double.infinity, height: 16, radius: 8),
          const SizedBox(height: 6),
          ShimmerBox(width: 80, height: 12, radius: 6),
        ],
      ),
    );
  }
}

/// List Shimmer للـ Adhkar tiles
class AppListShimmer extends StatelessWidget {
  const AppListShimmer({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AppLoadingShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _ShimmerTile(),
      ),
    );
  }
}

class _ShimmerTile extends StatelessWidget {
  const _ShimmerTile();

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.shimmerBase,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ShimmerBox(width: double.infinity, height: 16, radius: 8),
          const SizedBox(height: 8),
          ShimmerBox(width: 220, height: 16, radius: 8),
          const SizedBox(height: 8),
          ShimmerBox(width: 160, height: 14, radius: 8),
          const SizedBox(height: 12),
          Row(
            children: [
              ShimmerBox(width: 80, height: 24, radius: 12),
              const SizedBox(width: 8),
              ShimmerBox(width: 100, height: 24, radius: 12),
            ],
          ),
          const SizedBox(height: 10),
          ShimmerBox(width: double.infinity, height: 6, radius: 3),
        ],
      ),
    );
  }
}
