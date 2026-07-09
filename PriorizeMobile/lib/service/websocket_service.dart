import 'dart:async';

import 'package:stomp_dart_client/stomp_dart_client.dart';

class WebSocketService {
  StompClient? _stompClient;

  final StreamController<String> _mensagensController =
      StreamController<String>.broadcast();

  Stream<String> get mensagens => _mensagensController.stream;

  bool get estaConectado => _stompClient?.connected ?? false;

  void conectar({
    required String ipServidor,
    void Function()? aoConectar,
    void Function(dynamic erro)? aoErro,
  }) {
    final url = 'ws://$ipServidor:8080/ws-tarefas';

    _stompClient = StompClient(
      config: StompConfig(
        url: url,
        onConnect: (StompFrame frame) {
          _stompClient?.subscribe(
            destination: '/topic/tarefas',
            callback: (StompFrame frame) {
              final mensagem = frame.body;

              if (mensagem != null) {
                _mensagensController.add(mensagem);
              }
            },
          );

          aoConectar?.call();
        },
        onWebSocketError: (dynamic erro) {
          aoErro?.call(erro);
        },
        onStompError: (StompFrame frame) {
          aoErro?.call(frame.body);
        },
        onDisconnect: (StompFrame frame) {},
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _stompClient?.activate();
  }

  void enviarMensagem(String mensagem) {
    if (!estaConectado) {
      return;
    }

    _stompClient?.send(
      destination: '/app/atualizar-tarefa',
      body: mensagem,
    );
  }

  void desconectar() {
    _stompClient?.deactivate();
  }

  void dispose() {
    desconectar();
    _mensagensController.close();
  }
}