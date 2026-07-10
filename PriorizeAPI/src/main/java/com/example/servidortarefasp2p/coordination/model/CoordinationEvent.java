package com.example.servidortarefasp2p.coordination.model;

import java.time.Instant;

public record CoordinationEvent(String type, String roomId, Object data, Instant occurredAt) {
    public static CoordinationEvent of(String type, String roomId, Object data) {
        return new CoordinationEvent(type, roomId, data, Instant.now());
    }
}
