import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Screen/login.dart';
import '../Screen/dashboard.dart';
import '../Screen/dashboard_content.dart';
import '../Screen/shelters_content.dart';
import '../Screen/shelter_details_page.dart';
import '../Screen/reported_shelters_content.dart';
import '../Screen/blocked_shelters.dart';
import '../Screen/adopters_content.dart';
import '../Screen/adopter_details_page.dart';
import '../Screen/notification.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => AdminLoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => DashboardScreen(child: child),
      routes: [
        GoRoute(
          path: '/dashboard/content',
          builder: (context, state) => DashboardContent(),
        ),
        GoRoute(
          path: '/dashboard/shelter/content',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            return SheltersContent(key: UniqueKey(), arguments: args);
          },
        ),
        GoRoute(
          path: '/dashboard/shelter/details',
          builder: (context, state) {
            final shelter = state.extra as Map<String, dynamic>;
            final onApprove = state.uri.queryParameters['onApprove'] as dynamic
                Function(Map<String, dynamic>);
            final onBack =
                state.uri.queryParameters['onBack'] as void Function();

            return ShelterDetailsPage(
              shelter: shelter,
              onApprove: onApprove,
              onBack: onBack,
            );
          },
        ),
        GoRoute(
          path: '/dashboard/reported/shelters',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            return ReportedSheltersScreen(key: UniqueKey(), arguments: args);
          },
        ),
        GoRoute(
          path: '/blocked/shelters',
          builder: (context, state) => BlockedSheltersScreen(),
        ),
        GoRoute(
          path: '/dashboard/notification',
          builder: (context, state) => ReportNotificationsScreen(),
        ),
        GoRoute(
          path: '/dashboard/adopters',
          builder: (context, state) => AdoptersPage(),
        ),
        GoRoute(
          path: '/dashboard/adopter/details',
          builder: (context, state) {
            final adopter = state.extra as Map<String, dynamic>;
            final onApprove = state.uri.queryParameters['onApprove'] as dynamic
                Function(Map<String, dynamic>);
            final onBack =
                state.uri.queryParameters['onBack'] as void Function();

            return AdopterDetailsScreen(
              adopter: adopter,
              onBack: onBack,
              onApprove: (Map<String, dynamic> p1) {},
            );
          },
        ),
      ],
    ),
  ],
);
