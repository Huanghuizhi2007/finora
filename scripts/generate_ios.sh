#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
flutter create --platforms=ios --org com.finora --project-name finora .
flutter pub get
