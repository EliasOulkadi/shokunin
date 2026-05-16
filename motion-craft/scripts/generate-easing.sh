#!/usr/bin/env bash
set -euo pipefail

# ── Motion Craft: Easing + Duration Generator ──────────────────────────
# Usage:
#   ./generate-easing.sh [style] [scale]
#
# style:  material | playful | calm     (default: material)
# scale:  <number>                      (default: 1.0)
#
# Generates CSS custom properties for easing curves and durations.
# ────────────────────────────────────────────────────────────────────────

STYLE="${1:-material}"
SCALE="${2:-1.0}"

if ! [[ "$SCALE" =~ ^[0-9]+\.?[0-9]*$ ]]; then
  echo "Error: scale must be a number (got: $SCALE)" >&2
  exit 1
fi

# ── Easing presets per style ────────────────────────────────────────────

case "$STYLE" in
  material)
    DECELERATED="cubic-bezier(0.0, 0.0, 0.2, 1.0)"
    ACCELERATED="cubic-bezier(0.4, 0.0, 1.0, 1.0)"
    STANDARD="cubic-bezier(0.4, 0.0, 0.2, 1.0)"
    EMPHASIZED="cubic-bezier(0.4, 0.0, 0.2, 1.0)"
    EMPHASIZED_DECEL="cubic-bezier(0.05, 0.7, 0.1, 1.0)"
    EMPHASIZED_ACCEL="cubic-bezier(0.3, 0.0, 0.8, 0.15)"
    SPRING_LIGHT="linear(0, 0.009, 0.032 2.1%, 0.062 3.2%, 0.128 5.4%, 0.202 7.8%, 0.442 13.5%, 0.724 19.9%, 1.608 32.4%, 1.472 38.1%, 1.136 46.8%, 1.008 53.9%, 0.978 57.9%, 0.978 63.3%, 1.001 72.5%, 1.016 79.6%, 1.004 91.9%, 1)"
    SPRING_BOUNCY="linear(0, 0.004, 0.016 1.9%, 0.108 4.8%, 0.254 7.9%, 0.606 13.5%, 1.122 19.9%, 1.642 25.8%, 1.982 31.4%, 1.998 34.4%, 1.864 39.4%, 1.502 46.4%, 1.306 51.1%, 1.148 57.2%, 1.086 61.3%, 1.042 67.6%, 1.014 76.8%, 1.002 88.8%, 1)"
    ;;
  playful)
    DECELERATED="cubic-bezier(0.0, 0.0, 0.0, 1.0)"
    ACCELERATED="cubic-bezier(0.5, 0.0, 1.0, 1.0)"
    STANDARD="cubic-bezier(0.34, 1.56, 0.64, 1.0)"
    EMPHASIZED="cubic-bezier(0.34, 1.56, 0.64, 1.0)"
    EMPHASIZED_DECEL="cubic-bezier(0.0, 0.8, 0.2, 1.0)"
    EMPHASIZED_ACCEL="cubic-bezier(0.3, 0.0, 0.8, 0.15)"
    SPRING_LIGHT="linear(0, 0.006 1.2%, 0.112 3.5%, 0.268 5.9%, 0.498 8.6%, 1.054 14.1%, 1.594 19.7%, 1.79 23.4%, 1.716 27.1%, 1.392 33.2%, 1.186 38.2%, 1.068 44.3%, 1.016 50.2%, 1.004 55.8%, 1.002 62.4%, 1 74.6%, 1)"
    SPRING_BOUNCY="linear(0, 0.002, 0.128 2.7%, 0.384 5.4%, 0.656 8.2%, 1.542 13.5%, 2.258 18.7%, 2.578 22.9%, 1.974 30.7%, 1.516 36.9%, 1.2 43.5%, 1.074 49.6%, 1.016 56.1%, 1.002 63.7%, 1 74.8%, 1)"
    ;;
  calm)
    DECELERATED="cubic-bezier(0.0, 0.0, 0.1, 1.0)"
    ACCELERATED="cubic-bezier(0.5, 0.0, 0.9, 1.0)"
    STANDARD="cubic-bezier(0.25, 0.1, 0.25, 1.0)"
    EMPHASIZED="cubic-bezier(0.25, 0.1, 0.25, 1.0)"
    EMPHASIZED_DECEL="cubic-bezier(0.0, 0.0, 0.05, 1.0)"
    EMPHASIZED_ACCEL="cubic-bezier(0.4, 0.0, 0.6, 0.05)"
    SPRING_LIGHT="linear(0, 0.002 1.3%, 0.055 4.1%, 0.128 6.9%, 0.378 12.9%, 0.608 18.5%, 0.792 23.7%, 0.914 28.7%, 0.982 33.7%, 1.014 39.4%, 1.012 45.1%, 0.992 53.7%, 1.002 71.3%, 1)"
    SPRING_BOUNCY="linear(0, 0.001 0.9%, 0.076 3.5%, 0.196 6.3%, 0.474 11.6%, 0.796 17%, 1.078 22.5%, 1.218 27.4%, 1.2 32.2%, 1.076 39%, 1.016 46.8%, 1.002 56.7%, 1 71.1%, 1)"
    ;;
  *)
    echo "Error: unknown style '$STYLE'. Use: material | playful | calm" >&2
    exit 1
    ;;
