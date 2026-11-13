import 'package:material_ui/material_ui.dart';

import '../api_service.dart';
import 'servicos_page.dart';
import 'agendar_page.dart';
import 'meus_agendamentos_page.dart';
import 'conta_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _aba = 0;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Sessao?>(
    valueListenable: ApiService.sessao,
    builder: (context, sessao, _) => Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/Barbearia_Logo.png',
              height: 40,
              semanticLabel: 'Logo da barbearia',
            ),
            const SizedBox(width: 12),
            const Flexible(child: Text('Barbearia do Zé')),
          ],
        ),
      ),
      body: IndexedStack(
        key: ValueKey(sessao?.email ?? 'visitante'),
        index: _aba,
        children: [
          const ServicosPage(),
          sessao == null ? const ContaPage() : const AgendarPage(),
          sessao == null ? const ContaPage() : const MeusAgendamentosPage(),
          const ContaPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.content_cut),
            label: 'Serviços',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available),
            label: 'Agendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Meus horários',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Conta'),
        ],
      ),
    ),
  );
}
