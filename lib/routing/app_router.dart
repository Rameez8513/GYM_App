import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/members/member_detail_screen.dart';
import '../screens/members/member_form_screen.dart';
import '../screens/members/member_list_screen.dart';
import '../screens/payments/monthly_payments_screen.dart';
import '../screens/payments/payment_history_screen.dart';
import '../screens/plans/plan_form_screen.dart';
import '../screens/plans/plan_list_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../widgets/common/app_scaffold.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static GoRouter build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();

    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: auth,
      redirect: (context, state) {
        final onLogin = state.matchedLocation == '/login';
        if (!auth.isLoggedIn && !onLogin) return '/login';
        if (auth.isLoggedIn && onLogin) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => AppScaffold(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              name: RouteNames.dashboard,
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/members',
              name: RouteNames.members,
              builder: (context, state) => const MemberListScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: RouteNames.memberAdd,
                  builder: (context, state) => const MemberFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  name: RouteNames.memberDetail,
                  builder: (context, state) =>
                      MemberDetailScreen(memberId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: ':id/edit',
                  name: RouteNames.memberEdit,
                  builder: (context, state) =>
                      MemberFormScreen(memberId: state.pathParameters['id']),
                ),
              ],
            ),
            GoRoute(
              path: '/plans',
              name: RouteNames.plans,
              builder: (context, state) => const PlanListScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: RouteNames.planAdd,
                  builder: (context, state) => const PlanFormScreen(),
                ),
                GoRoute(
                  path: ':id/edit',
                  name: RouteNames.planEdit,
                  builder: (context, state) =>
                      PlanFormScreen(planId: state.pathParameters['id']),
                ),
              ],
            ),
            GoRoute(
              path: '/payments',
              name: RouteNames.payments,
              builder: (context, state) => const MonthlyPaymentsScreen(),
            ),
            GoRoute(
              path: '/payment-history',
              name: RouteNames.paymentHistory,
              builder: (context, state) => const PaymentHistoryScreen(),
            ),
            GoRoute(
              path: '/settings',
              name: RouteNames.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
