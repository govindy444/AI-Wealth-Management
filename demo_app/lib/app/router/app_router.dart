import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/avatar/avatar_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/common/feature_scaffold.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/financial_health/financial_health_screen.dart';
import '../../features/fraud/fraud_screen.dart';
import '../../features/goals/goals_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/portfolio/portfolio_screen.dart';
import '../../features/predictive/predictive_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/recommendations/recommendations_screen.dart';
import '../../features/spending/spending_screen.dart';
import '../../features/voice/voice_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/splash/splash_screen.dart';
import 'app_routes.dart';

final _rootKey = GlobalKey<NavigatorState>();


GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.spending,
                builder: (_, __) => const SpendingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.advisor,
                builder: (_, __) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.portfolio,
                builder: (_, __) => const PortfolioScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(path: AppRoutes.chat, builder: (_, __) => const ChatScreen()),
      GoRoute(path: AppRoutes.avatar, builder: (_, __) => const AvatarScreen()),
      GoRoute(path: AppRoutes.voice, builder: (_, __) => const VoiceScreen()),
      GoRoute(
        path: AppRoutes.financialHealth,
        builder: (_, __) => const FinancialHealthScreen(),
      ),
      GoRoute(
        path: AppRoutes.predictive,
        builder: (_, __) => const PredictiveScreen(),
      ),
      GoRoute(path: AppRoutes.goals, builder: (_, __) => const GoalsScreen()),
      GoRoute(
        path: AppRoutes.recommendations,
        builder: (_, __) => const RecommendationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.fraudAlerts,
        builder: (_, __) => const FraudScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      _feature(AppRoutes.settings, 'Settings', Icons.settings_outlined,
          'Module 19 — Profile & Settings'),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}

GoRoute _feature(String path, String title, IconData icon, String module) {
  return GoRoute(
    path: path,
    builder: (_, __) =>
        FeatureScaffold(title: title, icon: icon, moduleLabel: module),
  );
}
