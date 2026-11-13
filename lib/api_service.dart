import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class Sessao {
  final String token, nome, email;
  Sessao(this.token, this.nome, this.email);
}

class ApiService {
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5114/api',
  );
  // Token só em memória: ao fechar/recarregar, a pessoa entra novamente.
  static final sessao = ValueNotifier<Sessao?>(null);
  static const _tempo = Duration(seconds: 20);
  Future<dynamic> _enviar(
    String metodo,
    String caminho, {
    Map<String, dynamic>? dados,
    bool autenticado = false,
  }) async {
    final atual = sessao.value;
    if (autenticado && atual == null) {
      throw Exception('Entre na sua conta para continuar.');
    }
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (autenticado) 'Authorization': 'Bearer ${atual!.token}',
    };
    try {
      final url = Uri.parse('$baseUrl$caminho');
      final r = await (switch (metodo) {
        'POST' => http.post(url, headers: headers, body: jsonEncode(dados)),
        'PUT' => http.put(url, headers: headers, body: jsonEncode(dados)),
        _ => http.get(url, headers: headers),
      }).timeout(_tempo);
      if (r.statusCode == 401 && autenticado) {
        if (sessao.value?.token == atual?.token) sessao.value = null;
        throw Exception('Sua sessão expirou. Entre novamente.');
      }
      dynamic corpo;
      if (r.body.isNotEmpty) {
        try {
          corpo = jsonDecode(r.body);
        } catch (_) {
          corpo = null;
        }
      }
      if (r.statusCode < 200 || r.statusCode >= 300) {
        String msg = r.statusCode == 429
            ? 'Muitas tentativas. Aguarde um minuto.'
            : 'Não foi possível concluir a operação (${r.statusCode}).';
        if (corpo is Map && corpo['erro'] is String) msg = corpo['erro'];
        if (corpo is Map && corpo['errors'] is Map) {
          msg = 'Confira os campos preenchidos.';
        }
        throw Exception(msg);
      }
      return corpo;
    } on TimeoutException {
      throw Exception('A conexão demorou. Tente novamente.');
    } on http.ClientException {
      throw Exception(
        'Não foi possível conectar. Verifique sua conexão e tente novamente.',
      );
    }
  }

  Future<void> entrar(String email, String senha) async {
    final j = await _enviar(
      'POST',
      '/conta/login',
      dados: {'email': email.trim(), 'senha': senha},
    );
    sessao.value = Sessao(j['token'], j['nome'], j['email']);
  }

  Future<void> cadastrar(
    String nome,
    String telefone,
    String email,
    String senha,
  ) => _enviar(
    'POST',
    '/conta/cadastro',
    dados: {
      'nome': nome.trim(),
      'telefone': telefone.trim(),
      'email': email.trim(),
      'senha': senha,
    },
  );
  Future<void> recuperar(String email) =>
      _enviar('POST', '/conta/recuperacao', dados: {'email': email.trim()});
  Future<List<Servico>> servicos() async =>
      (await _enviar('GET', '/servicos') as List)
          .map((e) => Servico.fromJson(e))
          .toList();
  Future<List<Barbeiro>> barbeiros() async =>
      (await _enviar('GET', '/barbeiros') as List)
          .map((e) => Barbeiro.fromJson(e))
          .toList();
  Future<List<String>> horarios(
    DateTime dia,
    int servicoId,
    int barbeiroId,
  ) async {
    final data = dia.toIso8601String().substring(0, 10);
    return (await _enviar(
      'GET',
      '/agendamentos/horarios-disponiveis?data=$data&servicoId=$servicoId&barbeiroId=$barbeiroId',
    ) as List).map((e) => e.toString()).toList();
  }

  Future<Agendamento> agendar({
    required int servicoId,
    required int barbeiroId,
    required String inicioIso,
  }) async => Agendamento.fromJson(
    await _enviar(
      'POST',
      '/agendamentos',
      autenticado: true,
      dados: {
        'servicoId': servicoId,
        'barbeiroId': barbeiroId,
        'inicio': inicioIso,
      },
    ),
  );
  Future<List<Agendamento>> meusAgendamentos() async =>
      (await _enviar('GET', '/agendamentos', autenticado: true) as List)
          .map((e) => Agendamento.fromJson(e))
          .toList();
  Future<void> cancelar(int id) => _enviar(
    'PUT',
    '/agendamentos/$id/status',
    autenticado: true,
    dados: {'status': 'Cancelado'},
  );
  static String mensagem(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
