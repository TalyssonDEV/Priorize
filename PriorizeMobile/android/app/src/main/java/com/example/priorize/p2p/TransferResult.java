package com.example.priorize.p2p;

public class TransferResult {
    private final boolean success;
    private final String error, finalPath, calculatedHash;
    private final long bytesReceived;
    public TransferResult(boolean success, String error, String finalPath, String calculatedHash, long bytesReceived) {
        this.success = success; this.error = error; this.finalPath = finalPath; this.calculatedHash = calculatedHash; this.bytesReceived = bytesReceived;
    }
    public boolean success() { return success; }
    public String error() { return error; }
    public String finalPath() { return finalPath; }
    public String calculatedHash() { return calculatedHash; }
    public long bytesReceived() { return bytesReceived; }
    public static TransferResult success(String path, String hash, long size) {
        return new TransferResult(true, null, path, hash, size);
    }

    public static TransferResult failure(String error) {
        return new TransferResult(false, error, null, null, 0);
    }
}
