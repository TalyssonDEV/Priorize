import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../model/p2p_models.dart';
import '../../service/coordination_service.dart';
import 'p2p_room_screen.dart';

class SharedRoomsScreen extends StatefulWidget {
  const SharedRoomsScreen({super.key});
  @override State<SharedRoomsScreen> createState() => _SharedRoomsScreenState();
}

class _SharedRoomsScreenState extends State<SharedRoomsScreen> {
  final _server = TextEditingController();
  final _userName = TextEditingController();
  final _roomCode = TextEditingController();
  List<RoomSummary> _rooms = [];
  String? _userId;
  bool _loading = false;
  String? _error;

  @override void initState() { super.initState(); _loadIdentity(); }

  Future<void> _loadIdentity() async {
    final box = await Hive.openBox('p2p_settings');
    var id = box.get('userId') as String?;
    if (id == null) {
      id = 'user-${DateTime.now().microsecondsSinceEpoch}';
      await box.put('userId', id);
    }
    _server.text = box.get('serverHost', defaultValue: '') as String;
    _userName.text = box.get('userName', defaultValue: '') as String;
    if (mounted) setState(() => _userId = id);
    if (_server.text.isNotEmpty) await _refresh();
  }

  Future<void> _saveSettings() async {
    final box = await Hive.openBox('p2p_settings');
    await box.put('serverHost', _server.text.trim());
    await box.put('userName', _userName.text.trim());
  }

  Future<void> _refresh() async {
    if (_userId == null || _server.text.trim().isEmpty) return;
    await _run(() async {
      await _saveSettings();
      _rooms = await CoordinationService(_server.text.trim()).userRooms(_userId!);
    });
  }

  Future<void> _createRoom() async {
    final nameController = TextEditingController(text: 'Sala Priorize');
    final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Nova sala compartilhada'),
      content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome da sala')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, nameController.text.trim()), child: const Text('Criar'))],
    ));
    if (name == null || name.isEmpty) return;
    await _run(() async {
      _validateSettings(); await _saveSettings();
      final roomId = await CoordinationService(_server.text.trim()).createRoom(name, _userId!, _userName.text.trim());
      await _openRoom(roomId, role: 'LEADER');
    });
  }

  Future<void> _joinRoom() async => _run(() async {
    _validateSettings();
    final code = _roomCode.text.trim().toUpperCase();
    if (code.isEmpty) throw Exception('Informe o código da sala');
    await _saveSettings();
    await CoordinationService(_server.text.trim()).joinRoom(code, _userId!, _userName.text.trim());
    _roomCode.clear(); await _openRoom(code, role: 'MEMBER');
  });

  Future<void> _openRoom(String roomId, {String? role}) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => P2PRoomScreen(
      serverHost: _server.text.trim(), userId: _userId!, userName: _userName.text.trim(),
      initialRoomId: roomId, memberRole: role ?? 'MEMBER',
    )));
    _rooms = await CoordinationService(_server.text.trim()).userRooms(_userId!);
    if (mounted) setState(() {});
  }

  Future<void> _removeRoom(RoomSummary room) async {
    final leader = room.memberRole == 'LEADER';
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(leader ? 'Excluir sala' : 'Sair da sala'),
      content: Text(leader
          ? 'A sala e todas as tarefas compartilhadas serão excluídas para todos.'
          : 'Você deixará de participar desta sala.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(leader ? 'Excluir' : 'Sair'))],
    ));
    if (confirmed != true) return;
    await _run(() async {
      final api = CoordinationService(_server.text.trim());
      if (leader) { await api.deleteRoom(room.roomId, _userId!); }
      else { await api.leaveRoom(room.roomId, _userId!); }
      _rooms = await api.userRooms(_userId!);
    });
  }

  void _validateSettings() {
    if (_server.text.trim().isEmpty || _userName.text.trim().isEmpty) throw Exception('Informe servidor e seu nome');
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return; setState(() { _loading = true; _error = null; });
    try { await action(); } catch (e) { if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Salas compartilhadas'), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))]),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: _server, decoration: const InputDecoration(labelText: 'IP do Spring Boot', hintText: '192.168.0.10')),
      TextField(controller: _userName, decoration: const InputDecoration(labelText: 'Seu nome')),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _loading ? null : _createRoom, icon: const Icon(Icons.add), label: const Text('Criar sala')),
      Row(children: [Expanded(child: TextField(controller: _roomCode, textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: 'Código para entrar'))),
        IconButton(onPressed: _loading ? null : _joinRoom, icon: const Icon(Icons.login))]),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
      const SizedBox(height: 16),
      const Text('Minhas salas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      if (_rooms.isEmpty && !_loading) const ListTile(title: Text('Nenhuma sala vinculada')),
      ..._rooms.map((room) => Card(child: ListTile(
        leading: const Icon(Icons.groups), title: Text(room.name), subtitle: Text('${room.roomId} • ${room.memberRole == 'LEADER' ? 'Líder' : 'Membro'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (_) => _removeRoom(room),
          itemBuilder: (_) => [PopupMenuItem(value: 'remove', child: Text(room.memberRole == 'LEADER' ? 'Excluir sala' : 'Sair da sala'))],
        ), onTap: () => _openRoom(room.roomId, role: room.memberRole),
      ))),
    ]),
  );

  @override void dispose() { _server.dispose(); _userName.dispose(); _roomCode.dispose(); super.dispose(); }
}
