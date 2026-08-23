-- Corrige una vulnerabilidad de escalación de privilegios encontrada durante
-- pruebas de seguridad dinámicas: la política "profiles_update_own"
-- permitía a cualquier usuario autenticado modificar su propia fila en
-- `profiles`, incluyendo la columna `role`. Postgres RLS restringe filas,
-- no columnas, así que un solicitante podía convertirse en supervisor con
-- un solo PATCH a la REST API, sin pasar por la app.
--
-- La app no tiene pantalla de edición de perfil, así que la política se
-- elimina en vez de reescribirse: nadie necesita hacer UPDATE de profiles
-- desde el cliente.
--
-- Ejecutar en el SQL Editor con el rol en "postgres" (no "authenticated").

drop policy if exists "profiles_update_own" on public.profiles;
