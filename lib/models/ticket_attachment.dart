/// Modelo de adjunto de ticket.
/// Representa un archivo (imagen) asociado a un ticket.
class TicketAttachment {
  final String id;
  final String ticketId;
  final String fileUrl;
  final DateTime createdAt;

  TicketAttachment({
    required this.id,
    required this.ticketId,
    required this.fileUrl,
    required this.createdAt,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) =>
      TicketAttachment(
        id: json['id'] as String,
        ticketId: json['ticket_id'] as String,
        fileUrl: json['file_url'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_id': ticketId,
        'file_url': fileUrl,
        'created_at': createdAt.toIso8601String(),
      };
}
