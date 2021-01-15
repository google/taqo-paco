// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
