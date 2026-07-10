package com.example.servidortarefasp2p.coordination.repository;
import com.example.servidortarefasp2p.coordination.entity.RoomMemberEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface RoomMemberRepository extends JpaRepository<RoomMemberEntity, String> {
    List<RoomMemberEntity> findByUserIdOrderByJoinedAtDesc(String userId);
    List<RoomMemberEntity> findByRoomIdOrderByJoinedAt(String roomId);
    Optional<RoomMemberEntity> findByRoomIdAndUserId(String roomId, String userId);
    long countByRoomId(String roomId);
    void deleteByRoomId(String roomId);
}
