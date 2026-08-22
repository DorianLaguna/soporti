import 'package:flutter/material.dart';

/// Pantalla de inicio de sesión.
/// La implementación completa se realizará en la tarea 4.2.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SoporTI',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Iniciar Sesión',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              const Text(
                'Las cuentas son provisionadas por el área de TI',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
