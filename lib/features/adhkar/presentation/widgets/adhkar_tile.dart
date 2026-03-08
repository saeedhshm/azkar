import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../domain/entities/adhkar.dart';

class AdhkarTile extends StatelessWidget {
  const AdhkarTile({
    super.key,
    required this.adhkar,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final Adhkar adhkar;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        title: Text(
          adhkar.text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.rtl,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    label: Text('${'common.count'.tr()}: ${adhkar.count}'),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (adhkar.reference.isNotEmpty)
                    Chip(
                      label: Text(adhkar.reference),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (adhkar.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    adhkar.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        trailing: IconButton(
          onPressed: onFavoriteTap,
          icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
        ),
      ),
    );
  }
}
