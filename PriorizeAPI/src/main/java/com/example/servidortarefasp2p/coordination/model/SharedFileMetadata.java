package com.example.servidortarefasp2p.coordination.model;

import java.time.Instant;

public record SharedFileMetadata(
        String fileId,
        String roomId,
        String fileName,
        long fileSize,
        String sha256,
        String ownerPeerId,
        Instant createdAt) {
}
