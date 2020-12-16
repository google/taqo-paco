package com.pacoapp.paco.net.tesp.message.response;

import com.pacoapp.paco.net.tesp.message.TespMessage;

public class TespResponseInvalidRequest extends TespResponseWithStringPayload {
    public static TespResponseInvalidRequest withPayload(String payload) {
        final TespResponseInvalidRequest response = new TespResponseInvalidRequest();
        response.setPayload(payload);
        return response;
    }

    public static TespResponseInvalidRequest withEncodedPayload(byte[] bytes) {
        final TespResponseInvalidRequest response = new TespResponseInvalidRequest();
        response.setPayloadWithEncoded(bytes);
        return response;
    }

    @Override
    public int getCode() {
        return TespMessage.tespCodeResponseInvalidRequest;
    }
}
