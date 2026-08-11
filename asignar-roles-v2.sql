-- ════════════════════════════════════════
-- Paso 3 (v2): asignar roles usando el schema nuevo
-- Correr DESPUÉS de schema-v2.sql
-- Usa los mismos 3 usuarios ya creados en Auth
-- ════════════════════════════════════════

-- 1) Admin
insert into perfiles (id, rol, nombre) values
('052ff6b5-021c-4894-930a-5cd939764b4c', 'admin', 'Administrador');

-- 2) Árbitro (Jorge Silva / arbitro01)
insert into arbitros (id, nombre, codigo) values
('0144cb3f-6b43-4163-a724-c3ceda604b5c', 'Jorge Silva', 'arbitro01');

insert into perfiles (id, rol, nombre) values
('0144cb3f-6b43-4163-a724-c3ceda604b5c', 'arbitro', 'Jorge Silva');

-- 3) Club + equipo Los Rayos + perfil, todo en un solo paso
with nuevo_club as (
  insert into clubes (nombre) values ('Los Rayos') returning id
), nuevo_equipo as (
  insert into equipos (club_id, nombre, categoria, serie)
  select id, 'Los Rayos', 'Sub 8', 'A' from nuevo_club
  returning id
)
insert into perfiles (id, rol, nombre, equipo_id)
select '3fa4b249-c980-40b3-a055-b71ec26d11bd', 'equipo', 'Los Rayos', id
from nuevo_equipo;

-- 4) Un torneo de ejemplo para poder crear partidos
insert into torneos (nombre, tipo) values ('Apertura 2026', 'Apertura');

-- ════════════════════════════════════════
-- Verificación: debería devolver 3 filas
-- ════════════════════════════════════════
select p.rol, p.nombre, e.nombre as equipo
from perfiles p
left join equipos e on e.id = p.equipo_id;
