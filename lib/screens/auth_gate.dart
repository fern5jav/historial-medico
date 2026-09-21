import 'patient_history_screen.dart';
import 'patient_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'welcome_screen.dart';

String authError(FirebaseAuthException error) => switch (error.code) {
  'invalid-email' => 'Escribe un correo válido.',
  'email-already-in-use' =>
    'No se pudo registrar este correo. Intenta iniciar sesión o recuperar tu contraseña.',
  'weak-password' => 'La contraseña no cumple los requisitos de seguridad.',
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' => 'Correo o contraseña incorrectos.',
  'user-disabled' => 'Esta cuenta está deshabilitada.',
  'network-request-failed' =>
    'Revisa tu conexión a Internet e inténtalo de nuevo.',
  'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
  'operation-not-allowed' =>
    'El acceso con correo y contraseña no está habilitado.',
  _ => 'No pudimos completar la solicitud. Inténtalo de nuevo.',
};

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> changes = FirebaseAuth.instance.userChanges();
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: changes,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Scaffold(
          body: Center(
            child: Text(
              'No pudimos recuperar la sesión. Cierra y abre la aplicación.',
            ),
          ),
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      return user == null
          ? const WelcomeScreen()
          : AccountScreen(key: ValueKey(user.uid), user: user);
    },
  );
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.user});
  final User user;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool busy = false;
  String? message;
  Future<void> perform(Future<void> Function() action, String success) async {
    if (busy) {
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
      if (mounted) {
        setState(() => message = success);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => message = authError(e));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'No pudimos completar la solicitud. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user.displayName?.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.account_circle_outlined, size: 64),
                  const SizedBox(height: 20),
                  Text(
                    name == null || name.isEmpty ? 'Bienvenido' : 'Hola, $name',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(widget.user.email ?? ''),
                  const SizedBox(height: 12),
                  Text(
                    widget.user.emailVerified
                        ? 'Correo verificado'
                        : 'Correo pendiente de verificación',
                  ),
                  if (!widget.user.emailVerified) ...[
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => perform(
                              () => widget.user.sendEmailVerification(),
                              'Enlace enviado. Revisa tu correo y la carpeta de spam.',
                            ),
                      child: const Text('Enviar correo de verificación'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => perform(
                              () => widget.user.reload(),
                              'Estado del correo actualizado.',
                            ),
                      child: const Text('Ya verifiqué mi correo'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Ya puedes guardar tu perfil y tus registros de salud. Los archivos adjuntos y los permisos para profesionales se integrarán después. La demostración contiene datos ficticios de Alex.',
                      ),
                    ),
                  ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(message!, semanticsLabel: message),
                    ),
                  if (busy) const LinearProgressIndicator(),
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            final saved = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PatientProfileScreen(user: widget.user),
                                  ),
                                );
                            if (!context.mounted) {
                              return;
                            }
                            if (saved == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Perfil guardado correctamente.',
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Mi perfil de paciente'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PatientHistoryScreen(uid: widget.user.uid),
                            ),
                          ),
                    icon: const Icon(Icons.history),
                    label: const Text('Mi historial médico'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: busy ? null : () => openDemo(context),
                    child: const Text('Explorar demostración'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => perform(
                            () => FirebaseAuth.instance.signOut(),
                            '',
                          ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
