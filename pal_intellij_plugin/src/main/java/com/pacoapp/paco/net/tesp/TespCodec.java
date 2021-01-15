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
import com.pacoapp.paco.net.tesp.message.TespPayload;

import java.nio.ByteBuffer;

public class TespCodec {
    // The TESP protocol version. It needs to fit in an 8-bit unsigned integer (0-255).
    public static final int protocolVersion = 1;

    // Constants associated with the protocol specification
    public static final int headerLength = 2;
    public static final int payloadSizeLength = 4;
    public static final int headerWithPayloadSizeLength = headerLength + payloadSizeLength;
    public static final int versionOffset = 0;
    public static final int codeOffset = 1;
    public static final int payloadSizeOffset = headerLength;
    public static final int payloadOffset = payloadSizeOffset + payloadSizeLength;

    private static final TespCodec instance = new TespCodec();

    private final Encoder encoder = new Encoder();
    private final Decoder decoder = new Decoder();

    private TespCodec() {}

    public static TespCodec getInstance() {
        return instance;
    }

    public byte[] encode(TespMessage message) {
        return encoder.encode(message);
    }

    public Decoder getDecoder() {
        return decoder;
    }

    public Decoder getDecoderAddingEvent() {
        return decoder;
    }

    static class Encoder {
        public byte[] encode(TespMessage message) {
            final byte protocolVersionByte = ByteBuffer.allocate(4).putInt(protocolVersion).array()[3];
            final byte messageCodeByte = ByteBuffer.allocate(4).putInt(message.getCode()).array()[3];

            if (message.hasPayload()) {
                final ByteBuffer buffer = ByteBuffer.allocate(payloadOffset + message.payloadSize());
                buffer.put(protocolVersionByte);
                buffer.put(messageCodeByte);
                buffer.putInt(message.payloadSize());
                buffer.put(((TespPayload)message).getEncodedPayload());
                return buffer.array();
            } else {
                final ByteBuffer buffer = ByteBuffer.allocate(headerLength);
                buffer.put(protocolVersionByte);
                buffer.put(messageCodeByte);
                return buffer.array();
            }
        }
    }

    static class Decoder {
        // TODO
        // PAL IntelliJ plugin (as written) doesn't really care about responses
    }
}
