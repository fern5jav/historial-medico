import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const recordCategories = [
  'Consulta',
  'Estudio',
  'Receta',
  'Tratamiento',
  'Otro',
];

class PatientRecord {
  const PatientRecord({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    required this.description,
    required this.authorUid,
    this.createdAt,
  });
  final String id;
  final String title;
  final DateTime date;
  final String category;
  final String description;
  final String authorUid;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() => {
    'titulo': title.trim(),
    'fecha': Timestamp.fromDate(DateTime.utc(date.year, date.month, date.day)),
    'categoria': category,
    'descripcion': description.trim(),
    'autorUid': authorUid,
    'origen': 'paciente',
    'creadoEn': FieldValue.serverTimestamp(),
  };

  factory PatientRecord.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return PatientRecord(
      id: doc.id,
      title: d['titulo'] as String,
      date: (d['fecha'] as Timestamp).toDate().toUtc(),
      category: d['categoria'] as String,
      description: d['descripcion'] as String,
      authorUid: d['autorUid'] as String,
      createdAt: (d['creadoEn'] as Timestamp?)?.toDate(),
    );
  }
}

abstract class RecordStore {
  String get uid;
  String newId();
  Future<List<PatientRecord>> load();
  Future<void> create(PatientRecord record);
}

class FirestoreRecordStore implements RecordStore {
  FirestoreRecordStore(this.uid);
  @override
  final String uid;
  CollectionReference<Map<String, dynamic>> get collection => FirebaseFirestore
      .instance
      .collection('pacientes')
      .doc(uid)
      .collection('registros');

  void checkSession() {
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
      );
    }
  }

  @override
  String newId() => collection.doc().id;

  @override
  Future<List<PatientRecord>> load() async {
    checkSession();
    final result = await collection
        .orderBy('fecha', descending: true)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 20));
    checkSession();
    return result.docs.map(PatientRecord.fromDocument).toList();
  }

  @override
  Future<void> create(PatientRecord record) async {
    checkSession();
    final reference = collection.doc(record.id);
    // A stable ID makes retries safe if the previous confirmation was lost.
    await FirebaseFirestore.instance.runTransaction<void>((transaction) async {
      checkSession();
      final existing = await transaction.get(reference);
      if (existing.exists) {
        final data = existing.data()!;
        final expected = record.toFirestore()..remove('creadoEn');
        if (!expected.entries.every(
          (entry) => data[entry.key] == entry.value,
        )) {
          throw StateError('Record ID already used');
        }
        return;
      }
      transaction.set(reference, record.toFirestore());
    });
  }
}
