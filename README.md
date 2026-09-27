# TripSpot (versión individual) — funcional, sin servicios externos

Versión simplificada para la materia de la Profa. Dulce: **solo app
móvil**, todo funciona local en el teléfono (sin Firebase, sin
Facebook, sin Google Maps) — pensada para tener algo funcional ya,
y conectar servicios en la nube después cuando quieras.

## Qué incluye
- Registro / login local (sin base de datos externa) — la contraseña se
  guarda con hash SHA-256, nunca en texto plano.
- **El primer usuario que se registra en el dispositivo se vuelve
  administrador automáticamente.** Los siguientes son usuarios normales.
- Búsqueda de lugares reales cercanos por tu ubicación GPS real
  (Overpass API de OpenStreetMap, sin API key).
- Mapa con tu ubicación real (OpenStreetMap vía `flutter_map`).
- Favoritos guardados en el propio teléfono.
- **Panel de administrador** (solo lo ve la cuenta admin): lista de
  usuarios registrados en el dispositivo, y CRUD de "lugares
  destacados" que aparecen fijados arriba para todos los usuarios.

## Cómo probarlo
```bash
cd mobile_cloud
flutter create --platforms=android --org com.tripspot .
```
(esto genera la carpeta `android/` completa; vuelve a copiar encima el
`AndroidManifest.xml` que ya viene en este proyecto, ya trae los
permisos de ubicación).

```bash
flutter pub get
flutter run -d <id-de-tu-telefono>
```

Para ver el panel de administrador: regístrate (esa primera cuenta será
admin), inicia sesión, y en la barra inferior debe aparecer la pestaña
**Admin**. Si registras una segunda cuenta y entras con ella, esa NO
tendrá acceso al panel — así puedes demostrar el control de acceso.

## Cuando quieras agregar los servicios en la nube
Ya armamos antes una versión con Firebase Auth + Firestore + Facebook
Login + Google Maps (queda guardada aparte si la necesitas retomar).
Cuando estés listo para integrarlos:
- Los favoritos y "lugares destacados" pasarían de `SharedPreferences`
  a **Cloud Firestore**.
- El registro/login pasaría a **Firebase Authentication**.
- El mapa pasaría de `flutter_map`/OpenStreetMap a **Google Maps**.
- La estructura de pantallas (Explora, Mapa, Favoritos, Perfil, Admin)
  no cambia — solo cambia de dónde vienen los datos.
