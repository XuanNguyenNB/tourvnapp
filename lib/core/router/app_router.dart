import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_vn/core/providers/admin_claim_provider.dart';
import 'package:tour_vn/core/services/onboarding_service.dart';
import 'package:tour_vn/core/providers/firebase_providers.dart';
import 'package:tour_vn/core/router/not_found_screen.dart';
import 'package:tour_vn/core/router/scaffold_with_nav_bar.dart';
import 'package:tour_vn/features/home/presentation/screens/home_screen.dart';
// import 'package:tour_vn/features/example/presentation/screens/example_screen.dart'; // REMOVED - Story 3-1
// ExploreScreen removed - merged with HomeScreen
import 'package:tour_vn/features/trip/presentation/screens/trips_screen.dart';
import 'package:tour_vn/features/trip/presentation/screens/create_trip_screen.dart';
import 'package:tour_vn/features/trip/presentation/screens/visual_planner_screen.dart';
import 'package:tour_vn/features/itinerary/presentation/screens/ai_plan_screen.dart';
import 'package:tour_vn/features/profile/presentation/screens/profile_screen.dart';
import 'package:tour_vn/features/auth/presentation/screens/login_screen.dart';
import 'package:tour_vn/features/destination/presentation/screens/destination_hub_screen.dart'; // Story 3-2
import 'package:tour_vn/features/destination/presentation/screens/location_detail_screen.dart'; // Story 3-7
import 'package:tour_vn/features/destination/domain/entities/location.dart'; // Story 3-7
import 'package:tour_vn/features/review/presentation/screens/review_detail_screen.dart'; // Story 3-8
import 'package:tour_vn/features/home/domain/entities/review_preview.dart'; // Story 3-8
import 'package:tour_vn/features/onboarding/presentation/screens/mood_selection_screen.dart'; // Story 6-3
import 'package:tour_vn/features/admin/presentation/screens/admin_layout_screen.dart'; // Admin
import 'package:tour_vn/features/admin/presentation/screens/admin_overview_screen.dart';
import 'package:tour_vn/features/admin/presentation/screens/manage_destinations_screen.dart';
import 'package:tour_vn/features/admin/presentation/screens/manage_locations_screen.dart';
import 'package:tour_vn/features/admin/presentation/screens/manage_categories_screen.dart';
import 'package:tour_vn/features/admin/presentation/screens/manage_reviews_screen.dart';
import 'package:tour_vn/features/admin/presentation/screens/import_json_screen.dart';
import 'package:tour_vn/features/admin/presentation/screens/ai_content_hub_screen.dart';

/// Route name constants for type-safe navigation
///
/// Usage:
/// ```dart
/// context.goNamed(AppRoutes.home);
/// context.goNamed(AppRoutes.destination, pathParameters: {'id': 'da-lat'});
/// ```
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  // Bottom navigation routes
  static const String home = 'home';
  static const String explore = 'explore';
  static const String trips = 'trips';
  static const String profile = 'profile';

  // Feature routes (nested under tabs or standalone)
  static const String destination = 'destination';
  static const String location = 'location';
  static const String locationStandalone = 'location-standalone';
  static const String review = 'review';
  static const String tripDetail = 'trip-detail';
  static const String createTrip = 'create-trip';
  static const String aiPlan = 'ai-plan';
  static const String visualPlanner = 'visual-planner';
  static const String login = 'login';
  static const String onboarding = 'onboarding'; // Story 6-3
}

// Navigator keys to prevent GlobalKey duplication between routes
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeNavKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _tripsNavKey = GlobalKey<NavigatorState>(debugLabel: 'trips');
final _profileNavKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

