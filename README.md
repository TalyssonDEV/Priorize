# Priorize — P2P Híbrido Corporativo

## Comunicação Segura e Gestão de Tarefas para sua Empresa

O **Priorize** é uma plataforma de P2P híbrido desenvolvida especificamente para empresas que desejam manter a comunicação e a gestão de tarefas entre seus funcionários de forma segura e direta, sem depender de uma conexão de internet externa para as transferências de arquivos mais pesadas.

Este software resolve o desafio comum em ambientes corporativos onde o acesso Wi-Fi à internet é restrito ou difícil de obter, permitindo que a equipe colabore de forma eficiente e segura, mantendo todos os dados críticos dentro do perímetro da rede local da empresa.

---

## Recursos Principais (Features)
<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/020dc946-b7cf-4c0b-8c3e-ece96045e34b" width="180" alt="Imagem 1">
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/33dfa790-ee6a-4fd1-a3a7-9666a50e58b2" width="180" alt="Imagem 2">
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/2a59d867-bdb8-4b42-b1b5-09caf06add1f" width="180" alt="Imagem 3">
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/ced08318-8718-49ad-af0f-59d1616c857d" width="180" alt="Imagem 4">
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/396440cd-b09f-417d-807b-0ee84a6782ad" width="180" alt="Imagem 5">
    </td>
  </tr>
</table>

*   **Gestão de Tarefas Híbrida:** Crie tarefas pessoais e de equipe que funcionam perfeitamente sem conexão com a internet, sincronizando quando houver rede local disponível.
*   **Salas Privadas de Tarefas:** Crie salas de chat privadas vinculadas a tarefas específicas para discussões diretas e contextuais com colegas de departamento ou equipe de projeto.
*   **Envio de Arquivos P2P (Local):** Compartilhe documentos diretamente entre dispositivos na rede local da empresa (LAN/Wi-Fi local).
    *   **Formatos Suportados:** Áudio, documentos DOCX, PDFs e mais.
*   **Arquitetura Dispositivo-Servidor:** Quando um arquivo é enviado, o dispositivo do remetente se torna temporariamente um servidor, garantindo que os dados permaneçam dentro da rede local.
*   **Segurança Corporativa:** Os dados de chat e arquivos nunca saem da rede local da empresa para nuvens públicas, minimizando o risco de vazamentos externos.

---

## Arquitetura P2P Híbrida Corporativa

O **Priorize** utiliza uma arquitetura híbrida projetada para superar restrições de rede.

Visualize a interface principal do aplicativo na imagem_94cdc7.png, onde é possível gerenciar tarefas e acessar as salas de chat corporativas.

### Como Funciona:

1.  **Modo Offline:** O gerenciamento de tarefas pessoais e a redação de mensagens de chat funcionam localmente no dispositivo, mesmo sem conexão de rede.
2.  **Conexão de Rede Local (LAN):** Para compartilhar arquivos e sincronizar chats de sala, o Priorize (ou P2P Connect) utiliza a rede corporativa local (LAN/Wi-Fi local).
3.  **Compartilhamento de Arquivos P2P:** Quando você envia um arquivo para uma sala:
    *   O aplicativo localiza os destinatários na rede local.
    *   O seu dispositivo **se torna um servidor temporário** para esse arquivo.
    *   Os outros dispositivos baixam o arquivo **diretamente do seu dispositivo**, sem passar por um servidor central na nuvem.

Isso resolve o problema de Wi-Fi restrito, pois os arquivos nunca tentam acessar a internet pública; eles viajam apenas dentro da infraestrutura de rede local da empresa.

---

## Pré-requisitos e Instalação (Instruções Gerais)

### Pré-requisitos de Rede:

*   Dispositivos devem estar na mesma rede local (LAN) da empresa.
*   Permissão de rede para tráfego P2P local (tráfego direto entre dispositivos).

### Instalação (Para Desenvolvedores/Administradores de TI):

1.  Clone o repositório.
    ```bash
    git clone [https://github.com/TalyssonDEV/Priorize]
    ```
2.  Siga as instruções de build e implantação para a plataforma desejada (Android/iOS/Desktop).
3.  Para implantação corporativa, verifique os guias de configuração de rede para garantir o tráfego P2P.


## Licença

Copyright © 2024. Priorize. Todos os direitos reservados.
Licensed under the [MIT License](LICENSE).
