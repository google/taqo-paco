package com.pacoapp.paco.net.tesp.message.request;

import com.pacoapp.paco.net.tesp.message.TespMessage;

public class TespRequestAllowlistDataOnly extends TespRequest {
    @Override
    public int getCode() {
        return TespMessage.tespCodeRequestAllowlistDataOnly;
    }
}
