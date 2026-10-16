# NQ Central — Portal privado para restaurantes

## Qué incluye
- `index.html`: acceso y solicitudes de cuenta.
- `admin.html`: administración de usuarios, restaurantes y estadísticas NFC/QR.
- `portal.html`: portal de restaurante reutilizando el diseño de `Restaurantes-preview`.
- `supabase/migrations/003_secure_restaurant_portal.sql`: conexión segura del portal con los datos reales.

## Activación requerida en Supabase
Antes de que los restaurantes usen el portal, ejecutar una vez el archivo:
`supabase/migrations/003_secure_restaurant_portal.sql`

En Supabase: **SQL Editor → New query**, pegar el contenido completo del archivo y pulsar **Run**. La migración:
- importa los eventos NFC/QR históricos a `app_events` sin duplicarlos;
- refleja automáticamente los nuevos eventos de `nfc_events` en `app_events`;
- conserva la separación NFC/QR;
- habilita las capturas manuales de apertura y cierre de reseñas;
- permite editar el nombre del perfil sin permitir que un usuario cambie su rol o se apruebe a sí mismo.

No elimina ni reemplaza las tablas históricas `nfc_events` ni `nfc_card_tokens`.

## Prueba de aceptación
1. Iniciar sesión como administrador en `/central/`.
2. Aprobar la cuenta de prueba y asignarla a **un solo** restaurante.
3. Abrir `/central/portal.html` con esa cuenta.
4. Confirmar que ve únicamente el restaurante asignado, con NFC y QR separados.
5. Guardar una apertura y un cierre de reseñas; comprobar la diferencia.
6. Probar actualizar la página, cerrar sesión y volver a entrar.
7. Intentar abrir otro restaurante: no debe aparecer en el selector ni permitir consultar sus eventos.

No considerar el portal listo para clientes hasta completar esta prueba con dos cuentas distintas y verificar que cada una solo ve su restaurante.
