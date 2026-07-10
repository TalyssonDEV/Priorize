package com.example.priorize.p2p;

public final class FileTransferProtocol {
    public static final String GET_FILE = "GET_FILE";
    public static final String FILE_INFO = "FILE_INFO";
    public static final String FILE_DATA = "FILE_DATA";
    public static final String FILE_NOT_FOUND = "FILE_NOT_FOUND";
    public static final String TRANSFER_COMPLETE = "TRANSFER_COMPLETE";
    public static final String TRANSFER_ERROR = "TRANSFER_ERROR";

    private FileTransferProtocol() { }
}
