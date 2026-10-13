# Prototipo central NFC + QR

Este prototipo está aislado en la rama `central-app-prototype` y en la carpeta `central/`. No sustituye el `index.html` raíz que se usa en el experimento anterior de VETA/GA4.

## Diseño técnico

- Interfaz web responsive con marca central negro/madera/dorado.
- Supabase Auth para registro e inicio de sesión.
- Todo usuario nuevo queda `role=restaurant` y `status=pending`.
- Un administrador debe aprobar las cuentas y asociar el usuario al restaurante.
- PostgreSQL + RLS separan los datos por restaurante.
- NFC y QR tienen tipos de evento distintos: `nfc_tap` y `qr_scan`.
- Reseñas se almacenan en snapshots; nunca se calculan a partir de escaneos.

## Archivos

- `central/index.html`: pantalla inicial de acceso. No funciona hasta configurar las dos variables de Supabase en el script.
- `central/supabase/migrations/001_app_core.sql`: esquema aditivo de primera etapa.

## Próximos pasos antes de activar

1. Hacer una copia de seguridad de Supabase.
2. Revisar la migración SQL y ejecutarla en SQL Editor. Solo crea tablas `app_*`; no modifica tablas existentes.
3. Configurar Auth URLs y confirmación de correo en Supabase.
4. Crear tu usuario mediante el formulario.
5. Convertir tu usuario en administrador desde SQL Editor, reemplazando el email:

```sql
update public.app_profiles p
set role = 'admin', status = 'approved'
from auth.users u
where p.user_id = u.id
  and lower(u.email) = lower('TU_EMAIL');
```

6. Para cada restaurante, el panel administrativo creará el registro `app_restaurants` y una fila en `app_restaurant_members` al aprobar su solicitud.
7. Probar con dos usuarios distintos y verificar que no puedan ver datos ajenos antes de usarlo con clientes reales.

## No hacer todavía

- No cambies ni elimines políticas actuales de `nfc_events`.
- No migres todavía las tarjetas impresas ni cambies sus destinos.
- No pongas una clave `service_role` en el navegador.
- No confundas eventos NFC/QR con reseñas reales.
