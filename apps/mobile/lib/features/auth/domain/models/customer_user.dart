class CustomerUser {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;

  const CustomerUser({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
  });

  factory CustomerUser.fromJson(
    Map<String, dynamic> json,
  ) {
    final id = json['id'];
    final email = json['email'];
    final name = json['name'];
    final avatarUrl = json['avatarUrl'];

    if (
      id is! String ||
      email is! String ||
      name is! String ||
      (avatarUrl != null && avatarUrl is! String)
    ) {
      throw const FormatException(
        'Invalid customer user data',
      );
    }

    return CustomerUser(
      id: id,
      email: email,
      name: name,
      avatarUrl: avatarUrl as String?,
    );
  }
}
