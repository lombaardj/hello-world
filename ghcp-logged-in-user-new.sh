#!/bin/bash

# macOS VS Code log roots
log_roots=(
  "$HOME/Library/Application Support/Code/logs"
  "$HOME/Library/Application Support/Code - Insiders/logs"
)

# Filter to existing roots
existing_roots=()
for r in "${log_roots[@]}"; do
  [[ -d "$r" ]] && existing_roots+=("$r")
done

echo "Latest GitHub Copilot login entries:"
echo "====================================="
printf "%-23s %-25s %-15s %-15s\n" "DateTime" "GitHub Username" "Hostname" "System User"
printf "%-23s %-25s %-15s %-15s\n" "--------" "---------------" "--------" "-----------"

# Collect + parse + pick latest unique
# 1. find all Copilot Chat logs
# 2. awk: match lines with timestamp + 'Logged in as <username>'
# 3. print datetime|username
# 4. sort reverse by datetime then by username
# 5. awk keep first occurrence per username (latest due to reverse sort)
# 6. final format
{
  for root in "${existing_roots[@]}"; do
    find "$root" -path "*/exthost/GitHub.copilot-chat/*.log" 2>/dev/null
  done
} | while IFS= read -r logfile; do
  [[ -f "$logfile" ]] || continue
  awk '
    # Match: 2025-09-19 12:34:56.123 ... Logged in as username
    /^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}.*Logged in as [^ ]+/ {
      # Extract timestamp (first 23 chars) and username (after "Logged in as ")
      match($0, /^([0-9-]+ [0-9:.]+).*Logged in as ([^ ]+)/, m)
      if (m[1] != \"\" && m[2] != \"\") {
        print m[1] \"|\" m[2]
      }
    }
  ' "$logfile"
done | sort -t'|' -k1,1r -k2,2 | awk -F'|' '!seen[$2]++' | while IFS='|' read -r dt user; do
  printf "%-23s %-25s %-15s %-15s\n" "$dt" "$user" "$(hostname)" "$USER"
done
