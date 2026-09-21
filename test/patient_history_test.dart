import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historial_medico/data/patient_record.dart';
import 'package:historial_medico/screens/patient_history_screen.dart';

class MemoryRecords implements RecordStore {
  final records = <PatientRecord>[];
  final ids = <String>[];
  bool fail = false;
  bool failRead = false;
  @override
  String get uid => 'usuario-prueba';
  @override
  String newId() => 'registro-prueba';
  @override
  Future<List<PatientRecord>> load() async {
    if (failRead) {
      throw Exception('Read failure');
    }
    return List.of(records);
  }

  @override
  Future<void> create(PatientRecord record) async {
    ids.add(record.id);
    if (fail) {
      throw Exception('Write failure');
    }
    if (!records.any((r) => r.id == record.id)) {
      records.add(record);
    }
  }
}

void main() {
  test('El registro fija procedencia, autor y fecha sin desplazar el día', () {
    final r = PatientRecord(
      id: '1',
      title: ' Ejemplo ',
      date: DateTime(2025, 2, 15),
      category: 'Estudio',
      description: ' Datos ficticios ',
      authorUid: 'A',
    );
    final data = r.toFirestore();
    expect(data['origen'], 'paciente');
    expect(data['autorUid'], 'A');
    expect(data['titulo'], 'Ejemplo');
    expect(
      (data['fecha'] as Timestamp).toDate().toUtc(),
      DateTime.utc(2025, 2, 15),
    );
    expect(data.keys.toSet(), {
      'titulo',
      'fecha',
      'categoria',
      'descripcion',
      'autorUid',
      'origen',
      'creadoEn',
    });
  });

  Future<void> start(WidgetTester tester, MemoryRecords store) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: HistoryPage(store: store)));
    await tester.pumpAndSettle();
  }

  testWidgets('Crea, lista y abre el detalle de un registro', (tester) async {
    final store = MemoryRecords();
    await start(tester, store);
    expect(find.textContaining('Aún no tienes registros'), findsOneWidget);
    await tester.tap(find.text('Agregar registro'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar registro'));
    await tester.tap(find.text('Guardar registro'));
    await tester.pumpAndSettle();
    expect(store.records, isEmpty);
    expect(find.text('Escribe entre 2 y 120 caracteres.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('recordTitle')),
      'Control de ejemplo',
    );
    await tester.enterText(
      find.byKey(const Key('recordDescription')),
      'Descripción ficticia de la consulta.',
    );
    await tester.ensureVisible(find.text('Guardar registro'));
    await tester.tap(find.text('Guardar registro'));
    await tester.pumpAndSettle();
    expect(store.records, hasLength(1));
    await tester.tap(find.text('Control de ejemplo'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del registro'), findsOneWidget);
    expect(find.text('Descripción ficticia de la consulta.'), findsOneWidget);
  });

  testWidgets('Error al guardar conserva datos y reintenta el mismo ID', (
    tester,
  ) async {
    final store = MemoryRecords()..fail = true;
    await start(tester, store);
    await tester.tap(find.text('Agregar registro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('recordTitle')), 'Ejemplo');
    await tester.enterText(
      find.byKey(const Key('recordDescription')),
      'Datos de ejemplo.',
    );
    await tester.ensureVisible(find.text('Guardar registro'));
    await tester.tap(find.text('Guardar registro'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No pudimos confirmar'), findsOneWidget);
    expect(find.text('Registro guardado correctamente.'), findsNothing);
    store.fail = false;
    await tester.ensureVisible(find.text('Reintentar guardado'));
    await tester.tap(find.text('Reintentar guardado'));
    await tester.pumpAndSettle();
    expect(store.ids, ['registro-prueba', 'registro-prueba']);
    expect(store.records, hasLength(1));
  });

  testWidgets('Ordena los registros del más reciente al más antiguo', (
    tester,
  ) async {
    final store = MemoryRecords();
    for (final year in [2023, 2025, 2024]) {
      store.records.add(
        PatientRecord(
          id: '$year',
          title: 'Registro $year',
          date: DateTime(year),
          category: 'Otro',
          description: 'Ejemplo ficticio',
          authorUid: store.uid,
        ),
      );
    }
    await start(tester, store);
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title! as Text).data)
        .toList();
    expect(titles, ['Registro 2025', 'Registro 2024', 'Registro 2023']);
  });

  testWidgets('No confunde un error de lectura con historial vacío', (
    tester,
  ) async {
    final store = MemoryRecords()..failRead = true;
    await start(tester, store);
    expect(find.textContaining('Aún no tienes registros'), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);
    store.failRead = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aún no tienes registros'), findsOneWidget);
  });
}
