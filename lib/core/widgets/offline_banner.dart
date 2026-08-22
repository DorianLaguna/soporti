import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/offline/providers/connectivity_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// Banner dorado que se muestra en la parte superior cuando no hay conexión.
///
/// Muestra:
/// - Icono de nube sin conexión
/// - Texto "Sin conexión"
/// - Conteo de operaciones pendientes de sincronizar
///
/// Solo es visible cuando [connectivityProvider] indica estado offline.
/// Este widget es exclusivamente visual — no hay lógica real de sincronización.
class OfflineBanner extends ConsumerWidget {
  /// Cantidad de operaciones pendientes a mostrar (visual, sin lógica real).
  final int pendingOps;

  const OfflineBanner({super.key, this.pendingOps = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    final isOffline = connectivityAsync.when(
      data: (connected) => !connected,
      loading: () => false,
      error: (_, _) => false,
    );

    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.offlineBanner,
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            size: 20,
            color: AppColors.offlineText,
          ),
          const SizedBox(width: 8),
          Text(
            AppStrings.offlineBanner,
            style: TextStyle(
              color: AppColors.offlineText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (pendingOps > 0)
            Text(
              '$pendingOps ${AppStrings.pendingOperations}',
              style: TextStyle(
                color: AppColors.offlineText,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
