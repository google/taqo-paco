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

import jnr.unixsocket.UnixSocketAddress;
import jnr.unixsocket.UnixSocketChannel;
import org.jetbrains.annotations.NotNull;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.nio.channels.Channels;
import java.util.concurrent.TimeUnit;

public class UnixSocketClient {

  public static final String UNIX_SOCKET_FILEPATH = "/var/tmp/pal.sock";
  private final UnixSocketChannel channel;
  private final BufferedReader socketInputStream;
  private final PrintWriter out;

  public UnixSocketClient() throws IOException, InterruptedException {
    channel = setupChannel();
    out = new PrintWriter(Channels.newOutputStream(channel));
    socketInputStream = new BufferedReader(new InputStreamReader(Channels.newInputStream(channel)));
  }

  public String send(String data) throws IOException {
    out.println(data);
    out.flush();
    return socketInputStream.readLine();
  }

  public void close() {
    try {
      channel.close();
    } catch (IOException e) {
      System.err.println("Error closing unix socket channel to PacoLocalServer. "  + e.getMessage());
      e.printStackTrace();
    }
  }

  @NotNull
  private static UnixSocketChannel setupChannel() throws InterruptedException, IOException {
    java.io.File path = new java.io.File(UNIX_SOCKET_FILEPATH);
    int retries = 0;
    while (!path.exists()) {
      TimeUnit.MILLISECONDS.sleep(500L);
      retries++;
      if (retries > 10) {
        throw new IOException(
                String.format(
                        "File %s does not exist after retry",
                        path.getAbsolutePath()
                )
        );
      }
    }
    UnixSocketAddress address = new UnixSocketAddress(path);
    UnixSocketChannel channel = UnixSocketChannel.open(address);
    System.out.println("connected to " + channel.getRemoteSocketAddress());
    return channel;
  }

  public static void main(String[] args) throws IOException, InterruptedException {
    UnixSocketClient client = new UnixSocketClient();
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



