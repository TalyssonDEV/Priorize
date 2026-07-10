package com.example.priorize.p2p;

import android.util.Log;
import java.io.*;
import java.net.Socket;

public class PeerConnectionHandler implements Runnable {
    private static final String TAG = "PriorizeP2P";
    private final Socket socket;
    private final PeerFileCatalog catalog;

    public PeerConnectionHandler(Socket socket, PeerFileCatalog catalog) {
        this.socket = socket;
        this.catalog = catalog;
    }

    @Override
    public void run() {
        String thread = Thread.currentThread().getName();
        Log.i(TAG, "Peer conectado: " + socket.getRemoteSocketAddress() + " | thread=" + thread);
        try (Socket client = socket;
             DataInputStream input = new DataInputStream(new BufferedInputStream(client.getInputStream()));
             DataOutputStream output = new DataOutputStream(new BufferedOutputStream(client.getOutputStream()))) {
            client.setSoTimeout(30_000);
            String command = input.readUTF();
            if (!FileTransferProtocol.GET_FILE.equals(command)) {
                sendError(output, "Comando inválido: " + command);
                return;
            }
            String fileId = input.readUTF();
            Log.i(TAG, "Arquivo solicitado: " + fileId + " | thread=" + thread);
            FileMetadata metadata = catalog.find(fileId);
            if (metadata == null) {
                output.writeUTF(FileTransferProtocol.FILE_NOT_FOUND);
                output.writeUTF("Arquivo não encontrado neste peer");
                output.flush();
                return;
            }
            output.writeUTF(FileTransferProtocol.FILE_INFO);
            output.writeUTF(metadata.fileId());
            output.writeUTF(metadata.fileName());
            output.writeLong(metadata.fileSize());
            output.writeUTF(metadata.sha256());
            output.writeUTF(FileTransferProtocol.FILE_DATA);
            long sent = 0;
            try (InputStream fileInput = new BufferedInputStream(new FileInputStream(metadata.localPath()))) {
                byte[] buffer = new byte[8192];
                int read;
                while ((read = fileInput.read(buffer)) != -1) {
                    output.write(buffer, 0, read);
                    sent += read;
                }
            }
            output.writeUTF(FileTransferProtocol.TRANSFER_COMPLETE);
            output.flush();
            Log.i(TAG, "Transferência concluída: " + sent + " bytes | thread=" + thread);
        } catch (Exception error) {
            Log.e(TAG, "Erro na transferência | thread=" + thread, error);
        }
    }

    private void sendError(DataOutputStream output, String message) throws IOException {
        output.writeUTF(FileTransferProtocol.TRANSFER_ERROR);
        output.writeUTF(message);
        output.flush();
    }
}
