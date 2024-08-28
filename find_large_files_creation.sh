#!/bin/bash

# Define the minimum file size (20MB in this case)
MIN_SIZE=20M

# Define the creation date filter (e.g., files created after "2024-01-01")
FILTER_DATE="2024-08-28"

# Find files larger than the specified size and filter by creation date,
# then sort by size in descending order and display the top 20 with the creation date at the end
find / -type f -size +$MIN_SIZE 2>/dev/null | while read -r file; do
    # Extract the creation date using stat (the %W format gives the creation date in seconds since epoch if supported)
    creation_date=$(stat --format '%W' "$file")
    # Convert the creation date from seconds since epoch to a readable format, and filter by the specified date
    if [[ "$creation_date" != "-1" ]] && [[ $(date -d @$creation_date +%Y-%m-%d) > $FILTER_DATE ]]; then
        # Print the file size, name, and creation date
        stat --format '%s %n %w' "$file"
    fi  
done | sort -hr -k1 | head -n 20