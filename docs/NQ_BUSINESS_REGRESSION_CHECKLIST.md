# NQ Business — pruebas antes de lanzar

## Seguridad
- [ ] Confirmar qué Supabase usa la web publicada.
- [ ] Auditar triggers de app_profiles y permisos de UPDATE por columna.
- [ ] Bloquear modificación de role/status por cliente, verificar con sesión no admin.
- [ ] Verificar que solo admin gestiona estados NFC/QR.
- [ ] Verificar aislamiento de negocio y membresías múltiples.
- [ ] Revisar SELECT anónimo sobre target_url y negocios aprobados.

## Compatibilidad
- [ ] Probar VETA, Tzura y Feral con NFC y QR reales.
- [ ] Comparar contadores con consultas a eventos.
- [ ] Probar redirecciones Google Maps en iPhone y Android.
- [ ] Probar login, recuperación, edición de perfil y logout.
- [ ] Confirmar que no se alteran eventos ni históricos.

## Interfaz
- [ ] NQ Central Admin para administrador.
- [ ] NQ Business para clientes de cualquier categoría.
- [ ] NQ Restaurant para sector restaurante.
- [ ] Dashboard responsive y gráficos NFC/QR separados.
- [ ] Verificar que la interfaz no muestra controles de activación al cliente.

## Lanzamiento
- [ ] Preview aislada validada.
- [ ] Revisión de diff y aprobación antes de merge.
- [ ] Plan de reversión documentado.
