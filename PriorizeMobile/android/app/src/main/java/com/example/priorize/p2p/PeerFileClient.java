package com.example.priorize.p2p;

import android.util.Log;
import java.io.*;
import java.net.*;

public class PeerFileClient {
    private static final String TAG = "PriorizeP2P";

    public TransferResult download(String host, int port, String fileId, File destination, String expectedHash) {
        File partial = new File(destination.getAbsolutePath() + ".part");
        long received = 0;
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(host, port), 8_000);
            socket.setSoTimeout(30_000);
            try (DataOutputStream output = new DataOutputStream(new BufferedOutputStream(socket.getOutputStream()));
                 DataInputStream input = new DataInputStream(new BufferedInputStream(socket.getInputStream()))) {
                output.writeUTF(FileTransferProtocol.GET_FILE);
                output.writeUTF(fileId);
                output.flush();
                String response = input.readUTF();
                if (FileTransferProtocol.FILE_NOT_FOUND.equals(response) || FileTransferProtocol.TRANSFER_ERROR.equals(response)) {
                    return TransferResult.failure(input.readUTF());
                }
                if (!FileTransferProtocol.FILE_INFO.equals(response)) return TransferResult.failure("Resposta inválida: " + response);
                input.readUTF();
                String fileName = input.readUTF();
                long size = input.readLong();
                String remoteHash = input.readUTF();
                if (!FileTransferProtocol.FILE_DATA.equals(input.readUTF())) return TransferResult.failure("FILE_DATA esperado");
                File parent = destination.getParentFile();
                if (parent != null && !parent.exists()) parent.mkdirs();
                try (OutputStream fileOutput = new BufferedOutputStream(new FileOutputStream(partial))) {
                    byte[] buffer = new byte[8192];
                    while (received < size) {
                        int read = input.read(buffer, 0, (int) Math.min(buffer.length, size - received));
                        if (read < 0) throw new EOFException("Conexão encerrada antes do fim do arquivo");
                        fileOutput.write(buffer, 0, read);
                        received += read;
                    }
                }
                if (!FileTransferProtocol.TRANSFER_COMPLETE.equals(input.readUTF())) return TransferResult.failure("Transferência não confirmada");
                String calculated = HashService.sha256(partial);
                String wanted = expectedHash == null || expectedHash.isBlank() ? remoteHash : expectedHash;
                if (!calculated.equalsIgnoreCase(wanted) || !calculated.equalsIgnoreCase(remoteHash)) {
                    partial.delete();
                    return TransferResult.failure("Hash SHA-256 inválido");
                }
                if (destination.exists() && !destination.delete()) return TransferResult.failure("Não foi possível substituir o destino");
                if (!partial.renameTo(destination)) return TransferResult.failure("Não foi possível finalizar o arquivo");
                Log.i(TAG, "Download concluído: " + fileName + " | " + received + " bytes");
                return TransferResult.success(destination.getAbsolutePath(), calculated, received);
            }
        } catch (Exception error) {
            partial.delete();
            Log.e(TAG, "Erro no download P2P", error);
            return TransferResult.failure(error.getMessage() == null ? error.getClass().getSimpleName() : error.getMessage());
        }
    }
}
