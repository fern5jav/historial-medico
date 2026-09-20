import 'package:flutter/material.dart';
import '../data/demo_records.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int section = 0;
  String filter = 'Todos';
  String query = '';
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool accessActive = true;
  static const labels = [
    'Inicio',
    'Historial',
    'Documentos',
    'Accesos',
    'Perfil',
  ];
  static const icons = [
    Icons.home_outlined,
    Icons.history,
    Icons.folder_outlined,
    Icons.shield_outlined,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        section == 0 ? 'Mi historial' : labels[section],
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 20),
          child: CircleAvatar(child: Text('AR')),
        ),
      ],
    ),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            key: ValueKey(section),
            padding: const EdgeInsets.all(20),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'DEMOSTRACIÓN · DATOS FICTICIOS',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.3,
                    color: Color(0xFF526775),
                  ),
                ),
              ),
              ...switch (section) {
                0 => home(),
                1 => history(),
                2 => documents(),
                3 => access(),
                _ => profile(),
              },
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: section,
      onDestinationSelected: (value) => setState(() => section = value),
      destinations: List.generate(
        labels.length,
        (i) => NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
      ),
    ),
  );

  Widget heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF183645),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF526775), height: 1.5),
        ),
      ],
    ),
  );

  Widget panel(Widget child) => Card(
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );

  List<Widget> home() => [
    heading(
      'Hola, Alex',
      'Tu información de salud, organizada en un solo lugar.',
    ),
    Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF075B68), Color(0xFF128E96)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.health_and_safety_outlined,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(height: 18),
          const Text(
            'Tu historia merece\nestar contigo.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Consulta tus antecedentes y encuentra tus registros cuando los necesites.',
            style: TextStyle(color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: () => setState(() => section = 1),
            child: const Text('Explorar mi historial'),
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ActionChip(
          avatar: const Icon(Icons.folder_outlined),
          label: const Text('2 documentos'),
          onPressed: () => setState(() => section = 2),
        ),
        ActionChip(
          avatar: const Icon(Icons.shield_outlined),
          label: Text('${accessActive ? 1 : 0} acceso activo'),
          onPressed: () => setState(() => section = 3),
        ),
      ],
    ),
    const SizedBox(height: 26),
    heading('Actividad reciente', 'Cada registro conserva su procedencia.'),
    recordTile(demoRecords.first),
    panel(
      const Text(
        'Tú decides con quién compartir tu información. En esta demostración, los permisos son simulados y no dan acceso a datos reales.',
      ),
    ),
  ];

  List<Widget> history() {
    final records = demoRecords.where(
      (r) =>
          (filter == 'Todos' || r.category == filter) &&
          '${r.title} ${r.author}'.toLowerCase().contains(query.toLowerCase()),
    );
    return [
      heading(
        'Tu historia de salud',
        'Consultas, estudios y recetas, del más reciente al más antiguo.',
      ),
      TextField(
        onChanged: (value) => setState(() => query = value),
        controller: searchController,
        decoration: const InputDecoration(
          labelText: 'Buscar registros',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        children: ['Todos', 'Consultas', 'Estudios', 'Recetas']
            .map(
              (item) => ChoiceChip(
                label: Text(item),
                selected: filter == item,
                onSelected: (_) => setState(() => filter = item),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 20),
      if (records.isEmpty)
        panel(const Text('No encontramos registros con esos filtros.')),
      ...records.map(recordTile),
    ];
  }

  Widget recordTile(MedicalRecord record) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE1F3F3),
        child: Icon(
          record.category == 'Consultas'
              ? Icons.medical_services_outlined
              : Icons.description_outlined,
          color: const Color(0xFF087F8C),
        ),
      ),
      title: Text(
        record.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '${record.date}\n${record.source} · ${record.author}',
          style: const TextStyle(height: 1.5),
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(record.title),
          content: SingleChildScrollView(
            child: Text(
              '${record.date}\nAutor: ${record.author}\nOrigen: ${record.source}\n\n${record.detail}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    ),
  );

  List<Widget> documents() => [
    heading(
      'Tus documentos',
      'Ejemplos de estudios y recetas organizados por fecha.',
    ),
    panel(
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vista de demostración. Los documentos muestran sus datos de ejemplo; la carga y apertura de archivos se integrarán después.',
            ),
          ),
        ],
      ),
    ),
    ...demoRecords.skip(1).map(recordTile),
  ];

  List<Widget> access() => [
    heading(
      'Tú tienes el control',
      'Revisa quién puede consultar tu información.',
    ),
    panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dra. Elena Torres',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const Text('Medicina general · Profesional ficticio'),
          const SizedBox(height: 16),
          Chip(
            label: Text(
              accessActive
                  ? 'Acceso activo · Simulado'
                  : 'Acceso revocado · Simulado',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Alcance: consultas y estudios de ejemplo.\nDuración de ejemplo: 7 días.',
            style: TextStyle(height: 1.6),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: accessActive ? revokeAccess : null,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Revocar acceso de ejemplo'),
          ),
          if (!accessActive)
            TextButton(
              onPressed: () => setState(() => accessActive = true),
              child: const Text('Restablecer demostración'),
            ),
        ],
      ),
    ),
    const Text(
      'Esta acción solo cambia la demostración en esta sesión. Los permisos reales necesitarán autenticación y validación en el servidor.',
    ),
  ];

  Future<void> revokeAccess() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Revocar acceso de ejemplo?'),
        content: const Text(
          'La tarjeta quedará como revocada. No se modifican permisos reales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) setState(() => accessActive = false);
  }

  List<Widget> profile() => [
    heading('Mi perfil', 'Información de un paciente ficticio.'),
    panel(
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            child: Text('AR', style: TextStyle(fontSize: 22)),
          ),
          SizedBox(height: 16),
          Text(
            'Alex Rivera',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          Text('Paciente de demostración · Identidad sin verificar'),
          Divider(height: 32),
          Text('Alergias', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Penicilina · Dato ficticio declarado por el paciente'),
          SizedBox(height: 18),
          Text('Antecedentes', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Sin antecedentes capturados en esta demostración.'),
          SizedBox(height: 18),
          Text(
            'Tratamientos actuales',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Sin tratamientos capturados en esta demostración.'),
        ],
      ),
    ),
    panel(
      const Text(
        'Versión inicial de la interfaz. El registro, la edición del perfil y el guardado de información estarán disponibles en una siguiente etapa.',
      ),
    ),
  ];
}
