
abstract interface class TokenProvider {
  Future<String?> accessToken();

  
  Future<String?> refresh();

  Future<bool> isAuthenticated();
}


class UnauthenticatedTokenProvider implements TokenProvider {
  const UnauthenticatedTokenProvider();

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<String?> refresh() async => null;

  @override
  Future<bool> isAuthenticated() async => false;
}
