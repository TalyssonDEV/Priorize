package com.example.servidortarefasp2p.coordination.repository;
import com.example.servidortarefasp2p.coordination.entity.TaskAttachmentEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface TaskAttachmentRepository extends JpaRepository<TaskAttachmentEntity, String> {
    List<TaskAttachmentEntity> findByTaskIdOrderByCreatedAt(String taskId);
    List<TaskAttachmentEntity> findByUploadedBy(String userId);
    void deleteByTaskId(String taskId);
    void deleteByRoomId(String roomId);
}
