class CustomerUser {
  final String id;
  final String email;
  final String name;

  const CustomerUser({
    required this.id,
    required this.email,
    required this.name,
  });

  factory CustomerUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final name = json['name'];

    if (id is! String || email is! String || name is! String) {
      throw const FormatException('Invalid customer user data');
    }

    return CustomerUser(id: id, email: email, name: name);
  }
}
