package com.example.servidortarefasp2p.coordination.repository;
import com.example.servidortarefasp2p.coordination.entity.SharedTaskEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface SharedTaskRepository extends JpaRepository<SharedTaskEntity, String> {
    List<SharedTaskEntity> findByRoomIdOrderByCreatedAtDesc(String roomId);
    void deleteByRoomId(String roomId);
}
