package com.example.servidortarefasp2p.coordination.controller;

import com.example.servidortarefasp2p.coordination.model.*;
import com.example.servidortarefasp2p.coordination.service.CoordinationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(originPatterns = "*")
public class CoordinationController {
    private final CoordinationService service;

    public CoordinationController(CoordinationService service) {
        this.service = service;
    }

    @PostMapping("/rooms")
    public RoomInfo createRoom(@RequestBody Map<String, String> body) {
        String leaderName = body.getOrDefault("leaderName", body.get("createdBy"));
        String leaderUserId = body.getOrDefault("leaderUserId", leaderName);
        return service.createRoom(body.get("name"), leaderUserId, leaderName);
    }

    @GetMapping("/rooms/{roomId}")
    public RoomInfo room(@PathVariable String roomId) { return service.getRoom(roomId); }

    @GetMapping("/users/{userId}/rooms")
    public List<RoomSummary> userRooms(@PathVariable String userId) { return service.roomsForUser(userId); }

    @PostMapping("/rooms/{roomId}/members")
    public RoomSummary joinRoom(@PathVariable String roomId, @RequestBody Map<String, String> body) {
        return service.joinRoom(roomId, body.get("userId"), body.get("userName"));
    }

    @GetMapping("/rooms/{roomId}/members")
    public List<com.example.servidortarefasp2p.coordination.entity.RoomMemberEntity> members(@PathVariable String roomId) {
        return service.members(roomId);
    }

    @DeleteMapping("/rooms/{roomId}/members/{userId}")
    public ResponseEntity<Void> leaveRoom(@PathVariable String roomId, @PathVariable String userId) {
        service.leaveRoom(roomId, userId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/rooms/{roomId}")
    public ResponseEntity<Void> deleteRoom(@PathVariable String roomId, @RequestParam String requestedBy) {
        service.deleteRoom(roomId, requestedBy);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/peers")
    public PeerInfo registerPeer(@RequestBody PeerInfo peer) { return service.registerPeer(peer); }

    @DeleteMapping("/peers/{peerId}")
    public ResponseEntity<Void> removePeer(@PathVariable String peerId) {
        service.removePeer(peerId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/rooms/{roomId}/peers")
    public List<PeerInfo> peers(@PathVariable String roomId) { return service.participants(roomId); }

    @GetMapping("/rooms/{roomId}/tasks")
    public List<SharedTaskInfo> tasks(@PathVariable String roomId, @RequestParam String userId) {
        return service.tasks(roomId, userId);
    }

    @PostMapping("/rooms/{roomId}/tasks")
    public SharedTaskInfo createTask(@PathVariable String roomId, @RequestParam String userId,
                                     @RequestParam String userName, @RequestBody SharedTaskInfo task) {
        return service.createTask(roomId, userId, userName, task);
    }

    @PutMapping("/rooms/{roomId}/tasks/{taskId}")
    public SharedTaskInfo updateTask(@PathVariable String roomId, @PathVariable String taskId,
                                     @RequestParam String userId, @RequestBody SharedTaskInfo task) {
        return service.updateTask(roomId, taskId, userId, task);
    }

    @DeleteMapping("/rooms/{roomId}/tasks/{taskId}")
    public ResponseEntity<Void> deleteTask(@PathVariable String roomId, @PathVariable String taskId,
                                           @RequestParam String userId) {
        service.deleteTask(roomId, taskId, userId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/rooms/{roomId}/tasks/{taskId}/attachments")
    public TaskAttachmentInfo addAttachment(@PathVariable String roomId, @PathVariable String taskId,
                                             @RequestParam String userId, @RequestBody SharedFileMetadata file) {
        return service.registerTaskAttachment(roomId, taskId, userId, file);
    }

    @GetMapping("/rooms/{roomId}/tasks/{taskId}/attachments")
    public List<TaskAttachmentInfo> attachments(@PathVariable String roomId, @PathVariable String taskId,
                                                 @RequestParam String userId) {
        return service.taskAttachments(roomId, taskId, userId);
    }

    @PostMapping("/files")
    public SharedFileMetadata registerFile(@RequestBody SharedFileMetadata file) { return service.registerFile(file); }

    @GetMapping("/rooms/{roomId}/files")
    public List<SharedFileMetadata> files(@PathVariable String roomId) { return service.filesInRoom(roomId); }

    @GetMapping("/files/{fileId}/sources")
    public List<FileSourceInfo> sources(@PathVariable String fileId) { return service.sources(fileId); }

    @PostMapping("/files/{fileId}/sources/{peerId}")
    public ResponseEntity<Void> addSource(@PathVariable String fileId, @PathVariable String peerId) {
        service.addSource(fileId, peerId);
        return ResponseEntity.noContent().build();
    }

    @ExceptionHandler({IllegalArgumentException.class, java.util.NoSuchElementException.class})
    public ResponseEntity<Map<String, String>> handle(RuntimeException error) {
        return ResponseEntity.badRequest().body(Map.of("error", error.getMessage()));
    }
}
