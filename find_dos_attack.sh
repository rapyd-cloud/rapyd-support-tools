#!/bin/bash

# Define the time frame
start_date="29/Aug/2024:00:00:00"
end_date="29/Aug/2024:23:59:59"

# List of LiteSpeed access log files
log_files=(
    "/var/log/litespeed/access.log"
    "/var/log/litespeed/access.log.2024_08_29"

    # Add more log files as needed
)

# List of IP addresses to ignore
ignore_ips=(
    "52.213.162.56"
    "54.214.224.33"
    "52.21.223.221"
    # Add more IP addresses as needed
)
# Temporary file to store intermediate results
temp_file=$(mktemp)

# Convert ignore IPs to a pattern string for easy matching
ignore_pattern=$(printf "|^%s\$" "${ignore_ips[@]}")
ignore_pattern="${ignore_pattern:1}"  # Remove leading |

# Process each log file
for log_file in "${log_files[@]}"; do
    echo "Processing $log_file..."
    awk -v start="$start_date" -v end="$end_date" -v ignore="$ignore_pattern" '
    BEGIN {
        # Convert start and end times to epoch
        split(start, s, "[:/ ]")
        split(end, e, "[:/ ]")
        start_epoch = mktime(s[3] " " s[2] " " s[1] " " s[4] " " s[5] " " s[6])
        end_epoch = mktime(e[3] " " e[2] " " e[1] " " e[4] " " e[5] " " e[6])
    }

    {
        # Extract timestamp and IP address from each line
        match($0, /\[([^\]]+)\]/, arr)
        log_time = arr[1]
        split(log_time, t, "[:/ ]")
        log_epoch = mktime(t[3] " " t[2] " " t[1] " " t[4] " " t[5] " " t[6])
        
        if (log_epoch >= start_epoch && log_epoch <= end_epoch) {
            match($0, /^([0-9.]+) - -/, ip_arr)
            ip = ip_arr[1]
            if (ip != "" && ip !~ ignore) {
                print ip
            }
        }
    }
    ' "$log_file" >> "$temp_file"
done

# Aggregate and fetch geolocation for each IP
awk '
{
    ips[$1]++
}
END {
    for (ip in ips) {
        print ips[ip], ip
    }
}
' "$temp_file" | sort -nr | while read count ip; do
    # Fetch geolocation data
    country=$(curl -s "https://ipinfo.io/$ip" | awk -F'"' '/"country"/ {print $4}')
    echo "$count $ip $country"
done

# Clean up
rm "$temp_file"
