import 'package:glados/glados.dart';
import 'package:test/test.dart';
import 'package:soporti/core/utils/validators.dart';
import 'package:soporti/core/constants/app_strings.dart';

// Feature: soporti-app, Property 7: Form validation — empty/whitespace rejection

/// Generador de strings compuestos exclusivamente de caracteres whitespace.
/// Produce combinaciones de espacios, tabs, newlines y carriage returns.
final _whitespaceChars = [' ', '\t', '\n', '\r', '\u00A0'];

/// Genera un string de whitespace de longitud variable (0 a maxLen).
String _generateWhitespace(int seed, int maxLen) {
  if (maxLen <= 0) return '';
  final length = seed.abs() % (maxLen + 1);
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(_whitespaceChars[(seed + i) % _whitespaceChars.length]);
  }
  return buffer.toString();
}

void main() {
  // Feature: soporti-app, Property 7: Form validation — empty/whitespace rejection
  // **Validates: Requirements 1.7**
  group('Property 7: Form validation — empty/whitespace rejection', () {
    group('validateEmail rechaza strings vacíos y de whitespace', () {
      test('string vacío es rechazado', () {
        expect(validateEmail(''), equals(AppStrings.fieldRequired));
      });

      test('null es rechazado', () {
        expect(validateEmail(null), equals(AppStrings.fieldRequired));
      });

      Glados(any.intInRange(0, 1000), ExploreConfig(numRuns: 100)).test(
        'cualquier string compuesto solo de whitespace es rechazado por validateEmail',
        (seed) {
          // Generar string de whitespace con longitud 1..50
          final length = (seed.abs() % 50) + 1;
          final whitespaceStr = _generateWhitespace(seed, length);

          // Si por casualidad queda vacío, forzar al menos un espacio
          final input = whitespaceStr.isEmpty ? ' ' : whitespaceStr;

          final result = validateEmail(input);
          expect(result, isNotNull,
              reason:
                  'validateEmail debería rechazar whitespace: "${input.replaceAll('\n', '\\n').replaceAll('\t', '\\t')}"');
          expect(result, equals(AppStrings.fieldRequired));
        },
      );
    });

    group('validateRequired rechaza strings vacíos y de whitespace', () {
      test('string vacío es rechazado', () {
        expect(validateRequired(''), equals(AppStrings.fieldRequired));
      });

      test('null es rechazado', () {
        expect(validateRequired(null), equals(AppStrings.fieldRequired));
      });

      Glados(any.intInRange(0, 1000), ExploreConfig(numRuns: 100)).test(
        'cualquier string compuesto solo de whitespace es rechazado por validateRequired',
        (seed) {
          final length = (seed.abs() % 50) + 1;
          final whitespaceStr = _generateWhitespace(seed, length);
          final input = whitespaceStr.isEmpty ? ' ' : whitespaceStr;

          final result = validateRequired(input);
          expect(result, isNotNull,
              reason:
                  'validateRequired debería rechazar whitespace: "${input.replaceAll('\n', '\\n').replaceAll('\t', '\\t')}"');
          expect(result, equals(AppStrings.fieldRequired));
        },
      );
    });

    group('validateEmail acepta emails con formato válido', () {
      /// Genera un email válido a partir de un seed.
      String _generateValidEmail(int seed) {
        final names = [
          'user',
          'admin',
          'test',
          'soporte',
          'juan.perez',
          'maria-garcia',
          'carlos_lopez'
        ];
        final domains = [
          'empresa.mx',
          'uvm.edu.mx',
          'correo.com',
          'soporte.org'
        ];
        final name = names[seed.abs() % names.length];
        final domain = domains[seed.abs() % domains.length];
        return '$name@$domain';
      }

      Glados(any.intInRange(0, 1000), ExploreConfig(numRuns: 100)).test(
        'emails con formato válido son aceptados',
        (seed) {
          final email = _generateValidEmail(seed);
          final result = validateEmail(email);
          expect(result, isNull,
              reason: 'validateEmail debería aceptar email válido: "$email"');
        },
      );
    });

    group('validateEmail rechaza strings no-email sin whitespace', () {
      Glados(any.letterOrDigits, ExploreConfig(numRuns: 100)).test(
        'strings sin @ son rechazados como formato inválido',
        (input) {
          // Solo probar strings no vacíos que no contengan @
          if (input.trim().isEmpty || input.contains('@')) return;

          final result = validateEmail(input);
          expect(result, isNotNull,
              reason:
                  'validateEmail debería rechazar string sin formato email: "$input"');
          expect(result, equals(AppStrings.invalidEmailFormat));
        },
      );
    });
  });
}
