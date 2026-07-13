package com.example.servidortarefasp2p.coordination.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "rooms")
public class RoomEntity {
    @Id @Column(length = 6) private String roomId;
    @Column(nullable = false, length = 80) private String name;
    @Column(nullable = false, length = 80) private String leaderUserId;
    @Column(nullable = false, length = 80) private String leaderName;
    @Column(nullable = false) private Instant createdAt;

    protected RoomEntity() { }
    public RoomEntity(String roomId, String name, String leaderUserId, String leaderName) {
        this.roomId = roomId; this.name = name; this.leaderUserId = leaderUserId;
        this.leaderName = leaderName; this.createdAt = Instant.now();
    }
    public String getRoomId() { return roomId; }
    public String getName() { return name; }
    public String getLeaderUserId() { return leaderUserId; }
    public String getLeaderName() { return leaderName; }
    public Instant getCreatedAt() { return createdAt; }
}
