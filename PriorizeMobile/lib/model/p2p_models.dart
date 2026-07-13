class PeerInfo {
  final String peerId, roomId, userName, ipAddress;
  final int p2pPort;
  PeerInfo.fromJson(Map<String, dynamic> json)
      : peerId = json['peerId'], roomId = json['roomId'], userName = json['userName'],
        ipAddress = json['ipAddress'], p2pPort = json['p2pPort'];
}

class RoomSummary {
  final String roomId, name, leaderUserId, leaderName, memberRole;
  RoomSummary.fromJson(Map<String, dynamic> json)
      : roomId = json['roomId'], name = json['name'], leaderUserId = json['leaderUserId'],
        leaderName = json['leaderName'], memberRole = json['memberRole'] ?? 'MEMBER';
}

class SharedTaskInfo {
  final String taskId, roomId, title, description, priority, createdBy, createdByName;
  final bool completed;
  SharedTaskInfo.fromJson(Map<String, dynamic> json)
      : taskId = json['taskId'], roomId = json['roomId'], title = json['title'],
        description = json['description'] ?? '', priority = json['priority'],
        completed = json['completed'] ?? false, createdBy = json['createdBy'],
        createdByName = json['createdByName'];
}

class TaskAttachmentInfo {
  final String fileId, taskId, roomId, fileName, sha256, ownerPeerId, uploadedBy;
  final int fileSize;
  TaskAttachmentInfo.fromJson(Map<String, dynamic> json)
      : fileId = json['fileId'], taskId = json['taskId'], roomId = json['roomId'],
        fileName = json['fileName'], fileSize = json['fileSize'], sha256 = json['sha256'],
        ownerPeerId = json['ownerPeerId'], uploadedBy = json['uploadedBy'];
}

class SharedFileInfo {
  final String fileId, roomId, fileName, sha256, ownerPeerId;
  final int fileSize;
  SharedFileInfo.fromJson(Map<String, dynamic> json)
      : fileId = json['fileId'], roomId = json['roomId'], fileName = json['fileName'],
        sha256 = json['sha256'], ownerPeerId = json['ownerPeerId'], fileSize = json['fileSize'];
}

class FileSourceInfo {
  final String peerId, userName, ipAddress;
  final int p2pPort;
  FileSourceInfo.fromJson(Map<String, dynamic> json)
      : peerId = json['peerId'], userName = json['userName'],
        ipAddress = json['ipAddress'], p2pPort = json['p2pPort'];
}
