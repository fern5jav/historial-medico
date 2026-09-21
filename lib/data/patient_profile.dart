import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientProfile {
  const PatientProfile({
    required this.name,
    this.birthDate = '',
    this.allergies = '',
    this.history = '',
    this.version,
  });
  final String name;
  final String birthDate;
  final String allergies;
  final String history;
  final Timestamp? version;

  Map<String, dynamic> toFirestore() => {
    'nombre': name.trim(),
    'fechaNacimiento': birthDate.trim(),
    'alergias': allergies.trim(),
    'antecedentes': history.trim(),
    'actualizadoEn': FieldValue.serverTimestamp(),
  };

  factory PatientProfile.fromFirestore(Map<String, dynamic> data) =>
      PatientProfile(
        name: data['nombre'] as String,
        birthDate: data['fechaNacimiento'] as String,
        allergies: data['alergias'] as String,
        history: data['antecedentes'] as String,
        version: data['actualizadoEn'] as Timestamp?,
      );
}

String? validateBirthDate(String? value, {DateTime? today}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
    return 'Usa el formato AAAA-MM-DD.';
  }
  final date = DateTime.tryParse(text);
  if (date == null || date.toIso8601String().substring(0, 10) != text) {
    return 'Escribe una fecha que exista.';
  }
  final now = today ?? DateTime.now();
  if (date.isAfter(DateTime(now.year, now.month, now.day))) {
    return 'La fecha no puede estar en el futuro.';
  }
  if (date.year < 1900) {
    return 'Escribe un año desde 1900.';
  }
  return null;
}

abstract class ProfileStore {
  Future<PatientProfile?> load();
  Future<void> save(PatientProfile profile, PatientProfile? original);
}

class ProfileConflict implements Exception {}

class FirestoreProfileStore implements ProfileStore {
  FirestoreProfileStore(this.uid);
  final String uid;
  DocumentReference<Map<String, dynamic>> get reference =>
      FirebaseFirestore.instance.collection('pacientes').doc(uid);

  void checkSession() {
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
      );
    }
  }

  @override
  Future<PatientProfile?> load() async {
    checkSession();
    final result = await reference
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 20));
    checkSession();
    final data = result.data();
    return data == null ? null : PatientProfile.fromFirestore(data);
  }

  @override
  Future<void> save(PatientProfile profile, PatientProfile? original) async {
    checkSession();
    await FirebaseFirestore.instance.runTransaction<void>((transaction) async {
      checkSession();
      final current = await transaction.get(reference);
      if (current.exists != (original != null) ||
          (current.exists &&
              current.data()?['actualizadoEn'] != original?.version)) {
        throw ProfileConflict();
      }
      transaction.set(reference, profile.toFirestore());
    });
  }
}
