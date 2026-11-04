#!/bin/sh
# Owner runs this ONCE on the integrator Mac (Laptop 2) so auto-sync survives logout/reboot.
# It installs a user LaunchAgent that runs `integrator_sync.sh --watch` from the integrator checkout.
# Remove later with: launchctl bootout gui/$(id -u)/com.logisticsempire.integrator && rm ~/Library/LaunchAgents/com.logisticsempire.integrator.plist
set -e
DIR="$(cd "$(dirname "$0")/.." && pwd)"
[ "$(git -C "$DIR" branch --show-current)" = "main" ] || { echo "Run from the integrator checkout (on main)" >&2; exit 1; }
PLIST="$HOME/Library/LaunchAgents/com.logisticsempire.integrator.plist"
LOG="$HOME/Library/Logs/LogisticsEmpire-integrator.log"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
	<key>Label</key><string>com.logisticsempire.integrator</string>
	<key>ProgramArguments</key><array><string>/bin/sh</string><string>$DIR/scripts/integrator_sync.sh</string><string>--watch</string></array>
	<key>WorkingDirectory</key><string>$DIR</string>
	<key>EnvironmentVariables</key><dict><key>PATH</key><string>$HOME/.rokit/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string></dict>
	<key>RunAtLoad</key><true/>
	<key>KeepAlive</key><true/>
	<key>StandardOutPath</key><string>$LOG</string>
	<key>StandardErrorPath</key><string>$LOG</string>
</dict></plist>
EOF
launchctl bootout "gui/$(id -u)/com.logisticsempire.integrator" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Auto-sync installed. Log: $LOG"
