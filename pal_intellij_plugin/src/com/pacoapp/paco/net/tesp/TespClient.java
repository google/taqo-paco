package com.pacoapp.paco.net.tesp;

import com.pacoapp.paco.net.tesp.message.request.TespRequest;
import com.pacoapp.paco.net.tesp.message.response.TespResponse;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.logging.Logger;

public class TespClient {
    private static final int defaultConnectionTimeoutMs = 5000;
    private static final int defaultChunkTimeoutMs = 5000;

    public static final Logger log = Logger.getLogger(TespClient.class.getName());

    private final String serverAddress;
    private final int port;

    private final int connectionTimeoutMs;
    private final int chunkTimeoutMs;

    private Socket socket;
    private TespMessageSocket<TespResponse, TespRequest> tespSocket;

    public TespClient(String serverAddress, int port) throws IOException {
        this(serverAddress, port, defaultConnectionTimeoutMs, defaultChunkTimeoutMs);
    }

    public TespClient(String serverAddress, int port, int connectionTimeout, int chunkTimeout) throws IOException {
        this.serverAddress = serverAddress;
        this.port = port;
        this.connectionTimeoutMs = connectionTimeout;
        this.chunkTimeoutMs = chunkTimeout;

        connect();
    }

    public void connect() throws IOException {
        socket = new Socket();
        socket.connect(new InetSocketAddress(serverAddress, port), connectionTimeoutMs);
        tespSocket = new TespMessageSocket<>(socket);
    }

    // TODO Handle a response
    public /*TespResponse*/ void send(TespRequest request) throws IOException {
        if (tespSocket == null) {
            connect();
        }

        tespSocket.add(request);
    }

    public void close() {
        tespSocket.close();
        try {
            socket.close();
        } catch (IOException e) {
            log.warning("Exception closing TespClient socket: " + e.getMessage());
        } finally {
            tespSocket = null;
            socket = null;
        }
    }
}
