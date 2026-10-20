# NQ Business — auditoría técnica (solo lectura)

Fecha: 2026-10-20. Estado: auditoría parcial, NO se modificó Supabase ni main.

## Entornos detectados
- Proyecto Supabase «Tzura SteakHouse»: contiene app_businesses con category, app_business_members, app_business_cards, app_business_events, app_business_review_snapshots y app_profiles. También conserva tablas legacy app_restaurants y app_events.
- Proyecto «NQ Central Security Test»: contiene app_businesses y tablas de eventos/tarjetas; su esquema es diferente, sin la misma columna category en app_businesses.
- No asumir que cualquiera de los dos es producción sin confirmar el frontend conectado.

## Seguridad (Tzura SteakHouse, consulta pg_policies)
- app_business_cards: escritura ALL solo para perfiles admin approved; SELECT público para tarjetas active de negocios approved y no archivadas.
- app_business_events: escritura ALL para private.app_is_admin(); SELECT para admin o miembros con perfil approved y negocio approved.
- app_business_members: escritura admin; SELECT del propio usuario o admin.
- app_businesses: escritura admin; SELECT público de negocios approved; SELECT adicional de miembro o admin.
- app_profiles: SELECT propio o admin; UPDATE propio o admin. Revisar si el auto-UPDATE permite cambiar role/status, ya que WITH CHECK solo comprueba user_id. **Posible escalada de privilegios; requiere inspección de GRANT por columnas, triggers y pruebas controladas.**
- Los GRANT a authenticated incluyen UPDATE sobre app_profiles (revisar en detalle). No asumir que RLS por sí sola protege columnas sensibles.
- Los GRANT de authenticated para app_business_cards incluyen escrituras, pero RLS parece restringirlas a admin. Verificar mediante sesión no admin.
- Los SELECT anon de app_businesses y app_business_cards están concedidos; revisar exposición de target_url y otros campos. No revocar sin analizar gateway público.

## Frontend GitHub
- Repositorio dariobarrii/Restaurantes confirmado mediante commits, último commit consultado modificó index.html.
- La API del conector fetch_file devolvió 404 para index.html incluso en main; no se pudo inspeccionar su contenido. Evitar renombrar o reescribir frontend a ciegas.

## Acciones siguientes
1. Auditar app_profiles: permisos UPDATE por columna, triggers y protección de role/status; prueba de usuario normal en entorno seguro.
2. Confirmar origen Supabase del frontend desplegado y rutas reales del código.
3. Mantener tablas y endpoints; cambiar solo etiquetas visibles NQ Business / NQ Central Admin / NQ Restaurant en rama de pruebas.
4. Pruebas de regresión NFC, QR, login, roles, membresías y redirecciones antes de publicar.
