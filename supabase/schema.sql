-- SoporTI: esquema de base de datos, triggers y Row Level Security.
-- Ejecutar completo en el SQL Editor de un proyecto Supabase nuevo.

-- ============================================================
-- 1. Tablas
-- ============================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  full_name text not null,
  role text not null check (role in ('solicitante', 'tecnico', 'supervisor')),
  location text not null default ''
);

create sequence if not exists public.ticket_code_seq start 2400;

create table if not exists public.tickets (
  id uuid primary key default gen_random_uuid(),
  code text unique,
  title text not null,
  description text not null,
  category text not null check (category in ('Hardware', 'Software', 'Red', 'Accesos', 'Otros')),
  priority text not null default 'Media' check (priority in ('Baja', 'Media', 'Alta', 'Crítica')),
  status text not null default 'Abierto'
    check (status in ('Abierto', 'Asignado', 'En proceso', 'En espera', 'Resuelto', 'Cerrado')),
  location text not null default '',
  requester_id uuid not null references public.profiles (id),
  assigned_to uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz,
  rating int check (rating between 1 and 5)
);

create table if not exists public.ticket_events (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.tickets (id) on delete cascade,
  event_type text not null,
  description text not null,
  is_internal boolean not null default false,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

create table if not exists public.ticket_attachments (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.tickets (id) on delete cascade,
  file_url text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_tickets_requester on public.tickets (requester_id);
create index if not exists idx_tickets_assigned on public.tickets (assigned_to);
create index if not exists idx_tickets_status on public.tickets (status);
create index if not exists idx_ticket_events_ticket on public.ticket_events (ticket_id);
create index if not exists idx_ticket_attachments_ticket on public.ticket_attachments (ticket_id);

-- ============================================================
-- 2. Generación automática de folio (SOP-####)
-- ============================================================
-- CreateTicketRequest.toJson() (lib/features/tickets/repositories/ticket_repository.dart)
-- no envía `code`, así que se genera aquí en el INSERT.

create or replace function public.generate_ticket_code()
returns trigger
language plpgsql
as $$
begin
  if new.code is null then
    new.code := 'SOP-' || nextval('public.ticket_code_seq');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_generate_ticket_code on public.tickets;
create trigger trg_generate_ticket_code
  before insert on public.tickets
  for each row
  execute function public.generate_ticket_code();

-- ============================================================
-- 3. Helper de rol para políticas RLS
-- ============================================================

create or replace function public.get_my_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- ============================================================
-- 4. Row Level Security
-- ============================================================

alter table public.profiles enable row level security;
alter table public.tickets enable row level security;
alter table public.ticket_events enable row level security;
alter table public.ticket_attachments enable row level security;

-- profiles: lectura abierta a cualquier autenticado (se necesita para mostrar
-- nombres de técnicos en reasignación y carga de trabajo del dashboard).
-- Sin política de INSERT/DELETE: las cuentas se provisionan manualmente
-- (ver supabase/README.md), no hay registro público.
create policy "profiles_select_authenticated"
  on public.profiles for select
  to authenticated
  using (true);

create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- tickets
create policy "tickets_select"
  on public.tickets for select
  to authenticated
  using (
    requester_id = auth.uid()
    or assigned_to = auth.uid()
    or public.get_my_role() = 'supervisor'
    or (public.get_my_role() = 'tecnico' and assigned_to is null and status = 'Abierto')
  );

create policy "tickets_insert"
  on public.tickets for insert
  to authenticated
  with check (requester_id = auth.uid());

create policy "tickets_update"
  on public.tickets for update
  to authenticated
  using (
    requester_id = auth.uid()
    or assigned_to = auth.uid()
    or public.get_my_role() = 'supervisor'
    or (public.get_my_role() = 'tecnico' and assigned_to is null)
  )
  with check (
    requester_id = auth.uid()
    or assigned_to = auth.uid()
    or public.get_my_role() = 'supervisor'
    or public.get_my_role() = 'tecnico'
  );

-- ticket_events: eventos internos solo visibles para técnico/supervisor.
create policy "ticket_events_select"
  on public.ticket_events for select
  to authenticated
  using (
    exists (
      select 1 from public.tickets t
      where t.id = ticket_events.ticket_id
        and (t.requester_id = auth.uid() or t.assigned_to = auth.uid() or public.get_my_role() = 'supervisor')
    )
    and (is_internal = false or public.get_my_role() in ('tecnico', 'supervisor'))
  );

create policy "ticket_events_insert"
  on public.ticket_events for insert
  to authenticated
  with check (
    created_by = auth.uid()
    and exists (
      select 1 from public.tickets t
      where t.id = ticket_events.ticket_id
        and (t.requester_id = auth.uid() or t.assigned_to = auth.uid() or public.get_my_role() = 'supervisor')
    )
  );

-- ticket_attachments: visibilidad ligada al acceso al ticket.
create policy "ticket_attachments_select"
  on public.ticket_attachments for select
  to authenticated
  using (
    exists (
      select 1 from public.tickets t
      where t.id = ticket_attachments.ticket_id
        and (t.requester_id = auth.uid() or t.assigned_to = auth.uid() or public.get_my_role() = 'supervisor')
    )
  );

create policy "ticket_attachments_insert"
  on public.ticket_attachments for insert
  to authenticated
  with check (
    exists (
      select 1 from public.tickets t
      where t.id = ticket_attachments.ticket_id
        and (t.requester_id = auth.uid() or t.assigned_to = auth.uid() or public.get_my_role() = 'supervisor')
    )
  );

-- ============================================================
-- 5. Storage: bucket de adjuntos
-- ============================================================
-- Público porque storage_repository.dart usa getPublicUrl() (no URLs firmadas).

insert into storage.buckets (id, name, public)
values ('ticket-attachments', 'ticket-attachments', true)
on conflict (id) do nothing;

create policy "ticket_attachments_storage_read"
  on storage.objects for select
  to public
  using (bucket_id = 'ticket-attachments');

create policy "ticket_attachments_storage_insert"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'ticket-attachments');
