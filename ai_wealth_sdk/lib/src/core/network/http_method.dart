/// HTTP verbs supported by the SDK's [ApiClient].
enum HttpMethod { get, post, put, patch, delete }

extension HttpMethodValue on HttpMethod {
  String get value => switch (this) {
        HttpMethod.get => 'GET',
        HttpMethod.post => 'POST',
        HttpMethod.put => 'PUT',
        HttpMethod.patch => 'PATCH',
        HttpMethod.delete => 'DELETE',
      };
}
