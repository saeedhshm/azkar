import 'package:flutter/material.dart';

import 'prayer_time_tile.dart';

class PrayerTimesGrid extends StatelessWidget {
  const PrayerTimesGrid({super.key, required this.items});

  final List<PrayerTimeTileData> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 104),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.48,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return PrayerTimeTile(
          name: item.name,
          time: item.time,
          icon: item.icon,
          isCurrent: item.isCurrent,
          isNext: item.isNext,
          isPast: item.isPast,
        );
      },
    );
  }
}

class PrayerTimeTileData {
  const PrayerTimeTileData({
    required this.name,
    required this.time,
    required this.icon,
    required this.isCurrent,
    required this.isNext,
    required this.isPast,
  });

  final String name;
  final String time;
  final IconData icon;
  final bool isCurrent;
  final bool isNext;
  final bool isPast;
}