/// Riverpod Provider cho GoRouter.
///
/// Router giờ "reactive" với Riverpod state — có thể:
/// - Invalidate khi auth state đổi
/// - Dùng cached adminClaimProvider thay vì gọi network mỗi lần
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: kIsWeb ? '/admin' : '/',
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) =>
        NotFoundScreen(errorMessage: state.error?.toString()),
    // Redirect to onboarding if user hasn't completed it (mobile only)
    redirect: (context, state) {
      // Skip redirect for web (admin) routes
      if (kIsWeb) return null;

      final currentPath = state.uri.path;

      // Only redirect from home '/' to onboarding
      // Don't redirect if already on onboarding or other routes
      if (currentPath == '/') {
        try {
          final shouldShow = ref.read(shouldShowOnboardingProvider);
          if (shouldShow) {
            return '/onboarding';
          }
        } catch (_) {
          // Provider not initialized yet, skip redirect
        }
      }

      // If on onboarding but already completed, go to home
      // UNLESS user is editing preferences from Profile (query param edit=true)
      if (currentPath == '/onboarding') {
        final isEditing = state.uri.queryParameters['edit'] == 'true';
        if (!isEditing) {
          try {
            final shouldShow = ref.read(shouldShowOnboardingProvider);
            if (!shouldShow) {
              return '/';
            }
          } catch (_) {
            // Provider not initialized, allow onboarding
          }
        }
      }

      return null;
    },
    routes: [
      // Standalone routes
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/onboarding',
        name: AppRoutes.onboarding,
        builder: (context, state) => const MoodSelectionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/login',
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/review/:id',
        name: AppRoutes.review,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final reviewPreview = state.extra as ReviewPreview?;
          return ReviewDetailScreen(reviewId: id, reviewPreview: reviewPreview);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/location/:destId/:locId',
        name: AppRoutes.locationStandalone,
        builder: (context, state) {
          final locId = state.pathParameters['locId']!;
          final location = state.extra as Location?;
          return LocationDetailScreen(locationId: locId, location: location);
        },
      ),

      // Bottom tab navigation with persistent state
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavKey,
            routes: [
              GoRoute(
                path: '/',
                name: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'destination/:id',
                    name: AppRoutes.destination,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return DestinationHubScreen(destinationId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'location/:locId',
                        name: AppRoutes.location,
                        builder: (context, state) {
                          final locId = state.pathParameters['locId']!;
                          final location = state.extra as Location?;
                          return LocationDetailScreen(
                            locationId: locId,
                            location: location,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tripsNavKey,
            routes: [
              GoRoute(
                path: '/trips',
                name: AppRoutes.trips,
                builder: (context, state) => const TripsScreen(),
                routes: [
                  GoRoute(
                    path: 'planner',
                    name: AppRoutes.visualPlanner,
                    builder: (context, state) {
                      return const VisualPlannerScreen.fromPending();
                    },
                  ),
                  GoRoute(
                    path: 'create',
                    name: AppRoutes.createTrip,
                    builder: (context, state) {
                      return const CreateTripScreen();
                    },
                  ),
                  GoRoute(
                    path: 'ai-plan',
                    name: AppRoutes.aiPlan,
                    builder: (context, state) {
                      return const AiPlanScreen();
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    name: AppRoutes.tripDetail,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return VisualPlannerScreen(tripId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Admin Dashboard (Web)
      ShellRoute(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, child) {
          return AdminLayoutScreen(
            currentPath: state.uri.toString(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/admin',
            name: 'admin-overview',
            builder: (context, state) => const AdminOverviewScreen(),
            redirect: (context, state) => _adminGuard(ref),
          ),
          GoRoute(
            path: '/admin/categories',
            name: 'admin-categories',
            builder: (context, state) => const ManageCategoriesScreen(),
            redirect: (context, state) => _adminGuard(ref),
          ),
          GoRoute(
            path: '/admin/destinations',
            name: 'admin-destinations',
            builder: (context, state) => const ManageDestinationsScreen(),
            redirect: (context, state) => _adminGuard(ref),
          ),
          GoRoute(
            path: '/admin/locations',
            name: 'admin-locations',
            builder: (context, state) => const ManageLocationsScreen(),
            redirect: (context, state) => _adminGuard(ref),
          ),
          GoRoute(
            path: '/admin/reviews',
            name: 'admin-reviews',
            builder: (context, state) => const ManageReviewsScreen(),
            redirect: (context, state) => _adminGuard(ref),
          ),
          GoRoute(
            path: '/admin/import',
            name: 'admin-import',
            builder: (context, state) => const ImportJsonScreen(),
            redirect: (context, state) => _adminGuard(ref),
          ),
          GoRoute(
            path: '/admin/ai-content',
            name: 'admin-ai-content',
            builder: (context, state) => const AiContentHubScreen(),
            redirect: (context, state) => _adminGuard(ref),
          ),
        ],
      ),
    ],
  );
});

/// Admin guard dùng cached claim từ Riverpod provider.
///
/// Sync check auth state → nếu chưa login → '/login'.
/// Dùng `adminClaimProvider` (cached) thay vì gọi `getIdTokenResult()` mỗi lần.
FutureOr<String?> _adminGuard(Ref ref) {
  final auth = ref.read(firebaseAuthProvider);
  final user = auth.currentUser;

  // 1. Not logged in or anonymous -> go to login
  if (user == null || user.isAnonymous) {
    return '/login';
  }

  // 2. Check cached admin claim
  final adminClaim = ref.read(adminClaimProvider);
  return adminClaim.when(
    data: (isAdmin) => isAdmin ? null : '/',
    loading: () => null, // Đang load → cho qua, UI sẽ handle
    error: (_, __) => '/',
  );
}
