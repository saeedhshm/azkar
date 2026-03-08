import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/app_categories.dart';
import '../cubit/adhkar_cubit.dart';
import '../cubit/adhkar_state.dart';
import '../widgets/adhkar_tile.dart';

class AdhkarListScreen extends StatefulWidget {
  const AdhkarListScreen({super.key, required this.categoryKey});

  final String categoryKey;

  @override
  State<AdhkarListScreen> createState() => _AdhkarListScreenState();
}

class _AdhkarListScreenState extends State<AdhkarListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = AppCategories.byKey(widget.categoryKey);

    return BlocProvider<AdhkarCubit>(
      create: (_) => getIt<AdhkarCubit>()..loadCategory(widget.categoryKey),
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'common.search_adhkar'.tr(),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) =>
                      context.read<AdhkarCubit>().search(value),
                )
              : Text(category.titleKey.tr()),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() => _isSearching = !_isSearching);

                if (!_isSearching) {
                  _searchController.clear();
                  context.read<AdhkarCubit>().search('');
                }
              },
            ),
          ],
        ),
        body: BlocBuilder<AdhkarCubit, AdhkarState>(
          builder: (context, state) {
            if (state.status == AdhkarStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == AdhkarStatus.failure) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'common.failed_load_adhkar'.tr(),
                ),
              );
            }

            if (state.items.isEmpty) {
              return Center(child: Text('common.no_adhkar_in_category'.tr()));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = state.items[index];
                final isFavorite = state.favoriteIds.contains(item.id);

                return AdhkarTile(
                  adhkar: item,
                  isFavorite: isFavorite,
                  onTap: () => context.push(
                    '/reader/${widget.categoryKey}?id=${item.id}&index=$index',
                  ),
                  onFavoriteTap: () {
                    context.read<AdhkarCubit>().toggleFavorite(item.id);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
