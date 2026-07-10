package com.example.servidortarefasp2p.coordination.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "task_attachments")
public class TaskAttachmentEntity {
    @Id private String fileId;
    @Column(nullable = false) private String taskId;
    @Column(nullable = false, length = 6) private String roomId;
    @Column(nullable = false) private String fileName;
    @Column(nullable = false) private long fileSize;
    @Column(nullable = false, length = 64) private String sha256;
    @Column(nullable = false) private String ownerPeerId;
    @Column(nullable = false) private String uploadedBy;
    @Column(nullable = false) private Instant createdAt;

    protected TaskAttachmentEntity() { }
    public TaskAttachmentEntity(String fileId, String taskId, String roomId, String fileName, long fileSize,
                                String sha256, String ownerPeerId, String uploadedBy) {
        this.fileId = fileId; this.taskId = taskId; this.roomId = roomId; this.fileName = fileName;
        this.fileSize = fileSize; this.sha256 = sha256; this.ownerPeerId = ownerPeerId;
        this.uploadedBy = uploadedBy; this.createdAt = Instant.now();
    }
    public String getFileId() { return fileId; }
    public String getTaskId() { return taskId; }
    public String getRoomId() { return roomId; }
    public String getFileName() { return fileName; }
    public long getFileSize() { return fileSize; }
    public String getSha256() { return sha256; }
    public String getOwnerPeerId() { return ownerPeerId; }
    public String getUploadedBy() { return uploadedBy; }
    public Instant getCreatedAt() { return createdAt; }
}
