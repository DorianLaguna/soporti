import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que emite `true` cuando hay conexión a internet y `false` cuando no.
///
/// Utiliza connectivity_plus para escuchar cambios en la conectividad del
/// dispositivo. Emite `false` solo cuando todos los resultados son
/// [ConnectivityResult.none].
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
});
