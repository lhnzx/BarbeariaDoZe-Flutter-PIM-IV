import 'package:material_ui/material_ui.dart';

import '../api_service.dart';
import '../models.dart';

class MeusAgendamentosPage extends StatefulWidget {
  const MeusAgendamentosPage({super.key});
  @override
  State<MeusAgendamentosPage> createState() => _MeusAgendamentosPageState();
}

class _MeusAgendamentosPageState extends State<MeusAgendamentosPage> {
  final _api = ApiService();
  List<Agendamento> _lista = [];
  String? _mensagem;
  bool _carregando = false;
  int? _cancelando;
  @override
  void initState() {
    super.initState();
    _buscar();
  }

  Future<void> _buscar() async {
    if (_carregando) return;
    setState(() => _carregando = true);
    try {
      final r = await _api.meusAgendamentos();
      if (mounted) {
        setState(() {
          _lista = r;
          _mensagem = r.isEmpty ? 'Nenhum agendamento encontrado.' : null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _mensagem = ApiService.mensagem(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _cancelar(Agendamento a) async {
    if (_cancelando != null) return;
    final confirma = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancelar agendamento?'),
        content: Text('${a.servico} com ${a.barbeiro}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    setState(() => _cancelando = a.id);
    try {
      await _api.cancelar(a.id);
      await _buscar();
    } catch (e) {
      if (mounted) setState(() => _mensagem = ApiService.mensagem(e));
    } finally {
      if (mounted) setState(() => _cancelando = null);
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'MEUS HORÁRIOS',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: _carregando ? null : _buscar,
              tooltip: 'Atualizar lista',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      if (_carregando) const LinearProgressIndicator(),
      if (_mensagem != null)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Semantics(liveRegion: true, child: Text(_mensagem!)),
        ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: _lista
              .map(
                (a) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.servico,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(a.barbeiro),
                        Text(_fmt(a.inicio)),
                        Text(
                          'R\$ ${a.valor.toStringAsFixed(2).replaceAll('.', ',')} · ${a.status}',
                        ),
                        if (a.status == 'Confirmado')
                          TextButton.icon(
                            onPressed: _cancelando != null
                                ? null
                                : () => _cancelar(a),
                            icon: const Icon(Icons.cancel_outlined),
                            label: Text(
                              _cancelando == a.id
                                  ? 'Cancelando...'
                                  : 'Cancelar agendamento',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );
}
