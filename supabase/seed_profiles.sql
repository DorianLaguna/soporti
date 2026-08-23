-- Inserta las filas de profiles para los 3 usuarios de prueba ya creados en
-- Authentication → Users. Ejecutar una sola vez en el SQL Editor, con el
-- selector de rol del editor en "postgres" (no "authenticated") — `profiles`
-- no tiene política de INSERT a propósito (no hay registro público, ver
-- supabase/schema.sql), así que corriendo como "authenticated" esto falla
-- por RLS. Como "postgres" la evita por completo.
-- Ajusta los UID si vuelves a crear los usuarios (cámbialos por los que
-- te muestre el Dashboard).

insert into public.profiles (id, email, full_name, role, location) values
  ('e8a199fe-c46e-408e-9838-7bb5bc1a1198', 'solicitante@soporti.mx', 'Dorian Laguna', 'solicitante', 'Piso 2 · Administración'),
  ('a03d275a-2b4e-4555-b7df-8ebd456d8006', 'tecnico@soporti.mx', 'Iván Reséndiz', 'tecnico', ''),
  ('e67bb386-d340-4141-9ac9-807949f23668', 'supervisor@soporti.mx', 'Karla Vega', 'supervisor', '')
on conflict (id) do update set
  email = excluded.email,
  full_name = excluded.full_name,
  role = excluded.role,
  location = excluded.location;
