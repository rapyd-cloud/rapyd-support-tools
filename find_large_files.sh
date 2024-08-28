#!/bin/bash

# Define the minimum file size (20MB in this case)
MIN_SIZE=20M

# Find files larger than the specified size, sort them by size in descending order, 
# and display the top 20, with the modification date at the end of each line
find / -type f -size +$MIN_SIZE -exec ls -lh {} + 2>/dev/null | \ 
    awk '{ print $5, $9, $6, $7, $8 }' | sort -hr -k1 | head -n 50