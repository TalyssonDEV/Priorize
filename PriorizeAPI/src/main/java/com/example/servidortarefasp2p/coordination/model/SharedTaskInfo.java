package com.example.servidortarefasp2p.coordination.model;
import java.time.Instant;
public record SharedTaskInfo(String taskId, String roomId, String title, String description,
        String priority, boolean completed, String createdBy, String createdByName,
        Instant createdAt, Instant updatedAt) { }
