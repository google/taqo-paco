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

package com.pacoapp.paco.net;

import org.jetbrains.annotations.NotNull;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.concurrent.TimeUnit;

public class TcpSocketClient {

  private static final String localHost = "127.0.0.1";
  private static final int localPort = 6666;

  private final Socket socket;
  private final BufferedReader socketInputStream;
  private final PrintWriter out;

  public TcpSocketClient() throws IOException, InterruptedException {
    socket = setupSocket();
    out = new PrintWriter(socket.getOutputStream(), true);
    socketInputStream = new BufferedReader(new InputStreamReader(socket.getInputStream()));
  }

  public String send(String data) throws IOException {
    out.println(data);
    out.flush();
    return socketInputStream.readLine();
  }

  public void close() {
    try {
      socket.close();
    } catch (IOException e) {
      System.err.println("Error closing unix socket channel to PacoLocalServer. "  + e.getMessage());
      e.printStackTrace();
    }
  }

  @NotNull
  private static Socket setupSocket() throws InterruptedException, IOException {
    Socket socket = null;
    int retries = 0;
    while (socket == null) {
      try {
        socket = new Socket(localHost, localPort);
      } catch (Exception e) {
        System.out.println(e.getMessage());
        socket = null;
      }
      TimeUnit.MILLISECONDS.sleep(500L);
      if (++retries > 10) {
        throw new IOException("Socket cannot connect after retry");
      }
    }
    System.out.println("connected to " + socket.getInetAddress());
    return socket;
  }

  public static void main(String[] args) throws IOException, InterruptedException {
    TcpSocketClient client = new TcpSocketClient();
    try (BufferedReader stdIn = new BufferedReader(new InputStreamReader(System.in))) {
      String userInput;
      System.out.print(">");
      while ((userInput = stdIn.readLine()) != null) {
        String response = client.send(userInput);
        System.out.println("echo: " + response);
        System.out.print("\n>");
      }
    } catch (IOException e) {
      System.err.println("Couldn't get I/O for the connection ");
      System.exit(1);
    }

    System.exit(0);
  }
}
