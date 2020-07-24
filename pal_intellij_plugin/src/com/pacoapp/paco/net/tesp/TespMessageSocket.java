package com.pacoapp.paco.net.tesp;

import com.pacoapp.paco.net.tesp.message.TespMessage;

import java.io.*;
import java.net.Socket;
import java.util.logging.Logger;

public class TespMessageSocket<R extends TespMessage, S extends TespMessage> {
    private static final int defaultTimeoutMs = 5000;

    public static final Logger log = Logger.getLogger(TespMessageSocket.class.getName());

    private final TespCodec tespCodec = TespCodec.getInstance();

    private final Socket socket;
    private final InputStream socketInputStream;
    private final OutputStream socketOutputStream;

    private final int timeoutMs;
    private final boolean isAsync = false;

    public TespMessageSocket(Socket socket) throws IOException {
        this(socket, defaultTimeoutMs);
    }

    public TespMessageSocket(Socket socket, int timeout) throws IOException {
        this.socket = socket;
        socketOutputStream = socket.getOutputStream();
        socketInputStream = socket.getInputStream();

        this.timeoutMs = timeout;
    }

    public void add(S message) throws IOException {
      socketOutputStream.write(tespCodec.encode(message));
      socketOutputStream.flush();


        // byte[] encodedMessage = tespCodec.encode(message);
        // System.out.println("encodedmessage size: " + encodedMessage.length);
        // try {
        //     Socket socket2 = new Socket("127.0.0.1", 31415);
        //     OutputStream outputStream = socket2.getOutputStream();
        //     outputStream.write(encodedMessage);
        //     outputStream.flush();
        //     outputStream.close();
        //     socket2.close();
        //     System.out.println("Done writing to socket");
        // } catch (IOException e) {
        //     log.info("Caught exception in add(message): " +e.getMessage());
        //     e.printStackTrace();
        //     throw e;
        // }
//
//        byte[] buf = new byte[1024];
//        int cnt=0;
//        int tmp = 0;
//        while (( tmp = socketInputStream.read(buf)) > 0) {
//            cnt += tmp;
//        }
//        System.out.println("received back bytes: " + cnt);
    }

    public void close() {
        log.info("Closing socket");
        try {
            socketOutputStream.flush();
            socket.close();
        } catch (IOException e) {
            log.warning("Exception closing TespMessageSocket socket: " + e.getMessage());
        }
    }

    public boolean isBroken() {
        return !socket.isConnected();
    }
}
