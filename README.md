# Historial médico

Interfaz inicial de una aplicación Flutter para organizar información de salud en México. Desarrollo inicial en Android desde Windows; iOS se abordará después.

## Estado actual

- Inicio con resumen y accesos directos.
- Historial con filtros por categoría, búsqueda y detalle de registros.
- Documentos de ejemplo con autor, fecha y procedencia.
- Accesos simulados con confirmación para revocar y opción para reiniciar la demostración.
- Perfil ficticio con antecedentes y alergias.

Todos los datos son ficticios. No hay autenticación, backend, archivos médicos reales ni persistencia. La revocación solo modifica el estado visual en memoria y se reinicia al arrancar la aplicación. Las etiquetas de autor y procedencia son ejemplos, no identidades verificadas.

## Ejecutar

Con Flutter 3.41.9 y las herramientas de Android configuradas:

```powershell
flutter pub get
flutter emulators --launch Pixel_9_Pro
flutter devices
flutter run
```

El ID del emulador puede variar. Usa `flutter emulators` para consultar los disponibles.

## Comprobar

```powershell
flutter analyze
flutter test
```

## Organización

- `lib/main.dart`: aplicación y tema visual.
- `lib/screens/home_shell.dart`: navegación y pantallas iniciales.
- `lib/data/demo_records.dart`: modelo y datos ficticios.
- `test/widget_test.dart`: navegación, filtros, detalle y revocación simulada.

## Siguientes etapas

Autenticación, perfil editable, almacenamiento de documentos y permisos comprobados en servidor. Diferenciar siempre información declarada por el paciente de registros aportados por profesionales. No cargar datos médicos reales en este prototipo.

## Flujo de acceso (prototipo)

La aplicación abre en Bienvenida. Crear cuenta e Iniciar sesión permiten probar formularios con validación local de correo y contraseña; el registro también comprueba nombre y confirmación. No existe autenticación real, no se crean cuentas y no se guardan ni envían los valores introducidos. Usa exclusivamente datos ficticios. El diálogo de validación permite abrir el mismo perfil de ejemplo de Alex.

Puedes entrar directamente con Explorar demostración y salir desde Perfil. Al salir, se elimina la pantalla de demostración y su estado en memoria. Los formularios se descartan al entrar en la demostración. La siguiente etapa será seleccionar y configurar el servicio de autenticación.
