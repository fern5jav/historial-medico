import 'package:firebase_auth/firebase_auth.dart';
import 'auth_gate.dart';
import 'package:flutter/material.dart';
import 'home_shell.dart';

void openDemo(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (context) => HomeShell(
        onExit: () => Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    ),
    (route) => route.isFirst,
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: CircleAvatar(
                    radius: 34,
                    child: Icon(Icons.health_and_safety_outlined, size: 38),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Tu salud tiene\nuna historia.',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Organiza tus antecedentes, encuentra tus documentos y decide con quién compartir tu información.',
                  style: TextStyle(fontSize: 17, height: 1.6),
                ),
                const SizedBox(height: 28),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Crea tu cuenta o inicia sesión. También puedes explorar un historial de demostración con datos ficticios.',
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountFormScreen(register: true),
                    ),
                  ),
                  child: const Text('Crear cuenta'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountFormScreen(register: false),
                    ),
                  ),
                  child: const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => openDemo(context),
                  child: const Text('Explorar demostración'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({super.key, required this.register});
  final bool register;
  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final formKey = GlobalKey<FormState>();
  final password = TextEditingController();
  final email = TextEditingController();
  final name = TextEditingController();
  bool busy = false;
  bool accountCreated = false;
  String? error;
  bool obscure = true;

  @override
  void dispose() {
    password.dispose();
    email.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> validate() async {
    if (busy || !formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (widget.register) {
        final result = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: email.text.trim(),
              password: password.text,
            );
        accountCreated = true;
        await result.user!.updateDisplayName(name.text.trim());
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      if (mounted) {
        setState(() => busy = false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => error = accountCreated
              ? 'La cuenta se creó, pero no pudimos guardar tu nombre. Continúa a tu cuenta.'
              : authError(e),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = accountCreated
              ? 'La cuenta se creó, pero no pudimos guardar tu nombre. Continúa a tu cuenta.'
              : 'No pudimos completar la solicitud. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    if (busy) return;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim())) {
      setState(() => error = 'Escribe primero tu correo electrónico.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim(),
      );
      if (mounted) {
        setState(
          () => error =
              'Si el correo tiene una cuenta, recibirás un enlace para restablecer la contraseña. Revisa también spam.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => error = e.code == 'user-not-found'
              ? 'Si el correo tiene una cuenta, recibirás un enlace para restablecer la contraseña. Revisa también spam.'
              : authError(e),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'No pudimos enviar la solicitud. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.register ? 'Crear cuenta' : 'Iniciar sesión'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.register
                          ? 'Comienza tu historia'
                          : 'Bienvenido de nuevo',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Usa un correo al que tengas acceso. Tu cuenta se gestiona con Firebase Authentication.',
                      style: TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    if (widget.register) ...[
                      TextFormField(
                        key: const Key('name'),
                        controller: name,
                        enabled: !busy,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value?.trim().length ?? 0) < 2
                            ? 'Escribe al menos 2 caracteres.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      key: const Key('email'),
                      controller: email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'alex@example.com',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Escribe un correo válido.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('password'),
                      enabled: !busy,
                      controller: password,
                      obscureText: obscure,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: obscure
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(
                            obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Escribe una contraseña.';
                        }
                        if (widget.register && value.length < 8) {
                          return 'Usa al menos 8 caracteres.';
                        }
                        return null;
                      },
                    ),
                    if (widget.register) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('confirmPassword'),
                        enabled: !busy,
                        obscureText: obscure,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == password.text &&
                                (value?.isNotEmpty ?? false)
                            ? null
                            : 'Las contraseñas no coinciden.',
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(error!, key: const Key('authMessage')),
                      ),
                    if (busy) const LinearProgressIndicator(),
                    FilledButton(
                      onPressed: busy || accountCreated ? null : validate,
                      child: Text(
                        widget.register ? 'Crear cuenta' : 'Iniciar sesión',
                      ),
                    ),
                    if (!widget.register)
                      TextButton(
                        onPressed: busy ? null : resetPassword,
                        child: const Text('Olvidé mi contraseña'),
                      ),
                    if (accountCreated)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => Navigator.of(
                                context,
                              ).popUntil((r) => r.isFirst),
                        child: const Text('Continuar a mi cuenta'),
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
