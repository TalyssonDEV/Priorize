package com.example.priorize.p2p;

import java.io.File;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class PeerFileCatalog {
    private final Map<String, FileMetadata> files = new ConcurrentHashMap<>();

    public void register(FileMetadata metadata) {
        File file = new File(metadata.localPath());
        if (!file.isFile()) throw new IllegalArgumentException("Arquivo local não encontrado");
        files.put(metadata.fileId(), metadata);
    }

    public FileMetadata find(String fileId) {
        FileMetadata metadata = files.get(fileId);
        if (metadata == null || !new File(metadata.localPath()).isFile()) return null;
        return metadata;
    }
}
