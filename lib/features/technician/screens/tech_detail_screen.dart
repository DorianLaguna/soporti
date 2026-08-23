import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/priority_chip.dart';
import '../../../core/widgets/timeline_event.dart';
import '../../../models/ticket.dart';
import '../../../models/ticket_event.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tickets/providers/ticket_events_provider.dart';
import '../../tickets/providers/ticket_provider.dart';
import '../../tickets/screens/ticket_detail_screen.dart' show ticketByIdProvider;
import '../providers/tech_provider.dart';
import '../repositories/tech_repository.dart';
import '../widgets/reassign_modal.dart';

/// Pantalla de detalle y gestión de ticket para el técnico.
///
/// Muestra:
/// - Código + botón "Reasignar"
/// - Título
/// - Row: PriorityChip + SLA indicator + Location chip
/// - Resumen de línea de tiempo (últimos 3 eventos)
/// - Chips de selección de estatus (En proceso, En espera, Resuelto)
/// - Campo "Solución aplicada" (10–1000 chars, requerido si estatus = Resuelto)
/// - Casilla "Comentario interno" + campo de texto (1–500 chars)
/// - Botones "Guardar" y "Marcar resuelto"
class TechDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const TechDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TechDetailScreen> createState() => _TechDetailScreenState();
}

class _TechDetailScreenState extends ConsumerState<TechDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _solutionController = TextEditingController();
  final _commentController = TextEditingController();

  String? _selectedStatus;
  bool _internalCommentEnabled = false;
  bool _isSaving = false;

  /// Statuses available for the technician to select.
  static const _availableStatuses = ['En proceso', 'En espera', 'Resuelto'];

  @override
  void dispose() {
    _solutionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(techTicketByIdProvider(widget.ticketId));
    final eventsAsync = ref.watch(techTicketEventsProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.ticketDetail),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(AppStrings.error, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(techTicketByIdProvider(widget.ticketId)),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
        data: (ticket) {
          // Initialize selected status from ticket's current status on first build.
          _selectedStatus ??= _availableStatuses.contains(ticket.status)
              ? ticket.status
              : null;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header: code + "Reasignar" button
                  _buildHeader(ticket),
                  const SizedBox(height: 12),

                  // 2. Title
                  Text(
                    ticket.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Row: PriorityChip + SLA indicator + Location chip
                  _buildInfoRow(ticket),
                  const SizedBox(height: 20),

                  // 3.5 Description
                  _buildDescription(ticket),
                  const SizedBox(height: 20),

                  // 4. Timeline summary (last 3 events)
                  _buildTimelineSummary(eventsAsync),
                  const SizedBox(height: 20),

                  // El ticket ya fue calificado y cerrado por el
                  // solicitante: no tiene sentido seguir ofreciendo
                  // controles para gestionarlo.
                  if (ticket.status == 'Cerrado')
                    _buildClosedNotice()
                  else ...[
                    // 5. Status selection chips
                    _buildStatusSelection(ticket),
                    const SizedBox(height: 20),

                    // 6. "Solución aplicada" field
                    _buildSolutionField(),
                    const SizedBox(height: 16),

                    // 7. Internal comment checkbox + field
                    _buildInternalComment(),
                    const SizedBox(height: 24),

                    // 8. Action buttons
                    _buildActionButtons(ticket),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Header row with ticket code and "Reasignar" button.
  Widget _buildHeader(Ticket ticket) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          ticket.code,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        // Un ticket cerrado ya no se puede reasignar.
        if (ticket.status != 'Cerrado')
          OutlinedButton.icon(
            onPressed: () => _handleReassign(ticket),
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text(AppStrings.reassign),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  /// Aviso de solo lectura para tickets ya cerrados por el solicitante.
  Widget _buildClosedNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusCerrado.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.statusCerrado.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.statusCerrado, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Este ticket ya fue calificado y cerrado por el solicitante. '
              'No se puede modificar.',
              style: TextStyle(
                color: AppColors.statusCerrado,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Row with priority chip, SLA indicator, and location chip.
  Widget _buildInfoRow(Ticket ticket) {
    final slaColor = ticket.isSlaBreached ||
            ticket.timeRemaining < const Duration(hours: 2)
        ? AppColors.slaWarning
        : AppColors.textSecondary;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PriorityChip(priority: ticket.priority),
        // SLA indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: slaColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: slaColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 14, color: slaColor),
              const SizedBox(width: 4),
              Text(
                ticket.displayTimeRemaining,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: slaColor,
                ),
              ),
            ],
          ),
        ),
        // Location chip
        if (ticket.location.isNotEmpty)
          Chip(
            avatar: const Icon(Icons.location_on_outlined, size: 14),
            label: Text(
              ticket.location,
              style: const TextStyle(fontSize: 12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: AppColors.divider),
          ),
      ],
    );
  }

  /// Descripción original del incidente, escrita por el solicitante.
  Widget _buildDescription(Ticket ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.descriptionLabel,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ticket.description,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Timeline summary showing the last 3 events.
  Widget _buildTimelineSummary(AsyncValue<List<TicketEvent>> eventsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.timeline,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        eventsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => const Text(
            'No se pudieron cargar los eventos',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          data: (events) {
            if (events.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin eventos registrados',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              );
            }

            // Show last 3 events (most recent at the bottom)
            final recentEvents = events.length > 3
                ? events.sublist(events.length - 3)
                : events;

            return Column(
              children: recentEvents.asMap().entries.map((entry) {
                final index = entry.key;
                final event = entry.value;
                return TimelineEventWidget(
                  event: event,
                  isLast: index == recentEvents.length - 1,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Status selection with ChoiceChips.
  Widget _buildStatusSelection(Ticket ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.changeStatus,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _availableStatuses.map((status) {
            final isSelected = _selectedStatus == status;
            return ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? status : null;
                });
              },
              selectedColor: AppColors.statusColor(status).withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.statusColor(status)
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.statusColor(status)
                    : AppColors.divider,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// "Solución aplicada" text field.
  Widget _buildSolutionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.solutionLabel,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _solutionController,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(
            hintText: 'Describe la solución aplicada al incidente',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          validator: (value) {
            // Only validate if "Resuelto" is selected or "Marcar resuelto" was pressed
            if (_selectedStatus == 'Resuelto') {
              final trimmed = value?.trim() ?? '';
              if (trimmed.length < 10) {
                return AppStrings.solutionRequired;
              }
              if (trimmed.length > 1000) {
                return AppStrings.solutionRequired;
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Internal comment checkbox and text field.
  Widget _buildInternalComment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _internalCommentEnabled,
              onChanged: (value) {
                setState(() {
                  _internalCommentEnabled = value ?? false;
                });
              },
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _internalCommentEnabled = !_internalCommentEnabled;
                  });
                },
                child: const Text(
                  AppStrings.internalComment,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_internalCommentEnabled) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Nota interna (no visible para el solicitante)',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            validator: (value) {
              if (_internalCommentEnabled) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty || trimmed.length > 500) {
                  return 'El comentario debe tener entre 1 y 500 caracteres';
                }
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  /// Action buttons: "Guardar" and "Marcar resuelto".
  Widget _buildActionButtons(Ticket ticket) {
    return Row(
      children: [
        // "Guardar" button
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => _handleSave(ticket),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    AppStrings.save,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        // "Marcar resuelto" button
        Expanded(
          child: FilledButton(
            onPressed: _isSaving ? null : () => _handleMarkResolved(ticket),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              AppStrings.markResolved,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  /// Handles the "Guardar" action.
  /// Validates that a different status is selected or internal comment is filled.
  Future<void> _handleSave(Ticket ticket) async {
    // Validate: must have a different status selected or internal comment filled
    if (_selectedStatus == null || _selectedStatus == ticket.status) {
      if (!_internalCommentEnabled ||
          _commentController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.statusChangeRequired),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // If "Resuelto" is selected, require solution field
    if (_selectedStatus == 'Resuelto') {
      final solutionText = _solutionController.text.trim();
      if (solutionText.length < 10 || solutionText.length > 1000) {
        _formKey.currentState?.validate();
        return;
      }
    }

    // Validate internal comment if enabled
    if (_internalCommentEnabled) {
      final commentText = _commentController.text.trim();
      if (commentText.isEmpty || commentText.length > 500) {
        _formKey.currentState?.validate();
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) return;

      final repository = ref.read(techRepositoryProvider);

      // Update status if changed
      if (_selectedStatus != null && _selectedStatus != ticket.status) {
        await repository.updateTicketStatus(widget.ticketId, _selectedStatus!);

        // Register status change event
        await repository.addEvent(
          ticketId: widget.ticketId,
          eventType: _selectedStatus == 'Resuelto'
              ? 'resolved'
              : 'status_change',
          description: _selectedStatus == 'Resuelto'
              ? _solutionController.text.trim()
              : 'Estatus cambiado a $_selectedStatus',
          createdBy: user.id,
          isInternal: false,
        );
      }

      // Add internal comment if enabled and filled
      if (_internalCommentEnabled &&
          _commentController.text.trim().isNotEmpty) {
        await repository.addEvent(
          ticketId: widget.ticketId,
          eventType: 'note',
          description: _commentController.text.trim(),
          createdBy: user.id,
          isInternal: true,
        );
      }

      // Refresh providers
      ref.invalidate(techTicketByIdProvider(widget.ticketId));
      ref.invalidate(techTicketEventsProvider(widget.ticketId));
      ref.invalidate(techQueueProvider);
      // La vista del solicitante (otra sesión, u otro rol en el mismo
      // dispositivo) tiene sus propios providers cacheados por separado;
      // sin esto, un cambio de estatus del técnico no se reflejaba ahí
      // hasta reiniciar la app.
      ref.invalidate(ticketByIdProvider(widget.ticketId));
      ref.invalidate(ticketEventsProvider(widget.ticketId));
      ref.invalidate(userTicketsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados exitosamente'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Handles the "Marcar resuelto" action.
  /// Requires the solution field to be between 10-1000 chars.
  Future<void> _handleMarkResolved(Ticket ticket) async {
    // Force status to Resuelto for validation
    setState(() => _selectedStatus = 'Resuelto');

    final solutionText = _solutionController.text.trim();
    if (solutionText.length < 10 || solutionText.length > 1000) {
      _formKey.currentState?.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.solutionRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) return;

      final repository = ref.read(techRepositoryProvider);

      // Update status to Resuelto
      await repository.updateTicketStatus(widget.ticketId, 'Resuelto');

      // Register resolved event with solution description (visible to requester)
      await repository.addEvent(
        ticketId: widget.ticketId,
        eventType: 'resolved',
        description: solutionText,
        createdBy: user.id,
        isInternal: false,
      );

      // Also add internal comment if enabled
      if (_internalCommentEnabled &&
          _commentController.text.trim().isNotEmpty) {
        await repository.addEvent(
          ticketId: widget.ticketId,
          eventType: 'note',
          description: _commentController.text.trim(),
          createdBy: user.id,
          isInternal: true,
        );
      }

      // Refresh providers
      ref.invalidate(techTicketByIdProvider(widget.ticketId));
      ref.invalidate(techTicketEventsProvider(widget.ticketId));
      ref.invalidate(techQueueProvider);
      // La vista del solicitante (otra sesión, u otro rol en el mismo
      // dispositivo) tiene sus propios providers cacheados por separado;
      // sin esto, un cambio de estatus del técnico no se reflejaba ahí
      // hasta reiniciar la app.
      ref.invalidate(ticketByIdProvider(widget.ticketId));
      ref.invalidate(ticketEventsProvider(widget.ticketId));
      ref.invalidate(userTicketsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket marcado como resuelto'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al resolver ticket: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Handles the "Reasignar" action.
  /// Shows a modal with available technicians and reassigns the ticket.
  Future<void> _handleReassign(Ticket ticket) async {
    final selectedTech = await ReassignModal.show(
      context,
      currentTechId: ticket.assignedTo,
    );

    if (selectedTech == null || !mounted) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(techRepositoryProvider);
      await repository.reassignTicket(widget.ticketId, selectedTech.id);

      // Refresh relevant providers
      ref.invalidate(techTicketByIdProvider(widget.ticketId));
      ref.invalidate(techTicketEventsProvider(widget.ticketId));
      ref.invalidate(techQueueProvider);
      // La vista del solicitante (otra sesión, u otro rol en el mismo
      // dispositivo) tiene sus propios providers cacheados por separado;
      // sin esto, un cambio de estatus del técnico no se reflejaba ahí
      // hasta reiniciar la app.
      ref.invalidate(ticketByIdProvider(widget.ticketId));
      ref.invalidate(ticketEventsProvider(widget.ticketId));
      ref.invalidate(userTicketsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket reasignado a ${selectedTech.fullName}'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reasignar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
