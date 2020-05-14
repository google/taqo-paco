package com.pacoapp.paco.net.tesp.message;

public interface TespPayload<T> {
    T getPayload();
    byte[] getEncodedPayload();
    void setPayload(T payload);
    void setPayloadWithEncoded(byte[] bytes);
}
