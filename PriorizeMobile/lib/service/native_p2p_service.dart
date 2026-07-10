import 'package:flutter/services.dart';

class NativeP2PService {
  static const _channel = MethodChannel('priorize/p2p');

  Future<Map<String, dynamic>> startServer() async =>
      Map<String, dynamic>.from(await _channel.invokeMethod('startPeerServer', {'port': 0}));

  Future<Map<String, dynamic>?> selectFile() async {
    final result = await _channel.invokeMethod('selectLocalFile');
    return result == null ? null : Map<String, dynamic>.from(result);
  }

  Future<void> registerFile(Map<String, dynamic> file) =>
      _channel.invokeMethod('registerLocalFile', file);

  Future<Map<String, dynamic>> download({required String ip, required int port,
    required String fileId, required String fileName, required String hash}) async =>
      Map<String, dynamic>.from(await _channel.invokeMethod('downloadFile', {
        'ipAddress': ip, 'port': port, 'fileId': fileId,
        'fileName': fileName, 'expectedHash': hash,
      }));

  Future<void> stopServer() => _channel.invokeMethod('stopPeerServer');

  Future<void> openDownloadedFile(String contentUri) =>
      _channel.invokeMethod('openDownloadedFile', {'contentUri': contentUri});
}
