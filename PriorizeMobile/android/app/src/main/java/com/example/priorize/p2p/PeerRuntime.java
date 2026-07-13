package com.example.priorize.p2p;

/** Estado único do peer mantido vivo pelo serviço Android em primeiro plano. */
public final class PeerRuntime {
    private static final PeerFileCatalog CATALOG = new PeerFileCatalog();
    private static final PeerFileServer SERVER = new PeerFileServer(CATALOG);

    private PeerRuntime() { }
    public static PeerFileCatalog catalog() { return CATALOG; }
    public static PeerFileServer server() { return SERVER; }
}
