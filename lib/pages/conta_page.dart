import 'package:material_ui/material_ui.dart';

import '../api_service.dart';

class ContaPage extends StatefulWidget {
  const ContaPage({super.key});
  @override
  State<ContaPage> createState() => _ContaPageState();
}

class _ContaPageState extends State<ContaPage> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController(),
      _telefone = TextEditingController(),
      _email = TextEditingController(),
      _senha = TextEditingController(),
      _confirmacao = TextEditingController();
  bool _cadastro = false, _ocupado = false, _recuperacao = false;
  String? _mensagem;
  @override
  void dispose() {
    for (final c in [_nome, _telefone, _email, _senha, _confirmacao]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_ocupado || !_form.currentState!.validate()) return;
    setState(() {
      _ocupado = true;
      _mensagem = null;
    });
    try {
      final api = ApiService();
      if (_recuperacao) {
        await api.recuperar(_email.text);
        if (mounted) {
          setState(
            () => _mensagem = 'Se houver uma conta com esse e-mail, enviaremos as instruções.',
          );
        }
      } else {
        if (_cadastro) {
          await api.cadastrar(
            _nome.text,
            _telefone.text,
            _email.text,
            _senha.text,
          );
        }
        await api.entrar(_email.text, _senha.text);
        if (mounted) {
          _senha.clear();
          _confirmacao.clear();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _mensagem = ApiService.mensagem(e));
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ApiService.sessao.value;
    if (s != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.account_circle, size: 72, color: Color(0xFFF39C12)),
          const SizedBox(height: 16),
          Text(
            'Olá, ${s.nome}',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          Text(s.email, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const Text(
            'Sua conta protege suas reservas. A sessão dura até 30 minutos e termina ao fechar o aplicativo.',
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ApiService.sessao.value = null,
            child: const Text('Sair da conta'),
          ),
        ],
      );
    }
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Image.asset(
            'assets/Barbearia_Logo.png',
            height: 90,
            semanticLabel: 'Barbearia do Zé',
          ),
          const SizedBox(height: 16),
          Text(
            _recuperacao
                ? 'Recuperar senha'
                : _cadastro
                ? 'Criar conta'
                : 'Entrar',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_cadastro && !_recuperacao) ...[
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe seu nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone (DDD + número)',
              ),
              validator: (v) => RegExp(r'^\d{10,11}$').hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Informe 10 ou 11 dígitos',
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'E-mail'),
            validator: (v) =>
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '')
                ? null
                : 'Informe um e-mail válido',
          ),
          if (!_recuperacao) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _senha,
              obscureText: true,
              maxLength: 128,
              decoration: InputDecoration(
                labelText: _cadastro ? 'Senha (mínimo 12 caracteres)' : 'Senha',
              ),
              validator: (v) =>
                  v == null || v.isEmpty || (_cadastro && v.length < 12)
                  ? 'Confira sua senha'
                  : null,
            ),
            if (_cadastro)
              TextFormField(
                controller: _confirmacao,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar senha'),
                validator: (v) =>
                    v == _senha.text ? null : 'As senhas devem ser iguais',
              ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _ocupado ? null : _enviar,
            child: Text(
              _ocupado
                  ? 'Aguarde...'
                  : _recuperacao
                  ? 'Enviar link'
                  : _cadastro
                  ? 'Criar conta e entrar'
                  : 'Entrar',
            ),
          ),
          if (_mensagem != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Semantics(liveRegion: true, child: Text(_mensagem!)),
            ),
          TextButton(
            onPressed: _ocupado
                ? null
                : () => setState(() {
                    _cadastro = !_cadastro;
                    _recuperacao = false;
                    _mensagem = null;
                  }),
            child: Text(_cadastro ? 'Já tenho uma conta' : 'Criar uma conta'),
          ),
          TextButton(
            onPressed: _ocupado
                ? null
                : () => setState(() {
                    _recuperacao = !_recuperacao;
                    _mensagem = null;
                  }),
            child: Text(
              _recuperacao ? 'Voltar ao login' : 'Esqueci minha senha',
            ),
          ),
        ],
      ),
    );
  }
}
