package com.example.servidortarefasp2p.coordination.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "shared_tasks")
public class SharedTaskEntity {
    @Id private String taskId;
    @Column(nullable = false, length = 6) private String roomId;
    @Column(nullable = false, length = 100) private String title;
    @Column(nullable = false, length = 500) private String description;
    @Column(nullable = false, length = 10) private String priority;
    @Column(nullable = false) private boolean completed;
    @Column(nullable = false, length = 80) private String createdBy;
    @Column(nullable = false, length = 80) private String createdByName;
    @Column(nullable = false) private Instant createdAt;
    @Column(nullable = false) private Instant updatedAt;

    protected SharedTaskEntity() { }
    public SharedTaskEntity(String taskId, String roomId, String title, String description,
                            String priority, String createdBy, String createdByName) {
        this.taskId = taskId; this.roomId = roomId; this.title = title; this.description = description;
        this.priority = priority; this.createdBy = createdBy; this.createdByName = createdByName;
        this.createdAt = Instant.now(); this.updatedAt = this.createdAt;
    }
    public void update(String title, String description, String priority, boolean completed) {
        this.title = title; this.description = description; this.priority = priority;
        this.completed = completed; this.updatedAt = Instant.now();
    }
    public String getTaskId() { return taskId; }
    public String getRoomId() { return roomId; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public String getPriority() { return priority; }
    public boolean isCompleted() { return completed; }
    public String getCreatedBy() { return createdBy; }
    public String getCreatedByName() { return createdByName; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
