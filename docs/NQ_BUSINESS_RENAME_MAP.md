# NQ Business — contrato de nombres y compatibilidad

## Nombres visibles
- NQ Central Admin: consola del administrador.
- NQ Business: portal común de clientes.
- NQ Restaurant: variante para restauración; se mantiene para los clientes existentes.
- Negocio / Negocios: etiquetas genéricas del panel central.
- NFC y QR: conservar etiquetas y métricas separadas.
- Reseñas: recuentos verificados o snapshots; nunca convertir aperturas en reseñas.

## Persistencia y APIs
- NO renombrar app_businesses, app_business_members, app_business_cards, app_business_events ni app_profiles.
- NO renombrar columnas, funciones RPC, URLs NFC/QR, tokens ni identificadores.
- NO cambiar dominios, credenciales o conexión Supabase.
- Mantener todas las referencias legacy app_restaurants y app_events hasta verificar consumidores.
- Clientes pueden solicitar activación/desactivación; únicamente admin puede ejecutar cambios.

## Compatibilidad y aceptación
1. Login, logout, cambio de nombre y recuperación de contraseña intactos.
2. Métricas NFC/QR hoy, 7, 30 días y total consistentes con base.
3. Redirección NFC y QR válida, incluso en móvil.
4. El usuario de un negocio no accede a datos ajenos.
5. Clientes no pueden editar estado de tarjeta ni rol/estado de cuenta.
6. NQ Restaurant permanece funcional y no se pierde ningún histórico.
7. Validar preview y regresión antes de fusionar a main.
