#!/bin/bash

# Define the minimum file size (20MB in this case)
MIN_SIZE=20M

# Define the date to filter files modified after this date (e.g., "2024-01-01")
FILTER_DATE="2024-08-28"

# Find files larger than the specified size and modified after the specified date,
# sort them by size in descending order, and display the top 20 with the modification date at the end
find /var/www -type f -size +$MIN_SIZE -newermt "$FILTER_DATE" -exec ls -lh {} + 2>/dev/null | \ 
    awk '{ print $5, $9, $6, $7, $8 }' | sort -hr -k1 | head -n 50