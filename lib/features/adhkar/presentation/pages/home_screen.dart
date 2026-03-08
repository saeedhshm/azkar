import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/app_categories.dart';
import '../../domain/repositories/adhkar_repository.dart';
import '../widgets/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<Map<String, int>> _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadCategoryCounts();
  }

  Future<Map<String, int>> _loadCategoryCounts() async {
    final repository = getIt<AdhkarRepository>();
    final all = await repository.getAllAdhkar();
    final counts = <String, int>{};

    for (final item in all) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.name'.tr()),
        actions: [
          IconButton(
            tooltip: 'common.favorites'.tr(),
            onPressed: () => context.push('/favorites'),
            icon: const Icon(Icons.bookmark_outline),
          ),
          IconButton(
            tooltip: 'common.tasbeeh_counter'.tr(),
            onPressed: () => context.push('/tasbeeh'),
            icon: const Icon(Icons.touch_app_outlined),
          ),
          IconButton(
            tooltip: 'common.settings'.tr(),
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
        child: FutureBuilder<Map<String, int>>(
          future: _countsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final counts = snapshot.data ?? <String, int>{};

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              itemCount: AppCategories.sections.length,
              itemBuilder: (context, sectionIndex) {
                final section = AppCategories.sections[sectionIndex];
                final sectionItems = AppCategories.itemsBySection(section.key);

                if (sectionItems.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.titleKey.tr(),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              section.subtitleKey.tr(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = width >= 1000
                              ? 4
                              : width >= 700
                              ? 3
                              : 2;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sectionItems.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.05,
                                ),
                            itemBuilder: (context, itemIndex) {
                              final category = sectionItems[itemIndex];

                              return CategoryCard(
                                category: category,
                                index: itemIndex,
                                itemCount: counts[category.key] ?? 0,
                                onTap: () {
                                  context.push('/adhkar/${category.key}');
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
