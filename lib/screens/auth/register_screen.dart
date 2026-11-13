import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _message = null; });
    try {
      final result = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {'nickname': _nickname.text.trim()},
      );
      if (!mounted) return;
      if (result.session == null) {
        setState(() => _message = 'Conta criada. Confirme seu e-mail e depois entre.');
      } else {
        context.go('/faction');
      }
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (_) {
      setState(() => _message = 'Falha de conexão. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() { _nickname.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('NOVO SOBREVIVENTE')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(22), children: [
      const Text('Crie sua identidade no novo mundo.', style: TextStyle(color: Color(0xFFA6ADA7))),
      const SizedBox(height: 24),
      Form(key: _form, child: Column(children: [
        TextFormField(controller: _nickname, maxLength: 18, decoration: const InputDecoration(labelText: 'Apelido'), validator: (v) => v == null || v.trim().length < 3 ? 'Use pelo menos 3 caracteres.' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail'), validator: (v) => v == null || !v.contains('@') ? 'E-mail inválido.' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha (mínimo 6 caracteres)'), validator: (v) => v == null || v.length < 6 ? 'Senha muito curta.' : null),
        if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!, style: const TextStyle(color: Color(0xFFD6C9A5)))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _register, child: Text(_busy ? 'CRIANDO...' : 'CRIAR CONTA'))),
      ])),
      TextButton(onPressed: () => context.go('/login'), child: const Text('Voltar ao login')),
    ])),
  );
}
