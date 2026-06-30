package com.example.servidortarefasp2p.controller;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

@Controller
public class TarefaController {
    @MessageMapping("/atualizar-tarefa")
    @SendTo ("/topic/tarefas")

    public String sincromizarTarefa(String tarefaJosn){

        System.out.println("Nova Atualização recebida na rede: " + tarefaJosn);
        return tarefaJosn;
    }
}