esac

# ── Duration scale ──────────────────────────────────────────────────────

BASE_DURATIONS=(
  "instant:50"
  "fast:100"
  "normal:200"
  "slow:350"
  "glacial:500"
)

echo "/* ── Motion Craft: Generated Tokens ────────────────────────── */"
echo "/*   Style: $STYLE   |   Scale: ${SCALE}x                     */"
echo "/*   Generated: $(date +%Y-%m-%d)                             */"
echo "/* ──────────────────────────────────────────────────────────── */"
echo ""
echo ":root {"

# Easing tokens
echo "  /* Easing curves */"
echo "  --ease-decelerated: $DECELERATED;"
echo "  --ease-accelerated: $ACCELERATED;"
echo "  --ease-standard: $STANDARD;"
echo "  --ease-emphasized: $EMPHASIZED;"
echo "  --ease-emphasized-decel: $EMPHASIZED_DECEL;"
echo "  --ease-emphasized-accel: $EMPHASIZED_ACCEL;"
echo "  --ease-spring-light: $SPRING_LIGHT;"
echo "  --ease-spring-bouncy: $SPRING_BOUNCY;"
echo ""

# Duration tokens (scaled)
echo "  /* Durations (scaled ×$SCALE) */"
for entry in "${BASE_DURATIONS[@]}"; do
  NAME="${entry%%:*}"
  VALUE="${entry##*:}"
  SCALED=$(echo "$VALUE * $SCALE" | bc -l 2>/dev/null || echo "$VALUE * $SCALE" | python3 -c "import sys; print(float(sys.stdin.read().strip().split('*')[0]) * $SCALE)" 2>/dev/null || echo "$VALUE")
  SCALED_INT=$(printf "%.0f" "$SCALED" 2>/dev/null || echo "$SCALED")
  echo "  --duration-$NAME: ${SCALED_INT}ms;"
done

echo "}"

# ── Spring presets (for JS animation libs) ──────────────────────────────

echo ""
echo "/* ── Spring presets (for Framer Motion / react-spring) ─────── */"
echo "/* Style: $STYLE */"
echo "/*"

case "$STYLE" in
  material)
    echo "   * Light:   { type: 'spring', stiffness: 300, damping: 30 }"
    echo "   * Bouncy:  { type: 'spring', stiffness: 500, damping: 25 }"
    echo "   * Gentle:  { type: 'spring', stiffness: 200, damping: 40 }"
    ;;
  playful)
    echo "   * Light:   { type: 'spring', stiffness: 400, damping: 20 }"
    echo "   * Bouncy:  { type: 'spring', stiffness: 700, damping: 15 }"
    echo "   * Gentle:  { type: 'spring', stiffness: 250, damping: 25 }"
    ;;
  calm)
    echo "   * Light:   { type: 'spring', stiffness: 200, damping: 35 }"
    echo "   * Bouncy:  { type: 'spring', stiffness: 350, damping: 30 }"
    echo "   * Gentle:  { type: 'spring', stiffness: 150, damping: 45 }"
    ;;
esac
echo "*/"
