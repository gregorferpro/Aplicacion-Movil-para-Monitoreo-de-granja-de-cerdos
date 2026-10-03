# Cabaña Porcina

Aplicación Flutter para administrar una cabaña de cerdos desde celular.

## Qué incluye

- Dashboard operativo con métricas de animales, madres, alimento y alertas.
- Mapa animado de la granja inspirado en la maqueta 3D original.
- Áreas: Alimentos, Engorde, Parrilla, Pre Destete, Gestación, Maternidad 1, Maternidad 2 y Cargadero.
- Registros de movimientos, sanidad y tareas.
- Navegación inferior pensada para uso móvil.

## Ejecutar

```powershell
flutter pub get
flutter run
```

Para probar en navegador:

```powershell
flutter run -d chrome
```

## Generar APK

Primero corrige el SDK Android:

```powershell
flutter doctor -v
```

En esta máquina falta el componente `cmdline-tools` del Android SDK. Instálalo desde Android Studio:

`More Actions > SDK Manager > SDK Tools > Android SDK Command-line Tools`

Después ejecuta:

```powershell
flutter build apk --release
```

Nota: si una build nativa falla por la ruta con `ñ`, copia el proyecto a una ruta sin acentos, por ejemplo `D:\Cabana\cabana_cerdos_app`, y compila desde ahí.
