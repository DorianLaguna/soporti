import 'package:glados/glados.dart';
import 'package:soporti/core/utils/validators.dart';
import 'package:soporti/core/constants/app_strings.dart';

// Feature: soporti-app, Property 7: Form validation — empty/whitespace rejection
// Feature: soporti-app, Property 8: Form validation — length boundaries
// **Validates: Requirements 3.2, 3.4**

/// Caracteres whitespace comunes.
const _whitespaceChars = [' ', '\t', '\n', '\r', '\u00A0'];

/// Genera un string de whitespace de longitud variable a partir de un seed.
String _generateWhitespace(int seed, int length) {
  if (length <= 0) return ' ';
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(_whitespaceChars[(seed + i).abs() % _whitespaceChars.length]);
  }
  return buffer.toString();
}

/// Genera un string no-whitespace de longitud exacta usando caracteres alfanuméricos.
String _generateNonWhitespace(int seed, int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(chars[(seed + i).abs() % chars.length]);
  }
  return buffer.toString();
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Property 7: Form validation — empty/whitespace rejection (ticket form)
  // **Validates: Requirements 3.2, 3.4**
  // ═══════════════════════════════════════════════════════════════════════════
  group('Property 7: Form validation — empty/whitespace rejection (ticket)', () {
    group('validateTitle rechaza strings vacíos y de whitespace', () {
      test('null es rechazado', () {
        expect(validateTitle(null), equals(AppStrings.fieldRequired));
      });

      test('string vacío es rechazado', () {
        expect(validateTitle(''), equals(AppStrings.fieldRequired));
      });

      Glados(any.intInRange(1, 1000), ExploreConfig(numRuns: 100)).test(
        'cualquier string compuesto solo de whitespace es rechazado por validateTitle',
        (seed) {
          final length = (seed.abs() % 50) + 1;
          final whitespaceStr = _generateWhitespace(seed, length);

          final result = validateTitle(whitespaceStr);
          expect(result, isNotNull,
              reason:
                  'validateTitle debería rechazar whitespace-only de longitud $length');
          expect(result, equals(AppStrings.fieldRequired));
        },
      );
    });

    group('validateDescription rechaza strings vacíos y de whitespace', () {
      test('null es rechazado', () {
        expect(validateDescription(null), equals(AppStrings.fieldRequired));
      });

      test('string vacío es rechazado', () {
        expect(validateDescription(''), equals(AppStrings.fieldRequired));
      });

      Glados(any.intInRange(1, 1000), ExploreConfig(numRuns: 100)).test(
        'cualquier string compuesto solo de whitespace es rechazado por validateDescription',
        (seed) {
          final length = (seed.abs() % 100) + 1;
          final whitespaceStr = _generateWhitespace(seed, length);

          final result = validateDescription(whitespaceStr);
          expect(result, isNotNull,
              reason:
                  'validateDescription debería rechazar whitespace-only de longitud $length');
          expect(result, equals(AppStrings.fieldRequired));
        },
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Property 8: Form validation — length boundaries
  // **Validates: Requirements 3.2, 3.4**
  // ═══════════════════════════════════════════════════════════════════════════
  group('Property 8: Form validation — length boundaries', () {
    group('validateTitle — títulos con < 5 caracteres son rechazados', () {
      Glados(any.intInRange(1, 4), ExploreConfig(numRuns: 100)).test(
        'strings de 1 a 4 caracteres no-whitespace son rechazados con titleMinLength',
        (length) {
          final seed = Random().nextInt(10000);
          final shortTitle = _generateNonWhitespace(seed, length);

          final result = validateTitle(shortTitle);
          expect(result, isNotNull,
              reason:
                  'validateTitle debería rechazar título de longitud $length: "$shortTitle"');
          expect(result, equals(AppStrings.titleMinLength));
        },
      );
    });

    group('validateTitle — títulos entre 5-100 caracteres son aceptados', () {
      Glados(any.intInRange(5, 100), ExploreConfig(numRuns: 100)).test(
        'strings de 5 a 100 caracteres no-whitespace son aceptados (retorna null)',
        (length) {
          final seed = Random().nextInt(10000);
          final validTitle = _generateNonWhitespace(seed, length);

          final result = validateTitle(validTitle);
          expect(result, isNull,
              reason:
                  'validateTitle debería aceptar título de longitud $length');
        },
      );
    });

    group('validateTitle — títulos con > 100 caracteres son rechazados', () {
      Glados(any.intInRange(101, 500), ExploreConfig(numRuns: 100)).test(
        'strings de más de 100 caracteres son rechazados con titleMaxLength',
        (length) {
          final seed = Random().nextInt(10000);
          final longTitle = _generateNonWhitespace(seed, length);

          final result = validateTitle(longTitle);
          expect(result, isNotNull,
              reason:
                  'validateTitle debería rechazar título de longitud $length');
          expect(result, equals(AppStrings.titleMaxLength));
        },
      );
    });

    group(
        'validateDescription — descripciones con < 10 caracteres son rechazadas',
        () {
      Glados(any.intInRange(1, 9), ExploreConfig(numRuns: 100)).test(
        'strings de 1 a 9 caracteres no-whitespace son rechazados con descriptionMinLength',
        (length) {
          final seed = Random().nextInt(10000);
          final shortDesc = _generateNonWhitespace(seed, length);

          final result = validateDescription(shortDesc);
          expect(result, isNotNull,
              reason:
                  'validateDescription debería rechazar descripción de longitud $length: "$shortDesc"');
          expect(result, equals(AppStrings.descriptionMinLength));
        },
      );
    });

    group(
        'validateDescription — descripciones entre 10-1000 caracteres son aceptadas',
        () {
      Glados(any.intInRange(10, 1000), ExploreConfig(numRuns: 100)).test(
        'strings de 10 a 1000 caracteres no-whitespace son aceptados (retorna null)',
        (length) {
          final seed = Random().nextInt(10000);
          final validDesc = _generateNonWhitespace(seed, length);

          final result = validateDescription(validDesc);
          expect(result, isNull,
              reason:
                  'validateDescription debería aceptar descripción de longitud $length');
        },
      );
    });

    group(
        'validateDescription — descripciones con > 1000 caracteres son rechazadas',
        () {
      Glados(any.intInRange(1001, 2000), ExploreConfig(numRuns: 100)).test(
        'strings de más de 1000 caracteres son rechazados con descriptionMaxLength',
        (length) {
          final seed = Random().nextInt(10000);
          final longDesc = _generateNonWhitespace(seed, length);

          final result = validateDescription(longDesc);
          expect(result, isNotNull,
              reason:
                  'validateDescription debería rechazar descripción de longitud $length');
          expect(result, equals(AppStrings.descriptionMaxLength));
        },
      );
    });
  });
}
