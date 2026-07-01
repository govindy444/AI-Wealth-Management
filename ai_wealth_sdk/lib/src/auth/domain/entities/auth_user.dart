import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.roles = const ['customer'],
  });

  final String id;
  final String email;
  final String fullName;
  final List<String> roles;

  bool hasRole(String role) => roles.contains(role);

  @override
  List<Object?> get props => [id, email, fullName, roles];
}
