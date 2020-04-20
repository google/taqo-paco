bool matches(String text, String pattern, {bool caseInsensitive: false}) =>
    text != null && RegExp(pattern, caseSensitive: !caseInsensitive).hasMatch(text);

bool matchesHost(Uri url, String host) =>
    url != null && matches(url.host, '$host\$', caseInsensitive: true);

bool matchesPath(Uri url, String path) => url != null && matches(url.path, path);

bool matchesPort(Uri url, int port) => url != null && matches('${url.port}', '^${url.port}\$');

bool matchesHostAndPath(Uri url, String host, String path) =>
    url != null && matchesHost(url, host) && matchesPath(url, path);

bool matchesHostAndPort(Uri url, String host, int port) =>
    url != null && matchesHost(url, host) && matchesPort(url, port);
