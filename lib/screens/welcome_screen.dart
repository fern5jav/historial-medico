import 'package:flutter/material.dart';
import 'home_shell.dart';

void openDemo(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (context) => HomeShell(
      onExit: () => Navigator.of(context).popUntil((route) => route.isFirst),
    )),
    (route) => route.isFirst,
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Align(alignment: Alignment.centerLeft,
            child: CircleAvatar(radius: 34, child: Icon(Icons.health_and_safety_outlined, size: 38))),
          const SizedBox(height: 32),
          Text('Tu salud tiene\nuna historia.', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          const Text('Organiza tus antecedentes, encuentra tus documentos y decide con quién compartir tu información.', style: TextStyle(fontSize: 17, height: 1.6)),
          const SizedBox(height: 28),
          const Card(child: Padding(padding: EdgeInsets.all(18), child: Text(
            'Prototipo con datos ficticios. Las cuentas y el inicio de sesión todavía no están conectados. No introduzcas contraseñas ni datos personales reales.',
            style: TextStyle(height: 1.5)))),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
            builder: (_) => const AccountFormScreen(register: true))),
            child: const Text('Crear cuenta')),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
            builder: (_) => const AccountFormScreen(register: false))),
            child: const Text('Iniciar sesión')),
          const SizedBox(height: 10),
          TextButton(onPressed: () => openDemo(context), child: const Text('Explorar demostración')),
        ]),
      ),
    ))),
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
  bool obscure = true;

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> validate() async {
    if (!formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final explore = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Formulario válido'),
      content: Text(widget.register
        ? 'La validación local pasó. No se creó ninguna cuenta ni se guardaron tus datos. Puedes explorar el perfil ficticio de Alex.'
        : 'La validación local pasó. No se verificaron las credenciales ni se inició una sesión real. Puedes explorar el perfil ficticio de Alex.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ver demostración')),
      ],
    ));
    if (explore == true && mounted) openDemo(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.register ? 'Crear cuenta' : 'Iniciar sesión')),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460),
        child: Form(key: formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.register ? 'Comienza tu historia' : 'Bienvenido de nuevo',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Formulario de prueba. Usa datos ficticios; no se envían ni se guardan.', style: TextStyle(height: 1.5)),
            const SizedBox(height: 24),
            if (widget.register) ...[
              TextFormField(key: const Key('name'), textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre de ejemplo', border: OutlineInputBorder()),
                validator: (value) => (value?.trim().length ?? 0) < 2 ? 'Escribe al menos 2 caracteres.' : null),
              const SizedBox(height: 16),
            ],
            TextFormField(key: const Key('email'), keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Correo electrónico', hintText: 'alex@example.com', border: OutlineInputBorder()),
              validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
                ? null : 'Escribe un correo válido.'),
            const SizedBox(height: 16),
            TextFormField(key: const Key('password'), controller: password,
              obscureText: obscure, enableSuggestions: false, autocorrect: false,
              decoration: InputDecoration(labelText: 'Contraseña de prueba', border: const OutlineInputBorder(),
                suffixIcon: IconButton(tooltip: obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Escribe una contraseña de prueba.';
                if (widget.register && value.length < 8) return 'Usa al menos 8 caracteres.';
                return null;
              }),
            if (widget.register) ...[
              const SizedBox(height: 16),
              TextFormField(key: const Key('confirmPassword'), obscureText: obscure,
                enableSuggestions: false, autocorrect: false,
                decoration: const InputDecoration(labelText: 'Confirmar contraseña', border: OutlineInputBorder()),
                validator: (value) => value == password.text && (value?.isNotEmpty ?? false)
                  ? null : 'Las contraseñas no coinciden.'),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: validate, child: const Text('Validar formulario de prueba')),
          ],
        )),
      ),
    ))),
  );
}
