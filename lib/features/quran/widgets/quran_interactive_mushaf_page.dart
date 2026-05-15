import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../domain/entities/ayah_highlight.dart';
import '../domain/entities/quran_page.dart';
import '../domain/entities/quran_selected_ayah.dart';
import '../presentation/cubit/quran_ayah_selection_cubit.dart';
import '../presentation/cubit/quran_highlight_cubit.dart';
import '../presentation/cubit/quran_highlight_state.dart';
import '../presentation/cubit/quran_polygon_cubit.dart';
import '../presentation/cubit/quran_polygon_state.dart';
import '../presentation/widgets/quran_mushaf_image_page.dart';
import '../services/quran_polygon_hit_test_engine.dart';
import '../services/quran_svg_page_service.dart';
import 'quran_polygon_interaction_layer.dart';

class QuranInteractiveMushafPage extends StatelessWidget {
  const QuranInteractiveMushafPage({
    super.key,
    required this.pageNumber,
    required this.pageService,
    this.onAyahLongPress,
  });

  final int pageNumber;
  final QuranSvgPageService pageService;
  final void Function(QuranSelectedAyah selectedAyah)? onAyahLongPress;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<QuranPolygonCubit>()..loadPage(pageNumber),
      child: _QuranInteractiveMushafPageBody(
        pageNumber: pageNumber,
        pageService: pageService,
        onAyahLongPress: onAyahLongPress,
      ),
    );
  }
}

class _QuranInteractiveMushafPageBody extends StatelessWidget {
  const _QuranInteractiveMushafPageBody({
    required this.pageNumber,
    required this.pageService,
    this.onAyahLongPress,
  });

  final int pageNumber;
  final QuranSvgPageService pageService;
  final void Function(QuranSelectedAyah selectedAyah)? onAyahLongPress;

  @override
  Widget build(BuildContext context) {
    final hitTestEngine = getIt<QuranPolygonHitTestEngine>();
    return BlocBuilder<QuranPolygonCubit, QuranPolygonState>(
      buildWhen: (previous, current) =>
          previous.page != current.page ||
          previous.highlightedPolygonId != current.highlightedPolygonId ||
          previous.status != current.status,
      builder: (context, polygonState) {
        final page = polygonState.page;
        return QuranMushafImagePage(
          pageNumber: pageNumber,
          pageService: pageService,
          overlay: page == null
              ? null
              : _HighlightOverlay(
                  pageNumber: pageNumber,
                  page: page,
                  hitTestEngine: hitTestEngine,
                ),
          onTapUp: page == null
              ? null
              : (
                  tapDetails,
                  controllerValue,
                  viewportSize,
                  displaySize,
                  fitScale,
                ) {
                  final localPoint = _mapTapToCanvas(
                    tapPosition: tapDetails.localPosition,
                    viewportSize: viewportSize,
                    displaySize: displaySize,
                    fitScale: fitScale,
                    translation: controllerValue.position,
                    scale: controllerValue.scale ?? 1,
                  );

                  if (localPoint == null) return;

                  final polygon = hitTestEngine.hitTest(page, localPoint);
                  if (polygon == null) return;

                  HapticFeedback.lightImpact();

                  final highlightCubit =
                      context.read<QuranHighlightCubit>();
                  final highlight = AyahHighlight(
                    id: 'tap-${polygon.id}',
                    polygonId: polygon.id,
                    pageNumber: pageNumber,
                    surahNumber: polygon.surah,
                    ayahNumber: polygon.ayah,
                    type: AyahHighlightType.tap,
                  );
                  highlightCubit.addTapHighlight(highlight);

                  context.read<QuranAyahSelectionCubit>().selectAyah(
                    QuranSelectedAyah(
                      pageNumber: pageNumber,
                      polygonId: polygon.id,
                      surahNumber: polygon.surah,
                      ayahNumber: polygon.ayah,
                      lineNumber: polygon.line,
                    ),
                  );
                },
          onLongPressUp: page == null || onAyahLongPress == null
              ? null
              : (
                  longPressDetails,
                  controllerValue,
                  viewportSize,
                  displaySize,
                  fitScale,
                ) {
                  final callback = onAyahLongPress;
                  if (callback == null) return;

                  HapticFeedback.heavyImpact();

                  final localPoint = _mapTapToCanvas(
                    tapPosition: longPressDetails.localPosition,
                    viewportSize: viewportSize,
                    displaySize: displaySize,
                    fitScale: fitScale,
                    translation: controllerValue.position,
                    scale: controllerValue.scale ?? 1,
                  );

                  if (localPoint == null) return;

                  final polygon = hitTestEngine.hitTest(page, localPoint);
                  if (polygon == null) return;

                  callback(
                    QuranSelectedAyah(
                      pageNumber: pageNumber,
                      polygonId: polygon.id,
                      surahNumber: polygon.surah,
                      ayahNumber: polygon.ayah,
                      lineNumber: polygon.line,
                    ),
                  );
                },
        );
      },
    );
  }

