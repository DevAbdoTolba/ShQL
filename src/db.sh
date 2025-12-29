#!/usr/bin/env bash
################################################################################
# ShQL - Database Management System in Bash
# File: db.sh
# Description: Main database management interface
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
META_DIR="${DATA_DIR}/meta"


# Initialize data directory if it doesn't exist
if [[ ! -d "$DATA_DIR" ]]; then
    mkdir -p "$DATA_DIR"
fi

if [[ ! -d "$META_DIR" ]]; then
    mkdir -p "$META_DIR"
fi

if [[ ! -f "$META_DIR/DBS" ]]; then
    touch "$META_DIR/DBS"
fi

# Main menu loop
while true; do
    clear
    echo "======================================"
    echo "  ShQL - Database Management System  "
    echo "======================================"
    echo ""
    echo "Please select an option:"
    echo ""

    # Using select for menu (alternative to PS3 prompts)
    select choice in \
        "Create Database" \
        "List Databases" \
        "Connect to Database" \
        "Drop Database" \
        "Exit"; do

        case $REPLY in
            1)
                echo ""
                echo "=== Create Database ==="
                read -p "Enter database name (3,55 and only english letters): " db_name
                if [[ -z "$db_name" ]]; then
                    echo "Error: Can not be empty"
                elif [[ "${#db_name}" -lt 3  ]]; then
                    echo "Error: Can not be less than 3 letters!"
                elif [[ "${#db_name}" -gt 55 ]]; then
                    echo "Error: Can not be more than 55 letters!"
                elif [[ ! "$db_name" =~ ^[a-zA-Z]{3,55}$ ]]; then
                    echo "Error: Only english letters"
                elif [[ "$db_name" =~ " " ]]; then
                    echo "Error: can not include space"
                elif [[ "$db_name" =~ ^[a-zA-Z]{3,55}$ ]]; then
                    if grep -q "$db_name" "$META_DIR/DBS"; then
                        echo "ERROR: Database already Exists!"
                    else
                        echo "Creating Database: ${db_name}"
                        echo "${db_name},0," >> "$META_DIR/DBS"
                        mkdir $DATA_DIR/$db_name
                    fi
                fi
                read -p "Press Enter to continue..."
                break
                ;;
            2)
                echo ""
                echo "=== List Databases ==="
                # TODO: Implement database listing logic
                # - List all directories in $DATA_DIR
                # - Display in formatted table
                # - Show database metadata (creation date, table count, etc.)
                read -p "Press Enter to continue..."
                break
                ;;
            3)
                echo ""
                echo "=== Connect to Database ==="
                # TODO: Implement database connection logic
                # - Prompt for database name
                # - Validate database exists
                # - Export database path for table operations
                # - Call table.sh for table management
                read -p "Press Enter to continue..."
                break
                ;;
            4)
                echo ""
                echo "=== Drop Database ==="
                # TODO: Implement database deletion logic
                # - Prompt for database name
                # - Confirm deletion (Y/N)
                # - Remove database directory and all contents
                # - Display success message
                read -p "Press Enter to continue..."
                break
                ;;
            5)
                echo ""
                echo "Exiting ShQL. Goodbye!"
                exit 0
                ;;
            *)
                echo ""
                echo "Invalid option. Please select 1-5."
                read -p "Press Enter to continue..."
                break
                ;;
        esac
    done
done
