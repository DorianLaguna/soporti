# SoporTI

Mesa de ayuda móvil para áreas internas de TI: registro, asignación, seguimiento y cierre de tickets de soporte técnico, con interfaces diferenciadas por rol (solicitante, técnico, supervisor).

Construida con Flutter + Riverpod + go_router, sobre un backend Supabase (PostgreSQL, Auth, Row Level Security, Storage).

## Backend

La app requiere un proyecto Supabase configurado. Sigue los pasos en [`supabase/README.md`](supabase/README.md) para crear el proyecto, cargar el esquema (`supabase/schema.sql`) y provisionar usuarios de prueba.

## Correr la app

1. Completa la configuración del backend (ver arriba).
2. Copia `env/dev.json.example` a `env/dev.json` y coloca la URL y anon key de tu proyecto Supabase.
3. Ejecuta:

```
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

## Tests

```
flutter test
```
