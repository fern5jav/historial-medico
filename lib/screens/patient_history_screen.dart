import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/patient_record.dart';

String recordDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String recordError(Object error) {
  if (error is TimeoutException) {
    return 'La consulta tardó demasiado. Revisa Internet y vuelve a intentarlo.';
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'No se autorizó la operación. Comprueba las reglas de Firestore y tu sesión.';
  }
  if (error is FirebaseException && error.code == 'unauthenticated') {
    return 'Tu sesión terminó. Vuelve a iniciar sesión.';
  }
  return 'No pudimos confirmar la operación. Revisa tu conexión e inténtalo de nuevo.';
}

// The nested navigator is disposed in full when the authenticated user changes.
class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({super.key, required this.uid});
  final String uid;
  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  final navigation = GlobalKey<NavigatorState>();
  late final store = FirestoreRecordStore(widget.uid);
  late final changes = FirebaseAuth.instance.authStateChanges();
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: changes,
    initialData: FirebaseAuth.instance.currentUser,
    builder: (context, snapshot) {
      if (snapshot.hasError || snapshot.data?.uid != widget.uid) {
        return Scaffold(
          appBar: AppBar(title: const Text('Mi historial')),
          body: const Center(
            child: Text('La sesión cambió. Vuelve a iniciar sesión.'),
          ),
        );
      }
      return NavigatorPopHandler<Object?>(
        onPopWithResult: (_) => navigation.currentState!.maybePop(),
        child: Navigator(
          key: navigation,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => HistoryPage(
              store: store,
              onExit: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );
    },
  );
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.store, this.onExit});
  final RecordStore store;
  final VoidCallback? onExit;
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<PatientRecord> records = [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.store.load();
      result.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) {
        setState(() => records = result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = recordError(e));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> add() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RecordForm(store: widget.store)),
    );
    if (!mounted) {
      return;
    }
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro guardado correctamente.')),
      );
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mi historial'),
      leading: widget.onExit == null
          ? null
          : IconButton(
              onPressed: widget.onExit,
              tooltip: 'Volver a mi cuenta',
              icon: const Icon(Icons.arrow_back),
            ),
      actions: [
        IconButton(
          onPressed: loading ? null : load,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: add,
      icon: const Icon(Icons.add),
      label: const Text('Agregar registro'),
    ),
    body: SafeArea(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: load,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                const Text(
                  'Registros declarados por ti',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ordenados del más reciente al más antiguo. Durante las pruebas utiliza datos ficticios.',
                ),
                const SizedBox(height: 24),
                if (records.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aún no tienes registros. Agrega el primero con el botón inferior.',
                      ),
                    ),
                  ),
                ...records.map(
                  (record) => Card(
                    child: ListTile(
                      title: Text(record.title),
                      subtitle: Text(
                        '${recordDate(record.date)} · ${record.category}\nDeclarado por el paciente',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RecordDetail(record: record),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}

class RecordDetail extends StatelessWidget {
  const RecordDetail({super.key, required this.record});
  final PatientRecord record;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle del registro')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(record.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text('${recordDate(record.date)} · ${record.category}'),
          const SizedBox(height: 16),
          const Text('Declarado por el paciente · Sin validación profesional'),
          const SizedBox(height: 24),
          SelectableText(
            record.description,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
          const Divider(height: 40),
          SelectableText('Autor (ID de cuenta): ${record.authorUid}'),
          if (record.createdAt != null)
            Text('Capturado el ${recordDate(record.createdAt!)}'),
        ],
      ),
    ),
  );
}

class RecordForm extends StatefulWidget {
  const RecordForm({super.key, required this.store});
  final RecordStore store;
  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  late final String id = widget.store.newId();
  String category = recordCategories.first;
  DateTime date = DateUtils.dateOnly(DateTime.now());
  bool saving = false;
  bool dirty = false;
  String? error;
  PatientRecord? attempt;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(1900),
      lastDate: DateUtils.dateOnly(DateTime.now()),
      helpText: 'Fecha del registro',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (chosen != null && mounted) {
      setState(() {
        date = chosen;
        dirty = true;
      });
    }
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    // After an ambiguous network failure, retry precisely the same payload and ID.
    attempt ??= PatientRecord(
      id: id,
      title: title.text,
      date: date,
      category: category,
      description: description.text,
      authorUid: widget.store.uid,
    );
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.store.create(attempt!);
      if (!mounted) {
        return;
      }
      setState(() {
        saving = false;
        dirty = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => error =
              '${recordError(e)} Puedes reintentar el mismo registro sin duplicarlo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir del formulario?'),
        content: Text(
          attempt == null
              ? 'Los cambios sin guardar se perderán.'
              : 'No se confirmó el último intento. Revisa el historial antes de crear el registro otra vez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar aquí'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving && !dirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !saving) {
        leave();
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Agregar registro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Declarado por el paciente',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Captura información ficticia para las pruebas. Este registro no se presenta como una receta ni como una valoración profesional.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('recordTitle'),
                  controller: title,
                  enabled: attempt == null,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => dirty = true),
                  validator: (v) =>
                      (v?.trim().length ?? 0) < 2 || v!.trim().length > 120
                      ? 'Escribe entre 2 y 120 caracteres.'
                      : null,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: attempt == null ? chooseDate : null,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Fecha: ${recordDate(date)}'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: recordCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: attempt == null
                      ? (v) => setState(() {
                          category = v!;
                          dirty = true;
                        })
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('recordDescription'),
                  controller: description,
                  enabled: attempt == null,
                  maxLength: 4000,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => dirty = true),
                  validator: (v) =>
                      (v?.trim().length ?? 0) < 5 || v!.trim().length > 4000
                      ? 'Escribe entre 5 y 4000 caracteres.'
                      : null,
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(error!),
                  ),
                if (saving) const LinearProgressIndicator(),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(
                    attempt == null
                        ? 'Guardar registro'
                        : saving
                        ? 'Confirmando guardado…'
                        : 'Reintentar guardado',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
