# Manual de execução e demonstração — Priorize P2P

## 1. Arquitetura

- `PriorizeAPI`: Spring Boot, H2, REST e WebSocket para salas, membros, tarefas e metadados.
- `PriorizeMobile`: Flutter para interface e estado local.
- Android Java: `ServerSocket`, `Socket`, protocolo binário, `ExecutorService` e SHA-256.
- Os bytes dos anexos trafegam diretamente entre os aparelhos; o Spring não recebe arquivos.

## 2. Iniciar o servidor pelo VS Code

1. Abra a pasta `Priorize` no VS Code.
2. Abra `PriorizeAPI/src/main/java/com/example/servidortarefasp2p/ServidorTarefasP2pApplication.java`.
3. Clique em **Run** acima do método `main`.
4. Aguarde `Started ServidorTarefasP2pApplication`.

Alternativa pelo terminal:

```powershell
cd C:\Users\Iago\Desktop\Priorize\PriorizeAPI
mvn spring-boot:run
```

O banco persistente é criado em `PriorizeAPI/data/` ou `data/`, conforme o diretório de execução. Ambas as pastas estão ignoradas pelo Git.

## 3. Descobrir o IP e testar a rede

```powershell
ipconfig
Test-NetConnection localhost -Port 8080
```

Use o IPv4 do adaptador Wi-Fi, por exemplo `192.168.0.10`. No navegador do celular, abra:

```text
http://192.168.0.10:8080/teste-websocket.html
```

## 4. Compilar e instalar o Android

```powershell
cd C:\Users\Iago\Desktop\Priorize\PriorizeMobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

APK:

```text
PriorizeMobile/build/app/outputs/flutter-apk/app-debug.apk
```

Instalação por ADB:

```powershell
adb devices
adb install -r .\build\app\outputs\flutter-apk\app-debug.apk
```

## 5. Teste com dois aparelhos

1. Coloque computador e celulares no mesmo Wi-Fi.
2. Inicie o Spring Boot.
3. Instale o mesmo APK nos dois aparelhos.
4. No aparelho A, abra **Salas compartilhadas**, informe IP/nome e crie a sala.
5. No aparelho B, informe o mesmo IP, nome e código da sala.
6. Confirme a quantidade de participantes online no cabeçalho.
7. No aparelho A, toque em **Nova Tarefa**.
8. Informe título, descrição, prioridade e selecione um arquivo opcional.
9. No aparelho B, toque na tarefa e depois no botão de download do anexo.
10. Confirme o SHA-256 e o arquivo em `Downloads/Priorize`.

Logs:

```powershell
adb logcat -s PriorizeP2P
```

## 6. Persistência

Salas, membros, tarefas e metadados permanecem no H2 após reiniciar o Spring. Peer online e fontes disponíveis representam estado de execução. Não envie o banco `data/` para o Git.

## 7. Validação antes da pull request

Execute primeiro todos os testes:

```powershell
cd C:\Users\Iago\Desktop\Priorize\PriorizeAPI
mvn test

cd ..\PriorizeMobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Depois limpe os artefatos gerados. Não compile novamente após esta limpeza antes de conferir o tamanho:

```powershell
cd C:\Users\Iago\Desktop\Priorize\PriorizeMobile
flutter clean
Remove-Item -Recurse -Force .dart_tool -ErrorAction SilentlyContinue

cd ..\PriorizeAPI
mvn clean
```

Os comandos acima não removem o código nem o banco H2. Para apagar também os dados de teste, pare o Spring e remova manualmente `PriorizeAPI/data/` e `data/`; isso é opcional.

## 8. Criar branch, commit e pull request

```powershell
cd C:\Users\Iago\Desktop\Priorize
git status
git switch -c codex/priorize-p2p-salas-tarefas
git add .
git status
git diff --cached --check
git commit -m "feat: adiciona salas colaborativas e anexos P2P"
git push -u origin codex/priorize-p2p-salas-tarefas
```

Com GitHub CLI:

```powershell
gh pr create --title "Priorize P2P: salas, tarefas e anexos" --body "Implementa salas persistentes, tarefas compartilhadas, WebSocket e anexos transferidos diretamente entre peers por TCP."
```

Antes do `git commit`, confirme que `build/`, `.dart_tool/`, `.gradle/`, `target/` e `data/` não aparecem como arquivos adicionados.
