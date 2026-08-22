import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/connectivity_provider.dart';

/// Wrapper que modifica la apariencia visual del contenido cuando no hay conexión.
///
/// Cuando offline:
/// - Cambia el fondo del contenedor a [AppColors.offlineBackground] (dorado claro)
/// - Envuelve al hijo con un borde punteado amarillo [AppColors.offlineBorder]
///
/// Cuando online:
/// - Muestra el hijo sin modificaciones.
///
/// Es exclusivamente visual — no hay lógica de sincronización real.
class OfflineWrapper extends ConsumerWidget {
  /// Widget hijo que se envuelve con la apariencia offline.
  final Widget child;

  /// Si `true`, aplica borde punteado amarillo al child (para tarjetas de ticket).
  final bool showDashedBorder;

  const OfflineWrapper({
    super.key,
    required this.child,
    this.showDashedBorder = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    final isOffline = connectivityAsync.when(
      data: (connected) => !connected,
      loading: () => false,
      error: (_, _) => false,
    );

    if (!isOffline) return child;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.offlineBackground,
        borderRadius: BorderRadius.circular(8),
        border: showDashedBorder
            ? null
            : Border.all(color: AppColors.offlineBorder, width: 1.5),
      ),
      child: showDashedBorder
          ? CustomPaint(
              painter: _DashedBorderPainter(
                color: AppColors.offlineBorder,
                strokeWidth: 2.0,
                gap: 5.0,
                dashWidth: 8.0,
                borderRadius: 8.0,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: child,
              ),
            )
          : child,
    );
  }
}

/// Painter personalizado para dibujar un borde punteado (dashed) alrededor
/// del contenido offline.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashWidth;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dashWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final dashedPath = _createDashedPath(path);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        dashedPath.addPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = end + gap;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashWidth != dashWidth;
  }
}
