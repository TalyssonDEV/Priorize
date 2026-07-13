import 'dart:convert';
import 'dart:io';
import '../model/p2p_models.dart';

class CoordinationService {
  final String host;
  CoordinationService(this.host);
  Uri _uri(String path) => Uri.parse('http://$host:8080$path');

  Future<dynamic> _request(String method, String path, [Object? body]) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, _uri(path));
      request.headers.contentType = ContentType.json;
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close();
      final text = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decoded = text.isEmpty ? null : jsonDecode(text);
        throw Exception(decoded is Map ? decoded['error'] : 'HTTP ${response.statusCode}');
      }
      return text.isEmpty ? null : jsonDecode(text);
    } finally { client.close(); }
  }

  Future<String> createRoom(String name, String userId, String userName) async =>
      (await _request('POST', '/api/rooms', {'name': name, 'leaderUserId': userId, 'leaderName': userName}))['roomId'];

  Future<List<RoomSummary>> userRooms(String userId) async =>
      (await _request('GET', '/api/users/${Uri.encodeComponent(userId)}/rooms') as List)
          .map((e) => RoomSummary.fromJson(Map<String, dynamic>.from(e))).toList();

  Future<void> joinRoom(String roomId, String userId, String userName) =>
      _request('POST', '/api/rooms/$roomId/members', {'userId': userId, 'userName': userName});

  Future<void> leaveRoom(String roomId, String userId) =>
      _request('DELETE', '/api/rooms/$roomId/members/${Uri.encodeComponent(userId)}');

  Future<void> deleteRoom(String roomId, String userId) =>
      _request('DELETE', '/api/rooms/$roomId?requestedBy=${Uri.encodeQueryComponent(userId)}');

  Future<void> verifyRoom(String roomId) => _request('GET', '/api/rooms/$roomId');

  Future<void> registerPeer(Map<String, dynamic> peer) => _request('POST', '/api/peers', peer);
  Future<List<PeerInfo>> peers(String room) async => (await _request('GET', '/api/rooms/$room/peers') as List)
      .map((e) => PeerInfo.fromJson(Map<String, dynamic>.from(e))).toList();
  Future<List<SharedFileInfo>> files(String room) async => (await _request('GET', '/api/rooms/$room/files') as List)
      .map((e) => SharedFileInfo.fromJson(Map<String, dynamic>.from(e))).toList();
  Future<void> registerFile(Map<String, dynamic> file) => _request('POST', '/api/files', file);
  Future<List<FileSourceInfo>> sources(String fileId) async => (await _request('GET', '/api/files/$fileId/sources') as List)
      .map((e) => FileSourceInfo.fromJson(Map<String, dynamic>.from(e))).toList();
  Future<void> addSource(String fileId, String peerId) => _request('POST', '/api/files/$fileId/sources/$peerId');
  Future<void> leave(String peerId) => _request('DELETE', '/api/peers/$peerId');

  Future<List<SharedTaskInfo>> tasks(String roomId, String userId) async =>
      (await _request('GET', '/api/rooms/$roomId/tasks?userId=${Uri.encodeQueryComponent(userId)}') as List)
          .map((e) => SharedTaskInfo.fromJson(Map<String, dynamic>.from(e))).toList();

  Future<SharedTaskInfo> createTask(String roomId, String userId, String userName,
      String title, String description, String priority) async => SharedTaskInfo.fromJson(
        Map<String, dynamic>.from(await _request('POST',
          '/api/rooms/$roomId/tasks?userId=${Uri.encodeQueryComponent(userId)}&userName=${Uri.encodeQueryComponent(userName)}',
          {'title': title, 'description': description, 'priority': priority, 'completed': false})));

  Future<SharedTaskInfo> updateTask(SharedTaskInfo task, String userId, {bool? completed}) async =>
      SharedTaskInfo.fromJson(Map<String, dynamic>.from(await _request('PUT',
        '/api/rooms/${task.roomId}/tasks/${task.taskId}?userId=${Uri.encodeQueryComponent(userId)}',
        {'title': task.title, 'description': task.description, 'priority': task.priority,
         'completed': completed ?? task.completed})));

  Future<TaskAttachmentInfo> registerTaskAttachment(String roomId, String taskId, String userId,
      Map<String, dynamic> file) async => TaskAttachmentInfo.fromJson(Map<String, dynamic>.from(
        await _request('POST',
          '/api/rooms/$roomId/tasks/$taskId/attachments?userId=${Uri.encodeQueryComponent(userId)}', file)));

  Future<List<TaskAttachmentInfo>> taskAttachments(String roomId, String taskId, String userId) async =>
      (await _request('GET',
        '/api/rooms/$roomId/tasks/$taskId/attachments?userId=${Uri.encodeQueryComponent(userId)}') as List)
          .map((e) => TaskAttachmentInfo.fromJson(Map<String, dynamic>.from(e))).toList();
}
