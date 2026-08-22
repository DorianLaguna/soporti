import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/ticket_repository.dart';

/// Modelo simple para artículos de autoayuda.
class _SelfHelpArticle {
  final String title;
  final String content;

  const _SelfHelpArticle({required this.title, required this.content});
}

/// Artículos de autoayuda estáticos agrupados por categoría.
const Map<String, List<_SelfHelpArticle>> _selfHelpArticles = {
  'Hardware': [
    _SelfHelpArticle(
      title: 'Mi equipo no enciende',
      content:
          'Verifica que el cable de alimentación esté conectado correctamente. '
          'Prueba con otro tomacorriente. Si el equipo es laptop, intenta '
          'mantener presionado el botón de encendido por 10 segundos y luego '
          'conectar el cargador antes de encender nuevamente.',
    ),
    _SelfHelpArticle(
      title: 'El monitor no muestra imagen',
      content:
          'Asegúrate de que el cable de video (HDMI/VGA/DisplayPort) esté bien '
          'conectado tanto al monitor como al equipo. Prueba presionar '
          'Win+P para cambiar el modo de proyección. Si usas docking station, '
          'desconéctala y conecta el monitor directamente.',
    ),
    _SelfHelpArticle(
      title: 'El teclado o mouse no responde',
      content:
          'Si es inalámbrico, verifica las baterías o carga. Intenta '
          'desconectar y reconectar el receptor USB. Para dispositivos '
          'Bluetooth, olvida el dispositivo y vuelve a emparejarlo desde '
          'Configuración > Bluetooth.',
    ),
  ],
  'Software': [
    _SelfHelpArticle(
      title: 'Una aplicación se congela',
      content:
          'Presiona Ctrl+Alt+Supr y abre el Administrador de tareas. '
          'Selecciona la aplicación que no responde y haz clic en "Finalizar '
          'tarea". Si el problema persiste, reinicia el equipo. Asegúrate de '
          'tener las actualizaciones más recientes instaladas.',
    ),
    _SelfHelpArticle(
      title: 'No puedo instalar un programa',
      content:
          'Verifica que tienes permisos de administrador. Si aparece un error '
          'de permisos, contacta a TI para solicitar elevación temporal. '
          'Asegúrate de descargar el instalador desde la fuente oficial.',
    ),
    _SelfHelpArticle(
      title: 'Mi Office no activa la licencia',
      content:
          'Cierra todas las aplicaciones de Office. Abre cualquier app de '
          'Office, ve a Archivo > Cuenta y haz clic en "Cerrar sesión". '
          'Vuelve a iniciar sesión con tu correo corporativo @uvm.mx. Si '
          'el problema continúa, genera un ticket.',
    ),
  ],
  'Red': [
    _SelfHelpArticle(
      title: 'No tengo conexión a internet',
      content:
          'Verifica que el Wi-Fi esté activado. Olvida la red y vuelve a '
          'conectarte ingresando tu usuario y contraseña corporativos. Si '
          'usas cable Ethernet, verifica que esté bien conectado. Intenta '
          'reiniciar el adaptador de red: Configuración > Red > Restablecer.',
    ),
    _SelfHelpArticle(
      title: 'Internet va muy lento',
      content:
          'Cierra pestañas y aplicaciones que no estés usando. Verifica si '
          'hay descargas o actualizaciones en segundo plano. Prueba acercarte '
          'al punto de acceso Wi-Fi. Si el problema afecta a varios usuarios, '
          'probablemente hay un problema de infraestructura — genera un ticket.',
    ),
  ],
  'Accesos': [
    _SelfHelpArticle(
      title: 'Olvidé mi contraseña',
      content:
          'Ve a la página de inicio de sesión y haz clic en "¿Olvidaste tu '
          'contraseña?". Ingresa tu correo corporativo y sigue las instrucciones '
          'del correo de restablecimiento. Si no recibes el correo en 5 minutos, '
          'revisa tu carpeta de spam.',
    ),
    _SelfHelpArticle(
      title: 'No puedo acceder a una carpeta compartida',
      content:
          'Verifica que estés conectado a la red corporativa (VPN si estás '
          'fuera del campus). Asegúrate de estar usando tu usuario de dominio. '
          'Si acabas de cambiar de área, tu jefe inmediato debe solicitar el '
          'acceso a través de un ticket.',
    ),
  ],
  'Otros': [
    _SelfHelpArticle(
      title: 'Necesito un equipo de préstamo',
      content:
          'Los equipos de préstamo se solicitan a través de un ticket '
          'indicando el motivo y la duración estimada. El área de TI evaluará '
          'la disponibilidad y te notificará por correo. El tiempo de respuesta '
          'es de 24 a 48 horas hábiles.',
    ),
    _SelfHelpArticle(
      title: 'Solicitar cambio de equipo',
      content:
          'El cambio de equipo se gestiona a través de tu coordinación. '
          'Tu jefe inmediato debe generar un ticket de categoría "Hardware" '
          'indicando el motivo del cambio. TI evaluará y programará la '
          'migración de datos.',
    ),
  ],
};

/// Pantalla de creación de ticket para el solicitante.
///
/// Incluye:
/// - Chips de categoría (Hardware, Software, Red, Accesos, Otros)
/// - Campo de título (5–100 chars)
/// - Campo de descripción (10–1000 chars) con placeholder
/// - Campo de ubicación prellenado desde perfil
/// - Botones "Cámara" y "Galería" para adjuntar hasta 5 imágenes (≤5MB c/u)
/// - Miniaturas con opción de eliminar
/// - Sección de artículos de autoayuda según categoría
/// - Validación inline de campos obligatorios
/// - Botón "Generar ticket" con loading state
class TicketCreateScreen extends ConsumerStatefulWidget {
  const TicketCreateScreen({super.key});

