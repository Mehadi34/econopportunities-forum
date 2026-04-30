import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/events/create_edit_event_screen.dart';
import '../screens/forum/forum_screen.dart';
import '../screens/forum/post_detail_screen.dart';
import '../screens/forum/create_post_screen.dart';
import '../screens/announcements/announcements_screen.dart';
import '../screens/announcements/announcement_detail_screen.dart';
import '../screens/members/members_screen.dart';
import '../screens/members/member_profile_screen.dart';
import '../screens/resources/resources_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/admin/manage_events_screen.dart';
import '../screens/admin/manage_announcements_screen.dart';
import '../screens/admin/manage_forum_screen.dart';
import '../screens/admin/manage_resources_screen.dart';
import '../screens/admin/analytics_screen.dart';
import '../screens/admin/create_announcement_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuth = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/splash';

      if (!isLoggedIn && !isOnAuth) {
        return '/auth/login';
      }
      if (isLoggedIn && state.matchedLocation == '/auth/login') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/email-verification',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    EventDetailScreen(eventId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateEditEventScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => CreateEditEventScreen(
                  eventId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/forum',
            builder: (context, state) => const ForumScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    PostDetailScreen(postId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreatePostScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/announcements',
            builder: (context, state) => const AnnouncementsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => AnnouncementDetailScreen(
                    announcementId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/members',
            builder: (context, state) => const MembersScreen(),
            routes: [
              GoRoute(
                path: ':uid',
                builder: (context, state) => MemberProfileScreen(
                    uid: state.pathParameters['uid']!),
              ),
            ],
          ),
          GoRoute(
            path: '/resources',
            builder: (context, state) => const ResourcesScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
            routes: [
              GoRoute(
                path: 'users',
                builder: (context, state) => const ManageUsersScreen(),
              ),
              GoRoute(
                path: 'events',
                builder: (context, state) => const ManageEventsScreen(),
              ),
              GoRoute(
                path: 'announcements',
                builder: (context, state) => const ManageAnnouncementsScreen(),
              ),
              GoRoute(
                path: 'announcements/create',
                builder: (context, state) => const CreateAnnouncementScreen(),
              ),
              GoRoute(
                path: 'forum',
                builder: (context, state) => const ManageForumScreen(),
              ),
              GoRoute(
                path: 'resources',
                builder: (context, state) => const ManageResourcesScreen(),
              ),
              GoRoute(
                path: 'analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
