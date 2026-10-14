import 'package:flutter/animation.dart';
import 'package:photo_view/photo_view.dart';

/// Owns the double-tap zoom of a single Mushaf page.
///
/// The animated scale must be pushed into the [PhotoViewController]. Updating a
/// local field alone leaves the viewer untouched, so the zoom had no visible
/// effect.
class QuranPageZoomController {
  QuranPageZoomController({
    required TickerProvider vsync,
    required PhotoViewController photoViewController,
    this.duration = const Duration(milliseconds: 300),
    this.zoomedScale = 2.8,
    this.resetThreshold = 1.5,
  }) : _photoViewController = photoViewController {
    _animationController = AnimationController(vsync: vsync, duration: duration)
      ..addListener(_handleAnimation);
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  final PhotoViewController _photoViewController;
  final Duration duration;
  final double zoomedScale;
  final double resetThreshold;

  late final AnimationController _animationController;
  late final Animation<double> _animation;

  double _currentScale = 1.0;
  double _targetScale = 1.0;

  /// The scale currently applied to the viewer.
  double get currentScale => _currentScale;

  /// Whether a double tap would zoom out instead of zooming in.
  bool get isZoomedIn => _currentScale > resetThreshold;

  /// Toggles between the zoomed-in and fit-to-page scale.
  void toggle() {
    _targetScale = isZoomedIn ? 1.0 : zoomedScale;
    if (!isZoomedIn) {
      _photoViewController.position = Offset.zero;
    }
    _animationController.forward(from: 0);
  }

  /// Returns the viewer to the fit-to-page scale.
  void reset() {
    _currentScale = 1.0;
    _targetScale = 1.0;
    _animationController.reset();
    _photoViewController.position = Offset.zero;
    _photoViewController.scale = 1.0;
  }

  void _handleAnimation() {
    final scale = 1.0 + (_targetScale - 1.0) * _animation.value;
    _currentScale = scale;

    final current = _photoViewController.scale;
    if (current == null || (current - scale).abs() > 0.001) {
      _photoViewController.scale = scale;
    }
  }

  void dispose() {
    _animationController
      ..removeListener(_handleAnimation)
      ..dispose();
  }
}
