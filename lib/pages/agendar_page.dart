import 'package:material_ui/material_ui.dart';

import '../api_service.dart';
import '../models.dart';

class AgendarPage extends StatefulWidget {
  const AgendarPage({super.key});
  @override
  State<AgendarPage> createState() => _AgendarPageState();
}

class _AgendarPageState extends State<AgendarPage> {
  final _api = ApiService();
  List<Servico> _servicos = [];
  List<Barbeiro> _barbeiros = [];
  List<String> _horarios = [];
  Servico? _servico;
  Barbeiro? _barbeiro;
  DateTime? _data;
  String? _hora, _mensagem;
  bool _enviando = false, _carregando = false;
  int _consulta = 0;
  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final s = await _api.servicos();
      final b = await _api.barbeiros();
      if (mounted) {
        setState(() {
          _servicos = s;
          _barbeiros = b;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _mensagem = ApiService.mensagem(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _atualizarHorarios() async {
    final consulta = ++_consulta;
    setState(() {
      _hora = null;
      _horarios = [];
      _mensagem = null;
    });
    if (_servico == null || _barbeiro == null || _data == null) return;
    try {
      final h = await _api.horarios(_data!, _servico!.id, _barbeiro!.id);
      if (mounted && consulta == _consulta) {
        setState(() {
          _horarios = h;
          if (h.isEmpty) _mensagem = 'Sem horários livres nesta data.';
        });
      }
    } catch (e) {
      if (mounted && consulta == _consulta) {
        setState(() => _mensagem = ApiService.mensagem(e));
      }
    }
  }

  Future<void> _escolherData() async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final d = await showDatePicker(
      context: context,
      initialDate: _data ?? hoje.add(const Duration(days: 1)),
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 90)),
    );
    if (d != null && mounted) {
      setState(() => _data = d);
      await _atualizarHorarios();
    }
  }

  Future<void> _confirmar() async {
    if (_enviando) return;
    if (_servico == null ||
        _barbeiro == null ||
        _data == null ||
        _hora == null) {
      setState(
        () => _mensagem = 'Escolha serviço, profissional, data e horário.',
      );
      return;
    }
    setState(() => _enviando = true);
    try {
      final inicio = '${_data!.toIso8601String().substring(0, 10)}T$_hora:00';
      final ag = await _api.agendar(
        servicoId: _servico!.id,
        barbeiroId: _barbeiro!.id,
        inicioIso: inicio,
      );
      await _atualizarHorarios();
      if (mounted) {
        setState(
          () => _mensagem =
              'Agendamento #${ag.id} confirmado: ${ag.servico} com ${ag.barbeiro}. Consulte a aba Meus horários.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _mensagem = ApiService.mensagem(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'AGENDAR HORÁRIO',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      if (_carregando) const LinearProgressIndicator(),
      DropdownButtonFormField<Servico>(
        isExpanded: true,
        decoration: const InputDecoration(labelText: '1. Serviço'),
        items: _servicos
            .map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(
                  '${s.nome} - R\$ ${s.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                ),
              ),
            )
            .toList(),
        onChanged: _enviando
            ? null
            : (v) {
                setState(() => _servico = v);
                _atualizarHorarios();
              },
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<Barbeiro>(
        isExpanded: true,
        decoration: const InputDecoration(labelText: '2. Profissional'),
        items: _barbeiros
            .map((b) => DropdownMenuItem(value: b, child: Text(b.nome)))
            .toList(),
        onChanged: _enviando
            ? null
            : (v) {
                setState(() => _barbeiro = v);
                _atualizarHorarios();
              },
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: _enviando ? null : _escolherData,
        icon: const Icon(Icons.calendar_month),
        label: Text(
          _data == null
              ? '3. Escolher data'
              : '${_data!.day.toString().padLeft(2, '0')}/${_data!.month.toString().padLeft(2, '0')}/${_data!.year}',
        ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        key: ValueKey('$_consulta-${_hora ?? "vazio"}'),
        initialValue: _hora,
        decoration: const InputDecoration(labelText: 'Horário disponível'),
        items: _horarios
            .map(
              (h) => DropdownMenuItem(
                value: h.substring(11, 16),
                child: Text(h.substring(11, 16)),
              ),
            )
            .toList(),
        onChanged: _enviando ? null : (v) => setState(() => _hora = v),
      ),
      const SizedBox(height: 20),
      Text('Reserva para ${ApiService.sessao.value?.nome ?? "sua conta"}'),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: _enviando || _hora == null ? null : _confirmar,
        child: Text(_enviando ? 'CONFIRMANDO...' : 'CONFIRMAR AGENDAMENTO'),
      ),
      if (_mensagem != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Semantics(liveRegion: true, child: Text(_mensagem!)),
        ),
      if (!_carregando && _servicos.isEmpty)
        TextButton(
          onPressed: _carregar,
          child: const Text('Tentar carregar novamente'),
        ),
    ],
  );
}
