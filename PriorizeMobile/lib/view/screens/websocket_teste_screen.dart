import 'package:flutter/material.dart';
import 'package:priorize/service/websocket_service.dart';

class WebSocketTesteScreen extends StatefulWidget {
  const WebSocketTesteScreen({super.key});

  @override
  State<WebSocketTesteScreen> createState() => _WebSocketTesteScreenState();
}

class _WebSocketTesteScreenState extends State<WebSocketTesteScreen> {
  final WebSocketService _webSocketService = WebSocketService();

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _mensagemController = TextEditingController();

  final List<String> _mensagensRecebidas = [];

  bool _conectado = false;
  String _status = 'Desconectado';

  @override
  void initState() {
    super.initState();

    _webSocketService.mensagens.listen((mensagem) {
      setState(() {
        _mensagensRecebidas.add(mensagem);
      });
    });
  }

  void _conectar() {
    final ip = _ipController.text.trim();

    if (ip.isEmpty) {
      setState(() {
        _status = 'Informe o IP do servidor';
      });
      return;
    }

    setState(() {
      _status = 'Conectando...';
    });

    _webSocketService.conectar(
      ipServidor: ip,
      aoConectar: () {
        setState(() {
          _conectado = true;
          _status = 'Conectado ao servidor';
        });
      },
      aoErro: (erro) {
        setState(() {
          _conectado = false;
          _status = 'Erro na conexão: $erro';
        });
      },
    );
  }

  void _enviarMensagem() {
    final mensagem = _mensagemController.text.trim();

    if (mensagem.isEmpty) {
      return;
    }

    _webSocketService.enviarMensagem(mensagem);
    _mensagemController.clear();
  }

  void _desconectar() {
    _webSocketService.desconectar();

    setState(() {
      _conectado = false;
      _status = 'Desconectado';
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _mensagemController.dispose();
    _webSocketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste WebSocket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP do servidor',
                hintText: 'Ex: 192.168.0.100',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _conectado ? null : _conectar,
                    child: const Text('Conectar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _conectado ? _desconectar : null,
                    child: const Text('Desconectar'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Status: $_status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _conectado ? Colors.green : Colors.red,
                ),
              ),
            ),

            const Divider(height: 32),

            TextField(
              controller: _mensagemController,
              decoration: const InputDecoration(
                labelText: 'Mensagem',
                hintText: 'Digite uma mensagem de teste',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _conectado ? _enviarMensagem : null,
                icon: const Icon(Icons.send),
                label: const Text('Enviar mensagem'),
              ),
            ),

            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mensagens recebidas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: _mensagensRecebidas.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.message),
                      title: Text(_mensagensRecebidas[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}