  Offset? _mapTapToCanvas({
    required Offset tapPosition,
    required Size viewportSize,
    required Size displaySize,
    required double fitScale,
    required Offset translation,
    required double scale,
  }) {
    final baseOffset = Offset(
      (viewportSize.width - displaySize.width) / 2,
      0,
    );

    final dx = (tapPosition.dx - baseOffset.dx - translation.dx) / scale;
    final dy = (tapPosition.dy - baseOffset.dy - translation.dy) / scale;

    if (dx < 0 ||
        dy < 0 ||
        dx > displaySize.width ||
        dy > displaySize.height) {
      return null;
    }

    return Offset(dx / fitScale, dy / fitScale);
  }
}

class _HighlightOverlay extends StatelessWidget {
  const _HighlightOverlay({
    required this.pageNumber,
    required this.page,
    required this.hitTestEngine,
  });

  final int pageNumber;
  final QuranPage page;
  final QuranPolygonHitTestEngine hitTestEngine;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranHighlightCubit, QuranHighlightState>(
      buildWhen: (previous, current) {
        final prevPageHighlights = previous.highlightsForPage(pageNumber);
        final currPageHighlights = current.highlightsForPage(pageNumber);
        return prevPageHighlights != currPageHighlights;
      },
      builder: (context, highlightState) {
        final rawHighlights = highlightState.highlightsForPage(pageNumber);
        final resolvedHighlights = _resolveHighlights(
          rawHighlights,
          page,
          hitTestEngine,
        );

        final animatingIds = <String>{};
        final tapHighlight = highlightState.tapHighlight;
        if (tapHighlight != null &&
            tapHighlight.pageNumber == pageNumber) {
          animatingIds.add(tapHighlight.id);
        }

        return QuranPolygonInteractionLayer(
          page: page,
          hitTestEngine: hitTestEngine,
          highlights: resolvedHighlights,
          animatingIds: animatingIds,
        );
      },
    );
  }

  List<AyahHighlight> _resolveHighlights(
    List<AyahHighlight> highlights,
    QuranPage polygonPage,
    QuranPolygonHitTestEngine engine,
  ) {
    final ayahToPolygon = <String, String>{};
    for (final p in polygonPage.polygons) {
      ayahToPolygon[p.ayahKey] = p.id;
    }

    return highlights.map((h) {
      if (h.polygonId.isNotEmpty &&
          !engine.hasPolygon(polygonPage, h.polygonId)) {
        final resolved = ayahToPolygon[h.ayahKey];
        if (resolved != null && resolved != h.polygonId) {
          return AyahHighlight(
            id: h.id,
            polygonId: resolved,
            pageNumber: h.pageNumber,
            surahNumber: h.surahNumber,
            ayahNumber: h.ayahNumber,
            type: h.type,
            searchQuery: h.searchQuery,
          );
        }
      }
      return h;
    }).where((h) => engine.hasPolygon(polygonPage, h.polygonId)).toList();
  }
}
