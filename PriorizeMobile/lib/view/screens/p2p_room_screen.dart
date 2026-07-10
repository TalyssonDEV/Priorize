import 'dart:async';
import 'package:flutter/material.dart';
import '../../model/p2p_models.dart';
import '../../service/coordination_service.dart';
import '../../service/native_p2p_service.dart';
import '../../service/websocket_service.dart';

class P2PRoomScreen extends StatefulWidget {
  final String serverHost, userId, userName, initialRoomId, memberRole;
  const P2PRoomScreen({super.key, required this.serverHost, required this.userId,
    required this.userName, required this.initialRoomId, required this.memberRole});
  @override State<P2PRoomScreen> createState() => _P2PRoomScreenState();
}

class _P2PRoomScreenState extends State<P2PRoomScreen> {
  final _native = NativeP2PService();
  final _socket = WebSocketService();
  late final CoordinationService _api = CoordinationService(widget.serverHost);
  StreamSubscription? _events;
  List<PeerInfo> _peers = [];
  List<SharedTaskInfo> _tasks = [];
  final Map<String, String> _downloadedUris = {};
  String? _peerId, _localIp;
  int? _port;
  bool _busy = true, _cleanedUp = false;
  String _status = 'Conectando à sala...';

  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _connect()); }

  Future<void> _connect() async {
    await _run(() async {
      final native = await _native.startServer();
      _localIp = native['ipAddress']; _port = native['port'];
      await _api.verifyRoom(widget.initialRoomId);
      await _api.joinRoom(widget.initialRoomId, widget.userId, widget.userName);
      _peerId = 'peer-${widget.userId}-${widget.initialRoomId}';
      await _api.registerPeer({'peerId': _peerId, 'userId': widget.userId, 'roomId': widget.initialRoomId,
        'userName': widget.userName, 'ipAddress': _localIp, 'p2pPort': _port, 'connected': true});
      _events = _socket.mensagens.listen((_) => _refresh());
      _socket.conectar(ipServidor: widget.serverHost, destino: '/topic/rooms/${widget.initialRoomId}',
        aoConectar: _refresh, aoErro: (error) { if (mounted) setState(() => _status = 'WebSocket: $error'); });
      await _refresh();
      _status = 'Peer ativo em $_localIp:$_port';
    });
  }

  Future<void> _refresh() async {
    try {
      final values = await Future.wait([
        _api.peers(widget.initialRoomId), _api.tasks(widget.initialRoomId, widget.userId),
      ]);
      if (mounted) setState(() { _peers = values[0] as List<PeerInfo>; _tasks = values[1] as List<SharedTaskInfo>; });
    } catch (_) { }
  }

  Future<void> _createTask() async {
    final draft = await showDialog<_NewTaskDraft>(context: context, builder: (_) => _NewTaskDialog(native: _native));
    if (draft == null) return;
    await _run(() async {
      final task = await _api.createTask(widget.initialRoomId, widget.userId, widget.userName,
        draft.title, draft.description, draft.priority);
      if (draft.file != null) {
        final fileId = 'file-${DateTime.now().millisecondsSinceEpoch}';
        await _native.registerFile({...draft.file!, 'fileId': fileId});
        await _api.registerTaskAttachment(widget.initialRoomId, task.taskId, widget.userId, {
          'fileId': fileId, 'roomId': widget.initialRoomId, 'fileName': draft.file!['name'],
          'fileSize': draft.file!['size'], 'sha256': draft.file!['sha256'], 'ownerPeerId': _peerId,
        });
      }
      await _refresh();
      _status = 'Tarefa criada e sincronizada.';
    });
  }

  Future<void> _toggleTask(SharedTaskInfo task) async => _run(() async {
    await _api.updateTask(task, widget.userId, completed: !task.completed);
    await _refresh();
  });

  Future<void> _showTask(SharedTaskInfo task) async {
    await showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) =>
        FutureBuilder<List<TaskAttachmentInfo>>(
          future: _api.taskAttachments(widget.initialRoomId, task.taskId, widget.userId),
          builder: (context, snapshot) {
            final attachments = snapshot.data ?? [];
            return Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(task.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                  IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close))]),
                _PriorityBadge(priority: task.priority),
                const SizedBox(height: 16),
                Text(task.description.isEmpty ? 'Sem descrição' : task.description,
                  style: TextStyle(fontSize: 16, color: task.description.isEmpty ? Colors.grey : null)),
                const SizedBox(height: 8), Text('Criada por ${task.createdByName}', style: const TextStyle(color: Colors.grey)),
                const Divider(height: 32),
                const Text('Arquivos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (snapshot.connectionState == ConnectionState.waiting) const LinearProgressIndicator(),
                if (attachments.isEmpty && snapshot.connectionState != ConnectionState.waiting)
                  const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.attach_file), title: Text('Nenhum arquivo anexado')),
                ...attachments.map((file) => ListTile(contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file_outlined), title: Text(file.fileName),
                  subtitle: Text('${(file.fileSize / 1024).toStringAsFixed(1)} KB'),
                  trailing: _downloadedUris.containsKey(file.fileId)
                    ? IconButton(icon: const Icon(Icons.open_in_new), onPressed: () => _native.openDownloadedFile(_downloadedUris[file.fileId]!))
                    : file.ownerPeerId == _peerId
                      ? const Chip(label: Text('Local'))
                      : IconButton(icon: const Icon(Icons.download), onPressed: () async {
                          await _download(file); setSheetState(() {});
                        }),
                )),
              ]));
          },
        ),
      ));
  }

  Future<void> _download(TaskAttachmentInfo file) async => _run(() async {
    final sources = await _api.sources(file.fileId);
    final source = sources.where((item) => item.peerId != _peerId).firstOrNull;
    if (source == null) throw Exception('Nenhuma fonte remota disponível');
    _status = 'Baixando diretamente de ${source.userName}...';
    final result = await _native.download(ip: source.ipAddress, port: source.p2pPort,
      fileId: file.fileId, fileName: file.fileName, hash: file.sha256);
    if (result['success'] != true) throw Exception(result['error']);
    _downloadedUris[file.fileId] = result['contentUri'];
    await _api.addSource(file.fileId, _peerId!);
    _status = 'Download salvo em ${result['finalPath']}';
  });

  void _showParticipants() => showModalBottomSheet(context: context, builder: (context) => SafeArea(
    child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_peers.length} online', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ..._peers.map((peer) => ListTile(leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(peer.userName), subtitle: Text('${peer.ipAddress}:${peer.p2pPort}${peer.peerId == _peerId ? ' • você' : ''}'))),
      ])),
  ));

  Future<void> _leaveOrDeleteRoom() async {
    final leader = widget.memberRole == 'LEADER';
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(leader ? 'Excluir sala' : 'Sair da sala'),
      content: Text(leader ? 'A sala, tarefas e anexos serão excluídos para todos.' : 'Você deixará de participar desta sala.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(leader ? 'Excluir' : 'Sair'))],
    ));
    if (confirmed != true) return;
    await _run(() async {
      await _cleanupPeer();
      if (leader) { await _api.deleteRoom(widget.initialRoomId, widget.userId); }
      else { await _api.leaveRoom(widget.initialRoomId, widget.userId); }
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _cleanupPeer() async {
    if (_cleanedUp) return; _cleanedUp = true;
    try { if (_peerId != null) await _api.leave(_peerId!); } catch (_) { }
    await _events?.cancel(); _socket.desconectar();
    try { await _native.stopServer(); } catch (_) { }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy && _peerId != null) return;
    if (mounted) setState(() => _busy = true);
    try { await action(); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')))); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override Widget build(BuildContext context) {
    final completed = _tasks.where((task) => task.completed).length;
    final progress = _tasks.isEmpty ? 0.0 : completed / _tasks.length;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tarefas', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Sala ${widget.initialRoomId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
        ]),
        actions: [
          IconButton(onPressed: _showParticipants, tooltip: 'Participantes online', icon: Badge(
            label: Text('${_peers.length}'), child: const Icon(Icons.people_alt_outlined))),
          PopupMenuButton<String>(onSelected: (_) => _leaveOrDeleteRoom(), itemBuilder: (_) => [
            PopupMenuItem(value: 'exit', child: Row(children: [Icon(widget.memberRole == 'LEADER' ? Icons.delete_outline : Icons.logout),
              const SizedBox(width: 8), Text(widget.memberRole == 'LEADER' ? 'Excluir sala' : 'Sair da sala')]))]),
        ],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('$completed/${_tasks.length} concluídas'), Text('${(progress * 100).round()}%')]),
          const SizedBox(height: 8), LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(8)),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(_status,
            style: const TextStyle(fontSize: 12, color: Colors.grey))),
        ])),
        Expanded(child: _tasks.isEmpty ? _EmptyTasks(loading: _busy) : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), itemCount: _tasks.length,
          itemBuilder: (context, index) { final task = _tasks[index]; return Card(child: InkWell(
            onTap: () => _showTask(task), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              Checkbox(value: task.completed, onChanged: (_) => _toggleTask(task)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(task.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  decoration: task.completed ? TextDecoration.lineThrough : null)),
                if (task.description.isNotEmpty) Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8), Row(children: [_PriorityBadge(priority: task.priority),
                  const Spacer(), const Icon(Icons.chevron_right, color: Colors.grey)]),
              ])),
            ])))); },
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: _busy ? null : _createTask,
        icon: const Icon(Icons.add), label: const Text('Nova Tarefa')),
    );
  }

  @override void dispose() { _cleanupPeer(); _socket.dispose(); super.dispose(); }
}

