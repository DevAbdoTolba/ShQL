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
#
# Security Note:
#   Table name validation is required for all operations that accept table names
#   to prevent path traversal attacks. Due to the no-functions constraint,
#   validation logic is duplicated across operations. When implementing new
#   operations (Drop, Select, Update, Delete), ensure table name validation
#   includes:
#   1. Empty check
#   2. Minimum length (3 chars)
#   3. Format validation (^[a-zA-Z][a-zA-Z_]*$)
#   4. Reserved word check (case-insensitive)
#   5. Path traversal protection (realpath verification)
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
		LOWER_TABLE_NAME=$(echo "$TABLE_NAME" | tr 'A-Z' 'a-z')
		for WORD in $RESERVED_WORDS; do
		   LOWER_WORD=$(echo "$WORD" | tr 'A-Z' 'a-z')
    		   if [[ "$LOWER_TABLE_NAME" == "$LOWER_WORD" ]]; then
                      echo "Error: Table name is reserved word."
                      read -p "Press Enter..."
                      break 2
   		   fi
		done
		
		META_FILE="${DB_PATH}/${TABLE_NAME}.meta"
		DATA_FILE="${DB_PATH}/${TABLE_NAME}.data"
		
		# Ensure paths remain within DB_PATH
		REAL_META_PATH=$(realpath -m "$META_FILE")
		REAL_DATA_PATH=$(realpath -m "$DATA_FILE")
		REAL_DB_PATH=$(realpath "$DB_PATH")
		
		if [[ "$REAL_META_PATH" != "$REAL_DB_PATH"/* ]] || [[ "$REAL_DATA_PATH" != "$REAL_DB_PATH"/* ]]; then
		    echo "Error: Invalid table name."
		    read -p "Press Enter..."
		    break
		fi
		
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
        			echo "Error: Invalid column name. It must start with a letter and contain only letters and underscores."
        			rm -f "$META_FILE"
        			read -p "Press Enter..."
        			break 2
    			fi
    			LOWER_NAME=$(echo "$COL_NAME" | tr 'A-Z' 'a-z')
    			for WORD in $RESERVED_WORDS; do
        			LOWER_WORD=$(echo "$WORD" | tr 'A-Z' 'a-z')
        			if [[ "$LOWER_NAME" == "$LOWER_WORD" ]]; then
            			   echo "Error: Column name is reserved."
            			   rm -f "$META_FILE"
            			   read -p "Press Enter..."
            			   break 3
        			fi
    			done
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
        			echo "Error: Invalid data type. Must be 'int' or 'string'."
       				 rm -f "$META_FILE"
       				 read -p "Press Enter..."
       				 break 2
   			 fi
   			  # Primary Key
   			 if [[ $PK_COUNT -eq 0 ]]; then
    				read -p "  Primary Key? (y/n): " IS_PK
			else
    				IS_PK="n"
			fi

			if [[ "$IS_PK" == "y" ]]; then
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
  		# Recovery if no primary key selected
		if [[ $PK_COUNT -eq 0 ]]; then
    			echo ""
    			echo "No Primary Key selected."
    			echo "1) Choose Primary Key from existing columns"
    			echo "2) Cancel table creation"
    			read -p "Enter choice: " PK_OPTION

    			if [[ "$PK_OPTION" == "1" ]]; then
        			echo ""
        			echo "Available columns:"
        			awk -F: '{print NR ") " $1 " (" $2 ")"}' "$META_FILE"

        			read -p "Enter column number: " PK_COL

        			if ! [[ "$PK_COL" =~ ^[1-9][0-9]*$ ]]; then
            				echo "Invalid choice."
            				rm -f "$META_FILE"
            				read -p "Press Enter..."
            				break
        			fi

        			NUM_COLUMNS=$(wc -l < "$META_FILE")
        			if [[ "$PK_COL" -gt "$NUM_COLUMNS" ]]; then
            				echo "Error: Column number must be between 1 and $NUM_COLUMNS."
            				rm -f "$META_FILE"
            				read -p "Press Enter..."
            				break
        			fi

        			COL_TYPE=$(awk -F: -v n="$PK_COL" 'NR==n {print $2}' "$META_FILE")

        			if [[ "$COL_TYPE" != "int" ]]; then
            				echo "Error: Primary key must be integer."
            				rm -f "$META_FILE"
            				read -p "Press Enter..."
            				break
        			fi

        			awk -v n="$PK_COL" 'BEGIN { FS = OFS = ":" } NR==n { $3 = "PK" } { print }' \
        			"$META_FILE" > "${META_FILE}.tmp" && mv "${META_FILE}.tmp" "$META_FILE"
    			elif [[ "$PK_OPTION" == "2" ]]; then
        			echo "Table creation cancelled."
       			 	rm -f "$META_FILE"
        			read -p "Press Enter..."
        			break
    			else
        			echo "Invalid choice."
       			 	rm -f "$META_FILE"
        			read -p "Press Enter..."
        			break
    			fi
		fi

		if ! touch "$DATA_FILE"; then
    			echo "Error: Failed to create data file for table '$TABLE_NAME'."
    			rm -f "$META_FILE"
    			read -p "Press Enter..."
    			break
		fi
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
                RESERVED_WORDS="select insert delete update from where table database"
                # - Prompt for table name
                 read -p "Enter table name: " TABLE_NAME
                 
                 # Table Name Validation
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
                     echo "Error: Invalid table name."
                     read -p "Press Enter..."
                     break
                 fi
                 LOWER_TABLE_NAME=$(echo "$TABLE_NAME" | tr 'A-Z' 'a-z')
                 for WORD in $RESERVED_WORDS; do
                     LOWER_WORD=$(echo "$WORD" | tr 'A-Z' 'a-z')
                     if [[ "$LOWER_TABLE_NAME" == "$LOWER_WORD" ]]; then
                         echo "Error: Table name is reserved word."
                         read -p "Press Enter..."
                         break 2
                     fi
                 done
                 
    		 META_FILE="${DB_PATH}/${TABLE_NAME}.meta"
    		 DATA_FILE="${DB_PATH}/${TABLE_NAME}.data"
    		 
    		 # Ensure paths remain within DB_PATH
    		 REAL_META_PATH=$(realpath -m "$META_FILE")
    		 REAL_DATA_PATH=$(realpath -m "$DATA_FILE")
    		 REAL_DB_PATH=$(realpath "$DB_PATH")
    		 
    		 if [[ "$REAL_META_PATH" != "$REAL_DB_PATH"/* ]] || [[ "$REAL_DATA_PATH" != "$REAL_DB_PATH"/* ]]; then
    		     echo "Error: Invalid table name."
    		     read -p "Press Enter..."
    		     break
    		 fi
    		 
    		 if [[ ! -f "$META_FILE" || ! -f "$DATA_FILE" ]]; then
        		echo "Error: Table does not exist."
        		read -p "Press Enter..."
        		break
   		 fi
                # - Display column names
                COL_NAMES=()
		COL_TYPES=()
		COL_PKS=()
		while IFS=: read -r NAME TYPE PK; do
    			COL_NAMES+=("$NAME")
    			COL_TYPES+=("$TYPE")
    			COL_PKS+=("$PK")
		done < "$META_FILE"
                
                echo ""
    		echo "Table Columns:"
    		for i in "${!COL_NAMES[@]}"; do
    			if [[ "${COL_PKS[$i]}" == "PK" ]]; then
        			echo "$((i+1))) ${COL_NAMES[$i]} (${COL_TYPES[$i]}) [PK]"
    			else
        			echo "$((i+1))) ${COL_NAMES[$i]} (${COL_TYPES[$i]})"
   			 fi
		done
   		echo ""
                # - Prompt for values for each column
                VALUES=""
    		PK_VALUE=""
    		PK_INDEX=0
    		for i in "${!COL_NAMES[@]}"; do
    			while true; do
        			read -p "Enter value for ${COL_NAMES[$i]} (${COL_TYPES[$i]}): " VALUE	 
                # - Validate data types
                		if [[ -z "$VALUE" ]]; then
            				echo "Error: Value cannot be empty."
            				continue
        			fi
        	
                		if [[ "${COL_PKS[$i]}" == "PK" ]]; then
            				if [[ ! "$VALUE" =~ ^[1-9][0-9]*$ ]]; then
                				echo "Error: Primary key must be a positive integer."
                				continue
           				fi
                # - Handle primary key uniqueness
           				if awk -F: -v pk="$VALUE" -v idx=$((i+1)) '$idx == pk {exit 1}' "$DATA_FILE"; then
                			:
            				else
                				echo "Error: Duplicate primary key value."
                				continue
            				fi
            				PK_VALUE="$VALUE"
           				PK_INDEX=$((i+1))
        		
        			elif [[ "${COL_TYPES[$i]}" == "int" ]]; then
            				if [[ ! "$VALUE" =~ ^-?[0-9]+$ ]]; then
                			echo "Error: ${COL_NAMES[$i]} must be integer."
                			continue
            				fi
            			elif [[ "${COL_TYPES[$i]}" == "string" ]]; then
            				if [[ "$VALUE" == *:* ]]; then
                				echo "Error: ':' is not allowed in string."
                				continue
            				fi
       				fi
       		
       				break
    			done
    			if [[ -z "$VALUES" ]]; then
    				VALUES="$VALUE"
    			else
    				VALUES+=":$VALUE"
    			fi
		done
                # - Append to table data file using awk
    		awk -v record="$VALUES" 'END { print record }' "$DATA_FILE" >> "$DATA_FILE"
                echo "Record inserted successfully."
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
    		# Delete a row by primary key from the specified table
    		read -p "Enter table name: " TABLE_NAME
    		
    		# Table name validation
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
    		
    		META_FILE="${DB_PATH}/${TABLE_NAME}.meta"
    		DATA_FILE="${DB_PATH}/${TABLE_NAME}.data"
    		
    		if [[ ! -f "$META_FILE" || ! -f "$DATA_FILE" ]]; then
        		echo "Error: Table '$TABLE_NAME' does not exist."
        		read -p "Press Enter to continue..."
        		break
    		fi
    		
    		read -p "Enter Primary Key value to delete: " PK_VALUE
                
                if [[ -z "$PK_VALUE" ]]; then
                    echo "Error: Primary Key value cannot be empty."
                    read -p "Press Enter to continue..."
                    break
                fi

                if ! grep -q "^${PK_VALUE}:" "$DATA_FILE"; then
    			echo "Error: Primary Key not found."
        		read -p "Press Enter to continue..."
        		break
		fi

		sed -i "/^${PK_VALUE}:/d" "$DATA_FILE" 
		echo "Row deleted successfully."
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
