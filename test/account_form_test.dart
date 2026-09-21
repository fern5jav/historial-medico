import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historial_medico/main.dart';
import 'package:historial_medico/screens/welcome_screen.dart';
import 'package:historial_medico/screens/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  test('Los errores de credenciales no revelan si existe la cuenta', () {
    for (final code in [
      'wrong-password',
      'user-not-found',
      'invalid-credential',
    ]) {
      expect(
        authError(FirebaseAuthException(code: code)),
        'Correo o contraseña incorrectos.',
      );
    }
  });

  testWidgets('Registro valida los campos antes de contactar Firebase', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const HistorialApp(home: AccountFormScreen(register: true)),
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Crear cuenta'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe al menos 2 caracteres.'), findsOneWidget);
    expect(find.text('Escribe un correo válido.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('name')), 'Alex');
    await tester.enterText(find.byKey(const Key('email')), 'alex@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'Prueba123456');
    await tester.enterText(
      find.byKey(const Key('confirmPassword')),
      'diferente',
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Crear cuenta'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recuperación exige un correo y permite mostrar contraseña', (
    tester,
  ) async {
    await tester.pumpWidget(
      const HistorialApp(home: AccountFormScreen(register: false)),
    );
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    final reset = find.text('Olvidé mi contraseña');
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(find.text('Escribe primero tu correo electrónico.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
