import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:barbearia_app/api_service.dart';
import 'package:barbearia_app/pages/conta_page.dart';

void main() {
  setUp(() {
    ApiService.sessao.value = null;
  });
  testWidgets('Login vazio é validado antes de qualquer requisição', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ContaPage())),
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um e-mail válido'), findsOneWidget);
    expect(find.text('Confira sua senha'), findsOneWidget);
    expect(ApiService.sessao.value, isNull);
  });
  testWidgets('Sair remove o token e os dados da sessão', (tester) async {
    ApiService.sessao.value = Sessao(
      'token-de-teste',
      'Cliente Teste',
      'teste@example.invalid',
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ContaPage())),
    );
    await tester.tap(find.text('Sair da conta'));
    expect(ApiService.sessao.value, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
