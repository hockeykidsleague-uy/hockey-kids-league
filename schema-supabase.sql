-- ════════════════════════════════════════
-- HOCKEY KIDS LEAGUE — Schema inicial Supabase
-- Pegar completo en SQL Editor y ejecutar (RUN)
-- ════════════════════════════════════════

-- Roles de usuario (admin / arbitro / equipo)
create table perfiles (
  id uuid references auth.users on delete cascade primary key,
  rol text not null check (rol in ('admin','arbitro','equipo')),
  nombre text not null,
  equipo_id uuid,          -- solo si rol = 'equipo'
  created_at timestamp with time zone default now()
);

-- Equipos
create table equipos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  categoria text not null check (categoria in ('Sub 6','Sub 8','Sub 10','Sub 12')),
  color text default 't1',
  created_at timestamp with time zone default now()
);

-- Ahora sí, conectamos equipo_id de perfiles con equipos
alter table perfiles add constraint fk_equipo foreign key (equipo_id) references equipos(id);

-- Jugadores
create table jugadores (
  id uuid primary key default gen_random_uuid(),
  equipo_id uuid references equipos(id) on delete cascade,
  nombre text not null,
  ci text,
  fecha_nacimiento date,
  categoria text,
  sociedad_medica text,
  foto_url text,
  ficha_medica_url text,
  created_at timestamp with time zone default now()
);

-- Árbitros (además de tener su cuenta en perfiles)
create table arbitros (
  id uuid references auth.users on delete cascade primary key,
  nombre text not null,
  codigo text unique not null
);

-- Torneos
create table torneos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,          -- 'Apertura 2026' / 'Clausura 2026'
  modalidad text not null check (modalidad in ('todos_contra_todos','series')),
  activo boolean default true
);

-- Partidos
create table partidos (
  id uuid primary key default gen_random_uuid(),
  torneo_id uuid references torneos(id),
  equipo_local_id uuid references equipos(id),
  equipo_visita_id uuid references equipos(id),
  fecha date,
  hora time,
  cancha text,
  arbitro_id uuid references arbitros(id),
  estado text not null default 'precargado' check (estado in ('precargado','en_curso','cerrado')),
  gol_local int default 0,
  gol_visita int default 0,
  posesion text,              -- ej '60-40'
  mvp_jugador_id uuid references jugadores(id),
  cerrado_en timestamp with time zone,
  created_at timestamp with time zone default now()
);

-- Tarjetas (una fila por cada tarjeta cargada)
create table tarjetas (
  id uuid primary key default gen_random_uuid(),
  partido_id uuid references partidos(id) on delete cascade,
  jugador_id uuid references jugadores(id),
  tipo text not null check (tipo in ('verde','amarilla','roja')),
  created_at timestamp with time zone default now()
);

-- ════════════════════════════════════════
-- SEGURIDAD: Row Level Security (RLS)
-- ════════════════════════════════════════
alter table perfiles enable row level security;
alter table equipos enable row level security;
alter table jugadores enable row level security;
alter table arbitros enable row level security;
alter table torneos enable row level security;
alter table partidos enable row level security;
alter table tarjetas enable row level security;

-- Función helper: saber el rol del usuario logueado
create or replace function mi_rol() returns text as $$
  select rol from perfiles where id = auth.uid()
$$ language sql security definer;

create or replace function mi_equipo() returns uuid as $$
  select equipo_id from perfiles where id = auth.uid()
$$ language sql security definer;

-- Lectura pública (cualquiera puede ver equipos, tabla, partidos — es el sitio público)
create policy "lectura publica equipos" on equipos for select using (true);
create policy "lectura publica partidos" on partidos for select using (true);
create policy "lectura publica torneos" on torneos for select using (true);
create policy "lectura publica tarjetas" on tarjetas for select using (true);

-- Jugadores: lectura pública de datos básicos NO sensibles la maneja el frontend
-- (mostrando solo nombre/categoria en vistas públicas); acceso completo solo a su equipo o admin
create policy "equipo ve sus jugadores" on jugadores for select
  using (mi_rol() = 'admin' or equipo_id = mi_equipo());
create policy "equipo edita sus jugadores" on jugadores for insert
  with check (mi_rol() = 'admin' or equipo_id = mi_equipo());
create policy "equipo actualiza sus jugadores" on jugadores for update
  using (mi_rol() = 'admin' or equipo_id = mi_equipo());
create policy "equipo elimina sus jugadores" on jugadores for delete
  using (mi_rol() = 'admin' or equipo_id = mi_equipo());

-- Partidos: árbitro solo edita SU partido y solo si no está cerrado; admin edita siempre
create policy "arbitro edita su partido si no cerrado" on partidos for update
  using (
    mi_rol() = 'admin'
    or (mi_rol() = 'arbitro' and arbitro_id = auth.uid() and estado != 'cerrado')
  );
create policy "solo admin crea partidos" on partidos for insert
  with check (mi_rol() = 'admin');
create policy "solo admin borra partidos" on partidos for delete
  using (mi_rol() = 'admin');

-- Tarjetas: mismo criterio que partidos (vía el partido asociado)
create policy "arbitro carga tarjetas de su partido" on tarjetas for insert
  with check (
    mi_rol() = 'admin'
    or exists (
      select 1 from partidos p
      where p.id = partido_id and p.arbitro_id = auth.uid() and p.estado != 'cerrado'
    )
  );

-- Equipos/torneos: solo admin crea y modifica
create policy "solo admin crea equipos" on equipos for insert with check (mi_rol() = 'admin');
create policy "solo admin edita equipos" on equipos for update using (mi_rol() = 'admin');
create policy "solo admin crea torneos" on torneos for insert with check (mi_rol() = 'admin');
create policy "solo admin edita torneos" on torneos for update using (mi_rol() = 'admin');

-- Perfiles: cada uno ve el suyo, admin ve todos
create policy "ver mi perfil" on perfiles for select using (id = auth.uid() or mi_rol() = 'admin');
