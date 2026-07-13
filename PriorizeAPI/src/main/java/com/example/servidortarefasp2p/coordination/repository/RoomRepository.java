package com.example.servidortarefasp2p.coordination.repository;
import com.example.servidortarefasp2p.coordination.entity.RoomEntity;
import org.springframework.data.jpa.repository.JpaRepository;
public interface RoomRepository extends JpaRepository<RoomEntity, String> { }
