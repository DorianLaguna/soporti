/// Modelo de ticket de soporte.
/// Contiene lógica de SLA, truncación de título y formato de tiempo.
class Ticket {
  final String id;
  final String code; // SOP-0001
  final String title;
  final String description;
  final String category; // Hardware|Software|Red|Accesos|Otros
  final String priority; // Crítica|Alta|Media|Baja
  final String status; // Abierto|Asignado|En proceso|En espera|Resuelto|Cerrado
  final String location;
  final String requesterId;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final int? rating;

  Ticket({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.location,
    required this.requesterId,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.rating,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json['id'] as String,
        code: json['code'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        priority: json['priority'] as String,
        status: json['status'] as String,
        location: json['location'] as String? ?? '',
        requesterId: json['requester_id'] as String,
        assignedTo: json['assigned_to'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'] as String)
            : null,
        rating: json['rating'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'status': status,
        'location': location,
        'requester_id': requesterId,
        'assigned_to': assignedTo,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
        'rating': rating,
      };

  /// Tiempo máximo de resolución según prioridad.
  Duration get slaLimit => switch (priority) {
        'Crítica' => const Duration(hours: 4),
        'Alta' => const Duration(hours: 8),
        'Media' => const Duration(hours: 24),
        'Baja' => const Duration(hours: 48),
        _ => const Duration(hours: 24),
      };

  /// Tiempo restante antes de que venza el SLA.
  Duration get timeRemaining =>
      slaLimit - DateTime.now().difference(createdAt);

  /// Indica si el SLA ha sido rebasado.
  bool get isSlaBreached => timeRemaining.isNegative;

  /// Título truncado a 50 caracteres con "..." si excede.
  String get truncatedTitle =>
      title.length > 50 ? '${title.substring(0, 50)}...' : title;

  /// Tiempo restante formateado como "Xh Ym" o "Vencido".
  String get displayTimeRemaining {
    if (isSlaBreached) return 'Vencido';
    final remaining = timeRemaining;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
