package com.example.priorize.p2p;

public class FileMetadata {
    private final String fileId, fileName, sha256, localPath;
    private final long fileSize;
    public FileMetadata(String fileId, String fileName, long fileSize, String sha256, String localPath) {
        this.fileId = fileId; this.fileName = fileName; this.fileSize = fileSize; this.sha256 = sha256; this.localPath = localPath;
    }
    public String fileId() { return fileId; }
    public String fileName() { return fileName; }
    public long fileSize() { return fileSize; }
    public String sha256() { return sha256; }
    public String localPath() { return localPath; }
}
