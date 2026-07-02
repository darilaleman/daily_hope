# setup_structure.ps1 - Ejecutar desde la raíz del proyecto
# PowerShell: .\setup_structure.ps1

# Crear directorios
$directories = @(
    "lib/core/theme",
    "lib/core/constants",
    "lib/core/router",
    "lib/core/utils",
    "lib/data/local/hive",
    "lib/data/local/models",
    "lib/data/remote",
    "lib/data/repositories",
    "lib/features/daily/presentation/screens",
    "lib/features/daily/presentation/widgets",
    "lib/features/daily/presentation/providers",
    "lib/features/daily/domain/entities",
    "lib/features/favorites/presentation/screens",
    "lib/features/favorites/presentation/providers",
    "lib/features/history/presentation/screens",
    "lib/features/history/presentation/providers",
    "lib/features/settings/presentation/screens",
    "lib/features/notifications/services",
    "lib/features/notifications/providers",
    "assets/texts",
    "assets/fonts",
    "assets/images"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Write-Host "✓ Creado: $dir" -ForegroundColor Green
}

# Crear archivos vacíos
$files = @(
    "lib/main.dart",
    "lib/app.dart",
    "lib/core/theme/app_colors.dart",
    "lib/core/theme/app_text_styles.dart",
    "lib/core/theme/app_theme.dart",
    "lib/core/constants/api_constants.dart",
    "lib/core/constants/app_constants.dart",
    "lib/core/router/app_router.dart",
    "lib/core/utils/date_utils.dart",
    "lib/core/utils/share_utils.dart",
    "lib/data/local/hive/hive_service.dart",
    "lib/data/local/hive/boxes.dart",
    "lib/data/local/models/daily_text_model.dart",
    "lib/data/local/models/favorite_model.dart",
    "lib/data/remote/bible_api_service.dart",
    "lib/data/remote/ai_text_service.dart",
    "lib/data/repositories/daily_text_repository.dart",
    "lib/data/repositories/favorites_repository.dart",
    "lib/features/daily/presentation/screens/daily_screen.dart",
    "lib/features/daily/presentation/widgets/text_display_card.dart",
    "lib/features/daily/presentation/widgets/language_toggle.dart",
    "lib/features/daily/presentation/widgets/action_buttons.dart",
    "lib/features/daily/presentation/providers/daily_provider.dart",
    "lib/features/daily/domain/entities/daily_text.dart",
    "lib/features/favorites/presentation/screens/favorites_screen.dart",
    "lib/features/favorites/presentation/providers/favorites_provider.dart",
    "lib/features/history/presentation/screens/history_screen.dart",
    "lib/features/history/presentation/providers/history_provider.dart",
    "lib/features/settings/presentation/screens/settings_screen.dart",
    "lib/features/notifications/services/notification_service.dart",
    "lib/features/notifications/providers/notification_provider.dart",
    "assets/texts/es_reflections.json",
    "assets/texts/en_reflections.json",
    "assets/texts/prayers.json"
)

foreach ($file in $files) {
    New-Item -ItemType File -Force -Path $file | Out-Null
    Write-Host "✓ Creado: $file" -ForegroundColor Cyan
}

Write-Host "`n✅ Estructura creada exitosamente!" -ForegroundColor Green