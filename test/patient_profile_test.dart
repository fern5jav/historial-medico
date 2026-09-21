import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historial_medico/data/patient_profile.dart';
import 'package:historial_medico/screens/patient_profile_screen.dart';

class MemoryProfileStore implements ProfileStore {
  PatientProfile? profile;
  bool failLoad = false;
  bool failSave = false;
  int writes = 0;
  @override
  Future<PatientProfile?> load() async {
    if (failLoad) {
      throw Exception('Load failed');
    }
    return profile;
  }

  @override
  Future<void> save(PatientProfile value, PatientProfile? original) async {
    if (failSave) {
      throw ProfileConflict();
    }
    profile = value;
    writes++;
  }
}

void main() {
  test('Rechaza fechas inexistentes y futuras y acepta año bisiesto', () {
    final today = DateTime(2026, 9, 21);
    expect(validateBirthDate('2024-02-29', today: today), isNull);
    expect(validateBirthDate('2023-02-29', today: today), isNotNull);
    expect(validateBirthDate('2026-09-22', today: today), isNotNull);
    expect(validateBirthDate('01/01/2000', today: today), isNotNull);
    expect(validateBirthDate('', today: today), isNull);
  });

  test('La escritura usa solo los cinco campos autorizados', () {
    const profile = PatientProfile(name: ' Alex ', allergies: ' Ejemplo ');
    final data = profile.toFirestore();
    expect(data.keys.toSet(), {
      'nombre',
      'fechaNacimiento',
      'alergias',
      'antecedentes',
      'actualizadoEn',
    });
    expect(data['nombre'], 'Alex');
    expect(data['alergias'], 'Ejemplo');
  });

  Future<void> openEditor(WidgetTester tester, MemoryProfileStore store) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<bool>(
                  builder: (_) =>
                      ProfileEditor(store: store, initialName: 'Alex'),
                ),
              ),
              child: const Text('Abrir perfil'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir perfil'));
    await tester.pumpAndSettle();
  }

  testWidgets('Guarda un perfil nuevo y lo recupera al volver a abrir', (
    tester,
  ) async {
    final store = MemoryProfileStore();
    await openEditor(tester, store);
    await tester.enterText(
      find.byKey(const Key('profileName')),
      'Paciente de prueba',
    );
    await tester.enterText(
      find.byKey(const Key('profileBirthDate')),
      '2000-02-29',
    );
    await tester.ensureVisible(find.text('Guardar perfil'));
    await tester.tap(find.text('Guardar perfil'));
    await tester.pumpAndSettle();
    expect(store.writes, 1);
    expect(find.text('Abrir perfil'), findsOneWidget);
    await tester.tap(find.text('Abrir perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Paciente de prueba'), findsOneWidget);
    expect(find.text('2000-02-29'), findsOneWidget);
  });

  testWidgets('Una carga fallida impide guardar y permite reintentar', (
    tester,
  ) async {
    final store = MemoryProfileStore()..failLoad = true;
    await openEditor(tester, store);
    expect(find.text('Guardar perfil'), findsNothing);
    store.failLoad = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Guardar perfil'), findsOneWidget);
    expect(store.writes, 0);
  });

  testWidgets('Un conflicto conserva el formulario sin confirmar guardado', (
    tester,
  ) async {
    final store = MemoryProfileStore()..failSave = true;
    await openEditor(tester, store);
    await tester.enterText(find.byKey(const Key('profileName')), 'Mi edición');
    await tester.ensureVisible(find.text('Guardar perfil'));
    await tester.tap(find.text('Guardar perfil'));
    await tester.pumpAndSettle();
    expect(find.textContaining('El perfil cambió'), findsOneWidget);
    expect(find.text('Mi edición'), findsOneWidget);
    expect(store.writes, 0);
    expect(tester.takeException(), isNull);
  });
}
