/// Modelo de evento de ticket.
/// Registra cada cambio de estatus, asignación, nota o resolución.
class TicketEvent {
  final String id;
  final String ticketId;
  final String eventType; // 'created'|'assigned'|'status_change'|'resolved'|'closed'|'note'
  final String description;
  final bool isInternal;
  final String createdBy;
  final DateTime createdAt;

  TicketEvent({
    required this.id,
    required this.ticketId,
    required this.eventType,
    required this.description,
    required this.isInternal,
    required this.createdBy,
    required this.createdAt,
  });

  factory TicketEvent.fromJson(Map<String, dynamic> json) => TicketEvent(
        id: json['id'] as String,
        ticketId: json['ticket_id'] as String,
        eventType: json['event_type'] as String,
        description: json['description'] as String,
        isInternal: json['is_internal'] as bool? ?? false,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_id': ticketId,
        'event_type': eventType,
        'description': description,
        'is_internal': isInternal,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };
}
