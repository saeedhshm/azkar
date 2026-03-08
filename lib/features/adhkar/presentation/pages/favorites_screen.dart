import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/app_categories.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FavoritesCubit>(
      create: (_) => getIt<FavoritesCubit>()..loadFavorites(),
      child: Scaffold(
        appBar: AppBar(title: Text('common.favorites'.tr())),
        body: BlocBuilder<FavoritesCubit, FavoritesState>(
          builder: (context, state) {
            if (state.status == FavoritesStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == FavoritesStatus.failure) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'common.failed_load_favorites'.tr(),
                ),
              );
            }

            if (state.items.isEmpty) {
              return Center(child: Text('common.no_favorites'.tr()));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = state.items[index];
                final category = AppCategories.byKey(item.category);

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      item.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(category.titleKey.tr()),
                    ),
                    onTap: () =>
                        context.push('/reader/${item.category}?id=${item.id}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        context.read<FavoritesCubit>().toggleFavorite(item.id);
                      },
                    ),
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
