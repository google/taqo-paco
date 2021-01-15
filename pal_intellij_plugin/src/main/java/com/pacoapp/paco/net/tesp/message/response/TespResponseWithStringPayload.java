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

package com.pacoapp.paco.net.tesp.message.response;

import com.pacoapp.paco.net.tesp.message.TespPayload;

import java.nio.charset.StandardCharsets;

public abstract class TespResponseWithStringPayload extends TespResponse implements TespPayload<String> {
    private String payload;
    private byte[] encodedPayload;

    @Override
    public String getPayload() {
        return payload;
    }

    @Override
    public byte[] getEncodedPayload() {
        return encodedPayload;
    }

    @Override
    public void setPayload(String payload) {
        if (payload == null) {
            throw new IllegalArgumentException("Payload must not be null");
        }

        if (this.payload == null) {
            this.payload = payload;
        } else {
            throw new IllegalStateException("Payload cannot be set twice");
        }

        this.encodedPayload = this.payload.getBytes();
    }

    @Override
    public void setPayloadWithEncoded(byte[] bytes) {
        if (bytes == null) {
            throw new IllegalArgumentException("Payload must not be null");
        }

        encodedPayload = bytes;
        setPayload(new String(bytes, StandardCharsets.UTF_8));
    }

    @Override
    public boolean hasPayload() {
        return true;
    }

    @Override
    public int payloadSize() {
        return encodedPayload.length;
    }
}
