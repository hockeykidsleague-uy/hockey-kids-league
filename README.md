# Hockey Kids League

Sitio estático (HTML/CSS/JS puro, sin build). `index.html` es la página completa.

## Deploy en Vercel
1. Framework Preset: **Other**
2. Build Command: (dejar vacío)
3. Output Directory: `./`

## Base de datos (Supabase)
1. Correr `schema-supabase.sql` en el SQL Editor de Supabase
2. Correr `asignar-roles.sql` después
3. Variables de entorno en Vercel (Settings → Environment Variables):
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
