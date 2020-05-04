package com.pacoapp.paco.net.tesp;

import com.pacoapp.paco.net.tesp.message.request.TespRequest;
import com.pacoapp.paco.net.tesp.message.response.TespResponse;

import java.io.IOException;
import java.net.Socket;

public class TespClient {
    private static final long defaultConnectionTimeoutMs = 5000;
    private static final long defaultChunkTimeoutMs = 5000;

    private final String serverAddress;
    private final int port;

    private final long connectionTimeoutMs;
    private final long chunkTimeoutMs;

    private Socket socket;
    private TespMessageSocket<TespResponse, TespRequest> tespSocket;

    public TespClient(String serverAddress, int port) throws IOException {
        this(serverAddress, port, defaultConnectionTimeoutMs, defaultChunkTimeoutMs);
    }

    public TespClient(String serverAddress, int port, long connectionTimeout, long chunkTimeout) throws IOException {
        this.serverAddress = serverAddress;
        this.port = port;
        this.connectionTimeoutMs = connectionTimeout;
        this.chunkTimeoutMs = chunkTimeout;

        connect();
    }

    public void connect() throws IOException {
        socket = new Socket(serverAddress, port);
        tespSocket = new TespMessageSocket<>(socket);
    }

    // TODO Handle a response
    public /*TespResponse*/ void send(TespRequest request) throws IOException {
        if (tespSocket != null) {
            tespSocket.add(request);
        }
    }

    public void close() {
        tespSocket.close();
        try {
            socket.close();
        } catch (IOException e) {
        } finally {
            tespSocket = null;
            socket = null;
        }
    }
}
