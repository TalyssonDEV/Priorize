import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:priorize/view/screens/p2p_room_screen.dart';

void main() {
  testWidgets('tela P2P apresenta os campos de entrada da sala', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: P2PRoomScreen(
      serverHost: '127.0.0.1', userId: 'test-user', userName: 'Teste',
      initialRoomId: 'ABC123', memberRole: 'MEMBER',
    )));

    expect(find.text('Tarefas'), findsOneWidget);
    expect(find.text('Sala ABC123'), findsOneWidget);
    expect(find.text('Nova Tarefa'), findsOneWidget);
  });
}
