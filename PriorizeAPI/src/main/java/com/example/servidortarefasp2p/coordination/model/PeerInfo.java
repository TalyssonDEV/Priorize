package com.example.servidortarefasp2p.coordination.model;

import java.time.Instant;

public record PeerInfo(
        String peerId,
        String userId,
        String roomId,
        String userName,
        String ipAddress,
        int p2pPort,
        boolean connected,
        Instant lastSeen) {
}
