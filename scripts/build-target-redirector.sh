#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

if [[ ! -f "burp-extender-api-1.7.22.jar" ]]; then
  echo "Missing burp-extender-api-1.7.22.jar in repo root" >&2
  exit 1
fi

if ! command -v kotlinc >/dev/null 2>&1; then
  KOTLIN_VERSION="1.9.24"
  CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/target-redirector"
  COMPILER_DIR="$CACHE_DIR/kotlinc"
  mkdir -p "$CACHE_DIR"

  if [[ ! -x "$COMPILER_DIR/bin/kotlinc" ]]; then
    ARCHIVE="$CACHE_DIR/kotlin-compiler-${KOTLIN_VERSION}.zip"
    URLS=(
      "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-compiler/${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip"
      "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip"
    )

    downloaded="false"
    for url in "${URLS[@]}"; do
      if curl -fL --retry 3 --connect-timeout 15 "$url" -o "$ARCHIVE"; then
        downloaded="true"
        break
      fi
    done

    if [[ "$downloaded" != "true" ]]; then
      echo "Failed to download Kotlin compiler ${KOTLIN_VERSION}" >&2
      exit 1
    fi

    rm -rf "$COMPILER_DIR"
    unzip -q "$ARCHIVE" -d "$CACHE_DIR"
  fi

  export PATH="$COMPILER_DIR/bin:$PATH"
fi

OUT_DIR="$REPO_DIR/dist"
OUT_JAR="$OUT_DIR/target-redirector.jar"
mkdir -p "$OUT_DIR"

kotlinc -classpath burp-extender-api-1.7.22.jar src/main/kotlin/target-redirector.kt -include-runtime -d "$OUT_JAR"

echo "$OUT_JAR"
