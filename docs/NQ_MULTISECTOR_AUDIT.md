# NQ Central — Auditoría y plan multisectorial

Fecha: 2026-10-20
Estado: planificación; NO ejecutar cambios de producción.

## Objetivo
Convertir NQ Central en una plataforma para restaurantes, belleza, hoteles y comercios sin duplicar backend ni romper NQ Restaurant.

## Restricciones
- No modificar main ni despliegues de producción.
- No alterar datos reales, credenciales, tokens, RLS o endpoints existentes sin auditoría y pruebas.
- No contratar servicios ni comprar dominio.
- Activación/desactivación de NFC y QR: exclusiva del administrador; clientes solo solicitan cambios.
- Separar métricas NFC/QR de reseñas; nunca inferir reseñas reales de los taps.

## Auditoría pendiente
1. Inventariar rutas y archivos reales del repositorio y ramas de trabajo; el buscador no devolvió coincidencias y las rutas index.html, README.md y package.json no se encontraron en raíz.
2. Localizar frontend y componentes del portal y admin; identificar etiquetas y filtros dependientes de restaurante.
3. Revisar tablas app_businesses, app_restaurants, app_restaurant_members, app_profiles, eventos y políticas RLS directamente en Supabase, en modo lectura.
4. Verificar cómo se asocia cada tarjeta/QR a negocio y cómo se autoriza el acceso multiempresa.
5. Documentar contrato de compatibilidad y pruebas de regresión para VETA, Tzura y Feral.

## Propuesta de diseño (no implementada)
- Entidad genérica business con tipo de sector (restaurant, beauty, hotel, retail, other).
- Configuración de etiquetas y funciones por sector; mismas métricas de interacción.
- Migraciones aditivas y reversibles; no renombrar ni eliminar tablas existentes sin plan probado.
- UI NQ Restaurant como plantilla base reutilizable, conservando estilo premium.
- Panel admin único para gestionar sectores, negocios, usuarios, tarjetas, QR y solicitudes.

## Criterios de aceptación
- VETA, Tzura y Feral conservan login, métricas y enlaces NFC/QR.
- Usuarios de un negocio no acceden a datos de otros sin membresía autorizada.
- Ningún cliente puede activar/desactivar dispositivos directamente.
- La demo multisectorial funciona desde móvil antes de fusionar cambios.
- No se modifica producción hasta aprobación y pruebas.
