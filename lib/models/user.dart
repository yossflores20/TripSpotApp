class AppUser {
  final String name;
  final String email;
  final String passwordHash;
  final bool isAdmin;

  AppUser({
    required this.name,
    required this.email,
    required this.passwordHash,
    this.isAdmin = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'isAdmin': isAdmin,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        name: json['name'] as String,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String,
        isAdmin: json['isAdmin'] as bool? ?? false,
      );

  AppUser copyWith({
    String? name,
    String? email,
    String? passwordHash,
    bool? isAdmin,
  }) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
