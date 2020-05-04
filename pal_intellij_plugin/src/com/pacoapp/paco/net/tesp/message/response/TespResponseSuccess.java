package com.pacoapp.paco.net.tesp.message.response;

import com.pacoapp.paco.net.tesp.message.TespMessage;

public class TespResponseSuccess extends TespResponse {
    @Override
    public int getCode() {
        return TespMessage.tespCodeResponseSuccess;
    }
}