  @override
  ConsumerState<TicketCreateScreen> createState() => _TicketCreateScreenState();
}

class _TicketCreateScreenState extends ConsumerState<TicketCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCategory;
  final List<File> _attachedImages = [];
  bool _isLoading = false;
  bool _locationPrefilled = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Prellenar la ubicación desde el perfil del usuario.
  void _prefillLocation(String location) {
    if (!_locationPrefilled && location.isNotEmpty) {
      _locationController.text = location;
      _locationPrefilled = true;
    }
  }

  /// Seleccionar imagen desde cámara o galería.
  Future<void> _pickImage(ImageSource source) async {
    if (_attachedImages.length >= 5) {
      _showSnackBar(AppStrings.maxImagesReached);
      return;
    }

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (picked == null) return;

      final file = File(picked.path);
      final fileSize = await file.length();

      // Validar tamaño máximo: 5 MB
      if (fileSize > 5 * 1024 * 1024) {
        _showSnackBar(AppStrings.imageTooLarge);
        return;
      }

      setState(() {
        _attachedImages.add(file);
      });
    } catch (e) {
      _showSnackBar(AppStrings.imageUploadError);
    }
  }

  /// Eliminar una imagen adjunta por índice.
  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

  /// Mostrar artículo de autoayuda en un bottom sheet.
  void _showArticle(_SelfHelpArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                article.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                article.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Enviar el formulario para crear el ticket.
  Future<void> _submitTicket() async {
    // Validar categoría primero.
    if (_selectedCategory == null) {
      _showSnackBar(AppStrings.categoryRequired);
      return;
    }

    // Validar campos del formulario.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        _showSnackBar(AppStrings.error);
        setState(() => _isLoading = false);
        return;
      }

      final repository = ref.read(ticketRepositoryProvider);

      // Crear el ticket.
      final request = CreateTicketRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        location: _locationController.text.trim(),
        requesterId: user.id,
      );

      final ticket = await repository.createTicket(request);

      // TODO: Upload images via storage repository (task 6.2).
      // When implemented, iterate _attachedImages and upload each one.

      if (mounted) {
        context.go('/tickets/${ticket.id}');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(AppStrings.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    // Prellenar ubicación cuando se carga el perfil.
    userAsync.whenData((profile) {
      if (profile != null) {
        _prefillLocation(profile.location);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createTicketTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Categoría ─────────────────────────────────────────────
            Text(
              AppStrings.categoryLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            _CategoryChips(
              selectedCategory: _selectedCategory,
              onSelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
            const SizedBox(height: 20),

            // ─── Artículos de autoayuda ────────────────────────────────
            if (_selectedCategory != null) ...[
              _SelfHelpSection(
                category: _selectedCategory!,
                onArticleTap: _showArticle,
              ),
              const SizedBox(height: 20),
            ],

            // ─── Título ────────────────────────────────────────────────
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppStrings.titleLabel,
                hintText: AppStrings.titlePlaceholder,
                border: const OutlineInputBorder(),
              ),
              maxLength: 100,
              validator: validateTitle,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ─── Descripción ───────────────────────────────────────────
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: AppStrings.descriptionLabel,
                hintText: AppStrings.descriptionPlaceholder,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 1000,
              validator: validateDescription,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 16),

            // ─── Ubicación ─────────────────────────────────────────────
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: AppStrings.locationLabel,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),

            // ─── Imágenes adjuntas ─────────────────────────────────────
            Text(
              AppStrings.attachImages,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            _ImagePickerButtons(
              onCameraTap: () => _pickImage(ImageSource.camera),
              onGalleryTap: () => _pickImage(ImageSource.gallery),
              imageCount: _attachedImages.length,
            ),
            const SizedBox(height: 12),
            if (_attachedImages.isNotEmpty)
              _ImageThumbnails(
                images: _attachedImages,
                onRemove: _removeImage,
              ),
            const SizedBox(height: 24),

            // ─── Botón Generar ticket ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.uvmGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        AppStrings.generateTicket,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Chips de selección de categoría — uno activo a la vez.
class _CategoryChips extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppStrings.categories.map((category) {
        final isSelected = selectedCategory == category;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (_) => onSelected(category),
          selectedColor: AppColors.uvmGreen.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.uvmGreen : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

/// Sección de artículos de autoayuda según categoría seleccionada.
class _SelfHelpSection extends StatelessWidget {
  final String category;
  final ValueChanged<_SelfHelpArticle> onArticleTap;

  const _SelfHelpSection({
    required this.category,
    required this.onArticleTap,
  });

  @override
  Widget build(BuildContext context) {
    final articles = _selfHelpArticles[category] ?? [];
    if (articles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.selfHelpTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.uvmGreen,
              ),
        ),
        const SizedBox(height: 8),
        ...articles.map((article) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColors.divider),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.article_outlined,
                  color: AppColors.uvmGreen,
                ),
                title: Text(
                  article.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onArticleTap(article),
              ),
            )),
      ],
    );
  }
}

/// Botones para adjuntar imágenes desde cámara o galería.
class _ImagePickerButtons extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final int imageCount;

  const _ImagePickerButtons({
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.imageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: imageCount >= 5 ? null : onCameraTap,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text(AppStrings.camera),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: imageCount >= 5 ? null : onGalleryTap,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text(AppStrings.gallery),
        ),
        const Spacer(),
        Text(
          '$imageCount/5',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

/// Miniaturas de imágenes adjuntas con botón para eliminar.
class _ImageThumbnails extends StatelessWidget {
  final List<File> images;
  final ValueChanged<int> onRemove;

  const _ImageThumbnails({
    required this.images,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    images[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onRemove(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
