import 'package:flutter/material.dart';

class _ShimmerPainter extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets margin;

  const _ShimmerPainter({
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  final Widget child;

  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(opacity: _opacity.value, child: child),
      child: widget.child,
    );
  }
}

Widget skeletonLine({
  double width = double.infinity,
  double height = 14,
  double borderRadius = 6,
  EdgeInsets margin = const EdgeInsets.symmetric(vertical: 4),
}) {
  return _ShimmerWidget(
    child: _ShimmerPainter(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    ),
  );
}

Widget skeletonBox({
  double width = double.infinity,
  double height = 100,
  double borderRadius = 12,
  EdgeInsets margin = EdgeInsets.zero,
}) {
  return _ShimmerWidget(
    child: _ShimmerPainter(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    ),
  );
}

Widget skeletonCircle({
  double size = 48,
  EdgeInsets margin = EdgeInsets.zero,
}) {
  return _ShimmerWidget(
    child: _ShimmerPainter(
      width: size,
      height: size,
      borderRadius: size / 2,
      margin: margin,
    ),
  );
}

Widget skeletonCard({EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6)}) {
  return _ShimmerWidget(
    child: Padding(
      padding: margin,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                skeletonCircle(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      skeletonLine(width: 140, height: 14, margin: EdgeInsets.zero),
                      const SizedBox(height: 4),
                      skeletonLine(width: 80, height: 10, margin: EdgeInsets.zero),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            skeletonLine(height: 12, margin: EdgeInsets.zero),
            const SizedBox(height: 6),
            skeletonLine(width: 200, height: 12, margin: EdgeInsets.zero),
            const SizedBox(height: 12),
            Row(
              children: [
                skeletonBox(width: 80, height: 32, borderRadius: 8),
                const Spacer(),
                skeletonBox(width: 60, height: 24, borderRadius: 6),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget skeletonListItem({EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4)}) {
  return _ShimmerWidget(
    child: Padding(
      padding: margin,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            skeletonCircle(size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  skeletonLine(width: 160, height: 13, margin: EdgeInsets.zero),
                  const SizedBox(height: 4),
                  skeletonLine(width: 90, height: 10, margin: EdgeInsets.zero),
                ],
              ),
            ),
            skeletonBox(width: 60, height: 18, borderRadius: 4),
          ],
        ),
      ),
    ),
  );
}

Widget skeletonDetailPage(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.height * 0.35,
          pinned: true,
          backgroundColor: const Color(0xFF0D9488),
          flexibleSpace: const FlexibleSpaceBar(
            background: _ShimmerWidget(
              child: _ShimmerPainter(height: 300, borderRadius: 0),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _skeletonProgressCard(),
                const SizedBox(height: 16),
                _skeletonSection(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          skeletonBox(width: 4, height: 20, borderRadius: 2),
                          const SizedBox(width: 10),
                          skeletonLine(width: 100, height: 16, margin: EdgeInsets.zero),
                        ],
                      ),
                      const SizedBox(height: 14),
                      skeletonLine(height: 12, margin: EdgeInsets.zero),
                      const SizedBox(height: 6),
                      skeletonLine(height: 12, margin: EdgeInsets.zero),
                      const SizedBox(height: 6),
                      skeletonLine(width: 180, height: 12, margin: EdgeInsets.zero),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                _skeletonSection(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      skeletonLine(width: 120, height: 16, margin: EdgeInsets.zero),
                      const SizedBox(height: 16),
                      skeletonListItem(margin: EdgeInsets.zero),
                      const SizedBox(height: 8),
                      skeletonListItem(margin: EdgeInsets.zero),
                      const SizedBox(height: 8),
                      skeletonListItem(margin: EdgeInsets.zero),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _skeletonProgressCard() {
  return _ShimmerWidget(
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    skeletonLine(width: 80, height: 12, margin: EdgeInsets.zero),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        skeletonLine(width: 100, height: 24, margin: EdgeInsets.zero),
                        const SizedBox(width: 4),
                        skeletonLine(width: 30, height: 12, margin: EdgeInsets.zero),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  skeletonLine(width: 40, height: 12, margin: EdgeInsets.zero),
                  const SizedBox(height: 8),
                  skeletonLine(width: 80, height: 16, margin: EdgeInsets.zero),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          skeletonLine(height: 10, borderRadius: 6, margin: EdgeInsets.zero),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Row(
            children: [
              skeletonCircle(size: 36),
              const SizedBox(width: 10),
              Expanded(child: skeletonLine(height: 12, margin: EdgeInsets.zero)),
              const SizedBox(width: 16),
              skeletonCircle(size: 36),
              const SizedBox(width: 10),
              Expanded(child: skeletonLine(height: 12, margin: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _skeletonSection(Widget Function() builder) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: builder(),
  );
}

Widget skeletonListPage({int itemCount = 5, EdgeInsets padding = const EdgeInsets.only(top: 16)}) {
  return Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    body: SafeArea(
      child: Padding(
        padding: padding,
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (_, __) => skeletonCard(),
        ),
      ),
    ),
  );
}
