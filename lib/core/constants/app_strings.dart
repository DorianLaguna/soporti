/// Strings de UI centralizados para la aplicación SoporTI.
/// Todos los textos están en español.
class AppStrings {
  AppStrings._();

  // ─── General ─────────────────────────────────────────────────────────
  static const String appName = 'SoporTI';
  static const String loading = 'Cargando...';
  static const String error = 'Ocurrió un error';
  static const String retry = 'Reintentar';
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String back = 'Volver';
  static const String confirm = 'Confirmar';

  // ─── Auth / Login ────────────────────────────────────────────────────
  static const String loginTitle = 'Iniciar sesión';
  static const String emailLabel = 'Correo corporativo';
  static const String emailPlaceholder = 'nombre@empresa.mx';
  static const String passwordLabel = 'Contraseña';
  static const String loginButton = 'Ingresar';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';
  static const String accountsProvisioned =
      'Las cuentas son provisionadas por el área de TI';
  static const String invalidCredentials =
      'Correo o contraseña incorrectos';
  static const String invalidEmailFormat =
      'Ingresa un correo electrónico válido';
  static const String fieldRequired = 'Este campo es obligatorio';
  static const String resetPasswordSent =
      'Se envió un correo de restablecimiento';
  static const String resetPasswordError =
      'No se pudo enviar el correo de restablecimiento';

  // ─── Tickets - Lista ─────────────────────────────────────────────────
  static const String greeting = 'Hola, ';
  static const String myTickets = 'Mis tickets';
  static const String activeTickets = 'tickets activos';
  static const String filterAll = 'Todos';
  static const String filterOpen = 'Abiertos';
  static const String filterInProgress = 'En proceso';
  static const String filterClosed = 'Cerrados';
  static const String emptyTickets =
      'No hay tickets para el filtro seleccionado';
  static const String newTicket = 'Nuevo ticket';

  // ─── Tickets - Creación ──────────────────────────────────────────────
  static const String createTicketTitle = 'Nuevo ticket';
  static const String categoryLabel = 'Categoría';
  static const String titleLabel = 'Título';
  static const String titlePlaceholder = 'Título del incidente';
  static const String descriptionLabel = 'Descripción';
  static const String descriptionPlaceholder =
      'Describe qué ocurre, desde cuándo y qué has intentado';
  static const String locationLabel = 'Ubicación';
  static const String attachImages = 'Adjuntar imágenes';
  static const String camera = 'Cámara';
  static const String gallery = 'Galería';
  static const String generateTicket = 'Generar ticket';
  static const String selfHelpTitle =
      '¿Alguno de estos artículos resuelve tu caso?';
  static const String titleMinLength =
      'El título debe tener al menos 5 caracteres';
  static const String titleMaxLength =
      'El título no puede exceder 100 caracteres';
  static const String descriptionMinLength =
      'La descripción debe tener al menos 10 caracteres';
  static const String descriptionMaxLength =
      'La descripción no puede exceder 1000 caracteres';
  static const String categoryRequired = 'Selecciona una categoría';
  static const String maxImagesReached =
      'Máximo 5 imágenes permitidas';
  static const String imageTooLarge =
      'La imagen excede el tamaño máximo de 5 MB';
  static const String imageUploadError =
      'No se pudo adjuntar la imagen. Intenta de nuevo.';

  // ─── Categorías ──────────────────────────────────────────────────────
  static const String categoryHardware = 'Hardware';
  static const String categorySoftware = 'Software';
  static const String categoryNetwork = 'Red';
  static const String categoryAccess = 'Accesos';
  static const String categoryOther = 'Otros';

  static const List<String> categories = [
    categoryHardware,
    categorySoftware,
    categoryNetwork,
    categoryAccess,
    categoryOther,
  ];

  // ─── Prioridades ────────────────────────────────────────────────────
  static const String priorityCritica = 'Crítica';
  static const String priorityAlta = 'Alta';
  static const String priorityMedia = 'Media';
  static const String priorityBaja = 'Baja';

