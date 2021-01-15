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

package com.pacoapp.paco.net.tesp.message;

import com.pacoapp.paco.net.tesp.message.request.*;
import com.pacoapp.paco.net.tesp.message.response.*;

public abstract class TespMessage {
    public static final int tespCodeRequestAddEvent = 0x01;
    public static final int tespCodeRequestPause = 0x02;
    public static final int tespCodeRequestResume = 0x04;
    public static final int tespCodeRequestAllowlistDataOnly = 0x06;
    public static final int tespCodeRequestAllData = 0x08;
    public static final int tespCodeRequestPing = 0x0A;
    public static final int tespCodeResponseSuccess = 0x80;
    public static final int tespCodeResponseError = 0x81;
    public static final int tespCodeResponsePaused = 0x82;
    public static final int tespCodeResponseInvalidRequest = 0x83;
    public static final int tespCodeResponseAnswer = 0x85;

    public static TespMessage fromCode(int code) {
        if (code == tespCodeRequestPause) {
            return new TespRequestPause();
        } else if (code == tespCodeRequestResume) {
            return new TespRequestResume();
        } else if (code == tespCodeRequestAllowlistDataOnly) {
            return new TespRequestAllowlistDataOnly();
        } else if (code == tespCodeRequestAllData) {
            return new TespRequestAllData();
        } else if (code == tespCodeRequestPing) {
            return new TespRequestPing();
        } else if (code == tespCodeResponseSuccess) {
            return new TespResponseSuccess();
        } else if (code == tespCodeResponsePaused) {
            return new TespResponsePaused();
        } else {
            throw new IllegalArgumentException("Invalid message code " + Integer.toHexString(code));
        }
    }

    public static TespMessage fromCode(int code, byte[] encodedPayload) {
        if (code == tespCodeRequestAddEvent) {
            return TespRequestAddEvent.withEncodedPayload(encodedPayload);
        } else if (code == tespCodeResponseError) {
            return TespResponseError.withEncodedPayload(encodedPayload);
        } else if (code == tespCodeResponseInvalidRequest) {
            return TespResponseInvalidRequest.withEncodedPayload(encodedPayload);
        } else if (code == tespCodeResponseAnswer) {
            return TespResponseAnswer.withEncodedPayload(encodedPayload);
        } else {
            throw new IllegalArgumentException("Invalid message (with payload) code " + Integer.toHexString(code));
        }
    }

    public boolean hasPayload() {
        return false;
    }

    public int payloadSize() {
        return 0;
    }

    public abstract int getCode();
}