class _NewTaskDraft {
  final String title, description, priority;
  final Map<String, dynamic>? file;
  _NewTaskDraft(this.title, this.description, this.priority, this.file);
}

class _NewTaskDialog extends StatefulWidget {
  final NativeP2PService native;
  const _NewTaskDialog({required this.native});
  @override State<_NewTaskDialog> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<_NewTaskDialog> {
  final title = TextEditingController(), description = TextEditingController();
  String priority = 'MEDIUM';
  Map<String, dynamic>? file;
  bool selecting = false;

  Future<void> _selectFile() async {
    setState(() => selecting = true);
    try { file = await widget.native.selectFile(); }
    finally { if (mounted) setState(() => selecting = false); }
  }

  @override Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    title: const Text('Nova Tarefa', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: title, autofocus: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.title), labelText: 'Título', hintText: 'Ex: Preparar apresentação', border: OutlineInputBorder())),
      const SizedBox(height: 14),
      TextField(controller: description, minLines: 3, maxLines: 5, decoration: const InputDecoration(prefixIcon: Icon(Icons.description_outlined), labelText: 'Descrição (opcional)', border: OutlineInputBorder())),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(initialValue: priority, decoration: const InputDecoration(prefixIcon: Icon(Icons.flag_outlined), labelText: 'Prioridade', border: OutlineInputBorder()),
        items: const [DropdownMenuItem(value: 'LOW', child: Text('Baixa')), DropdownMenuItem(value: 'MEDIUM', child: Text('Média')), DropdownMenuItem(value: 'HIGH', child: Text('Alta'))],
        onChanged: (value) => setState(() => priority = value!)),
      const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: selecting ? null : _selectFile,
        icon: Icon(file == null ? Icons.upload_file : Icons.check_circle),
        label: Text(selecting ? 'Selecionando...' : file == null ? 'Anexar arquivo (opcional)' : file!['name'])),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(onPressed: () {
        if (title.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o título da tarefa')));
          return;
        }
        Navigator.pop(context, _NewTaskDraft(title.text.trim(), description.text.trim(), priority, file));
      }, child: const Text('Adicionar'))],
  );

  @override void dispose() { title.dispose(); description.dispose(); super.dispose(); }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});
  @override Widget build(BuildContext context) {
    final (label, color, icon) = switch (priority) {
      'HIGH' => ('Alta', Colors.red, Icons.arrow_upward),
      'LOW' => ('Baixa', Colors.green, Icons.arrow_downward),
      _ => ('Média', Colors.orange, Icons.remove),
    };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(color: color))]));
  }
}

class _EmptyTasks extends StatelessWidget {
  final bool loading;
  const _EmptyTasks({required this.loading});
  @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.inbox_outlined, size: 88, color: Colors.grey[300]), const SizedBox(height: 16),
    Text(loading ? 'Carregando...' : 'Nenhuma tarefa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[700])),
    if (!loading) Text('Adicione uma nova tarefa para começar', style: TextStyle(color: Colors.grey[500])),
  ]));
}