  static const List<String> priorities = [
    priorityCritica,
    priorityAlta,
    priorityMedia,
    priorityBaja,
  ];

  // ─── Estatus ─────────────────────────────────────────────────────────
  static const String statusAbierto = 'Abierto';
  static const String statusAsignado = 'Asignado';
  static const String statusEnProceso = 'En proceso';
  static const String statusEnEspera = 'En espera';
  static const String statusResuelto = 'Resuelto';
  static const String statusCerrado = 'Cerrado';

  // ─── Ticket - Detalle ────────────────────────────────────────────────
  static const String ticketDetail = 'Detalle del ticket';
  static const String timeline = 'Línea de tiempo';
  static const String ratingTitle = '¿Cómo calificas la atención recibida?';
  static const String submitAndClose = 'Enviar y cerrar ticket';
  static const String ratingRequired =
      'Selecciona una calificación antes de enviar';
  static const String slaBreached = 'Vencido';
  static const String slaRemaining = 'restantes';

  // ─── Técnico - Cola ──────────────────────────────────────────────────
  static const String techQueue = 'Mi cola';
  static const String availableTickets = 'Disponibles';
  static const String knowledgeBase = 'Base';
  static const String changeStatus = 'Cambiar estatus';
  static const String hoursRemaining = 'h restantes';
  static const String emptyQueue =
      'No hay tickets en tu cola';
  static const String assignToMe = 'Asignarme';

  // ─── Técnico - Detalle/Gestión ───────────────────────────────────────
  static const String reassign = 'Reasignar';
  static const String solutionLabel = 'Solución aplicada';
  static const String internalComment =
      'Comentario interno · no visible para el solicitante';
  static const String markResolved = 'Marcar resuelto';
  static const String solutionRequired =
      'La solución debe tener entre 10 y 1000 caracteres';
  static const String statusChangeRequired =
      'Selecciona un estatus diferente al actual';
  static const String selectTechnician = 'Seleccionar técnico';

  // ─── Supervisor - Dashboard ──────────────────────────────────────────
  static const String dashboard = 'Indicadores';
  static const String periodSuffix = ' · a la fecha';
  static const String kpiOpenTickets = 'Tickets abiertos';
  static const String kpiAvgResolution = 'Tiempo prom. resolución';
  static const String kpiSlaCompliance = 'Cumplimiento SLA';
  static const String kpiSatisfaction = 'Satisfacción';
  static const String categoryDistribution = 'Distribución por categoría';
  static const String techWorkload = 'Carga por técnico';
  static const String noDataAvailable =
      'No hay datos disponibles para el periodo';
  static const String hours = 'h';
  static const String ticketsLabel = 'Tickets';
  static const String team = 'Equipo';

  // ─── Perfil ──────────────────────────────────────────────────────────
  static const String profile = 'Perfil';
  static const String logout = 'Cerrar sesión';
  static const String roleSolicitante = 'Solicitante';
  static const String roleTecnico = 'Técnico';
  static const String roleSupervisor = 'Supervisor';

  // ─── Offline ─────────────────────────────────────────────────────────
  static const String offlineBanner = 'Sin conexión';
  static const String pendingOperations = 'operaciones pendientes';
  static const String pendingSend = 'Pendiente de enviar';
  static const String localResolved = 'Estatus: resuelto local';
  static const String unsyncedComment = 'Comentario sin sincronizar';

  // ─── Navegación ──────────────────────────────────────────────────────
  static const String navMyTickets = 'Mis tickets';
  static const String navNew = 'Nuevo';
  static const String navProfile = 'Perfil';
  static const String navQueue = 'Mi cola';
  static const String navAvailable = 'Disponibles';
  static const String navBase = 'Base';
  static const String navDashboard = 'Indicadores';
  static const String navTickets = 'Tickets';
  static const String navTeam = 'Equipo';
}
