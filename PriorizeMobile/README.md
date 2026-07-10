# 🗂️ Priorize

## 📑 Sumário

1. [⚠️ O Problema](#1️-⚠️-o-problema)  
2. [✨ A Solução](#2️-✨-a-solução)  
3. [🎯 Público Alvo](#3️-🎯-público-alvo)  
4. [🔗 Links Úteis](#4️-🔗-links-úteis)  
5. [👥 Equipe](#5️-👥-equipe)

---

## 1️ ⚠️ O Problema

Muitas pessoas enfrentam dificuldades em organizar suas tarefas diárias de forma eficiente, especialmente quando precisam lidar com múltiplas responsabilidades em diferentes áreas da vida — como **trabalho**, **estudos** e **vida pessoal**.

A ausência de um sistema simples e intuitivo para **categorizar**, **priorizar** e **acompanhar o progresso** das tarefas pode levar à procrastinação, perda de prazos e aumento do estresse.

---

## 2️ ✨ A Solução

O **Priorize** é um aplicativo multiplataforma desenvolvido com **Flutter**, que oferece uma forma prática e visual de organizar tarefas por **categoria** e **prioridade**.

### 🔧 Funcionalidades principais:

- ✅ Cadastro e gerenciamento de tarefas com título, descrição, data e prioridade  
- 🗂 Organização por categorias personalizáveis (ex: Casa, Trabalho, Estudos)  
- 🎚 Filtros por prioridade para facilitar o foco no que é mais importante  
- ☑ Marcação de tarefas como concluídas com apenas um toque  
- 💾 Armazenamento local com persistência de dados via Hive (compatível com Web e Mobile)  
- 🖥 Interface leve, responsiva e intuitiva  

> Com arquitetura baseada em `ViewModel`, `Service` e `Repository`, o Priorize é fácil de manter, escalar e adaptar a diferentes necessidades.

---

## 3️ 🎯 Público Alvo

- 👨‍🎓 **Estudantes** que precisam organizar suas atividades acadêmicas por disciplina e urgência  
- 👩‍💻 **Profissionais autônomos ou em home office** que buscam gerenciar tarefas pessoais e de trabalho  
- 🧠 **Usuários em geral** que desejam uma ferramenta simples para aumentar sua produtividade diária

---

## 4️ 🔗 Links Úteis

- 📽️ [Vídeo de Apresentação (em breve)](https://github.com/PriorizeApp)  
- 📘 [Manual do Usuário (em breve)](https://github.com/PriorizeApp)  
- 🧑‍💻 [Repositório GitHub](https://github.com/PriorizeApp)

---

## 5️ 👥 Equipe

<table>
  <tr>
    <td align="center">
      <img src="https://avatars.githubusercontent.com/u/68722672?v=4" width="100px;" alt="João Victor Silva de Hungria"/><br />
      <sub><b>João Victor Silva de Hungria</b></sub><br />
      <sub>Desenvolvedor</sub>
    </td>
    <td align="center">
      <img src="https://avatars.githubusercontent.com/u/105181008?v=4" width="100px;" alt="Talysson Felipe Vasconcelos Santos"/><br />
      <sub><b>Talysson Felipe Vasconcelos Santos</b></sub><br />
      <sub>Desenvolvedor</sub>
    </td>
  </tr>
</table>

---

> 🧩 Projeto desenvolvido com foco em **organização pessoal**, **produtividade** e **simplicidade** no gerenciamento de tarefas.

---

## MVP P2P híbrido — Sistemas Distribuídos

O projeto inclui uma demonstração acadêmica de compartilhamento de arquivos em rede local. O Spring Boot atua somente como coordenador: cria salas, registra peers, guarda metadados e informa quais peers possuem um arquivo. Os bytes não passam pelo Spring Boot.

As salas e tarefas compartilhadas agora são persistidas pelo Spring Boot em um banco H2 local. Cada instalação possui um `userId` estável salvo no Hive, pode pertencer a várias salas e pode criar ou concluir tarefas compartilhadas com título, descrição e prioridade. Estar offline não remove a associação à sala; sair da sala é uma ação distinta.

Dentro da sala, a interface segue o mesmo padrão visual da lista local de tarefas: progresso, participantes online, estado vazio, cards e botão **Nova Tarefa**. O formulário aceita título, descrição, prioridade e um arquivo opcional. Os metadados do anexo ficam associados ao `taskId` no H2; ao tocar no card, os detalhes exibem o arquivo com ação de download P2P.

O banco de desenvolvimento é criado em `PriorizeAPI/data/` quando o backend é iniciado. A estrutura é atualizada automaticamente pelo JPA/Hibernate.

Cada Android executa um servidor TCP Java e também pode atuar como cliente TCP:

```text
Peer A (Flutter + Java) <-- metadados/WebSocket --> Spring Boot
       ^                                            ^
       | arquivo via Socket TCP direto              | metadados/WebSocket
       v                                            v
Peer B (Flutter + Java) -----------------------------
```

### Conceitos de SD demonstrados

- Arquitetura P2P híbrida;
- `ServerSocket` e `Socket` TCP;
- `DataInputStream` e `DataOutputStream`;
- protocolo de aplicação com comandos UTF;
- transferência binária em blocos de 8192 bytes;
- concorrência com `ExecutorService` e pool fixo;
- estruturas concorrentes em memória;
- descoberta de peers por um coordenador;
- validação de integridade com SHA-256;
- cada peer atua como cliente e servidor;
- um peer que baixa passa a ser uma nova fonte.
- serviço Android em primeiro plano mantém o servidor TCP disponível com o aplicativo minimizado;
- arquivos recebidos são publicados em `Downloads/Priorize` e podem ser abertos pela própria tela.

### Protocolo TCP

Comandos: `GET_FILE`, `FILE_INFO`, `FILE_DATA`, `FILE_NOT_FOUND`, `TRANSFER_COMPLETE` e `TRANSFER_ERROR`.

O cliente envia `GET_FILE` e o identificador. O servidor responde com nome, tamanho e SHA-256, envia exatamente o número informado de bytes e finaliza com `TRANSFER_COMPLETE`. O receptor grava primeiro em `.part`, valida o hash e somente então finaliza o arquivo.

### Executar o coordenador

Requisito: JDK 17 ou superior.

```powershell
cd PriorizeAPI
.\mvnw.cmd spring-boot:run
```

Se o wrapper não funcionar no PowerShell local, execute com uma instalação Maven:

```powershell
mvn spring-boot:run
```

Descubra o IPv4 do computador com `ipconfig` e libere a porta TCP 8080 no firewall para a rede privada.

### Executar o Android

```powershell
cd PriorizeMobile
flutter pub get
flutter run
```

Abra **Salas P2P** pelo ícone de pasta compartilhada. Informe o IP do computador sem `http://` e sem porta, por exemplo `192.168.0.10`.

### Roteiro de demonstração com dois celulares

1. Conecte computador e celulares ao mesmo Wi-Fi.
2. Inicie o Spring Boot no computador.
3. Abra Salas P2P no celular A e crie uma sala.
4. Digite o código mostrado no celular B e entre.
5. Confirme que os dois nomes e portas P2P aparecem.
6. No celular A, selecione um arquivo em **Compartilhar**.
7. Confirme que o arquivo aparece no B sem ter sido enviado ao Spring.
8. No celular B, toque em download.
9. Observe no Logcat, filtrando por `PriorizeP2P`, a conexão, a thread e os bytes enviados.
10. Confirme a mensagem de SHA-256 validado.
11. Observe o evento `FILE_SOURCE_ADDED`: o celular B agora também é uma fonte.

Para confirmar que o arquivo não passou pelo backend, observe que a API não possui `MultipartFile`, endpoint de upload/download ou diretório de arquivos. Nos logs Spring aparecem apenas registros JSON; os logs Android mostram o endereço do peer remoto e a transferência TCP.

### Limitações do MVP

- somente Android;
- computador e peers na mesma rede Wi-Fi;
- sem NAT traversal e sem internet;
- coordenador em memória, reiniciar o Spring apaga salas e metadados;
- sem autenticação, criptografia, retomada ou download em partes;
- indicador simples de transferência, sem `EventChannel` de progresso;
- indicado para dois ou três peers e arquivos moderados;
- o Android pode encerrar o serviço se o usuário forçar a parada do aplicativo ou aplicar restrições severas de bateria.
