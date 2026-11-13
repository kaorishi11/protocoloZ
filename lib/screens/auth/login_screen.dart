import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(), password: _password.text,
      );
      if (!mounted) return;
      final profile = await Supabase.instance.client.from('profiles')
          .select('faction_id').single();
      if (!mounted) return;
      context.go(profile['faction_id'] == null ? '/faction' : '/home');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível conectar. Verifique sua internet e tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.shield_moon_outlined, size: 58, color: Color(0xFF78945E)),
        const SizedBox(height: 12),
        Text('PROTOCOLO Z', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 3)),
        const SizedBox(height: 8),
        const Text('A sobrevivência começa com você.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFA6ADA7))),
        const SizedBox(height: 34),
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)), validator: (v) => v == null || !v.contains('@') ? 'Informe um e-mail válido.' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)), validator: (v) => v == null || v.length < 6 ? 'A senha deve ter ao menos 6 caracteres.' : null),
        if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.redAccent))],
        const SizedBox(height: 22),
        FilledButton(onPressed: _busy ? null : _login, child: Padding(padding: const EdgeInsets.all(13), child: Text(_busy ? 'ENTRANDO...' : 'ENTRAR'))),
        TextButton(onPressed: () => context.go('/register'), child: const Text('Ainda não tem conta? Criar sobrevivente')),
      ])),
    )))),
  );
}
