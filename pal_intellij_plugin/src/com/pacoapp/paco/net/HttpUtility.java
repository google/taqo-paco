package com.pacoapp.paco.net;

import com.google.common.collect.Lists;
import com.pacoapp.paco.shared.model2.Pair;

import java.io.*;
import java.net.ConnectException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.List;
import java.util.logging.Logger;

public class HttpUtility {

  public static final Logger log = Logger.getLogger(HttpUtility.class.getName());

  protected String oAuthScope = AUTH_TOKEN_TYPE_USERINFO_EMAIL;
  public static final String AUTH_TOKEN_TYPE_USERINFO_EMAIL = "oauth2:https://www.googleapis.com/auth/userinfo.email";
  private static final String AUTH_TOKEN_TYPE_USERINFO_PROFILE = "oauth2:https://www.googleapis.com/auth/userinfo.profile";
  static final String UTF_8 = "UTF-8";

  public static final String POST = "POST";
  public static final String GET = "GET";
  private static final int MAX_ATTEMPTS = 2;

  private String url;
  private String httpMethod;
  private String body;
  private int attempts;

  protected void doRequest(String httpMethod, String url, String body, NetworkClient networkClient) {
//    String token = fetchToken();
//    if (token == null) {
//      // error has already been handled in fetchToken()
//      return;
//    }
//    userPrefs.setAccessToken(token);


    try {
      List<Pair<String, String>> headers = Lists.newArrayList();

      addStandardHeaders(headers);
      //addAccessTokenBearerHeader(fetchToken(), headers);

      URL u = new URL(url);
      HttpURLConnection urlConnection = ServerAddressBuilder.getConnection(u);
      for (Pair<String, String> header : headers) {
        urlConnection.addRequestProperty(header.first, header.second);
      }

      if (POST.equals(httpMethod)) {
        urlConnection.addRequestProperty("Content-Type", "application/json");
        urlConnection.setDoOutput(true);
        urlConnection.setRequestMethod(POST);
        OutputStream outputStream = urlConnection.getOutputStream();
        OutputStreamWriter writer = new OutputStreamWriter(outputStream, UTF_8);
        writer.write(body);
        writer.flush();
        outputStream.flush();
      }

      int sc = 0;
      try {
        sc = urlConnection.getResponseCode();
      } catch (ConnectException e) {
        sc = 503;
      }
      if (sc == 200) {
        InputStream is = urlConnection.getInputStream();
        String result = readResponse(urlConnection.getInputStream());
        is.close();
        networkClient.onSuccess(result);
        return;
      } else if (sc == 401) {
        //GoogleAuthUtil.invalidateToken(networkClient.getContext(), token);
        //onError("Server auth error, please try again.", null);
        log.info("Server auth error: " + readResponse(urlConnection.getErrorStream()));
        if (attempts < MAX_ATTEMPTS) {
          attempts++;
          log.info("Attempt: " + attempts + " for url:  " + url);
          doRequest(httpMethod, url, body, networkClient);
        }
        return;
      } else {
        networkClient.onError("Server returned the following error code: " + sc, null);
        return;
      }
    } catch (IOException e) {
      networkClient.onException(e);
    }

  }

  public void addStandardHeaders(List<Pair<String, String>> headers) {
    headers.add(new Pair<String, String>("http.useragent", "Macos"));
    headers.add(new Pair<String, String>("paco.version", "1"));
    headers.add(new Pair<String, String>("pacoProtocol", "4"));
  }

  // TODO add this back once we have anonPublic working
  public void addAccessTokenBearerHeader(String accessToken, final List<Pair<String, String>> headers) {
    headers.add(new Pair<String, String>("Authorization", "Bearer " + accessToken));
  }

  /**
   * Reads the response from the input stream and returns it as a string.
   */
  protected static String readResponse(InputStream is) throws IOException {
    ByteArrayOutputStream bos = new ByteArrayOutputStream();
    byte[] data = new byte[2048];
    int len = 0;
    while ((len = is.read(data, 0, data.length)) >= 0) {
      bos.write(data, 0, len);
    }
    return new String(bos.toByteArray(), UTF_8);
  }


}
