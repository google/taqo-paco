package com.pacoapp.paco.net.tesp.message.response;

import com.pacoapp.paco.net.tesp.message.TespMessage;

public class TespResponseAnswer extends TespResponseWithStringPayload {
    public static TespResponseAnswer withPayload(String payload) {
        final TespResponseAnswer response = new TespResponseAnswer();
        response.setPayload(payload);
        return response;
    }

    public static TespResponseAnswer withEncodedPayload(byte[] bytes) {
        final TespResponseAnswer response = new TespResponseAnswer();
        response.setPayloadWithEncoded(bytes);
        return response;
    }

    @Override
    public int getCode() {
        return TespMessage.tespCodeResponseAnswer;
    }
}
