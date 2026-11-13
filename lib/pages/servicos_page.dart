import 'package:material_ui/material_ui.dart';

import '../api_service.dart';
import '../models.dart';

class ServicosPage extends StatefulWidget {
  const ServicosPage({super.key});
  @override
  State<ServicosPage> createState() => _ServicosPageState();
}

class _ServicosPageState extends State<ServicosPage> {
  late Future<List<Servico>> _dados;
  @override
  void initState() {
    super.initState();
    _dados = ApiService().servicos();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Servico>>(
    future: _dados,
    builder: (c, s) {
      if (s.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (s.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ApiService.mensagem(s.error!)),
                TextButton(
                  onPressed: () =>
                      setState(() => _dados = ApiService().servicos()),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'NOSSOS SERVIÇOS',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuidado, estilo e atendimento com hora marcada.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ...s.data!.map(
            (a) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.content_cut, color: Color(0xFFF39C12)),
                    const SizedBox(height: 10),
                    Text(
                      a.nome.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(a.descricao),
                    const SizedBox(height: 12),
                    Text(
                      '${a.tempoMinutos} min · R\$ ${a.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        color: Color(0xFFF39C12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
