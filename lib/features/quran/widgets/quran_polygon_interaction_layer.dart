import 'package:flutter/material.dart';

import '../domain/entities/ayah_highlight.dart';
import '../domain/entities/quran_page.dart';
import '../services/quran_polygon_hit_test_engine.dart';

class QuranPolygonInteractionLayer extends StatefulWidget {
  const QuranPolygonInteractionLayer({
    super.key,
    required this.page,
    required this.hitTestEngine,
    required this.highlights,
    this.animatingIds = const {},
    this.isNightMode = false,
  });

  final QuranPage page;
  final QuranPolygonHitTestEngine hitTestEngine;
  final List<AyahHighlight> highlights;
  final Set<String> animatingIds;
  final bool isNightMode;

  @override
  State<QuranPolygonInteractionLayer> createState() =>
      _QuranPolygonInteractionLayerState();
}

class _QuranPolygonInteractionLayerState
    extends State<QuranPolygonInteractionLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.animatingIds.isNotEmpty) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant QuranPolygonInteractionLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animatingIds != oldWidget.animatingIds &&
        widget.animatingIds.isNotEmpty) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          return CustomPaint(
            painter: _AyahHighlightPainter(
              page: widget.page,
              highlights: widget.highlights,
              animatingIds: widget.animatingIds,
              animationValue: _pulseAnimation.value,
              hitTestEngine: widget.hitTestEngine,
              isDark: isDark || widget.isNightMode,
            ),
            isComplex: true,
            willChange: true,
          );
        },
      ),
    );
  }
}

class _AyahHighlightPainter extends CustomPainter {
  _AyahHighlightPainter({
    required this.page,
    required this.highlights,
    required this.animatingIds,
    required this.animationValue,
    required this.hitTestEngine,
    required this.isDark,
  }) : _highlightMap = _buildHighlightMap(highlights);

  final QuranPage page;
  final List<AyahHighlight> highlights;
  final Set<String> animatingIds;
  final double animationValue;
  final QuranPolygonHitTestEngine hitTestEngine;
  final bool isDark;
  final Map<String, AyahHighlight> _highlightMap;

  static Map<String, AyahHighlight> _buildHighlightMap(
    List<AyahHighlight> highlights,
  ) {
    if (highlights.isEmpty) return const {};
    final map = <String, AyahHighlight>{};
    for (final h in highlights) {
      final existing = map[h.polygonId];
      if (existing == null || h.type.priority > existing.type.priority) {
        map[h.polygonId] = h;
      }
    }
    return map;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_highlightMap.isEmpty) return;

    for (final entry in _highlightMap.entries) {
      final highlight = entry.value;
      final path = hitTestEngine.polygonPath(page, highlight.polygonId);
      if (path == null) continue;

      final isAnimating = animatingIds.contains(highlight.id);
      final progress = isAnimating ? animationValue : 1.0;
      if (progress <= 0.001) continue;

      _drawHighlight(canvas, path, highlight.type, progress);
    }
  }

  void _drawHighlight(
    Canvas canvas,
    Path path,
    AyahHighlightType type,
    double progress,
  ) {
    final theme = _themeForType(type);
    final easedOpacity = _easeOutCubic(progress);
    final easedStroke = _easeOutBack(progress);

    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        theme.glowRadius * (0.5 + 0.5 * progress),
      )
      ..color = theme.glowColor.withValues(alpha: easedOpacity * 0.6);
    canvas.drawPath(path, glowPaint);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = theme.fillColor.withValues(alpha: easedOpacity * 0.7);
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.strokeWidth * (0.5 + 0.5 * easedStroke)
      ..color = theme.strokeColor.withValues(alpha: easedOpacity * 0.9);
    canvas.drawPath(path, strokePaint);
  }

  _CachedTheme _themeForType(AyahHighlightType type) {
    switch (type) {
      case AyahHighlightType.tap:
        return isDark ? _darkTapTheme : _lightTapTheme;
      case AyahHighlightType.reading:
        return isDark ? _darkReadingTheme : _lightReadingTheme;
      case AyahHighlightType.search:
        return isDark ? _darkSearchTheme : _lightSearchTheme;
      case AyahHighlightType.bookmark:
        return isDark ? _darkBookmarkTheme : _lightBookmarkTheme;
    }
  }

  static double _easeOutCubic(double t) {
    return 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
  }

  static double _easeOutBack(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1.0;
    return 1.0 + c3 * (t - 1.0) * (t - 1.0) * (t - 1.0) +
        c1 * (t - 1.0) * (t - 1.0);
  }

  @override
  bool shouldRepaint(covariant _AyahHighlightPainter oldDelegate) {
    return oldDelegate.highlights != highlights ||
        oldDelegate.animatingIds != animatingIds ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.page != page ||
        oldDelegate.isDark != isDark;
  }
}

class _CachedTheme {
  const _CachedTheme({
    required this.glowColor,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.glowRadius,
  });

  final Color glowColor;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final double glowRadius;
}

const _lightTapTheme = _CachedTheme(
  glowColor: Color(0x33D4AF37),
  fillColor: Color(0x22D4AF37),
  strokeColor: Color(0xFFD4AF37),
  strokeWidth: 2.5,
  glowRadius: 10,
);

const _darkTapTheme = _CachedTheme(
  glowColor: Color(0x44D4AF37),
  fillColor: Color(0x33D4AF37),
  strokeColor: Color(0xFFD4AF37),
  strokeWidth: 2.5,
  glowRadius: 10,
);

const _lightReadingTheme = _CachedTheme(
  glowColor: Color(0x3356C5A0),
  fillColor: Color(0x2256C5A0),
  strokeColor: Color(0xFF56C5A0),
  strokeWidth: 2.5,
  glowRadius: 10,
);

const _darkReadingTheme = _CachedTheme(
  glowColor: Color(0x4456C5A0),
  fillColor: Color(0x3356C5A0),
  strokeColor: Color(0xFF56C5A0),
  strokeWidth: 2.5,
  glowRadius: 10,
);

const _lightSearchTheme = _CachedTheme(
  glowColor: Color(0x33F5C542),
  fillColor: Color(0x22F5C542),
  strokeColor: Color(0xFFF5C542),
  strokeWidth: 2.5,
  glowRadius: 10,
);

const _darkSearchTheme = _CachedTheme(
  glowColor: Color(0x44F5C542),
  fillColor: Color(0x33F5C542),
  strokeColor: Color(0xFFF5C542),
  strokeWidth: 2.5,
  glowRadius: 10,
);

const _lightBookmarkTheme = _CachedTheme(
  glowColor: Color(0x3334C759),
  fillColor: Color(0x2234C759),
  strokeColor: Color(0xFF34C759),
  strokeWidth: 2.5,
  glowRadius: 10,
);

const _darkBookmarkTheme = _CachedTheme(
  glowColor: Color(0x4434C759),
  fillColor: Color(0x3334C759),
  strokeColor: Color(0xFF34C759),
  strokeWidth: 2.5,
  glowRadius: 10,
);
