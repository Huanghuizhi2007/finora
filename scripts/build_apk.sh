#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."

if [ ! -d "android" ]; then
  echo "Generate Android platform files first..."
  flutter create --platforms=android --org com.finora --project-name finora .
fi

flutter pub get

SUPABASE_URL="${1:-https://YOUR_PROJECT.supabase.co}"
SUPABASE_ANON_KEY="${2:-YOUR_ANON_KEY}"

flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=USE_DEMO_DATA=false

echo "APK: build/app/outputs/flutter-apk/app-release.apk"
