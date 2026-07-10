package com.example.servidortarefasp2p.coordination.model;
import java.time.Instant;
public record RoomSummary(String roomId, String name, String leaderUserId, String leaderName,
                          String memberRole, Instant createdAt) { }
