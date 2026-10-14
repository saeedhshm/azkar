import 'package:azkar/features/quran/presentation/widgets/quran_page_zoom_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_view/photo_view.dart';

void main() {
  late PhotoViewController photoViewController;
  late QuranPageZoomController zoom;

  setUp(() {
    photoViewController = PhotoViewController();
  });

  tearDown(() {
    photoViewController.dispose();
  });

  Future<void> buildZoom(WidgetTester tester) async {
    // A minimal host is needed to supply a TickerProvider.
    await tester.pumpWidget(
      MaterialApp(
        home: _ZoomHost(
          photoViewController: photoViewController,
          onCreated: (controller) => zoom = controller,
        ),
      ),
    );
  }

  testWidgets('toggle drives the photo view scale to the zoomed value', (
    tester,
  ) async {
    await buildZoom(tester);

    zoom.toggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(zoom.currentScale, closeTo(2.8, 0.01));
    expect(photoViewController.scale, closeTo(2.8, 0.01));
  });

  testWidgets('a second toggle returns to the fit scale', (tester) async {
    await buildZoom(tester);

    zoom.toggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(zoom.isZoomedIn, isTrue);

    zoom.toggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(zoom.currentScale, closeTo(1.0, 0.01));
    expect(photoViewController.scale, closeTo(1.0, 0.01));
  });

  testWidgets('the scale changes progressively while animating', (
    tester,
  ) async {
    await buildZoom(tester);

    zoom.toggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final midScale = zoom.currentScale;
    expect(midScale, greaterThan(1.0));
    expect(midScale, lessThan(2.8));

    await tester.pump(const Duration(milliseconds: 400));
    expect(zoom.currentScale, greaterThan(midScale));
  });

  testWidgets('reset returns to the fit scale and clears the position', (
    tester,
  ) async {
    await buildZoom(tester);

    zoom.toggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    photoViewController.position = const Offset(50, 80);

    zoom.reset();
    await tester.pump();

    expect(zoom.currentScale, 1.0);
    expect(photoViewController.scale, 1.0);
    expect(photoViewController.position, Offset.zero);
  });

  testWidgets('zooming in from a reset state starts from the fit scale', (
    tester,
  ) async {
    await buildZoom(tester);

    expect(zoom.currentScale, 1.0);
    expect(zoom.isZoomedIn, isFalse);

    zoom.toggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(zoom.isZoomedIn, isTrue);
  });
}

/// Hosts a [QuranPageZoomController] and exposes it to the test.
class _ZoomHost extends StatefulWidget {
  const _ZoomHost({
    required this.photoViewController,
    required this.onCreated,
  });

  final PhotoViewController photoViewController;
  final void Function(QuranPageZoomController controller) onCreated;

  @override
  State<_ZoomHost> createState() => _ZoomHostState();
}

class _ZoomHostState extends State<_ZoomHost>
    with SingleTickerProviderStateMixin {
  late final QuranPageZoomController _zoom;

  @override
  void initState() {
    super.initState();
    _zoom = QuranPageZoomController(
      vsync: this,
      photoViewController: widget.photoViewController,
    );
    widget.onCreated(_zoom);
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
