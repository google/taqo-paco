package com.pacoapp.paco.net.tesp.message.request;

import com.pacoapp.paco.net.tesp.message.TespMessage;

public class TespRequestResume extends TespRequest {
    @Override
    public int getCode() {
        return TespMessage.tespCodeRequestResume;
    }
}
