#!/usr/bin/env bash
################################################################################
# ShQL - Database Management System in Bash
# File: table.sh
# Description: Table management interface (CRUD operations)
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

# Check if database path is provided as argument
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

# Main menu loop
while true; do
    clear
    echo "======================================"
    echo "  ShQL - Table Management            "
    echo "  Database: ${DB_NAME}               "
    echo "======================================"
    echo ""
    echo "Please select an option:"
    echo ""
    
    # Using select for menu
    select choice in \
        "Create Table" \
        "List Tables" \
        "Drop Table" \
        "Insert into Table" \
        "Select from Table" \
        "Update Table" \
        "Delete from Table" \
        "Back to Main Menu"; do
        
        case $REPLY in
            1)
                echo ""
                echo "=== Create Table ==="
                # TODO: Implement table creation logic
                # - Prompt for table name
                # - Prompt for column definitions (name:type)
                # - Create table metadata file
                # - Create table data file (CSV-like structure)
                # - Validate primary key constraints
                read -p "Press Enter to continue..."
                break
                ;;
            2)
                echo ""
                echo "=== List Tables ==="
                # TODO: Implement table listing logic
                # - List all tables in current database
                # - Display table metadata (columns, row count)
                # - Format output as table
                read -p "Press Enter to continue..."
                break
                ;;
            3)
                echo ""
                echo "=== Drop Table ==="
                # TODO: Implement table deletion logic
                # - Prompt for table name
                # - Confirm deletion (Y/N)
                # - Remove table metadata and data files
                # - Display success message
                read -p "Press Enter to continue..."
                break
                ;;
            4)
                echo ""
                echo "=== Insert into Table ==="
                # TODO: Implement insert logic
                # - Prompt for table name
                # - Display column names
                # - Prompt for values for each column
                # - Validate data types
                # - Append to table data file using awk/sed
                # - Handle primary key uniqueness
                read -p "Press Enter to continue..."
                break
                ;;
            5)
                echo ""
                echo "=== Select from Table ==="
                # TODO: Implement select logic
                # - Prompt for table name
                # - Prompt for columns to select (* for all)
                # - Prompt for WHERE conditions (optional)
                # - Use awk to filter and format results
                # - Display results in formatted table
                read -p "Press Enter to continue..."
                break
                ;;
            6)
                echo ""
                echo "=== Update Table ==="
                # TODO: Implement update logic
                # - Prompt for table name
                # - Prompt for column to update
                # - Prompt for new value
                # - Prompt for WHERE conditions
                # - Use sed/awk to update matching rows
                # - Display number of rows affected
                read -p "Press Enter to continue..."
                break
                ;;
            7)
                echo ""
                echo "=== Delete from Table ==="
                # TODO: Implement delete logic
                # - Prompt for table name
                # - Prompt for WHERE conditions
                # - Use sed/awk to remove matching rows
                # - Confirm deletion
                # - Display number of rows deleted
                read -p "Press Enter to continue..."
                break
                ;;
            8)
                echo ""
                echo "Returning to main menu..."
                break 2
                ;;
            *)
                echo ""
                echo "Invalid option. Please select 1-8."
                read -p "Press Enter to continue..."
                break
                ;;
        esac
    done
done
