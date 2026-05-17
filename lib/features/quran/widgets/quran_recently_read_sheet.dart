import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../data/datasources/quran_recently_read_service.dart';
import '../domain/entities/quran_surah.dart';

class QuranRecentlyReadSheet extends StatefulWidget {
  const QuranRecentlyReadSheet({
    super.key,
    required this.surahs,
    required this.onNavigate,
  });

  final List<QuranSurah> surahs;
  final void Function(int pageNumber, int surahNumber, int ayahNumber)
      onNavigate;

  @override
  State<QuranRecentlyReadSheet> createState() => _QuranRecentlyReadSheetState();
}

class _QuranRecentlyReadSheetState extends State<QuranRecentlyReadSheet> {
  final _service = getIt<QuranRecentlyReadService>();
  late List<RecentlyReadEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = _service.getAll();
  }

  String _surahName(int surahNumber) {
    for (final s in widget.surahs) {
      if (s.number == surahNumber) return s.name;
    }
    return 'quran.unknown_surah'.tr();
  }

  String _formatTimestamp(int timestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _clearAll() {
    _service.clear();
    setState(() => _entries = []);
  }

  void _removeEntry(RecentlyReadEntry entry) {
    _service.removeEntry(entry);
    setState(() => _entries = _service.getAll());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'quran.recently_read'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                if (_entries.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: Text('common.clear'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'quran.no_recently_read'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _entries.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Dismissible(
                      key: ValueKey('${entry.pageNumber}-${entry.timestamp}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.red),
                      ),
                      onDismissed: (_) => _removeEntry(entry),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${entry.pageNumber}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          _surahName(entry.surahNumber),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${'quran.ayah'.tr()} ${entry.ayahNumber} • ${'quran.page'.tr()} ${entry.pageNumber}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTimestamp(entry.timestamp),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_left_rounded,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              size: 18,
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onNavigate(
                            entry.pageNumber,
                            entry.surahNumber,
                            entry.ayahNumber,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
