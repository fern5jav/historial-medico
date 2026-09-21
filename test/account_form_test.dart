import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historial_medico/main.dart';

void main() {
  testWidgets('Valida registro sin crear una cuenta real', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const HistorialApp());
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Validar formulario de prueba'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un correo válido.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('name')), 'Alex');
    await tester.enterText(find.byKey(const Key('email')), 'alex@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'Prueba123');
    await tester.enterText(find.byKey(const Key('confirmPassword')), 'Otra1234');
    await tester.ensureVisible(find.text('Validar formulario de prueba'));
    await tester.tap(find.text('Validar formulario de prueba'));
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('confirmPassword')), 'Prueba123');
    await tester.ensureVisible(find.text('Validar formulario de prueba'));
    await tester.tap(find.text('Validar formulario de prueba'));
    await tester.pumpAndSettle();
    expect(find.text('Formulario válido'), findsOneWidget);
    await tester.tap(find.text('Ver demostración'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Alex'), findsOneWidget);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir de la demostración'));
    await tester.pumpAndSettle();
    expect(find.text('Explorar demostración'), findsOneWidget);
    expect(find.byKey(const Key('password')), findsNothing);
  });

  testWidgets('Inicio de sesión y visibilidad de contraseña', (tester) async {
    await tester.pumpWidget(const HistorialApp());
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('email')), 'alex@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'Prueba123');
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    await tester.ensureVisible(find.text('Validar formulario de prueba'));
    await tester.tap(find.text('Validar formulario de prueba'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se verificaron las credenciales'), findsOneWidget);
  });
}
