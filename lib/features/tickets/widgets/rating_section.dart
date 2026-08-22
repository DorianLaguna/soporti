import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../providers/ticket_events_provider.dart';
import '../repositories/ticket_repository.dart';
import '../screens/ticket_detail_screen.dart';

/// Sección de calificación y cierre de ticket.
///
/// Visible solo cuando el ticket tiene estatus "Resuelto".
/// Permite al solicitante calificar la atención (1-5) y cerrar el ticket.
///
/// Comportamiento:
/// - Muestra 5 botones numéricos para calificación
/// - Valida que se seleccione una calificación antes de enviar
/// - Al enviar: guarda rating, cambia estatus a "Cerrado", registra evento de cierre
/// - Al finalizar, refresca providers para que la sección desaparezca
class RatingSection extends ConsumerStatefulWidget {
  final String ticketId;

  const RatingSection({super.key, required this.ticketId});

  @override
  ConsumerState<RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends ConsumerState<RatingSection> {
  int? _selectedRating;
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    // Validación: debe seleccionar una calificación
    if (_selectedRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.ratingRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(ticketRepositoryProvider);
      await repository.rateAndCloseTicket(widget.ticketId, _selectedRating!);

      // Refrescar los providers para que la UI se actualice
      ref.invalidate(ticketByIdProvider(widget.ticketId));
      ref.invalidate(ticketEventsProvider(widget.ticketId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar ticket: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // Título de la sección
        Text(
          AppStrings.ratingTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Botones de calificación 1-5
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = _selectedRating == rating;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _RatingButton(
                rating: rating,
                isSelected: isSelected,
                onTap: _isSubmitting
                    ? null
                    : () {
                        setState(() => _selectedRating = rating);
                      },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Botón "Enviar y cerrar ticket"
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRating,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.uvmGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    AppStrings.submitAndClose,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Botón individual de calificación (1-5).
class _RatingButton extends StatelessWidget {
  final int rating;
  final bool isSelected;
  final VoidCallback? onTap;

  const _RatingButton({
    required this.rating,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.uvmGreen : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.uvmGreen : AppColors.divider,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          '$rating',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
