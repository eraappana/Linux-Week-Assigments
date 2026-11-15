#!/usr/bin/env bash
set -euo pipefail

# Return the disk status based on the usage percentage.
disk_status() {
    if [ "$1" -ge 80 ]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

# Test the function without changing the real disk usage.
if [ "${1:-}" = "--test" ]; then
    for value in 50 80 90; do
        echo "$value%: $(disk_status "$value")"
    done
    exit 0
fi

GENERATED_AT=$(date '+%Y-%m-%d %H:%M:%S %Z (%z)')
UPTIME_TEXT=$(uptime -p)
DISK_USAGE=$(df -P / | awk 'NR == 2 {print $5}')
DISK_PERCENT=${DISK_USAGE%\%}
DISK_STATUS=$(disk_status "$DISK_PERCENT")
MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
MEM_AVAILABLE=$(free -m | awk '/^Mem:/ {print $7}')

PROJECT_DIR="/var/www/viikko3"
OUTPUT_DIR="$PROJECT_DIR/public"

cp "$PROJECT_DIR/style.css" "$OUTPUT_DIR/style.css"
chmod 644 "$OUTPUT_DIR/style.css"

# Build a complete report before replacing the previous one.
TEMP_FILE=$(mktemp "$OUTPUT_DIR/.report.XXXXXX")
trap 'rm -f "$TEMP_FILE"' EXIT

cat > "$TEMP_FILE" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Week 3 - Server Status</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <header>
        <h1>My Web Project Week 3</h1>
        <p>Linux command line and Bash scripting</p>
        <p>I created a Bash script that generates a status report
        for my server in CSC cPouta.</p>
    </header>

    <section>
        <h2>Server status</h2>
        <table>
            <tr><th scope="row">Report generated</th><td>$GENERATED_AT</td></tr>
            <tr><th scope="row">Server uptime</th><td>$UPTIME_TEXT</td></tr>
            <tr><th scope="row">Root disk usage</th><td>$DISK_USAGE</td></tr>
            <tr><th scope="row">Disk space status</th><td>$DISK_STATUS</td></tr>
            <tr><th scope="row">Total RAM</th><td>$MEM_TOTAL MiB</td></tr>
            <tr><th scope="row">Available RAM</th><td>$MEM_AVAILABLE MiB</td></tr>
        </table>
        <p>Disk status is OK below 80% usage and WARNING at 80% or above.</p>
    </section>
</body>
</html>
HTML

chmod 644 "$TEMP_FILE"
mv -f "$TEMP_FILE" "$OUTPUT_DIR/index.html"
echo "Report generated: $GENERATED_AT"
