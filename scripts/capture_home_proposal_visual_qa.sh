#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${MEGRUM_SIMULATOR_UDID:-}"
DERIVED_DATA="${MEGRUM_DERIVED_DATA:-/tmp/megrum-native-home-proposal-visual-qa-build}"
BUNDLE_ID="${MEGRUM_BUNDLE_ID:-tokyo.megrum.native.preview}"
PROJECT_PATH="$ROOT_DIR/ios-native/MegrumNative.xcodeproj"
ASSET_DIR="$ROOT_DIR/notes/assets/swift-visual-qa"
RN_ASSET_DIR="$ROOT_DIR/notes/assets/rn-screen-lookup"
HTML_PATH="$ROOT_DIR/RN Swift Home Proposal Visual QA.html"
RN_PORT="${MEGRUM_RN_WEB_PORT:-8082}"
RN_BASE_URL="${MEGRUM_RN_WEB_BASE_URL:-http://localhost:${RN_PORT}}"
CHROME_BIN="${MEGRUM_CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
RN_VIEWPORT_WIDTH="${MEGRUM_RN_VIEWPORT_WIDTH:-402}"
RN_VIEWPORT_HEIGHT="${MEGRUM_RN_VIEWPORT_HEIGHT:-874}"
RN_DEVICE_SCALE_FACTOR="${MEGRUM_RN_DEVICE_SCALE_FACTOR:-3}"
SWIFT_SCREEN_SETTLE_SECONDS="${MEGRUM_SWIFT_SCREEN_SETTLE_SECONDS:-6}"
SKIP_BUILD=0
VERIFY_ONLY=0
INCLUDE_RN=0
RN_ONLY=0
SCREENS=(
  "home:swift-home-preview.png"
  "drawer-open:swift-drawer-open.png"
  "match-relation:swift-match-relation-rn-visual-header.png"
  "match-relation-candidates:swift-match-relation-candidates-expanded.png"
  "proposal-give:swift-proposal-give.png"
  "proposal-receive:swift-proposal-receive.png"
  "proposal-meetup:swift-proposal-meetup-week.png"
  "proposal-meetup-month:swift-proposal-meetup-month.png"
  "proposal-confirm:swift-proposal-confirm-final.png"
  "proposal-complete:swift-proposal-complete-fullscreen.png"
  "proposal-pending:swift-proposal-pending.png"
)
RN_MEETUPS_ENCODED="%5B%7B%22id%22%3A%22qa-1%22%2C%22label%22%3A%22%E5%80%99%E8%A3%9C1%22%2C%22time%22%3A%225%E6%9C%8817%E6%97%A5%2014%3A00%20-%2015%3A00%22%2C%22startAt%22%3A%222026-05-17T14%3A00%3A00%2B09%3A00%22%2C%22endAt%22%3A%222026-05-17T15%3A00%3A00%2B09%3A00%22%2C%22place%22%3A%22%E6%A8%AA%E6%B5%9C%E3%82%A2%E3%83%AA%E3%83%BC%E3%83%8A%20%E5%8C%97%E5%8F%A3%22%2C%22latitude%22%3A35.5075%2C%22longitude%22%3A139.6174%7D%5D"
RN_SCREENS=(
  "home:/?visualPreview=1:rn-home.png"
  "drawer-open:/drawer-visual:rn-drawer-open.png"
  "match-relation-candidates:/match-detail?candidateId=sua-card-01&visualExpanded=candidates:rn-match-detail-candidates-expanded.png"
  "proposal-give:/proposal-select?tab=give&exchangeMethod=hand:rn-proposal-give.png"
  "proposal-receive:/proposal-select?tab=receive&exchangeMethod=hand:rn-proposal-receive.png"
  "proposal-meetup:/proposal-select?tab=meetup&exchangeMethod=hand:rn-proposal-meetup-week.png"
  "proposal-meetup-month:/proposal-select?tab=meetup&exchangeMethod=hand&visualCalendarMode=month:rn-proposal-meetup-month.png"
  "proposal-confirm:/proposal-confirm?gives=give-1&receives=receive-1&exchangeMethod=hand&meetups=${RN_MEETUPS_ENCODED}:rn-proposal-confirm.png"
  "proposal-complete:/proposal-confirm?gives=give-1&receives=receive-1&exchangeMethod=hand&meetups=${RN_MEETUPS_ENCODED}&visualState=complete:rn-proposal-complete.png"
  "proposal-pending:/transactions-visual?visualPreview=1:rn-proposal-pending.png"
)

