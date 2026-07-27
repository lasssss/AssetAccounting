# PowerShell скрипт для сборки APK
# Запускать из папки D:\AI\Projects\ExcellApp\flutter_app
# Перед запуском установить Flutter: https://flutter.dev

$ErrorActionPreference = 'Stop'

# 1. Создать Flutter проект
$proj = "$env:TEMP\asset_accounting"
if (Test-Path $proj) { Remove-Item -Recurse -Force $proj }
flutter create --project-name asset_accounting $proj

# 2. Скопировать наши файлы
Copy-Item -Recurse -Force lib\* "$proj\lib\"
Copy-Item -Force pubspec.yaml "$proj\pubspec.yaml"

# 3. Создать папку assets
New-Item -ItemType Directory -Force "$proj\assets" | Out-Null

# 4. Собрать APK
Set-Location $proj
flutter pub get
flutter build apk --release

# 5. Скопировать результат обратно
$apk = "$proj\build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    Copy-Item $apk "D:\AI\Projects\ExcellApp\flutter_app\AssetAccounting.apk"
    Write-Host "APK создан: D:\AI\Projects\ExcellApp\flutter_app\AssetAccounting.apk"
} else {
    Write-Error "APK не найден"
}

Set-Location "D:\AI\Projects\ExcellApp\flutter_app"
Remove-Item -Recurse -Force $proj
