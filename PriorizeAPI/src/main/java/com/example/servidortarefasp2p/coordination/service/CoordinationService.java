package com.example.servidortarefasp2p.coordination.service;

import com.example.servidortarefasp2p.coordination.entity.*;
import com.example.servidortarefasp2p.coordination.model.*;
import com.example.servidortarefasp2p.coordination.repository.*;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class CoordinationService {
    private final Map<String, PeerInfo> peers = new ConcurrentHashMap<>();
    private final Map<String, SharedFileMetadata> files = new ConcurrentHashMap<>();
    private final Map<String, Set<String>> fileSources = new ConcurrentHashMap<>();
    private final SimpMessagingTemplate messagingTemplate;
    private final RoomRepository roomRepository;
    private final RoomMemberRepository memberRepository;
    private final SharedTaskRepository taskRepository;
    private final TaskAttachmentRepository attachmentRepository;

    public CoordinationService(SimpMessagingTemplate messagingTemplate, RoomRepository roomRepository,
                               RoomMemberRepository memberRepository, SharedTaskRepository taskRepository,
                               TaskAttachmentRepository attachmentRepository) {
        this.messagingTemplate = messagingTemplate;
        this.roomRepository = roomRepository;
        this.memberRepository = memberRepository;
        this.taskRepository = taskRepository;
        this.attachmentRepository = attachmentRepository;
    }

    @Transactional
    public RoomInfo createRoom(String name, String leaderUserId, String leaderName) {
        String roomId;
        do roomId = UUID.randomUUID().toString().substring(0, 6).toUpperCase(Locale.ROOT);
        while (roomRepository.existsById(roomId));
        RoomEntity room = roomRepository.save(new RoomEntity(roomId, requireText(name, "Nome da sala"),
                requireText(leaderUserId, "ID do líder"), requireText(leaderName, "Nome do líder")));
        memberRepository.save(new RoomMemberEntity(roomId, leaderUserId.trim(), leaderName.trim(), "LEADER"));
        publish("ROOM_CREATED", roomId, toSummary(room, "LEADER"));
        return new RoomInfo(room.getRoomId(), room.getName(), room.getLeaderName());
    }

    public RoomInfo getRoom(String roomId) {
        RoomEntity room = requireRoom(roomId);
        return new RoomInfo(room.getRoomId(), room.getName(), room.getLeaderName());
    }

    public List<RoomSummary> roomsForUser(String userId) {
        return memberRepository.findByUserIdOrderByJoinedAtDesc(requireText(userId, "Usuário")).stream()
                .map(member -> roomRepository.findById(member.getRoomId())
                        .map(room -> toSummary(room, member.getRole())).orElse(null))
                .filter(Objects::nonNull).toList();
    }

    @Transactional
    public RoomSummary joinRoom(String roomId, String userId, String userName) {
        RoomEntity room = requireRoom(roomId);
        RoomMemberEntity member = memberRepository.findByRoomIdAndUserId(room.getRoomId(), userId)
                .orElseGet(() -> memberRepository.save(new RoomMemberEntity(room.getRoomId(),
                        requireText(userId, "Usuário"), requireText(userName, "Nome"), "MEMBER")));
        RoomSummary summary = toSummary(room, member.getRole());
        publish("MEMBER_JOINED", room.getRoomId(), summary);
        return summary;
    }

    public List<RoomMemberEntity> members(String roomId) {
        requireRoom(roomId);
        return memberRepository.findByRoomIdOrderByJoinedAt(normalizeRoom(roomId));
    }

    @Transactional
    public boolean leaveRoom(String roomId, String userId) {
        String normalized = normalizeRoom(roomId);
        RoomEntity room = requireRoom(normalized);
        RoomMemberEntity member = memberRepository.findByRoomIdAndUserId(normalized, userId)
                .orElseThrow(() -> new NoSuchElementException("Usuário não pertence à sala"));
        memberRepository.delete(member);
        publish("MEMBER_LEFT", normalized, Map.of("userId", userId));
        if (memberRepository.countByRoomId(normalized) == 0) {
            taskRepository.deleteByRoomId(normalized);
            attachmentRepository.deleteByRoomId(normalized);
            roomRepository.delete(room);
            publish("ROOM_DELETED", normalized, Map.of("reason", "EMPTY"));
            return true;
        }
        return false;
    }

    @Transactional
    public void deleteRoom(String roomId, String requestedBy) {
        RoomEntity room = requireRoom(roomId);
        if (!room.getLeaderUserId().equals(requestedBy)) throw new IllegalArgumentException("Somente o líder pode excluir a sala");
        taskRepository.deleteByRoomId(room.getRoomId());
        attachmentRepository.deleteByRoomId(room.getRoomId());
        memberRepository.deleteByRoomId(room.getRoomId());
        roomRepository.delete(room);
        publish("ROOM_DELETED", room.getRoomId(), Map.of("reason", "LEADER"));
    }

    public PeerInfo registerPeer(PeerInfo input) {
        String roomId = normalizeRoom(input.roomId());
        requireRoom(roomId);
        String userId = input.userId() == null || input.userId().isBlank() ? input.peerId() : input.userId();
        joinRoom(roomId, userId, input.userName());
        PeerInfo peer = new PeerInfo(requireText(input.peerId(), "Peer ID"), userId, roomId,
                requireText(input.userName(), "Nome do usuário"), requireText(input.ipAddress(), "IP"),
                input.p2pPort(), true, Instant.now());
        if (peer.p2pPort() < 1 || peer.p2pPort() > 65535) throw new IllegalArgumentException("Porta P2P inválida");
        peers.put(peer.peerId(), peer);
        attachmentRepository.findByUploadedBy(userId).stream()
                .filter(attachment -> attachment.getRoomId().equals(roomId))
                .forEach(attachment -> {
                    SharedFileMetadata file = new SharedFileMetadata(attachment.getFileId(), attachment.getRoomId(),
                            attachment.getFileName(), attachment.getFileSize(), attachment.getSha256(),
                            peer.peerId(), attachment.getCreatedAt());
                    files.put(file.fileId(), file);
                    fileSources.computeIfAbsent(file.fileId(), ignored -> ConcurrentHashMap.newKeySet()).add(peer.peerId());
                });
        publish("PEER_JOINED", roomId, peer);
        return peer;
    }

    public List<PeerInfo> participants(String roomId) {
        String normalized = normalizeRoom(roomId);
        return peers.values().stream().filter(p -> p.connected() && p.roomId().equals(normalized)).toList();
    }

    public void removePeer(String peerId) {
        PeerInfo old = peers.remove(peerId);
        if (old == null) return;
        fileSources.values().forEach(sources -> sources.remove(peerId));
        publish("PEER_LEFT", old.roomId(), old);
    }

    public List<SharedTaskInfo> tasks(String roomId, String userId) {
        requireMembership(roomId, userId);
        return taskRepository.findByRoomIdOrderByCreatedAtDesc(normalizeRoom(roomId)).stream().map(this::toTask).toList();
    }

    public SharedTaskInfo createTask(String roomId, String userId, String userName, SharedTaskInfo input) {
        requireMembership(roomId, userId);
        SharedTaskEntity entity = taskRepository.save(new SharedTaskEntity(
                UUID.randomUUID().toString(), normalizeRoom(roomId), requireText(input.title(), "Título"),
                input.description() == null ? "" : input.description().trim(), normalizePriority(input.priority()),
                userId, requireText(userName, "Nome do criador")));
        SharedTaskInfo task = toTask(entity);
        publish("TASK_CREATED", entity.getRoomId(), task);
        return task;
    }

    @Transactional
    public SharedTaskInfo updateTask(String roomId, String taskId, String userId, SharedTaskInfo input) {
        requireMembership(roomId, userId);
        SharedTaskEntity entity = requireTask(roomId, taskId);
        entity.update(requireText(input.title(), "Título"), input.description() == null ? "" : input.description().trim(),
                normalizePriority(input.priority()), input.completed());
        SharedTaskInfo task = toTask(taskRepository.save(entity));
        publish("TASK_UPDATED", entity.getRoomId(), task);
        return task;
    }

    @Transactional
    public void deleteTask(String roomId, String taskId, String userId) {
        requireMembership(roomId, userId);
        SharedTaskEntity entity = requireTask(roomId, taskId);
        attachmentRepository.findByTaskIdOrderByCreatedAt(taskId).forEach(attachment -> {
            files.remove(attachment.getFileId());
            fileSources.remove(attachment.getFileId());
        });
        attachmentRepository.deleteByTaskId(taskId);
        taskRepository.delete(entity);
        publish("TASK_DELETED", entity.getRoomId(), Map.of("taskId", taskId));
    }

    public TaskAttachmentInfo registerTaskAttachment(String roomId, String taskId, String userId,
                                                       SharedFileMetadata input) {
        requireMembership(roomId, userId);
        requireTask(roomId, taskId);
        PeerInfo owner = requirePeer(input.ownerPeerId());
        if (!owner.roomId().equals(normalizeRoom(roomId))) throw new IllegalArgumentException("Peer não pertence à sala");
        TaskAttachmentEntity entity = attachmentRepository.save(new TaskAttachmentEntity(
                requireText(input.fileId(), "File ID"), taskId, normalizeRoom(roomId),
                requireText(input.fileName(), "Nome do arquivo"), input.fileSize(),
                requireText(input.sha256(), "SHA-256").toLowerCase(Locale.ROOT), owner.peerId(), userId));
        SharedFileMetadata file = new SharedFileMetadata(entity.getFileId(), entity.getRoomId(), entity.getFileName(),
                entity.getFileSize(), entity.getSha256(), entity.getOwnerPeerId(), entity.getCreatedAt());
        files.put(file.fileId(), file);
        fileSources.computeIfAbsent(file.fileId(), ignored -> ConcurrentHashMap.newKeySet()).add(owner.peerId());
        TaskAttachmentInfo result = toAttachment(entity);
        publish("ATTACHMENT_ADDED", entity.getRoomId(), result);
        return result;
    }

    public List<TaskAttachmentInfo> taskAttachments(String roomId, String taskId, String userId) {
        requireMembership(roomId, userId);
        requireTask(roomId, taskId);
        return attachmentRepository.findByTaskIdOrderByCreatedAt(taskId).stream().map(this::toAttachment).toList();
    }

    public SharedFileMetadata registerFile(SharedFileMetadata input) {
        requireRoom(input.roomId());
        PeerInfo owner = requirePeer(input.ownerPeerId());
        if (!owner.roomId().equals(normalizeRoom(input.roomId()))) throw new IllegalArgumentException("Peer não pertence à sala");
        SharedFileMetadata file = new SharedFileMetadata(requireText(input.fileId(), "File ID"), owner.roomId(),
                requireText(input.fileName(), "Nome do arquivo"), input.fileSize(),
                requireText(input.sha256(), "SHA-256").toLowerCase(Locale.ROOT), owner.peerId(), Instant.now());
        if (file.fileSize() < 0) throw new IllegalArgumentException("Tamanho inválido");
        files.put(file.fileId(), file);
        fileSources.computeIfAbsent(file.fileId(), ignored -> ConcurrentHashMap.newKeySet()).add(owner.peerId());
        publish("FILE_AVAILABLE", file.roomId(), file);
        return file;
    }

    public List<SharedFileMetadata> filesInRoom(String roomId) {
        String normalized = normalizeRoom(roomId);
        return files.values().stream().filter(f -> f.roomId().equals(normalized)).toList();
    }

    public List<FileSourceInfo> sources(String fileId) {
        if (!files.containsKey(fileId)) throw new NoSuchElementException("Arquivo não encontrado");
        return fileSources.getOrDefault(fileId, Set.of()).stream().map(peers::get).filter(Objects::nonNull)
                .filter(PeerInfo::connected).map(p -> new FileSourceInfo(p.peerId(), p.userName(), p.ipAddress(), p.p2pPort())).toList();
    }

    public void addSource(String fileId, String peerId) {
        SharedFileMetadata file = files.get(fileId);
        if (file == null) throw new NoSuchElementException("Arquivo não encontrado");
        PeerInfo peer = requirePeer(peerId);
        if (!peer.roomId().equals(file.roomId())) throw new IllegalArgumentException("Peer não pertence à sala do arquivo");
        fileSources.computeIfAbsent(fileId, ignored -> ConcurrentHashMap.newKeySet()).add(peerId);
        publish("FILE_SOURCE_ADDED", file.roomId(), Map.of("fileId", fileId, "peerId", peerId));
    }

    private RoomEntity requireRoom(String roomId) {
        return roomRepository.findById(normalizeRoom(roomId)).orElseThrow(() -> new NoSuchElementException("Sala não encontrada"));
    }
    private void requireMembership(String roomId, String userId) {
        if (memberRepository.findByRoomIdAndUserId(normalizeRoom(roomId), requireText(userId, "Usuário")).isEmpty())
            throw new IllegalArgumentException("Usuário não pertence à sala");
    }
    private SharedTaskEntity requireTask(String roomId, String taskId) {
        SharedTaskEntity task = taskRepository.findById(taskId).orElseThrow(() -> new NoSuchElementException("Tarefa não encontrada"));
        if (!task.getRoomId().equals(normalizeRoom(roomId))) throw new IllegalArgumentException("Tarefa não pertence à sala");
        return task;
    }
    private PeerInfo requirePeer(String peerId) {
        PeerInfo peer = peers.get(peerId);
        if (peer == null) throw new NoSuchElementException("Peer não encontrado");
        return peer;
    }
    private RoomSummary toSummary(RoomEntity room, String role) {
        return new RoomSummary(room.getRoomId(), room.getName(), room.getLeaderUserId(), room.getLeaderName(), role, room.getCreatedAt());
    }
    private SharedTaskInfo toTask(SharedTaskEntity task) {
        return new SharedTaskInfo(task.getTaskId(), task.getRoomId(), task.getTitle(), task.getDescription(),
                task.getPriority(), task.isCompleted(), task.getCreatedBy(), task.getCreatedByName(), task.getCreatedAt(), task.getUpdatedAt());
    }
    private TaskAttachmentInfo toAttachment(TaskAttachmentEntity file) {
        return new TaskAttachmentInfo(file.getFileId(), file.getTaskId(), file.getRoomId(), file.getFileName(),
                file.getFileSize(), file.getSha256(), file.getOwnerPeerId(), file.getUploadedBy(), file.getCreatedAt());
    }
    private void publish(String type, String roomId, Object data) {
        messagingTemplate.convertAndSend("/topic/rooms/" + roomId, CoordinationEvent.of(type, roomId, data));
    }
    private static String normalizePriority(String value) {
        String priority = requireText(value, "Prioridade").toUpperCase(Locale.ROOT);
        if (!Set.of("HIGH", "MEDIUM", "LOW").contains(priority)) throw new IllegalArgumentException("Prioridade inválida");
        return priority;
    }
    private static String normalizeRoom(String roomId) { return requireText(roomId, "Sala").toUpperCase(Locale.ROOT); }
    private static String requireText(String value, String field) {
        if (value == null || value.isBlank()) throw new IllegalArgumentException(field + " é obrigatório");
        return value.trim();
    }
}
