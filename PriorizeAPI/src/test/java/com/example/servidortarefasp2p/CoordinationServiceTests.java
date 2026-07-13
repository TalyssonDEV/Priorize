package com.example.servidortarefasp2p;

import com.example.servidortarefasp2p.coordination.model.*;
import com.example.servidortarefasp2p.coordination.service.CoordinationService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class CoordinationServiceTests {
    @Autowired CoordinationService service;

    @Test
    void tarefasESalasSaoCompartilhadasEntreMembros() {
        String roomId = service.createRoom("Sala persistente", "user-a", "Ana").roomId();
        service.joinRoom(roomId, "user-b", "Bruno");
        SharedTaskInfo created = service.createTask(roomId, "user-a", "Ana",
                new SharedTaskInfo(null, roomId, "Preparar slides", "Arquitetura P2P", "HIGH",
                        false, null, null, null, null));

        assertEquals(1, service.tasks(roomId, "user-b").size());
        assertEquals("Preparar slides", created.title());
        assertEquals(1, service.roomsForUser("user-b").size());
    }

    @Test
    void peerQueRecebeArquivoViraNovaFonte() {
        String roomId = service.createRoom("Sala de arquivo", "user-c", "Carla").roomId();
        service.registerPeer(new PeerInfo("peer-c", "user-c", roomId, "Carla", "192.168.0.10", 41000, true, null));
        service.registerPeer(new PeerInfo("peer-d", "user-d", roomId, "Davi", "192.168.0.11", 42000, true, null));
        service.registerFile(new SharedFileMetadata("file-test", roomId, "aula.pdf", 1024,
                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "peer-c", null));

        assertEquals(1, service.sources("file-test").size());
        service.addSource("file-test", "peer-d");
        assertEquals(2, service.sources("file-test").size());
    }
}
