import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historial_medico/main.dart';

void main() {
  testWidgets('Las cinco pantallas caben en un teléfono', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const HistorialApp());
    await tester.ensureVisible(find.text('Explorar demostración'));
    await tester.tap(find.text('Explorar demostración'));
    await tester.pumpAndSettle();

    for (final label in [
      'Historial',
      'Documentos',
      'Accesos',
      'Perfil',
      'Inicio',
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Navega, filtra y muestra el detalle', (tester) async {
    await tester.pumpWidget(const HistorialApp());
    await tester.ensureVisible(find.text('Explorar demostración'));
    await tester.tap(find.text('Explorar demostración'));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Alex'), findsOneWidget);

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recetas'));
    await tester.pumpAndSettle();

    expect(find.text('Consulta de seguimiento'), findsNothing);

    await tester.tap(find.text('Receta de consulta'));
    await tester.pumpAndSettle();

    expect(find.text('Cerrar'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();

    expect(
      find.text('No encontramos registros con esos filtros.'),
      findsOneWidget,
    );
  });

  testWidgets('Revocación confirmada actualiza Inicio', (tester) async {
    await tester.pumpWidget(const HistorialApp());
    await tester.ensureVisible(find.text('Explorar demostración'));
    await tester.tap(find.text('Explorar demostración'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accesos'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Revocar acceso de ejemplo'));
    await tester.tap(find.text('Revocar acceso de ejemplo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Acceso activo · Simulado'), findsOneWidget);

    await tester.ensureVisible(find.text('Revocar acceso de ejemplo'));
    await tester.tap(find.text('Revocar acceso de ejemplo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Revocar'));
    await tester.pumpAndSettle();

    expect(find.text('Acceso revocado · Simulado'), findsOneWidget);

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();

    // Desplaza Inicio hasta que se construya y aparezca el contador.
    await tester.scrollUntilVisible(
      find.text('0 acceso activo'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('0 acceso activo'), findsOneWidget);

    await tester.tap(find.text('Documentos'));
    await tester.pumpAndSettle();

    expect(find.text('Tus documentos'), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}