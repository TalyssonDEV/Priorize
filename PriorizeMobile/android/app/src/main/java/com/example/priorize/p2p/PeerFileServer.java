package com.example.priorize.p2p;

import android.util.Log;
import java.io.IOException;
import java.net.*;
import java.util.concurrent.*;

public class PeerFileServer {
    private static final String TAG = "PriorizeP2P";
    private final PeerFileCatalog catalog;
    private ExecutorService connectionPool;
    private ExecutorService acceptor;
    private volatile boolean running;
    private ServerSocket serverSocket;

    public PeerFileServer(PeerFileCatalog catalog) { this.catalog = catalog; }

    public synchronized int start(int desiredPort) throws IOException {
        if (running) return serverSocket.getLocalPort();
        serverSocket = new ServerSocket();
        serverSocket.setReuseAddress(true);
        serverSocket.bind(new InetSocketAddress(desiredPort));
        running = true;
        connectionPool = Executors.newFixedThreadPool(4);
        acceptor = Executors.newSingleThreadExecutor();
        acceptor.submit(this::acceptLoop);
        Log.i(TAG, "Servidor P2P iniciado na porta " + serverSocket.getLocalPort());
        return serverSocket.getLocalPort();
    }

    private void acceptLoop() {
        while (running) {
            try {
                connectionPool.submit(new PeerConnectionHandler(serverSocket.accept(), catalog));
            } catch (SocketException error) {
                if (running) Log.e(TAG, "ServerSocket interrompido", error);
            } catch (IOException error) {
                Log.e(TAG, "Erro ao aceitar peer", error);
            }
        }
    }

    public synchronized void stop() {
        running = false;
        try { if (serverSocket != null) serverSocket.close(); } catch (IOException ignored) { }
        if (acceptor != null) acceptor.shutdownNow();
        if (connectionPool != null) connectionPool.shutdownNow();
        Log.i(TAG, "Servidor P2P encerrado");
    }

    public boolean isRunning() { return running; }
    public int getPort() { return serverSocket == null ? 0 : serverSocket.getLocalPort(); }
}
