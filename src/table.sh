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
                RESERVED_WORDS="select insert delete update from where table database"
                # Table Name Validation
                read -p "Enter table name: " TABLE_NAME         
                if [[ -z "$TABLE_NAME" ]]; then
    		   echo "Error: Table name cannot be empty."
   		   read -p "Press Enter..."
   		   break
		fi		
		if [[ ${#TABLE_NAME} -lt 3 ]]; then
    		   echo "Error: Table name must be at least 3 characters long."
    		   read -p "Press Enter..."
		   break
		fi		
		if [[ ! "$TABLE_NAME" =~ ^[a-zA-Z][a-zA-Z_]*$ ]]; then
    		   echo "Error: Invalid table name. It must start with a letter and contain only letters and underscores."
    		   read -p "Press Enter..."
    		   break
		fi
		for WORD in $RESERVED_WORDS; do
    		   if [[ "$TABLE_NAME" == "$WORD" ]]; then
                      echo "Error: Table name is reserved word."
                      read -p "Press Enter..."
                      break 2
   		   fi
		done
		
		META_FILE="${DB_PATH}/${TABLE_NAME}.meta"
		DATA_FILE="${DB_PATH}/${TABLE_NAME}.data"
		
		if [[ -f "$META_FILE" ]]; then
    		   echo "Error: Table already exists."
    		   read -p "Press Enter..."
   		   break
		fi
		# Number of Columns
		read -p "Enter number of columns: " COL_COUNT
		if [[ ! "$COL_COUNT" =~ ^[1-9][0-9]*$ ]]; then
    		  echo "Error: Number of columns must be a positive integer."
    		  read -p "Press Enter..."
   		  break
		fi
		if [[ "$COL_COUNT" -gt 9 ]]; then
    		   echo "Error: Maximum number of columns allowed is 9."
    		   read -p "Press Enter..."
   		   break
		fi
		if [[ "$COL_COUNT" -lt 2 ]]; then
    		   echo "Error: Table must contain at least 2 columns."
		   read -p "Press Enter..."
    		   break
		fi
		
		> "$META_FILE"
		PK_COUNT=0
		COL_NAMES=""
		for (( i=1; i<=COL_COUNT; i++ )); do
    			echo "Column $i"
    			read -p "  Name: " COL_NAME
    			# Column name validations
			if [[ -z "$COL_NAME" ]]; then
				echo "Error: Column name cannot be empty."
				rm -f "$META_FILE"
				read -p "Press Enter..."
				break 2
			fi
			if [[ ${#COL_NAME} -lt 2 ]]; then
       				 echo "Error: Column name must be at least 2 characters."
       				 rm -f "$META_FILE"
        			read -p "Press Enter..."
        			break 2
   			fi
			if [[ ! "$COL_NAME" =~ ^[a-zA-Z][a-zA-Z_]*$ ]]; then
        			echo "Error: Invalid column name."
        			rm -f "$META_FILE"
        			read -p "Press Enter..."
        			break 2
    			fi
    			for WORD in $RESERVED_WORDS; do
        			if [[ "$COL_NAME" == "$WORD" ]]; then
            			   echo "Error: Column name is reserved."
            			   rm -f "$META_FILE"
            			   read -p "Press Enter..."
            			   break 3
        			fi
    			done
    			LOWER_NAME=$(echo "$COL_NAME" | tr 'A-Z' 'a-z')
    			for USED in $COL_NAMES; do
       			   if [[ "$LOWER_NAME" == "$USED" ]]; then
           		   	echo "Error: Duplicate column name."
           		   	rm -f "$META_FILE"
            	           	read -p "Press Enter..."
            		   	break 3
        		   fi
    			done
   			COL_NAMES="$COL_NAMES $LOWER_NAME"
    			# Column type
    			read -p "  Type (int/string): " COL_TYPE
    			if [[ "$COL_TYPE" != "int" && "$COL_TYPE" != "string" ]]; then
        			echo "Error: Invalid data type."
       				 rm -f "$META_FILE"
       				 read -p "Press Enter..."
       				 break 2
   			 fi
   			  # Primary Key
   			 read -p "  Primary Key? (y/n): " IS_PK
   			 if [[ "$IS_PK" == "y" ]]; then
       				 if [[ $PK_COUNT -eq 1 ]]; then
          			    echo "Error: Only one primary key allowed."
          			    rm -f "$META_FILE"
          			    read -p "Press Enter..."
         			    break 2
       				 fi

        			 if [[ "$COL_TYPE" != "int" ]]; then
           		 	    echo "Error: Primary key must be integer."
           			     rm -f "$META_FILE"
           			     read -p "Press Enter..."
           		 	     break 2
        			 fi

        			echo "${COL_NAME}:${COL_TYPE}:PK" >> "$META_FILE"
        			PK_COUNT=1
    			else
      				echo "${COL_NAME}:${COL_TYPE}" >> "$META_FILE"
  			fi
  		done
  		# Final PK Validation
  		if [[ $PK_COUNT -ne 1 ]]; then
    			echo "Error: Table must have exactly one primary key."
    			rm -f "$META_FILE"
    			read -p "Press Enter..."
    			break
		fi
		touch "$DATA_FILE"
		echo "Table '$TABLE_NAME' created successfully."
                
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
