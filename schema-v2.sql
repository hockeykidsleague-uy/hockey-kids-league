-- ════════════════════════════════════════
-- HOCKEY KIDS LEAGUE — Schema v2
-- Refleja: sin Sub-12, Club separado de Equipo,
-- campos de tutor obligatorios, tarjetas actualizadas
-- Pegar completo en SQL Editor de Supabase y ejecutar (RUN)
-- Si ya corriste el schema viejo, primero: DROP TABLE tarjetas, partidos, jugadores, equipos, arbitros, torneos, perfiles CASCADE;
-- ════════════════════════════════════════

create table perfiles (
  id uuid references auth.users on delete cascade primary key,
  rol text not null check (rol in ('admin','arbitro','equipo')),
  nombre text not null,
  equipo_id uuid,
  created_at timestamp with time zone default now()
);

-- Clubes (institución madre)
create table clubes (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  logo_url text,
  created_at timestamp with time zone default now()
);

-- Equipos (pertenecen a un club, un club puede tener varios equipos por categoría)
create table equipos (
  id uuid primary key default gen_random_uuid(),
  club_id uuid references clubes(id) on delete cascade,
  nombre text not null,
  categoria text not null check (categoria in ('Sub 6','Sub 8','Sub 10')),
  serie text default 'A',
  created_at timestamp with time zone default now()
);

alter table perfiles add constraint fk_equipo foreign key (equipo_id) references equipos(id);

-- Jugadores (con campos de tutor obligatorios)
create table jugadores (
  id uuid primary key default gen_random_uuid(),
  equipo_id uuid references equipos(id) on delete cascade,
  nombre text not null,
  apellido text not null,
  documento text,
  fecha_nacimiento date,
  categoria text check (categoria in ('Sub 6','Sub 8','Sub 10')),
  sociedad_medica text,
  telefono_sociedad_medica text,
  foto_url text,
  ficha_medica_url text,
  tutor_nombre text not null,
  tutor_telefono text not null,
  tutor_vinculo text not null,
  habilitado boolean default false,
  created_at timestamp with time zone default now()
);

create table arbitros (
  id uuid references auth.users on delete cascade primary key,
  nombre text not null,
  codigo text unique not null
);

-- Torneos: Apertura / Clausura / Copa Campeones
create table torneos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  tipo text not null check (tipo in ('Apertura','Clausura','Copa Campeones')),
  activo boolean default true
);

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
  posesion text,
  mvp_jugador_id uuid references jugadores(id),
  cerrado_en timestamp with time zone,
  created_at timestamp with time zone default now()
);

-- Tarjetas: verde sin duración (solo advertencia), amarilla 2/3/4 min según categoría, roja expulsión
create table tarjetas (
  id uuid primary key default gen_random_uuid(),
  partido_id uuid references partidos(id) on delete cascade,
  jugador_id uuid references jugadores(id),
  tipo text not null check (tipo in ('verde','amarilla','roja')),
  created_at timestamp with time zone default now()
);

-- ════════════════════════════════════════
-- RLS
-- ════════════════════════════════════════
alter table perfiles enable row level security;
alter table clubes enable row level security;
alter table equipos enable row level security;
alter table jugadores enable row level security;
alter table arbitros enable row level security;
alter table torneos enable row level security;
alter table partidos enable row level security;
alter table tarjetas enable row level security;

create or replace function mi_rol() returns text as $$
  select rol from perfiles where id = auth.uid()
$$ language sql security definer;

create or replace function mi_equipo() returns uuid as $$
  select equipo_id from perfiles where id = auth.uid()
$$ language sql security definer;

create policy "lectura publica clubes" on clubes for select using (true);
create policy "lectura publica equipos" on equipos for select using (true);
create policy "lectura publica partidos" on partidos for select using (true);
create policy "lectura publica torneos" on torneos for select using (true);
create policy "lectura publica tarjetas" on tarjetas for select using (true);

create policy "equipo ve sus jugadores" on jugadores for select
  using (mi_rol() = 'admin' or equipo_id = mi_equipo());
create policy "equipo carga sus jugadores" on jugadores for insert
  with check (mi_rol() = 'admin' or equipo_id = mi_equipo());
create policy "equipo actualiza sus jugadores" on jugadores for update
  using (mi_rol() = 'admin' or equipo_id = mi_equipo());
create policy "equipo elimina sus jugadores" on jugadores for delete
  using (mi_rol() = 'admin' or equipo_id = mi_equipo());

create policy "arbitro edita su partido si no cerrado" on partidos for update
  using (
    mi_rol() = 'admin'
    or (mi_rol() = 'arbitro' and arbitro_id = auth.uid() and estado != 'cerrado')
  );
create policy "solo admin crea partidos" on partidos for insert with check (mi_rol() = 'admin');
create policy "solo admin borra partidos" on partidos for delete using (mi_rol() = 'admin');

create policy "arbitro carga tarjetas de su partido" on tarjetas for insert
  with check (
    mi_rol() = 'admin'
    or exists (
      select 1 from partidos p
      where p.id = partido_id and p.arbitro_id = auth.uid() and p.estado != 'cerrado'
    )
  );

create policy "solo admin crea clubes" on clubes for insert with check (mi_rol() = 'admin');
create policy "solo admin edita clubes" on clubes for update using (mi_rol() = 'admin');
create policy "solo admin crea equipos" on equipos for insert with check (mi_rol() = 'admin');
create policy "solo admin edita equipos" on equipos for update using (mi_rol() = 'admin');
create policy "solo admin crea torneos" on torneos for insert with check (mi_rol() = 'admin');
create policy "solo admin edita torneos" on torneos for update using (mi_rol() = 'admin');

create policy "ver mi perfil" on perfiles for select using (id = auth.uid() or mi_rol() = 'admin');
