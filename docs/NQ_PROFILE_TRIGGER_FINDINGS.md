# NQ Central — revisión de protección del perfil

Fecha: 2026-10-20. Auditoría de solo lectura, proyecto Supabase Tzura SteakHouse.

## Evidencia
Trigger BEFORE UPDATE public.app_profiles_protect_fields llama a public.app_protect_profile_fields().
La función es SECURITY DEFINER, search_path vacío. Para el usuario que actualiza su propia fila y que NO es administrador, restablece NEW.role, NEW.status y NEW.email a sus valores anteriores, y establece updated_at = now().

## Consecuencias
- Existe protección contra cambio directo de role, status y email por usuarios normales.
- Los GRANT de UPDATE a authenticated sobre esas columnas siguen siendo amplios, pero el trigger mitiga parte del riesgo.
- El trigger no restablece explícitamente NEW.user_id. Revisar la PK/FK, posibles cambios de propietario de fila y funciones consumidoras.
- La protección de email requiere revisar flujo real de cambio confirmado, no eliminarla.
- No afirmar que existe una vulnerabilidad explotable sin una prueba autorizada.

## Pruebas necesarias
1. Usuario normal modifica full_name y conserva role/status/email.
2. Usuario normal intenta cambiar role/status y comprobar que no se persisten.
3. Usuario normal intenta cambiar user_id y comprobar que la operación se rechaza.
4. Admin puede gestionar aprobaciones por el flujo previsto.
5. Ninguna función SECURITY DEFINER elude validaciones por accidente.

No aplicar revocaciones de privilegios ni cambios en producción sin verificar dependencias y pruebas.
