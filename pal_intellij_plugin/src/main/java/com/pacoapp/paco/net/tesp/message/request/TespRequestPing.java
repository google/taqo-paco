package com.pacoapp.paco.net.tesp.message.request;

import com.pacoapp.paco.net.tesp.message.TespMessage;

public class TespRequestPing extends TespRequest {
    @Override
    public int getCode() {
        return TespMessage.tespCodeRequestPing;
    }
}
