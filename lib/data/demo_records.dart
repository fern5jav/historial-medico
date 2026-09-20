// Información enteramente ficticia, sin conexión a servicios de salud.
class MedicalRecord {
  const MedicalRecord(
    this.title,
    this.category,
    this.date,
    this.author,
    this.source,
    this.detail,
  );
  final String title;
  final String category;
  final String date;
  final String author;
  final String source;
  final String detail;
}

const demoRecords = [
  MedicalRecord(
    'Consulta de seguimiento',
    'Consultas',
    '18 sep 2026',
    'Dra. Elena Torres · Medicina general',
    'Profesional',
    'Registro ficticio de una consulta de seguimiento. Se revisaron los antecedentes aportados por el paciente. Este ejemplo no contiene indicaciones clínicas.',
  ),
  MedicalRecord(
    'Resultados de laboratorio',
    'Estudios',
    '12 sep 2026',
    'Laboratorio Central · Ejemplo',
    'Establecimiento',
    'Documento de muestra para organizar resultados de laboratorio. No hay un archivo adjunto ni resultados clínicos reales.',
  ),
  MedicalRecord(
    'Receta de consulta',
    'Recetas',
    '05 sep 2026',
    'Alex Rivera · Paciente de ejemplo',
    'Paciente',
    'Ejemplo de una receta incorporada por el paciente. Su contenido no ha sido validado por un profesional. No hay un archivo adjunto.',
  ),
];
