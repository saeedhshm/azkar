import 'package:go_router/go_router.dart';

import '../../features/adhkar/presentation/pages/adhkar_list_screen.dart';
import '../../features/adhkar/presentation/pages/dhikr_reader_screen.dart';
import '../../features/adhkar/presentation/pages/favorites_screen.dart';
import '../../features/navigation/presentation/pages/main_navigation_screen.dart';
import '../../features/quran/presentation/pages/quran_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/tasbeeh/presentation/pages/tasbeeh_counter_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(path: '/quran', builder: (context, state) => const QuranScreen()),
      GoRoute(
        path: '/adhkar/:category',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? 'morning_adhkar';
          return AdhkarListScreen(categoryKey: category);
        },
      ),
      GoRoute(
        path: '/reader/:category',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? 'morning_adhkar';
          final index = int.tryParse(state.uri.queryParameters['index'] ?? '0');
          final adhkarId = int.tryParse(state.uri.queryParameters['id'] ?? '');

          return DhikrReaderScreen(
            categoryKey: category,
            startIndex: index ?? 0,
            initialAdhkarId: adhkarId,
          );
        },
      ),
      GoRoute(
        path: '/tasbeeh',
        builder: (context, state) => const TasbeehCounterScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
