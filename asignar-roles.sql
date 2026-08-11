-- ════════════════════════════════════════
-- Paso 3: asignar roles a los usuarios ya creados
-- Pegar completo en SQL Editor y ejecutar (RUN)
-- ════════════════════════════════════════

-- 1) Admin
insert into perfiles (id, rol, nombre) values
('052ff6b5-021c-4894-930a-5cd939764b4c', 'admin', 'Administrador');

-- 2) Árbitro (Jorge Silva / arbitro01)
insert into arbitros (id, nombre, codigo) values
('0144cb3f-6b43-4163-a724-c3ceda604b5c', 'Jorge Silva', 'arbitro01');

insert into perfiles (id, rol, nombre) values
('0144cb3f-6b43-4163-a724-c3ceda604b5c', 'arbitro', 'Jorge Silva');

-- 3) Equipo Los Rayos — crea el equipo Y su perfil en un solo paso
with nuevo_equipo as (
  insert into equipos (nombre, categoria, color)
  values ('Los Rayos', 'Sub 8', 't3')
  returning id
)
insert into perfiles (id, rol, nombre, equipo_id)
select '3fa4b249-c980-40b3-a055-b71ec26d11bd', 'equipo', 'Los Rayos', id
from nuevo_equipo;

-- ════════════════════════════════════════
-- Verificación: esto debería devolver 3 filas
-- ════════════════════════════════════════
select p.rol, p.nombre, e.nombre as equipo
from perfiles p
left join equipos e on e.id = p.equipo_id;
