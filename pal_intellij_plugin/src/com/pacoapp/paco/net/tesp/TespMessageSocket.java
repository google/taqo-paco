package com.pacoapp.paco.net.tesp;

import com.pacoapp.paco.net.tesp.message.TespMessage;

import java.io.*;
import java.net.Socket;

public class TespMessageSocket<R extends TespMessage, S extends TespMessage> {
    private static final long defaultConnectionTimeoutMs = 5000;

    private final TespCodec tespCodec = TespCodec.getInstance();

    private final Socket socket;
    private final InputStream socketInputStream;
    private final OutputStream socketOutputStream;

    private final long timeoutMs;
    private final boolean isAsync = false;

    public TespMessageSocket(Socket socket) throws IOException {
        this(socket, defaultConnectionTimeoutMs);
    }

    public TespMessageSocket(Socket socket, long timeout) throws IOException {
        this.socket = socket;
        socketOutputStream = socket.getOutputStream();
        socketInputStream = socket.getInputStream();

        this.timeoutMs = timeout;
    }

    public void add(S message) throws IOException {
        socketOutputStream.write(tespCodec.encode(message));
        socketOutputStream.flush();
    }

    public void close() {
        try {
            socketOutputStream.flush();
            socket.close();
        } catch (IOException e) {
        }
    }
}
