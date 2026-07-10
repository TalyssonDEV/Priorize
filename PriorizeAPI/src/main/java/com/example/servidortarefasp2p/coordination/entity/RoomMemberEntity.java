package com.example.servidortarefasp2p.coordination.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "room_members", uniqueConstraints = @UniqueConstraint(columnNames = {"roomId", "userId"}))
public class RoomMemberEntity {
    @Id private String id;
    @Column(nullable = false, length = 6) private String roomId;
    @Column(nullable = false, length = 80) private String userId;
    @Column(nullable = false, length = 80) private String userName;
    @Column(nullable = false, length = 12) private String role;
    @Column(nullable = false) private Instant joinedAt;

    protected RoomMemberEntity() { }
    public RoomMemberEntity(String roomId, String userId, String userName, String role) {
        this.id = UUID.randomUUID().toString(); this.roomId = roomId; this.userId = userId;
        this.userName = userName; this.role = role; this.joinedAt = Instant.now();
    }
    public String getId() { return id; }
    public String getRoomId() { return roomId; }
    public String getUserId() { return userId; }
    public String getUserName() { return userName; }
    public String getRole() { return role; }
    public Instant getJoinedAt() { return joinedAt; }
}
