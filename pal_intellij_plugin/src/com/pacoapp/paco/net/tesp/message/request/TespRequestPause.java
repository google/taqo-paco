package com.pacoapp.paco.net.tesp.message.request;

import com.pacoapp.paco.net.tesp.message.TespMessage;

public class TespRequestPause extends TespRequest {
    @Override
    public int getCode() {
        return TespMessage.tespCodeRequestPause;
    }
}
