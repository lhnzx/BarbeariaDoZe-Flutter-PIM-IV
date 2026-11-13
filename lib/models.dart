// Modelos do aplicativo: espelham os DTOs devolvidos pela Web API.
class Servico {
  final int id;
  final String nome;
  final String descricao;
  final double preco;
  final int tempoMinutos;

  Servico({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.tempoMinutos,
  });

  factory Servico.fromJson(Map<String, dynamic> j) => Servico(
    id: j['id'],
    nome: j['nome'],
    descricao: j['descricao'],
    preco: (j['preco'] as num).toDouble(),
    tempoMinutos: j['tempoMinutos'],
  );
}

class Barbeiro {
  final int id;
  final String nome;
  final double avaliacao;

  Barbeiro({required this.id, required this.nome, required this.avaliacao});

  factory Barbeiro.fromJson(Map<String, dynamic> j) => Barbeiro(
    id: j['id'],
    nome: j['nome'],
    avaliacao: (j['avaliacao'] as num).toDouble(),
  );
}

class Agendamento {
  final int id;
  final String servico;
  final String barbeiro;
  final DateTime inicio;
  final DateTime fim;
  final double valor;
  final String status;

  Agendamento({
    required this.id,
    required this.servico,
    required this.barbeiro,
    required this.inicio,
    required this.fim,
    required this.valor,
    required this.status,
  });

  factory Agendamento.fromJson(Map<String, dynamic> j) => Agendamento(
    id: j['id'],
    servico: j['servico'],
    barbeiro: j['barbeiro'],
    inicio: DateTime.parse(j['inicio']),
    fim: DateTime.parse(j['fim']),
    valor: (j['valor'] as num).toDouble(),
    status: j['status'],
  );
}
