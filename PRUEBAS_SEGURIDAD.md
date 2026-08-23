# Pruebas de seguridad — SoporTI

Actividad 8, punto 3.3. Pruebas realizadas directamente contra el código fuente y el backend real en producción (Supabase), sin herramientas externas: se usó `flutter analyze` para el análisis estático de Dart y `curl` contra la API REST de Supabase para las pruebas dinámicas, simulando peticiones que un atacante podría enviar sin pasar por la app.

Fecha: 22 de agosto de 2026.

## 1. Pruebas estáticas

### 1.1 Análisis estático del código (`flutter analyze`)

```
$ flutter analyze
Analyzing soporti...
16 issues found.
```

Los 16 hallazgos son advertencias de estilo en archivos de test (imports innecesarios, nombres de variables) — ninguno relacionado con seguridad. **0 errores, 0 advertencias de seguridad en el código de producción (`lib/`).**

### 1.2 Búsqueda de credenciales hardcodeadas

```
$ grep -rniE "password\s*=\s*['\"]|api[_-]?key\s*=\s*['\"][a-z0-9]|secret\s*=\s*['\"]|YOUR_SUPABASE" lib/ --include="*.dart"
lib/core/constants/app_strings.dart:22:  static const String forgotPassword = '¿Olvidaste tu contraseña?';
```

Única coincidencia: una etiqueta de texto de UI, no una credencial real. **Sin secretos en texto plano en el código fuente.**

### 1.3 Manejo de credenciales de Supabase

```dart
// lib/main.dart
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
```

Las credenciales se inyectan en tiempo de compilación vía `--dart-define-from-file`, no están escritas en el código. El archivo real (`env/dev.json`) está excluido del control de versiones (`.gitignore`).

> **Nota de proceso**: en una versión anterior del proyecto, `main.dart` sí tenía la URL y la anon key de Supabase escritas directamente en el código (placeholder `YOUR_SUPABASE_URL`). Se corrigió antes de conectar el backend real — ver historial de commits.

## 2. Pruebas dinámicas

Todas las pruebas se ejecutaron con `curl` contra la API REST real de Supabase (`https://tmnifoaqfraaxxfsruln.supabase.co`), autenticándose como una cuenta de prueba real (`solicitante@soporti.mx`) para simular un usuario malicioso con una sesión legítima pero de bajo privilegio.

### 2.1 Transporte cifrado

```
$ curl -s -o /dev/null -w "Protocolo: %{scheme}\nTLS válido: %{ssl_verify_result}\n" \
  https://tmnifoaqfraaxxfsruln.supabase.co/rest/v1/

Protocolo: HTTPS
TLS válido: 0   (0 = certificado válido)
```

✅ Todo el tráfico va cifrado por HTTPS con certificado válido.

### 2.2 Acceso sin autenticación

```
$ curl -X GET ".../rest/v1/tickets?select=*" -H "apikey: <anon_key>"
[]
HTTP 200
```

✅ Una petición sin token de sesión (solo la anon key pública) no devuelve ningún ticket real. Row Level Security deniega por defecto: no hay error que revele si existen datos, simplemente no se retorna nada.

### 2.3 Control de acceso por fila (RLS)

Con sesión válida de `solicitante@soporti.mx`, se listaron los tickets visibles:

```json
[
  {"id": "1ae0079b-...", "code": "SOP-2400", "requester_id": "e8a199fe-...(yo mismo)"},
  {"id": "68300363-...", "code": "SOP-2401", "requester_id": "e8a199fe-...(yo mismo)"}
]
```

✅ Los 2 tickets visibles pertenecen únicamente al usuario autenticado. **0 tickets de otros usuarios visibles**, aunque la organización tiene más tickets en la base de datos.

### 2.4 Suplantación de identidad al crear un ticket

Intento de crear un ticket asignando `requester_id` de **otro** usuario (no el de la sesión actual):

```
$ curl -X POST ".../rest/v1/tickets" -H "Authorization: Bearer <token_solicitante>" \
  -d '{"requester_id": "<otro-usuario>", ...}'

{"code":"42501","message":"new row violates row-level security policy for table \"tickets\""}
HTTP 403
```

✅ Rechazado. La política `tickets_insert` obliga `requester_id = auth.uid()`.

### 2.5 Escalación de privilegios — vulnerabilidad real encontrada y corregida

Intento de que el propio usuario (`role: solicitante`) se otorgue el rol `supervisor` directamente vía la API:

```
$ curl -X PATCH ".../rest/v1/profiles?id=eq.<mi-id>" -H "Authorization: Bearer <token_solicitante>" \
  -d '{"role": "supervisor"}'

[{"id":"...","role":"supervisor", ...}]
HTTP 200   ← ¡el ataque funcionó!
```

🔴 **Vulnerabilidad confirmada.** La política `profiles_update_own` (`using: id = auth.uid()`) solo restringía **qué fila** podía editar el usuario, no **qué columnas**. Row Level Security en Postgres opera a nivel de fila, no de columna, así que cualquier usuario autenticado podía cambiar su propio `role` a `supervisor` o `tecnico` con una sola petición HTTP, sin pasar por la app ni por ninguna pantalla.

**Corrección aplicada**: como la app no tiene ninguna pantalla de "editar mi perfil", se eliminó por completo la política de `UPDATE` sobre `profiles` (`supabase/fix_privilege_escalation.sql`). Nadie puede modificar `profiles` desde el cliente, ni su propia fila.

**Re-prueba después de la corrección:**

```
$ curl -X PATCH ".../rest/v1/profiles?id=eq.<mi-id>" -H "Authorization: Bearer <token_solicitante>" \
  -d '{"role": "supervisor"}'

[]
HTTP 200   (0 filas modificadas — RLS lo bloquea)

$ curl -X GET ".../rest/v1/profiles?id=eq.<mi-id>&select=role" ...
[{"role":"solicitante"}]   ← el rol no cambió
```

✅ Corregido y verificado.

## Resumen

| # | Prueba | Resultado |
|---|---|---|
| 1.1 | Análisis estático del código | ✅ Sin hallazgos de seguridad |
| 1.2 | Credenciales hardcodeadas | ✅ Ninguna encontrada |
| 1.3 | Manejo de configuración sensible | ✅ Vía variables de entorno, no versionadas |
| 2.1 | Transporte cifrado (HTTPS) | ✅ Correcto |
| 2.2 | Acceso sin autenticación | ✅ Denegado |
| 2.3 | Aislamiento de datos entre usuarios (RLS) | ✅ Correcto |
| 2.4 | Suplantación de identidad al crear datos | ✅ Rechazado |
| 2.5 | Escalación de privilegios | 🔴→✅ Vulnerabilidad real encontrada y corregida |

**Herramienta usada**: pruebas manuales dirigidas con `curl` (cliente HTTP) contra la API REST de Supabase, y `flutter analyze` (analizador estático incluido en el SDK de Flutter/Dart) para el código. Enfoque de caja gris: se probó como lo haría un atacante con una cuenta de bajo privilegio ya autenticada, el escenario más realista para esta app.
