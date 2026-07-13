package com.example.servidortarefasp2p.coordination.model;
import java.time.Instant;
public record TaskAttachmentInfo(String fileId, String taskId, String roomId, String fileName,
        long fileSize, String sha256, String ownerPeerId, String uploadedBy, Instant createdAt) { }
