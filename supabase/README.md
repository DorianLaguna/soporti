# Configuración del backend Supabase

Estos pasos se hacen una sola vez, desde el Dashboard de Supabase (requieren tu cuenta, no se pueden automatizar desde el editor).

## 1. Crear el proyecto

1. Entra a [supabase.com](https://supabase.com) y crea un proyecto nuevo (elige una región cercana, p. ej. `us-east-1`).
2. Espera a que termine de aprovisionarse.

## 2. Ejecutar el esquema

1. Abre **SQL Editor** en el panel izquierdo.
2. Pega el contenido completo de [`schema.sql`](./schema.sql) y ejecútalo.
   - Crea las tablas `profiles`, `tickets`, `ticket_events`, `ticket_attachments`.
   - Crea el trigger que genera el folio `SOP-####` automáticamente.
   - Activa RLS y crea las políticas por rol.
   - Crea el bucket de Storage `ticket-attachments` (público) con sus políticas.

## 3. Crear usuarios de prueba (uno por rol)

No hay registro público en la app — las cuentas se provisionan manualmente, tal como se definió en la Etapa 2. Para cada usuario de prueba:

1. Ve a **Authentication → Users → Add user** y crea el usuario con correo y contraseña (marca "Auto Confirm User" para no depender de un correo de verificación).
2. Copia el `UID` que te asigna Supabase.
3. Crea su fila en `profiles`. Puedes usar **Table Editor → profiles → Insert row**, o pegar los `UID` reales en [`seed_profiles.sql`](./seed_profiles.sql) y ejecutarlo en el SQL Editor — más rápido para los 3 a la vez. **Este paso es obligatorio**: sin la fila en `profiles`, el login de Supabase funciona pero la app no encuentra tu perfil y falla en todas las pantallas.

| id (pega el UID) | email | full_name | role | location |
|---|---|---|---|---|
| `e8a199fe-c46e-408e-9838-7bb5bc1a1198` | solicitante@soporti.mx | Dorian Laguna | solicitante | Piso 2 · Administración |
| `a03d275a-2b4e-4555-b7df-8ebd456d8006` | tecnico@soporti.mx | Iván Reséndiz | tecnico | — |
| `e67bb386-d340-4141-9ac9-807949f23668` | supervisor@soporti.mx | Karla Vega | supervisor | — |

Repite con un segundo técnico si quieres probar reasignación y la gráfica de carga de trabajo con más de un técnico.

## 4. Obtener las credenciales de la app

1. Ve a **Project Settings → API**.
2. Copia **Project URL** y la clave **anon public**.
3. En la raíz del proyecto Flutter, copia `env/dev.json.example` a `env/dev.json` y pega ahí esos dos valores (ese archivo está en `.gitignore`, no se sube al repositorio).

## 5. Correr la app contra el backend real

```
flutter run --dart-define-from-file=env/dev.json
```

Inicia sesión con cada uno de los 3 usuarios de prueba y valida el ciclo completo: crear ticket como solicitante → verlo en "Disponibles" del técnico → auto-asignarlo → cambiar estatus → cerrarlo con calificación → confirmar que el panel de indicadores del supervisor refleja los datos.

## Nota de seguridad

Las políticas RLS de `tickets` son a nivel de fila, no de columna: un solicitante con acceso de `UPDATE` sobre su propio ticket podría, en teoría, modificar campos que no le corresponden (p. ej. `priority`), porque Postgres RLS no restringe columnas individuales. Es un hallazgo conocido y aceptado para el alcance de este proyecto — documentado aquí para la actividad de pruebas de seguridad (3.3). Si se quisiera cerrar, la solución sería mover esas actualizaciones a una Supabase Edge Function con lógica explícita de qué campos puede tocar cada rol.
