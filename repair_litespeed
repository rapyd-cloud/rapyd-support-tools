#!/bin/bash
#===============================================================
# EnvPrep Pro - Optimized for KeyDB & LiteSpeed 
#===============================================================
# Author: Alexander Gil
# Description: WordPress Migration Helper for RapydCloud/Jelastic
# Version: 1.1
#===============================================================

set -euo pipefail

# Colors and Formatting
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; LBLUE='\033[1;34m'; NC='\033[0m'
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

log_info() { echo -e "${LBLUE}[$TIMESTAMP - INFO] $1${NC}"; }
log_ok() { echo -e "${GREEN}[$TIMESTAMP - OK] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[$TIMESTAMP - WARNING] $1${NC}"; }
log_err() { echo -e "${RED}[$TIMESTAMP - ERROR] $1${NC}"; }

# Site enumeration via Rapyd CLI
get_users() { rapyd site list --format json | jq -r '.[].user'; }

# --- PRE-MIGRATION (Source Server) ---
run_pre() {
    log_info "=== Starting Pre-Migration ==="
    for user in $(get_users); do
        local wp_path="/home/${user}/web/www/app/public"
        if [ ! -d "$wp_path" ]; then log_warn "Path not found for $user, skipping..."; continue; fi
        
        log_info "Processing $user..."
        cd "$wp_path"

        # 1. Export LiteSpeed Configuration
        log_info "Exporting LiteSpeed Cache configuration..."
        wp litespeed-option export --filename=lsconf-premig.data --allow-root || log_warn "Export failed for $user"

        # 2. Flush Caches (WP and Memory)
        log_info "Flushing caches..."
        wp cache flush --allow-root || true
        
        if command -v keydb-cli &> /dev/null; then
            keydb-cli flushall && log_ok "KeyDB flushed successfully"
        elif command -v redis-cli &> /dev/null; then
            redis-cli flushall && log_ok "Redis flushed successfully"
        fi
        
        wp litespeed-purge all --allow-root || true

        # 3. Clean .htaccess to avoid path conflicts
        log_info "Cleaning .htaccess rules..."
        [ -f .htaccess ] && sed -i '/BEGIN LSCACHE/,/END LSCACHE/d' .htaccess || true
        
        log_ok "Pre-migration completed for $user."
    done
}

# --- POST-MIGRATION (Destination Server) ---
run_post() {
    log_info "=== Starting Post-Migration ==="
    for user in $(get_users); do
        local wp_path="/home/${user}/web/www/app/public"
        if [ ! -d "$wp_path" ]; then continue; fi
        
        log_info "Restoring $user..."
        cd "$wp_path"

        # 1. Import configuration if the file exists
        if [ -f "lsconf-premig.data" ]; then
            log_info "Importing LiteSpeed Cache configuration..."
            # Import without skip-plugins to avoid database errors
            wp litespeed-option import lsconf-premig.data --allow-root && rm -f lsconf-premig.data || log_warn "Import failed for $user"
        fi

        # 2. Force rule regeneration
        wp litespeed-purge all --allow-root || true
        
        # Disable cache for logged-in users (to avoid session bleeding)
        wp litespeed-option set cache-priv false --allow-root 2>/dev/null || true
        
        log_ok "$user restored successfully."
    done

    # 3. Master service restart
    log_info "Restarting OpenLiteSpeed and cleaning PHP processes..."
    systemctl restart lsws || log_warn "Could not restart lsws via systemctl"
    pkill -9 lsphp || true
    log_ok "Services restarted. Process finished."
}

# --- Main Execution ---
case "${1:-}" in
    --pre-migration) run_pre ;;
    --post-migration) run_post ;;
    *) echo "Usage: $0 [--pre-migration | --post-migration]"; exit 1 ;;
esac
