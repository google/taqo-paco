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

import com.google.gson.Gson;
import com.pacoapp.paco.net.tesp.message.TespMessage;

public class TespResponseError extends TespResponseWithStringPayload {
    public static final String tespServerErrorUnknown = "server-unknown";
    public static final String tespClientErrorResponseTimeout = "client-response-timeout";
    public static final String tespClientErrorServerCloseEarly = "client-server-close-early";
    public static final String tespClientErrorLostConnection = "client-lost-connection";
    public static final String tespClientErrorChunkTimeout = "client-chunk-timeout";
    public static final String tespClientErrorDecoding = "client-decoding-error";
    public static final String tespClientErrorPayloadDecoding = "client-payload-decoding-error";
    public static final String tespClientErrorUnknown = "client-unknown";

    private static final String jsonKeyCode = "code";
    private static final String jsonKeyMessage = "message";
    private static final String jsonKeyDetails = "details";

    private String errorCode;
    private String errorMessage;
    private String errorDetails;

    private TespResponseError() {}

    TespResponseError(String code) {
        this(code, null, null);
    }

    TespResponseError(String code, String message, String details) {
        errorCode = code;
        errorMessage = message;
        errorDetails = details;

        final JsonWrapper wrap = new JsonWrapper(errorCode, errorMessage, errorDetails);
        final Gson gson = new Gson();
        setPayload(gson.toJson(wrap));
    }

    public static TespResponseError withEncodedPayload(byte[] bytes) {
        final TespResponseError response = new TespResponseError();
        response.setPayloadWithEncoded(bytes);

        final Gson gson = new Gson();
        final JsonWrapper wrap = gson.fromJson(response.getPayload(), JsonWrapper.class);

        response.errorCode = wrap.code;
        response.errorMessage = wrap.message;
        response.errorDetails = wrap.details;
        return response;
    }

    @Override
    public int getCode() {
        return TespMessage.tespCodeResponseError;
    }

    class JsonWrapper {
        String code;
        String message;
        String details;
        JsonWrapper(String c, String m, String d) {
            code = c;
            message = m;
            details = d;
        }
    }
}
