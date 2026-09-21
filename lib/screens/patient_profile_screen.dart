import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/patient_profile.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key, required this.user});
  final User user;
  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  late final Stream<User?> changes = FirebaseAuth.instance.authStateChanges();
  late final store = FirestoreProfileStore(widget.user.uid);
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: changes,
    initialData: FirebaseAuth.instance.currentUser,
    builder: (context, snapshot) {
      if (snapshot.hasError || snapshot.data?.uid != widget.user.uid) {
        return Scaffold(
          appBar: AppBar(title: const Text('Mi perfil')),
          body: const Center(
            child: Text('La sesión cambió. Vuelve a iniciar sesión.'),
          ),
        );
      }
      return ProfileEditor(
        store: store,
        initialName: widget.user.displayName ?? '',
      );
    },
  );
}

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({super.key, required this.store, this.initialName = ''});
  final ProfileStore store;
  final String initialName;
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final birthDate = TextEditingController();
  final allergies = TextEditingController();
  final history = TextEditingController();
  PatientProfile? original;
  bool loading = true;
  bool saving = false;
  bool loaded = false;
  bool dirty = false;
  String? message;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    name.dispose();
    birthDate.dispose();
    allergies.dispose();
    history.dispose();
    super.dispose();
  }

  String describeError(Object error) {
    if (error is ProfileConflict) {
      return 'El perfil cambió en otra sesión. Vuelve a abrirlo para cargar la versión reciente antes de editar.';
    }
    if (error is TimeoutException) {
      return 'La consulta tardó demasiado. Revisa Internet y vuelve a intentarlo.';
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          'No se autorizó la operación. Revisa las reglas publicadas y la cuenta con la que ingresaste.',
        'unauthenticated' => 'Tu sesión terminó. Vuelve a iniciar sesión.',
        'unavailable' || 'deadline-exceeded' =>
          'No se pudo confirmar la operación. Revisa Internet y vuelve a abrir el perfil.',
        _ => 'No pudimos completar la operación. Inténtalo de nuevo.',
      };
    }
    return 'No pudimos completar la operación. Inténtalo de nuevo.';
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final profile = await widget.store.load();
      if (!mounted) {
        return;
      }
      original = profile;
      name.text = profile?.name ?? widget.initialName;
      birthDate.text = profile?.birthDate ?? '';
      allergies.text = profile?.allergies ?? '';
      history.text = profile?.history ?? '';
      setState(() {
        loaded = true;
        dirty = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          loaded = false;
          message = describeError(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> save() async {
    if (saving || !loaded || !form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      saving = true;
      message = null;
    });
    final value = PatientProfile(
      name: name.text,
      birthDate: birthDate.text,
      allergies: allergies.text,
      history: history.text,
    );
    try {
      await widget.store.save(value, original);
      if (!mounted) {
        return;
      }
      setState(() {
        saving = false;
        dirty = false;
      });
      // Wait for PopScope to receive the new state before closing the route.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => message = describeError(error));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> leave() async {
    if (saving) {
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text('Los cambios del formulario se perderán.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir sin guardar'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  Widget field(
    String label,
    String keyName,
    TextEditingController controller,
    int max, {
    int lines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: Key(keyName),
      controller: controller,
      enabled: !saving,
      maxLength: max,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (value) => (value?.trim().length ?? 0) > max
              ? 'Máximo $max caracteres.'
              : null,
      onChanged: (_) => setState(() {
        dirty = true;
        message = null;
      }),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !saving,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !saving) {
        leave();
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Mi perfil de paciente')),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (loaded) ...[
                            Text(
                              original == null
                                  ? 'Completa tu perfil'
                                  : 'Edita tu perfil',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Durante las pruebas, utiliza datos ficticios. Esta información es declarada por el paciente; no ha sido validada por un profesional.',
                            ),
                            const SizedBox(height: 24),
                            field(
                              'Nombre',
                              'profileName',
                              name,
                              100,
                              validator: (value) {
                                final length = value?.trim().length ?? 0;
                                return length < 2 || length > 100
                                    ? 'Escribe entre 2 y 100 caracteres.'
                                    : null;
                              },
                            ),
                            field(
                              'Fecha de nacimiento (AAAA-MM-DD, opcional)',
                              'profileBirthDate',
                              birthDate,
                              10,
                              validator: (value) => validateBirthDate(value),
                            ),
                            field(
                              'Alergias (opcional)',
                              'profileAllergies',
                              allergies,
                              2000,
                              lines: 3,
                            ),
                            field(
                              'Antecedentes (opcional)',
                              'profileHistory',
                              history,
                              4000,
                              lines: 4,
                            ),
                            const Text(
                              'Un campo vacío significa que no se ha capturado información; no significa que no existan alergias o antecedentes.',
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (message != null)
                            Semantics(
                              liveRegion: true,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(message!),
                              ),
                            ),
                          if (saving)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text('Esperando confirmación del guardado…'),
                                ],
                              ),
                            ),
                          if (loaded)
                            FilledButton.icon(
                              onPressed: saving ? null : save,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Guardar perfil'),
                            ),
                          if (!loaded)
                            FilledButton(
                              onPressed: load,
                              child: const Text('Reintentar'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    ),
  );
}
