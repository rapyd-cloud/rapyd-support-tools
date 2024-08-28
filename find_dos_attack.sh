#!/bin/bash

# Define the time frame
start_date="20/Aug/2024:00:00:00"
end_date="21/Aug/2024:23:59:59"

# List of LiteSpeed access log files
log_files=(
    "/var/log/litespeed/access.log"
    "/var/log/litespeed/access.log.2024_08_21"
    "/var/log/litespeed/access.log.2024_08_21.01"
    "/var/log/litespeed/access.log.2024_08_21.02"
    "/var/log/litespeed/access.log.2024_08_21.03"
    "/var/log/litespeed/access.log.2024_08_21.04"
    "/var/log/litespeed/access.log.2024_08_21.05"
    "/var/log/litespeed/access.log.2024_08_21.06"
    "/var/log/litespeed/access.log.2024_08_21.07"
    # Add more log files as needed
)

# Temporary file to store intermediate results
temp_file=$(mktemp)

# Process each log file
for log_file in "${log_files[@]}"; do
    echo "Processing $log_file..."
    awk -v start="$start_date" -v end="$end_date" '
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
            if (ip != "") {
                print ip
            }
        }
    }
    ' "$log_file" >> "$temp_file"
done

# Aggregate results
awk '
{
    ips[$1]++
}
END {
    for (ip in ips) {
        print ips[ip], ip
    }
}
' "$temp_file" | sort -nr | head

# Clean up
rm "$temp_file"