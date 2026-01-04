#!/usr/bin/env bash
################################################################################
# ShQL - Database Management System in Bash
# File: recovery.sh
# Description: Recovery system - Snapshots, Rollback, and User Education
#
# Constraints:
#   - NO FUNCTIONS ALLOWED (project requirement)
#   - Uses select/while loops with case statements
#   - Follows Korn/Bash shell standards
################################################################################

# Set strict error handling
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data"
SNAPSHOT_DIR="${DATA_DIR}/snapshots"
SNAPSHOT_DB_DIR="${SNAPSHOT_DIR}/db"
SNAPSHOT_TABLE_DIR="${SNAPSHOT_DIR}/table"
META_DIR="${DATA_DIR}/meta"

# Check if database name is provided
if [[ $# -lt 1 ]]; then
    echo "Error: No database specified."
    echo "Usage: $0 <database_name>"
    exit 1
fi

DB_NAME="$1"
DB_PATH="${DATA_DIR}/${DB_NAME}"

# Validate database exists
if [[ ! -d "$DB_PATH" ]]; then
    echo "Error: Database '${DB_NAME}' does not exist."
    exit 1
fi

# Create snapshot directories if they don't exist
mkdir -p "$SNAPSHOT_DB_DIR"
mkdir -p "$SNAPSHOT_TABLE_DIR"

# Main menu loop
while true; do
    clear
    echo "═══════════════════════════════════════════"
    echo "  ShQL - Recovery System                   "
    echo "  Database: ${DB_NAME}                     "
    echo "═══════════════════════════════════════════"
    echo ""
    echo "Please select an option:"
    echo ""
    
    select choice in \
        "Create Database Snapshot" \
        "Create Table Snapshot" \
        "List Snapshots" \
        "Rollback Database" \
        "Rollback Table" \
        "Recovery Help" \
        "Back to Table Menu"; do
        
        case $REPLY in
            1)
                # Create Database Snapshot
                echo ""
                echo "=== Create Database Snapshot ==="
                echo ""
                echo "This will create a snapshot of the entire database '${DB_NAME}'."
                echo ""
                read -p "Enter a description for this snapshot: " SNAPSHOT_DESC
                
                if [[ -z "$SNAPSHOT_DESC" ]]; then
                    SNAPSHOT_DESC="No description"
                fi
                
                # Generate snapshot name with timestamp
                TIMESTAMP=$(date +%s)
                SNAPSHOT_NAME="${DB_NAME}_${TIMESTAMP}"
                SNAPSHOT_PATH="${SNAPSHOT_DB_DIR}/${SNAPSHOT_NAME}"
                
                echo ""
                echo "Creating snapshot..."
                
                # Create snapshot directory and copy database contents
                mkdir -p "$SNAPSHOT_PATH"
                cp -r "$DB_PATH"/* "$SNAPSHOT_PATH/" 2>/dev/null || true
                
                # Create metadata file
                {
                    echo "name:${DB_NAME}"
                    echo "type:db"
                    echo "database:${DB_NAME}"
                    echo "timestamp:${TIMESTAMP}"
                    echo "description:${SNAPSHOT_DESC}"
                    echo "created:$(date '+%Y-%m-%d %H:%M:%S')"
                } > "${SNAPSHOT_PATH}/snapshot.meta"
                
                echo ""
                echo "✓ Snapshot created successfully!"
                echo "  Location: ${SNAPSHOT_PATH}"
                echo "  Timestamp: $(date -d @$TIMESTAMP '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r $TIMESTAMP '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo $TIMESTAMP)"
                
                read -p "Press Enter to continue..."
                break
                ;;
            2)
                # Create Table Snapshot
                echo ""
                echo "=== Create Table Snapshot ==="
                echo ""
                
                # List available tables
                echo "Available tables:"
                if compgen -G "$DB_PATH/*.meta" > /dev/null; then
                    i=1
                    for meta_file in "$DB_PATH"/*.meta; do
                        table_name=$(basename "$meta_file" .meta)
                        echo "  $i) $table_name"
                        ((i+=1))
                    done
                else
                    echo "  No tables found in this database."
                    read -p "Press Enter to continue..."
                    break
                fi
                
                echo ""
                read -p "Enter table name to snapshot: " TABLE_NAME
                
                if [[ -z "$TABLE_NAME" ]]; then
                    echo "Error: Table name cannot be empty."
                    read -p "Press Enter..."
                    break
                fi
                
                META_FILE="${DB_PATH}/${TABLE_NAME}.meta"
                DATA_FILE="${DB_PATH}/${TABLE_NAME}.data"
                
                if [[ ! -f "$META_FILE" ]]; then
                    echo "Error: Table '${TABLE_NAME}' does not exist."
                    read -p "Press Enter..."
                    break
                fi
                
                read -p "Enter a description for this snapshot: " SNAPSHOT_DESC
                
                if [[ -z "$SNAPSHOT_DESC" ]]; then
                    SNAPSHOT_DESC="No description"
                fi
                
                # Generate snapshot name with timestamp
                TIMESTAMP=$(date +%s)
                SNAPSHOT_NAME="${DB_NAME}_${TABLE_NAME}_${TIMESTAMP}"
                SNAPSHOT_PATH="${SNAPSHOT_TABLE_DIR}/${SNAPSHOT_NAME}"
                
                echo ""
                echo "Creating snapshot..."
                
                # Create snapshot directory and copy table files
                mkdir -p "$SNAPSHOT_PATH"
                cp "$META_FILE" "${SNAPSHOT_PATH}/"
                cp "$DATA_FILE" "${SNAPSHOT_PATH}/" 2>/dev/null || touch "${SNAPSHOT_PATH}/${TABLE_NAME}.data"
                
                # Create metadata file
                {
                    echo "name:${TABLE_NAME}"
                    echo "type:table"
                    echo "database:${DB_NAME}"
                    echo "timestamp:${TIMESTAMP}"
                    echo "description:${SNAPSHOT_DESC}"
                    echo "created:$(date '+%Y-%m-%d %H:%M:%S')"
                } > "${SNAPSHOT_PATH}/snapshot.meta"
                
                echo ""
                echo "✓ Snapshot created successfully!"
                echo "  Table: ${TABLE_NAME}"
                echo "  Location: ${SNAPSHOT_PATH}"
                
                read -p "Press Enter to continue..."
                break
                ;;
            3)
                # List Snapshots
                echo ""
                echo "=== Available Snapshots ==="
                echo ""
                
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo " DATABASE SNAPSHOTS"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                DB_SNAP_COUNT=0
                if [[ -d "$SNAPSHOT_DB_DIR" ]]; then
                    for snap_dir in "$SNAPSHOT_DB_DIR"/${DB_NAME}_*/; do
                        if [[ -d "$snap_dir" ]] && [[ -f "${snap_dir}snapshot.meta" ]]; then
                            ((DB_SNAP_COUNT+=1))
                            SNAP_NAME=$(basename "$snap_dir")
                            SNAP_DESC=$(grep "^description:" "${snap_dir}snapshot.meta" | cut -d: -f2-)
                            SNAP_DATE=$(grep "^created:" "${snap_dir}snapshot.meta" | cut -d: -f2-)
                            echo ""
                            echo "  📦 ${SNAP_NAME}"
                            echo "     Date: ${SNAP_DATE}"
                            echo "     Desc: ${SNAP_DESC}"
                        fi
                    done
                fi
                
                if [[ $DB_SNAP_COUNT -eq 0 ]]; then
                    echo "  No database snapshots found for '${DB_NAME}'."
                fi
                
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo " TABLE SNAPSHOTS"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                TABLE_SNAP_COUNT=0
                if [[ -d "$SNAPSHOT_TABLE_DIR" ]]; then
                    for snap_dir in "$SNAPSHOT_TABLE_DIR"/${DB_NAME}_*/; do
                        if [[ -d "$snap_dir" ]] && [[ -f "${snap_dir}snapshot.meta" ]]; then
                            ((TABLE_SNAP_COUNT+=1))
                            SNAP_NAME=$(basename "$snap_dir")
                            SNAP_TABLE=$(grep "^name:" "${snap_dir}snapshot.meta" | cut -d: -f2-)
                            SNAP_DESC=$(grep "^description:" "${snap_dir}snapshot.meta" | cut -d: -f2-)
                            SNAP_DATE=$(grep "^created:" "${snap_dir}snapshot.meta" | cut -d: -f2-)
                            echo ""
                            echo "  📄 ${SNAP_NAME}"
                            echo "     Table: ${SNAP_TABLE}"
                            echo "     Date: ${SNAP_DATE}"
                            echo "     Desc: ${SNAP_DESC}"
                        fi
                    done
                fi
                
                if [[ $TABLE_SNAP_COUNT -eq 0 ]]; then
                    echo "  No table snapshots found for '${DB_NAME}'."
                fi
                
                echo ""
                read -p "Press Enter to continue..."
                break
                ;;
            4)
                # Rollback Database
                echo ""
                echo "=== Rollback Database ==="
                echo ""
                
                # List available database snapshots
                echo "Available database snapshots for '${DB_NAME}':"
                echo ""
                
                SNAP_LIST=()
                if [[ -d "$SNAPSHOT_DB_DIR" ]]; then
                    for snap_dir in "$SNAPSHOT_DB_DIR"/${DB_NAME}_*/; do
                        if [[ -d "$snap_dir" ]] && [[ -f "${snap_dir}snapshot.meta" ]]; then
                            SNAP_LIST+=("$snap_dir")
                        fi
                    done
                fi
                
                if [[ ${#SNAP_LIST[@]} -eq 0 ]]; then
                    echo "  No database snapshots found."
                    echo "  Create a snapshot first using 'Create Database Snapshot'."
                    read -p "Press Enter to continue..."
                    break
                fi
                
                i=1
                for snap_dir in "${SNAP_LIST[@]}"; do
                    SNAP_NAME=$(basename "$snap_dir")
                    SNAP_DESC=$(grep "^description:" "${snap_dir}snapshot.meta" | cut -d: -f2-)
                    SNAP_DATE=$(grep "^created:" "${snap_dir}snapshot.meta" | cut -d: -f2-)
                    echo "  $i) ${SNAP_NAME}"
                    echo "     ${SNAP_DATE} - ${SNAP_DESC}"
                    ((i+=1))
                done
                
                echo ""
                read -p "Enter snapshot number to rollback to (or 'c' to cancel): " SNAP_NUM
                
                if [[ "$SNAP_NUM" == "c" || "$SNAP_NUM" == "C" ]]; then
                    echo "Rollback cancelled."
                    read -p "Press Enter..."
                    break
                fi
                
                if [[ ! "$SNAP_NUM" =~ ^[1-9][0-9]*$ ]] || [[ "$SNAP_NUM" -gt ${#SNAP_LIST[@]} ]]; then
                    echo "Error: Invalid selection."
                    read -p "Press Enter..."
                    break
                fi
                
                SELECTED_SNAP="${SNAP_LIST[$((SNAP_NUM-1))]}"
                
                echo ""
                echo "⚠️  WARNING: This will replace ALL current data in '${DB_NAME}'!"
                echo ""
                read -p "Are you sure you want to rollback? (y/n): " CONFIRM
                
                if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
                    echo "Rollback cancelled."
                    read -p "Press Enter..."
                    break
                fi
                
                # Create backup before rollback
                BACKUP_TIMESTAMP=$(date +%s)
                BACKUP_NAME="${DB_NAME}_backup_before_rollback_${BACKUP_TIMESTAMP}"
                BACKUP_PATH="${SNAPSHOT_DB_DIR}/${BACKUP_NAME}"
                
                echo ""
                echo "Creating backup of current state..."
                mkdir -p "$BACKUP_PATH"
                cp -r "$DB_PATH"/* "$BACKUP_PATH/" 2>/dev/null || true
                {
                    echo "name:${DB_NAME}"
                    echo "type:db"
                    echo "database:${DB_NAME}"
                    echo "timestamp:${BACKUP_TIMESTAMP}"
                    echo "description:Auto-backup before rollback"
                    echo "created:$(date '+%Y-%m-%d %H:%M:%S')"
                } > "${BACKUP_PATH}/snapshot.meta"
                
                echo "Performing rollback..."
                
                # Remove current data (except directory itself)
                rm -rf "$DB_PATH"/*
                
                # Copy snapshot data (exclude snapshot.meta)
                for item in "$SELECTED_SNAP"/*; do
                    if [[ "$(basename "$item")" != "snapshot.meta" ]]; then
                        cp -r "$item" "$DB_PATH/"
                    fi
                done
                
                echo ""
                echo "✓ Rollback completed successfully!"
                echo "  Backup created: ${BACKUP_NAME}"
                
                read -p "Press Enter to continue..."
                break
                ;;
            5)
                # Rollback Table
                echo ""
                echo "=== Rollback Table ==="
                echo ""
                
                # List available table snapshots
                echo "Available table snapshots for '${DB_NAME}':"
                echo ""
                
                SNAP_LIST=()
                if [[ -d "$SNAPSHOT_TABLE_DIR" ]]; then
                    for snap_dir in "$SNAPSHOT_TABLE_DIR"/${DB_NAME}_*/; do
                        if [[ -d "$snap_dir" ]] && [[ -f "${snap_dir}snapshot.meta" ]]; then
                            SNAP_LIST+=("$snap_dir")
                        fi
                    done
                fi
                
                if [[ ${#SNAP_LIST[@]} -eq 0 ]]; then
                    echo "  No table snapshots found."
                    echo "  Create a snapshot first using 'Create Table Snapshot'."
                    read -p "Press Enter to continue..."
                    break
                fi
                
                i=1
                for snap_dir in "${SNAP_LIST[@]}"; do
                    SNAP_NAME=$(basename "$snap_dir")
                    SNAP_TABLE=$(grep "^name:" "${snap_dir}snapshot.meta" | cut -d: -f2-)
                    SNAP_DESC=$(grep "^description:" "${snap_dir}snapshot.meta" | cut -d: -f2-)
                    SNAP_DATE=$(grep "^created:" "${snap_dir}snapshot.meta" | cut -d: -f2-)
                    echo "  $i) ${SNAP_NAME}"
                    echo "     Table: ${SNAP_TABLE} | ${SNAP_DATE}"
                    echo "     ${SNAP_DESC}"
                    ((i+=1))
                done
                
                echo ""
                read -p "Enter snapshot number to rollback to (or 'c' to cancel): " SNAP_NUM
                
                if [[ "$SNAP_NUM" == "c" || "$SNAP_NUM" == "C" ]]; then
                    echo "Rollback cancelled."
                    read -p "Press Enter..."
                    break
                fi
                
                if [[ ! "$SNAP_NUM" =~ ^[1-9][0-9]*$ ]] || [[ "$SNAP_NUM" -gt ${#SNAP_LIST[@]} ]]; then
                    echo "Error: Invalid selection."
                    read -p "Press Enter..."
                    break
                fi
                
                SELECTED_SNAP="${SNAP_LIST[$((SNAP_NUM-1))]}"
                TABLE_NAME=$(grep "^name:" "${SELECTED_SNAP}snapshot.meta" | cut -d: -f2-)
                
                echo ""
                echo "⚠️  WARNING: This will replace table '${TABLE_NAME}' with snapshot data!"
                echo ""
                read -p "Are you sure you want to rollback? (y/n): " CONFIRM
                
                if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
                    echo "Rollback cancelled."
                    read -p "Press Enter..."
                    break
                fi
                
                META_FILE="${DB_PATH}/${TABLE_NAME}.meta"
                DATA_FILE="${DB_PATH}/${TABLE_NAME}.data"
                
                # Create backup before rollback (if table exists)
                if [[ -f "$META_FILE" ]]; then
                    BACKUP_TIMESTAMP=$(date +%s)
                    BACKUP_NAME="${DB_NAME}_${TABLE_NAME}_backup_${BACKUP_TIMESTAMP}"
                    BACKUP_PATH="${SNAPSHOT_TABLE_DIR}/${BACKUP_NAME}"
                    
                    echo ""
                    echo "Creating backup of current table..."
                    mkdir -p "$BACKUP_PATH"
                    cp "$META_FILE" "${BACKUP_PATH}/"
                    cp "$DATA_FILE" "${BACKUP_PATH}/" 2>/dev/null || touch "${BACKUP_PATH}/${TABLE_NAME}.data"
                    {
                        echo "name:${TABLE_NAME}"
                        echo "type:table"
                        echo "database:${DB_NAME}"
                        echo "timestamp:${BACKUP_TIMESTAMP}"
                        echo "description:Auto-backup before rollback"
                        echo "created:$(date '+%Y-%m-%d %H:%M:%S')"
                    } > "${BACKUP_PATH}/snapshot.meta"
                fi
                
                echo "Performing rollback..."
                
                # Copy snapshot files to database
                cp "${SELECTED_SNAP}${TABLE_NAME}.meta" "$DB_PATH/"
                cp "${SELECTED_SNAP}${TABLE_NAME}.data" "$DB_PATH/" 2>/dev/null || touch "$DATA_FILE"
                
                echo ""
                echo "✓ Table '${TABLE_NAME}' rolled back successfully!"
                
                read -p "Press Enter to continue..."
                break
                ;;
            6)
                # Recovery Help
                clear
                echo "═══════════════════════════════════════════"
                echo "  ShQL Recovery Guide                      "
                echo "═══════════════════════════════════════════"
                echo ""
                echo "📸 SNAPSHOTS"
                echo "  • A snapshot is a point-in-time copy of your data"
                echo "  • Create snapshots BEFORE making risky changes"
                echo "  • Snapshots don't affect your working data"
                echo "  • You can create snapshots for:"
                echo "    - Entire database (all tables)"
                echo "    - Individual tables"
                echo ""
                echo "🔄 ROLLBACK"
                echo "  • Restore your data to a previous snapshot"
                echo "  • WARNING: Rollback replaces current data!"
                echo "  • A backup is created automatically before rollback"
                echo "  • You can rollback to any available snapshot"
                echo ""
                echo "💡 BEST PRACTICES"
                echo "  • Create snapshots before: Drop, Delete, bulk Updates"
                echo "  • Name snapshots descriptively (e.g., 'before_cleanup')"
                echo "  • Regularly clean old snapshots to save space"
                echo "  • Use table snapshots for granular recovery"
                echo "  • Use database snapshots before major changes"
                echo ""
                echo "⚠️  WHEN TO CREATE SNAPSHOTS"
                echo "  • Before dropping a table"
                echo "  • Before deleting many records"
                echo "  • Before running bulk updates"
                echo "  • Before any irreversible operation"
                echo "  • At regular intervals for important data"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                read -p "Press Enter to continue..."
                break
                ;;
            7)
                # Back to Table Menu
                echo ""
                echo "Returning to table menu..."
                exit 0
                ;;
            *)
                echo ""
                echo "Invalid option. Please select 1-7."
                read -p "Press Enter to continue..."
                break
                ;;
        esac
    done
done
