import 'package:azkar/core/theme/app_theme.dart';
import 'package:azkar/core/utils/app_categories.dart';
import 'package:azkar/core/widgets/islamic_ornament.dart';
import 'package:azkar/features/adhkar/presentation/widgets/category_card.dart';
import 'package:azkar/features/prayer_times/presentation/widgets/next_prayer_hero_card.dart';
import 'package:azkar/features/prayer_times/presentation/widgets/prayer_times_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 1.8]) {
        testWidgets(
          'dashboard fits width=$width scale=$scale dark=$dark in both directions',
          (tester) async {
            tester.view.physicalSize = Size(width, 850);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            for (final direction in [TextDirection.rtl, TextDirection.ltr]) {
              await tester.pumpWidget(
                MaterialApp(
                  theme: dark ? AppTheme.dark : AppTheme.light,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 850),
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: Directionality(
                      textDirection: direction,
                      child: Scaffold(
                        body: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const NextPrayerHeroCard(
                                label: 'الصلاة القادمة',
                                prayerName: 'المغرب',
                                countdown: '01:24:38',
                                currentContext: 'وقت العصر',
                                nextPrayerTimeLine: 'المغرب الساعة 6:24 مساءً',
                                progressStartLabel: 'العصر',
                                progressEndLabel: 'المغرب',
                                progressStartTime: '3:30 PM',
                                progressEndTime: '6:24 PM',
                                progress: .5,
                                location:
                                    'المدينة المنورة، المملكة العربية السعودية',
                                hijriDate: 'الأربعاء ١٢ شعبان ١٤٤٨',
                                gregorianDate: 'October 14, 2026',
                              ),
                              const SizedBox(height: 20),
                              const IslamicCollectionHeader(
                                title: 'الأذكار اليومية',
                                subtitle: 'مساحة هادئة للذكر والدعاء',
                                icon: Icons.auto_stories_outlined,
                              ),
                              const SizedBox(height: 20),
                              const PrayerTimesGrid(
                                embedded: true,
                                items: [
                                  PrayerTimeTileData(
                                    name: 'الفجر',
                                    time: '5:12 AM',
                                    icon: Icons.nightlight_round,
                                    isCurrent: true,
                                    isNext: false,
                                    isPast: false,
                                  ),
                                  PrayerTimeTileData(
                                    name: 'الشروق',
                                    time: '6:35 AM',
                                    icon: Icons.wb_sunny_outlined,
                                    isCurrent: false,
                                    isNext: true,
                                    isPast: false,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 180 * scale,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: CategoryCard(
                                        category: AppCategories.items.first,
                                        onTap: () {},
                                        index: 0,
                                        itemCount: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CategoryCard(
                                        category: AppCategories.items[1],
                                        onTap: () {},
                                        index: 1,
                                        itemCount: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.text('01:24:38'), findsOneWidget);
              await tester.drag(
                find.byType(SingleChildScrollView).first,
                const Offset(0, -700),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }
  }
}
