#!/usr/bin/env bash
# Captures README screenshots of the example app on an Apple TV simulator.
# Usage: scripts/screenshots.sh <Scheme> <bundle id> <scene> [<scene> ...]
# Writes docs/screenshots/<scene>.png, and fails instead of saving a blank or broken capture.
set -euo pipefail

SCHEME="$1"; BUNDLE_ID="$2"; shift 2
OUT="docs/screenshots"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

# A tvOS simulator runtime is needed to build and run; download it if the runner has none.
if ! xcrun simctl list runtimes available -j | jq -e '[.runtimes[] | select(.name | test("tvOS"))] | length > 0' > /dev/null; then
  echo "No tvOS simulator runtime installed, downloading one"
  xcodebuild -downloadPlatform tvOS
fi

# Newest "Apple TV 4K (3rd generation)", falling back to any Apple TV 4K, then any Apple TV.
pick_device() {
  xcrun simctl list devices available -j | jq -r '
    [.devices | to_entries | sort_by(.key) | reverse[] | select(.key | test("tvOS")) | .value[] | select(.name | test("^Apple TV"))]
    | (map(select(.name | test("3rd generation\\)$"))) + map(select(.name | test("4K"))) + .)
    | .[0].udid // empty'
}

UDID="$(pick_device)"
if [ -z "$UDID" ]; then
  # No Apple TV simulator exists yet: create one from the newest tvOS runtime and the best device type.
  RUNTIME="$(xcrun simctl list runtimes available -j | jq -r '[.runtimes[] | select(.name | test("tvOS"))] | last | .identifier')"
  DEVICE_TYPE="$(xcrun simctl list devicetypes -j | jq -r '
    [.devicetypes[] | select(.name | test("^Apple TV"))]
    | (map(select(.name | test("3rd generation\\)$"))) + map(select(.name | test("4K"))) + .)
    | .[0].identifier')"
  echo "Creating an Apple TV simulator ($DEVICE_TYPE, $RUNTIME)"
  UDID="$(xcrun simctl create "Apple TV 4K" "$DEVICE_TYPE" "$RUNTIME")"
fi
echo "Using simulator $UDID"

xcodebuild build \
  -project "Example/$SCHEME.xcodeproj" \
  -scheme "$SCHEME" \
  -destination "id=$UDID" \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM= | tail -n 5

APP="$(find build/Build/Products -maxdepth 2 -name "$SCHEME.app" | head -n 1)"
if [ -z "$APP" ]; then
  echo "Could not find $SCHEME.app in build/Build/Products" >&2
  exit 1
fi

xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" "$APP"

# A frame captured while the app is still launching (or after it crashed back to the home screen)
# is useless. A launching or blank frame compresses to a tiny PNG, and a crashed app has no process:
# retry until the app is running and the capture has real content.
MIN_BYTES=150000
for scene in "$@"; do
  capture="$TMP/$scene.png"
  ok=0
  for attempt in 1 2 3; do
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    sleep 1
    # Prints "<bundle id>: <pid>". Simulator apps are ordinary host processes, so kill -0 can check them.
    if ! launch_output="$(xcrun simctl launch "$UDID" "$BUNDLE_ID" -screenshot "$scene")"; then
      echo "Could not launch the app for $scene (attempt $attempt), retrying"
      continue
    fi
    pid="${launch_output##*: }"
    # tvOS simulators are slow to settle focus and animations after launch.
    sleep $((8 + attempt * 3))
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "The app is not running for $scene (attempt $attempt), retrying"
      continue
    fi
    rm -f "$capture"
    xcrun simctl io "$UDID" screenshot "$capture"
    size="$(wc -c < "$capture" | tr -d ' ')"
    if [ "$size" -gt "$MIN_BYTES" ]; then
      ok=1
      break
    fi
    echo "Blank capture for $scene ($size bytes, attempt $attempt), retrying"
  done
  if [ "$ok" -ne 1 ]; then
    echo "Capture for $scene is still blank or the app is not running; refusing to commit a broken screenshot." >&2
    exit 1
  fi
  mv "$capture" "$OUT/$scene.png"
  echo "Captured $scene"
done
