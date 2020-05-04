package com.pacoapp.paco.net;

public interface NetworkClient {

    void onSuccess(String response);

    void onException(Exception Exception);

    void onError(String message, Exception exception);
}
