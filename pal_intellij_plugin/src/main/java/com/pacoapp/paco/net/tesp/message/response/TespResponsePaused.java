package com.pacoapp.paco.net.tesp.message.response;

import com.pacoapp.paco.net.tesp.message.TespMessage;

public class TespResponsePaused extends TespResponse {
    @Override
    public int getCode() {
        return TespMessage.tespCodeResponsePaused;
    }
}
