@echo off
setlocal

cd /d "%~dp0.."

if not exist android (
  echo Generate Android platform files first...
  flutter create --platforms=android --org com.finora --project-name finora .
)

call flutter pub get

set "SUPABASE_URL=%~1"
set "SUPABASE_ANON_KEY=%~2"

if "%SUPABASE_URL%"=="" set "SUPABASE_URL=https://YOUR_PROJECT.supabase.co"
if "%SUPABASE_ANON_KEY%"=="" set "SUPABASE_ANON_KEY=YOUR_ANON_KEY"

call flutter build apk --release ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY% ^
  --dart-define=USE_DEMO_DATA=false

echo.
echo APK: build\app\outputs\flutter-apk\app-release.apk
endlocal
