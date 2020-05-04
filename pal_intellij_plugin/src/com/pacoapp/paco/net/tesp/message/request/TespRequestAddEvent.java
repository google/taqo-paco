package com.pacoapp.paco.net.tesp.message.request;

import com.pacoapp.paco.net.tesp.message.TespMessage;

public class TespRequestAddEvent extends TespRequestWithStringPayload {
    private TespRequestAddEvent() {}

    public static TespRequestAddEvent withPayload(String payload) {
        final TespRequestAddEvent request = new TespRequestAddEvent();
        request.setPayload(payload);
        return request;
    }

    public static TespRequestAddEvent withEncodedPayload(byte[] bytes) {
        final TespRequestAddEvent request = new TespRequestAddEvent();
        request.setPayloadWithEncoded(bytes);
        return request;
    }

    @Override
    public int getCode() {
        return TespMessage.tespCodeRequestAddEvent;
    }
}
