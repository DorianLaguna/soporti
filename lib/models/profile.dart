/// Modelo de perfil de usuario.
/// Representa a un solicitante, técnico o supervisor.
class Profile {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'solicitante' | 'tecnico' | 'supervisor'
  final String location;

  Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.location,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        role: json['role'] as String,
        location: json['location'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'location': location,
      };
}
