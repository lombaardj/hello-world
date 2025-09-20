#!/bin/bash

# macOS VS Code log paths
log_roots=(
    "$HOME/Library/Application Support/Code/logs"
    "$HOME/Library/Application Support/Code - Insiders/logs"
)

# Check which log directories exist
existing_roots=()
for root in "${log_roots[@]}"; do
    if [[ -d "$root" ]]; then
        existing_roots+=("$root")
    fi
done

echo "Latest GitHub Copilot login entries:"
echo "====================================="

# Temporary file to store all entries
temp_file=$(mktemp)

# Find all Copilot Chat logs and extract login entries
for root in "${existing_roots[@]}"; do
    # Find all GitHub Copilot Chat log files
    find "$root" -path "*/exthost/GitHub.copilot-chat/*.log" 2>/dev/null | while read -r logfile; do
        # Extract login entries with grep and process with sed
        grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}.*Logged in as [^ ]+" "$logfile" 2>/dev/null | while IFS= read -r line; do
            # Extract datetime and username using sed
            datetime=$(echo "$line" | sed -E 's/^([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}).*Logged in as ([^ ]+).*/\1/')
            username=$(echo "$line" | sed -E 's/^([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}).*Logged in as ([^ ]+).*/\2/')
            
            # Output: datetime|username|hostname|user
            echo "$datetime|$username|$(hostname)|$USER"
        done
    done
done > "$temp_file"

# Sort by datetime descending, then by username to get unique entries, then sort by datetime descending again
sort -t'|' -k1,1r -k2,2 "$temp_file" | awk -F'|' '!seen[$2]++ {print $0}' | sort -t'|' -k1,1r | while IFS='|' read -r datetime username hostname user; do
    printf "%-23s %-25s %-15s %-15s\n" "$datetime" "$username" "$hostname" "$user"
done

# Clean up
rm -f "$temp_file"