usage() {
  cat <<'USAGE'
Usage:
  scripts/capture_home_proposal_visual_qa.sh [options]

Options:
  --skip-build        Reuse the existing app in MEGRUM_DERIVED_DATA.
  --verify-only      Only verify that all <img> sources in the comparison HTML exist.
  --include-rn       Also capture RN web screenshots for direct QA routes.
  --rn-only          Capture only RN web screenshots and verify image links.
  --screens a,b,c    Capture only selected Swift QA screens.
                     Example: --screens home,match-relation-candidates
  --rn-screens a,b   Capture only selected RN QA screens.
                     Example: --rn-screens proposal-give,proposal-confirm

Environment:
  MEGRUM_SIMULATOR_UDID  Simulator UDID. Defaults to the first booted simulator.
  MEGRUM_DERIVED_DATA    Xcode derived data path.
  MEGRUM_BUNDLE_ID       App bundle id. Defaults to tokyo.megrum.native.preview.
  MEGRUM_RN_WEB_PORT     Expo web port. Defaults to 8082.
  MEGRUM_RN_WEB_BASE_URL Existing Expo web URL. Defaults to http://localhost:$MEGRUM_RN_WEB_PORT.
  MEGRUM_CHROME_BIN      Chrome binary used for headless screenshots.
  MEGRUM_RN_VIEWPORT_WIDTH
  MEGRUM_RN_VIEWPORT_HEIGHT
                         RN web CSS viewport. Defaults to 402x874.
  MEGRUM_RN_DEVICE_SCALE_FACTOR
                         RN web screenshot scale. Defaults to 3 for 1206x2622 output.
  MEGRUM_SWIFT_SCREEN_SETTLE_SECONDS
                         Seconds to wait after launching each Swift QA screen. Defaults to 6.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --verify-only)
      VERIFY_ONLY=1
      shift
      ;;
    --include-rn)
      INCLUDE_RN=1
      shift
      ;;
    --rn-only)
      INCLUDE_RN=1
      RN_ONLY=1
      shift
      ;;
    --screens)
      if [[ $# -lt 2 ]]; then
        echo "--screens requires a comma-separated list" >&2
        exit 2
      fi
      IFS=',' read -r -a requested <<< "$2"
      filtered=()
      for screen in "${requested[@]}"; do
        for entry in "${SCREENS[@]}"; do
          if [[ "${entry%%:*}" == "$screen" ]]; then
            filtered+=("$entry")
          fi
        done
      done
      if [[ ${#filtered[@]} -ne ${#requested[@]} ]]; then
        echo "Unknown screen in: $2" >&2
        exit 2
      fi
      SCREENS=("${filtered[@]}")
      shift 2
      ;;
    --rn-screens)
      if [[ $# -lt 2 ]]; then
        echo "--rn-screens requires a comma-separated list" >&2
        exit 2
      fi
      IFS=',' read -r -a requested <<< "$2"
      filtered=()
      for screen in "${requested[@]}"; do
        for entry in "${RN_SCREENS[@]}"; do
          if [[ "${entry%%:*}" == "$screen" ]]; then
            filtered+=("$entry")
          fi
        done
      done
      if [[ ${#filtered[@]} -ne ${#requested[@]} ]]; then
        echo "Unknown RN screen in: $2" >&2
        exit 2
      fi
      RN_SCREENS=("${filtered[@]}")
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

verify_html_images() {
  HTML_PATH="$HTML_PATH" node <<'NODE'
const fs = require("fs");
const path = require("path");
const { PNG } = require("pngjs");

const htmlPath = process.env.HTML_PATH;
const rootDir = path.dirname(htmlPath);
const html = fs.readFileSync(htmlPath, "utf8");
const srcs = [...html.matchAll(/<img\s+[^>]*src="([^"]+)"/g)].map((match) => match[1]);
const missing = srcs.filter((src) => !fs.existsSync(path.resolve(rootDir, src)));
const expected = [
  "notes/assets/rn-screen-lookup/rn-home.png",
  "notes/assets/swift-visual-qa/swift-home-preview.png",
  "notes/assets/rn-screen-lookup/rn-drawer-open.png",
  "notes/assets/swift-visual-qa/swift-drawer-open.png",
  "notes/assets/rn-screen-lookup/rn-match-detail.png",
  "notes/assets/swift-visual-qa/swift-match-relation-rn-visual-header.png",
  "notes/assets/rn-screen-lookup/rn-match-detail-candidates-expanded.png",
  "notes/assets/swift-visual-qa/swift-match-relation-candidates-expanded.png",
  "notes/assets/rn-screen-lookup/rn-proposal-give.png",
  "notes/assets/swift-visual-qa/swift-proposal-give.png",
  "notes/assets/rn-screen-lookup/rn-proposal-receive.png",
  "notes/assets/swift-visual-qa/swift-proposal-receive.png",
  "notes/assets/rn-screen-lookup/rn-proposal-meetup-week.png",
  "notes/assets/swift-visual-qa/swift-proposal-meetup-week.png",
  "notes/assets/rn-screen-lookup/rn-proposal-meetup-month.png",
  "notes/assets/swift-visual-qa/swift-proposal-meetup-month.png",
  "notes/assets/rn-screen-lookup/rn-proposal-confirm.png",
  "notes/assets/swift-visual-qa/swift-proposal-confirm-final.png",
  "notes/assets/rn-screen-lookup/rn-proposal-complete.png",
  "notes/assets/swift-visual-qa/swift-proposal-complete-fullscreen.png",
  "notes/assets/rn-screen-lookup/rn-proposal-pending.png",
  "notes/assets/swift-visual-qa/swift-proposal-pending.png"
];
const pairs = [
  {
    id: "home",
    rn: "notes/assets/rn-screen-lookup/rn-home.png",
    swift: "notes/assets/swift-visual-qa/swift-home-preview.png"
  },
  {
    id: "drawer-open",
    rn: "notes/assets/rn-screen-lookup/rn-drawer-open.png",
    swift: "notes/assets/swift-visual-qa/swift-drawer-open.png"
  },
  {
    id: "relation-entry",
    rn: "notes/assets/rn-screen-lookup/rn-match-detail.png",
    swift: "notes/assets/swift-visual-qa/swift-match-relation-rn-visual-header.png"
  },
  {
    id: "relation-candidates-expanded",
    rn: "notes/assets/rn-screen-lookup/rn-match-detail-candidates-expanded.png",
    swift: "notes/assets/swift-visual-qa/swift-match-relation-candidates-expanded.png"
  },
  {
    id: "proposal-give",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-give.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-give.png"
  },
  {
    id: "proposal-receive",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-receive.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-receive.png"
  },
  {
    id: "proposal-meetup-week",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-meetup-week.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-meetup-week.png"
  },
  {
    id: "proposal-meetup-month",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-meetup-month.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-meetup-month.png"
  },
  {
    id: "proposal-confirm",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-confirm.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-confirm-final.png"
  },
  {
    id: "proposal-complete",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-complete.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-complete-fullscreen.png"
  },
  {
    id: "proposal-pending",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-pending.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-pending.png"
  }
];
const expectedSet = new Set(expected);
const srcSet = new Set(srcs);
const missingExpected = expected.filter((src) => !srcSet.has(src));
const unexpected = srcs.filter((src) => !expectedSet.has(src));

function readPng(relativePath) {
  const absolutePath = path.resolve(rootDir, relativePath);
  const png = PNG.sync.read(fs.readFileSync(absolutePath));
  return { path: relativePath, width: png.width, height: png.height, data: png.data };
}

function samplePixel(image, x, y) {
  const sourceX = Math.min(image.width - 1, Math.max(0, Math.floor(x * image.width / 64)));
  const sourceY = Math.min(image.height - 1, Math.max(0, Math.floor(y * image.height / 64)));
  const index = (sourceY * image.width + sourceX) * 4;
  return [
    image.data[index],
    image.data[index + 1],
    image.data[index + 2],
    image.data[index + 3]
  ];
}

function averageLuminance(image) {
  let total = 0;
  for (let y = 0; y < 64; y += 1) {
    for (let x = 0; x < 64; x += 1) {
      const [r, g, b] = samplePixel(image, x, y);
      total += (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
    }
  }
  return Number((total / (64 * 64)).toFixed(2));
}

function meanAbsDiff(lhs, rhs) {
  let total = 0;
  for (let y = 0; y < 64; y += 1) {
    for (let x = 0; x < 64; x += 1) {
      const a = samplePixel(lhs, x, y);
      const b = samplePixel(rhs, x, y);
      total += Math.abs(a[0] - b[0]);
      total += Math.abs(a[1] - b[1]);
      total += Math.abs(a[2] - b[2]);
    }
  }
  return Number((total / (64 * 64 * 3)).toFixed(2));
}

const pairReport = pairs.map((pair) => {
  const rn = readPng(pair.rn);
  const swift = readPng(pair.swift);
  return {
    id: pair.id,
    rn: { path: pair.rn, width: rn.width, height: rn.height, averageLuminance: averageLuminance(rn) },
    swift: { path: pair.swift, width: swift.width, height: swift.height, averageLuminance: averageLuminance(swift) },
    dimensionDelta: {
      width: swift.width - rn.width,
      height: swift.height - rn.height
    },
    normalizedMeanAbsDiff: meanAbsDiff(rn, swift)
  };
});

const report = {
  expectedImageCount: expected.length,
  imageCount: srcs.length,
  missing,
  missingExpected,
  unexpected,
  pairReport
};
fs.mkdirSync(path.resolve(rootDir, "notes/assets/swift-visual-qa"), { recursive: true });
fs.writeFileSync(
  path.resolve(rootDir, "notes/assets/swift-visual-qa/visual-qa-report.json"),
  JSON.stringify(report, null, 2)
);
console.log(JSON.stringify(report, null, 2));
if (missing.length > 0 || missingExpected.length > 0 || unexpected.length > 0) {
  process.exit(1);
}
NODE
}

write_compare_images() {
  HTML_PATH="$HTML_PATH" node <<'NODE'
const fs = require("fs");
const path = require("path");
const { PNG } = require("pngjs");

const htmlPath = process.env.HTML_PATH;
const rootDir = path.dirname(htmlPath);
const pairs = [
  {
    id: "home",
    rn: "notes/assets/rn-screen-lookup/rn-home.png",
    swift: "notes/assets/swift-visual-qa/swift-home-preview.png",
    output: "notes/assets/swift-visual-qa/compare-home-rn-swift.png"
  },
  {
    id: "drawer-open",
    rn: "notes/assets/rn-screen-lookup/rn-drawer-open.png",
    swift: "notes/assets/swift-visual-qa/swift-drawer-open.png",
    output: "notes/assets/swift-visual-qa/compare-drawer-open-rn-swift.png"
  },
  {
    id: "relation-entry",
    rn: "notes/assets/rn-screen-lookup/rn-match-detail.png",
    swift: "notes/assets/swift-visual-qa/swift-match-relation-rn-visual-header.png",
    output: "notes/assets/swift-visual-qa/compare-relation-entry-rn-swift.png"
  },
  {
    id: "relation-candidates-expanded",
    rn: "notes/assets/rn-screen-lookup/rn-match-detail-candidates-expanded.png",
    swift: "notes/assets/swift-visual-qa/swift-match-relation-candidates-expanded.png",
    output: "notes/assets/swift-visual-qa/compare-relation-candidates-expanded-rn-swift.png"
  },
  {
    id: "proposal-give",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-give.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-give.png",
    output: "notes/assets/swift-visual-qa/compare-proposal-give-rn-swift.png"
  },
  {
    id: "proposal-receive",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-receive.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-receive.png",
    output: "notes/assets/swift-visual-qa/compare-proposal-receive-rn-swift.png"
  },
  {
    id: "proposal-meetup-week",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-meetup-week.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-meetup-week.png",
    output: "notes/assets/swift-visual-qa/compare-proposal-meetup-week-rn-swift.png"
  },
  {
    id: "proposal-meetup-month",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-meetup-month.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-meetup-month.png",
    output: "notes/assets/swift-visual-qa/compare-proposal-meetup-month-rn-swift.png"
  },
  {
    id: "proposal-confirm",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-confirm.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-confirm-final.png",
    output: "notes/assets/swift-visual-qa/compare-proposal-confirm-rn-swift.png"
  },
  {
    id: "proposal-complete",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-complete.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-complete-fullscreen.png",
    output: "notes/assets/swift-visual-qa/compare-proposal-complete-rn-swift.png"
  },
  {
    id: "proposal-pending",
    rn: "notes/assets/rn-screen-lookup/rn-proposal-pending.png",
    swift: "notes/assets/swift-visual-qa/swift-proposal-pending.png",
    output: "notes/assets/swift-visual-qa/compare-proposal-pending-rn-swift.png"
  }
];

function readPng(relativePath) {
  return PNG.sync.read(fs.readFileSync(path.resolve(rootDir, relativePath)));
}

function copyInto(source, destination, offsetX, offsetY) {
  for (let y = 0; y < source.height; y += 1) {
    for (let x = 0; x < source.width; x += 1) {
      const sourceIndex = (y * source.width + x) * 4;
      const destinationIndex = ((y + offsetY) * destination.width + x + offsetX) * 4;
      source.data.copy(destination.data, destinationIndex, sourceIndex, sourceIndex + 4);
    }
  }
}

for (const pair of pairs) {
  const rn = readPng(pair.rn);
  const swift = readPng(pair.swift);
  const gap = 48;
  const destination = new PNG({
    width: rn.width + swift.width + gap,
    height: Math.max(rn.height, swift.height),
    colorType: 6
  });
  destination.data.fill(246);
  copyInto(rn, destination, 0, 0);
  copyInto(swift, destination, rn.width + gap, 0);
  fs.writeFileSync(path.resolve(rootDir, pair.output), PNG.sync.write(destination));
  console.log(`Wrote compare ${pair.id} -> ${pair.output}`);
}
NODE
}

if [[ "$VERIFY_ONLY" == "1" ]]; then
  verify_html_images
  write_compare_images
  exit 0
fi

wait_for_url() {
  local url="$1"
  local attempts="${2:-90}"
  for _ in $(seq 1 "$attempts"); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

capture_rn_screens() {
  if [[ ! -x "$CHROME_BIN" ]]; then
    echo "Chrome not found or not executable: $CHROME_BIN" >&2
    exit 1
  fi

  mkdir -p "$RN_ASSET_DIR"

  local started_server=0
  local server_pid=""
  if ! curl -fsS "$RN_BASE_URL" >/dev/null 2>&1; then
    (
      cd "$ROOT_DIR/mobile"
      CI=1 npx expo start --web --port "$RN_PORT"
    ) >/tmp/megrum-rn-visual-qa-expo.log 2>&1 &
    server_pid="$!"
    started_server=1
    trap 'if [[ -n "${server_pid:-}" ]]; then kill "$server_pid" >/dev/null 2>&1 || true; wait "$server_pid" 2>/dev/null || true; fi' EXIT
    wait_for_url "$RN_BASE_URL" 120
  fi

  for entry in "${RN_SCREENS[@]}"; do
    local rest="${entry#*:}"
    local screen="${entry%%:*}"
    local route="${rest%%:*}"
    local filename="${rest#*:}"
    local destination="$RN_ASSET_DIR/$filename"
    local temporary
    temporary="$(mktemp "/tmp/megrum-rn-${screen}.XXXXXX.png")"

    "$CHROME_BIN" \
      --headless=new \
      --disable-gpu \
      --hide-scrollbars \
      --force-device-scale-factor="$RN_DEVICE_SCALE_FACTOR" \
      --window-size="$RN_VIEWPORT_WIDTH,$RN_VIEWPORT_HEIGHT" \
      --screenshot="$temporary" \
      "${RN_BASE_URL}${route}" >/dev/null 2>&1
    cp "$temporary" "$destination"
    rm -f "$temporary"
    echo "Captured RN $screen -> $destination"
  done

  if [[ "$started_server" == "1" && -n "$server_pid" ]]; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" 2>/dev/null || true
    trap - EXIT
  fi
}

if [[ "$INCLUDE_RN" == "1" ]]; then
  capture_rn_screens
fi

if [[ "$RN_ONLY" == "1" ]]; then
  verify_html_images
  exit 0
fi

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(xcrun simctl list devices booted | awk -F '[()]' '/Booted/ { print $2; exit }')"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "No booted simulator found. Boot a simulator or set MEGRUM_SIMULATOR_UDID." >&2
  exit 1
fi

mkdir -p "$ASSET_DIR"

if [[ "$SKIP_BUILD" != "1" ]]; then
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme MegrumNative \
    -destination "id=$DEVICE_ID" \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    build
fi

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/MegrumNative.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found: $APP_PATH" >&2
  exit 1
fi

xcrun simctl install "$DEVICE_ID" "$APP_PATH"

for entry in "${SCREENS[@]}"; do
  screen="${entry%%:*}"
  filename="${entry#*:}"
  destination="$ASSET_DIR/$filename"
  temporary="$(mktemp "/tmp/megrum-swift-${screen}.XXXXXX.png")"

  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  SIMCTL_CHILD_MEGRUM_VISUAL_QA_PREVIEW_AUTH=1 \
    SIMCTL_CHILD_MEGRUM_VISUAL_QA_INITIAL_SCREEN="$screen" \
    xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" >/dev/null
  sleep "$SWIFT_SCREEN_SETTLE_SECONDS"
  xcrun simctl io "$DEVICE_ID" screenshot "$temporary"
  cp "$temporary" "$destination"
  rm -f "$temporary"
done

verify_html_images
write_compare_images
