#!/usr/bin/env bash
set -euo pipefail

# Run from the project root after installing Flutter.
flutter create . --platforms=android,ios,web --project-name mind_agora_flutter
flutter pub get
