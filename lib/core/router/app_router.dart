import 'package:go_router/go_router.dart';
import '../../dashboard_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      // We'll keep the test console accessible via /test for now
      // We need to extract TestConsole from main.dart first ideally, 
      // but for now let's just point to Dashboard and I'll refactor TestConsole later.
    ],
  );
}
