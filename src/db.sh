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
                        mkdir $DATA_DIR/$db_name
                        echo "${db_name},0,$(date +%s),$(date +%s)" >> "$META_DIR/DBS"
                    fi
                fi
                read -p "Press Enter to continue..."
                break
                ;;
            2)
                echo ""
                echo "=== List Databases ==="
                if [[ -s "$META_DIR/DBS" ]]; then
                    echo "Databases List:"
                    awk -F',' '$1 !~ /!/ { print NR ") " $1 }' "$META_DIR/DBS"
                else
                    echo "No databases found."
                fi
                read -p "Press Enter to continue..."
                break
                ;;
            3)
                echo ""
                echo "=== Connect to Database ==="
                read -p "Enter database name (fullname no skips): " user_in
                db_name="$user_in"
                incase_senstive=0
                if [[ "$user_in" == *"-i"* ]]; then
                    incase_senstive=1
                    db_name="${user_in//-i/}"
                    db_name="${db_name// /}"
                fi

                if [[ "$incase_senstive" -gt 0 ]]; then
                    match_count=$(cut "$META_DIR/DBS" -d',' -f1 | grep -i "$db_name" | wc -l)
                    if [[ "$match_count" -gt 1 ]]; then
                        echo "ERROR: Can not use incase senstive flag for this name, multpile databases returned with the same name";
                    elif [[ "$match_count" -eq 0 ]]; then
                        echo "ERROR: Database not found! sry ;-;";
                    else
                        real_path=$(find "$DATA_DIR" -maxdepth 1 -type d -iname "$db_name" -print -quit)
                        if [[ -n "$real_path" ]]; then
                            echo "Connecting to $db_name";
                            $SCRIPT_DIR/table.sh $db_name;
                        else
                            echo "$db_name is courrpoted and requires user manual fix to prevent data loss!"
                            echo "please review the file located at $(realpath $META_DIR)/DBS for more information"
                        fi
                    fi

                elif cut "$META_DIR/DBS" -d',' -f1 | grep "$db_name" -x -q; then
                    real_path=$(find "$DATA_DIR" -maxdepth 1 -type d -name "$db_name" -print -quit)
                    if [[ -n "$real_path" ]]; then
                        echo "Connecting to $db_name";
                        $SCRIPT_DIR/table.sh $db_name;
                    else
                        echo "$db_name is courrpoted and requires user manual fix to prevent data loss!"
                        echo "please review the file located at $(realpath $META_DIR)/DBS for more information"
                    fi
                else
                    echo "ERROR: Database not found! sry ;-;";
                fi
                read -p "Press Enter to continue..."
                break
                ;;
            4)
                echo ""
                echo "=== Drop Database ==="
                read -p "Enter database name (use -a to remove metadata row): " user_in
                remove_all=0
    		db_name="$user_in"
    		if [[ "$user_in" == *"-a"* ]]; then
        		remove_all=1
        		db_name="${user_in//-a/}"
        		db_name="${db_name// /}"
    		fi
    		# Validation
    		if [[ -z "$db_name" ]]; then
        		echo "Error: Database name can not be empty!"
        		read -p "Press Enter to continue..."
        		break
    		elif [[ ! "$db_name" =~ ^[a-zA-Z]{3,55}$ ]]; then
        		echo "Error: Name must be 3-55 English letters only (no numbers, spaces, or symbols)"
        		read -p "Press Enter to continue..."
        		break
    		fi
    		if ! cut -d',' -f1 "$META_DIR/DBS" | grep -xq "$db_name"; then
        		echo "Database '$db_name' not found."
        		read -p "Press Enter to continue..."
        		break
    		fi
    		
    		read -p "Are you sure you want to delete '$db_name'? (Y/N): " confirm
    		
    		case "$confirm" in
        	   Y|y)
            		# Backup metadata before modification for rollback protection
            		cp "$META_DIR/DBS" "$META_DIR/DBS.backup"
            		
            		# Update metadata first before deleting directory
            		if [[ "$remove_all" -eq 1 ]]; then
                		grep -v "^${db_name}," "$META_DIR/DBS" > "$META_DIR/DBS.tmp"
                		mv "$META_DIR/DBS.tmp" "$META_DIR/DBS"
                		echo "Metadata row removed completely."
            		else
                		# Add deletion timestamp to database name
                		deletion_timestamp=$(date +%s)
                		awk -F',' -v db="$db_name" -v ts="$deletion_timestamp" '
                		BEGIN{OFS=","}
                		$1==db {$1=ts"!"db}
                		{print}
                		' "$META_DIR/DBS" > "$META_DIR/DBS.tmp"
                		mv "$META_DIR/DBS.tmp" "$META_DIR/DBS"
                		echo "Database marked as deleted in metadata with timestamp $deletion_timestamp."
            		fi

            		# Delete directory after metadata update
            		if [[ -d "$DATA_DIR/$db_name" ]]; then
                		if rm -rf "$DATA_DIR/$db_name"; then
                    			echo "Database directory deleted."
                    			# Success - remove backup
                    			if ! rm -f "$META_DIR/DBS.backup"; then
                        			echo "Warning: Could not remove backup file."
                    			fi
                		else
                    			echo "ERROR: Failed to delete database directory!"
                    			# Restore metadata from backup
                    			mv "$META_DIR/DBS.backup" "$META_DIR/DBS"
                    			echo "Metadata restored - operation rolled back."
                		fi
            		else
                		echo "Warning: Database folder missing, restoring metadata..."
                		# Restore metadata from backup since directory doesn't exist
                		mv "$META_DIR/DBS.backup" "$META_DIR/DBS"
                		echo "Operation canceled - metadata restored."
            		fi
            		;;
        	   *)
            		echo "Deletion canceled."
            		;;
    		esac
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
