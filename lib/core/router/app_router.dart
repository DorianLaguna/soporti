import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/technician/screens/available_tickets_screen.dart';
import '../../features/technician/screens/tech_queue_screen.dart';
import '../../features/tickets/screens/ticket_create_screen.dart';
import '../../features/tickets/screens/ticket_detail_screen.dart';
import '../../features/tickets/screens/ticket_list_screen.dart';
import '../providers/supabase_provider.dart';

/// Provider principal del router con guards de autenticación y redirección por rol.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserProvider);
  final client = ref.watch(supabaseClientProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable:
        GoRouterRefreshStream(client.auth.onAuthStateChange),
    redirect: (context, state) {
      final isLoggedIn = authState.value?.session != null;
      final isLoginRoute = state.matchedLocation == '/login';

      // Si no está autenticado y no está en login, redirigir a login.
      if (!isLoggedIn && !isLoginRoute) return '/login';

      // Si está autenticado y está en login, redirigir según rol.
      if (isLoggedIn && isLoginRoute) {
        final role = currentUser.value?.role;
        switch (role) {
          case 'solicitante':
            return '/tickets';
          case 'tecnico':
            return '/queue';
          case 'supervisor':
            return '/dashboard';
          default:
            return '/tickets';
        }
      }

      // Sin redirección.
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/tickets',
        builder: (context, state) => const TicketListScreen(),
      ),
      GoRoute(
        path: '/tickets/create',
        builder: (context, state) => const TicketCreateScreen(),
      ),
      GoRoute(
        path: '/tickets/:id',
        builder: (context, state) {
          final ticketId = state.pathParameters['id']!;
          return TicketDetailScreen(ticketId: ticketId);
        },
      ),
      GoRoute(
        path: '/queue',
        builder: (context, state) => const TechQueueScreen(),
      ),
      GoRoute(
        path: '/queue/:id',
        builder: (context, state) {
          final ticketId = state.pathParameters['id']!;
          return _PlaceholderScreen(title: 'Gestión: $ticketId');
        },
      ),
      GoRoute(
        path: '/available',
        builder: (context, state) => const AvailableTicketsScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

/// Pantalla placeholder para rutas que se implementarán en tareas posteriores.
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

/// Convierte un [Stream] en un [ChangeNotifier] para que GoRouter
/// pueda re-evaluar las redirecciones cuando cambia el estado de autenticación.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
