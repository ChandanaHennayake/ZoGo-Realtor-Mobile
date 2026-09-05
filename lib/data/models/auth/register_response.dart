class RegisterResponse {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;

  const RegisterResponse({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory RegisterResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return RegisterResponse(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
    );
  }
}