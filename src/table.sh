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
META_DIR="${DATA_DIR}/meta"

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
        "Recovery" \
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
    			read -p "  Type (int/string/date/binary): " COL_TYPE
    			if [[ "$COL_TYPE" != "int" && "$COL_TYPE" != "string" && "$COL_TYPE" != "date" && "$COL_TYPE" != "binary" ]]; then
        			echo "Error: Invalid data type. Must be 'int', 'string', 'date', or 'binary'."
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

        			if [[ "$PK_COL" -gt "$COL_COUNT" ]]; then
            				echo "Error: Column number must be between 1 and $COL_COUNT."
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
		# Update DBS metadata - increment table count and update last_modified
		awk -F',' -v db="$DB_NAME" -v ts="$(date +%s)" '
		BEGIN{OFS=","}
		$1==db {$2=$2+1; $4=ts}
		{print}
		' "$META_DIR/DBS" > "$META_DIR/DBS.tmp" && mv "$META_DIR/DBS.tmp" "$META_DIR/DBS"
                
                read -p "Press Enter to continue..."
                break
                ;;
            2)
                echo ""
                echo "=== List Tables ==="
                echo ""
                echo "Tables List:"
                # Check if any .meta files exist
                if compgen -G "$DB_PATH/*.meta" > /dev/null; then
                    i=1
                    for meta_file in "$DB_PATH"/*.meta; do
                        table_name=$(basename "$meta_file" .meta)
                        echo "$i) $table_name"
                        ((i++))
                    done
                else
                    echo "No tables found."
                fi
                read -p "Press Enter to continue..."
                break
                ;;
            3)
                echo ""
                echo "=== Drop Table ==="
                echo ""
                echo "💡 Recovery Tip: Consider creating a snapshot before dropping."
                echo "   This lets you undo this action if needed."
                echo ""
                echo "   [y] Yes, create snapshot first"
                echo "   [n] No, proceed with drop"
                echo "   [c] Cancel operation"
                echo ""
                read -p "Your choice: " DROP_CHOICE
                
                if [[ "$DROP_CHOICE" == "c" || "$DROP_CHOICE" == "C" ]]; then
                    echo "Operation cancelled."
                    read -p "Press Enter..."
                    break
                fi
                
                if [[ "$DROP_CHOICE" == "y" || "$DROP_CHOICE" == "Y" ]]; then
                    echo ""
                    echo "Launching Recovery to create snapshot..."
                    read -p "Press Enter to continue to Recovery..."
                    "$SCRIPT_DIR/recovery.sh" "$DB_NAME"
                    echo ""
                    echo "Returning to Drop Table..."
                fi
                
                read -p "Enter table name: " TABLE_NAME

                # Validation
                if [[ -z "$TABLE_NAME" ]]; then
                    echo "Error: Table name cannot be empty."
                    read -p "Press Enter..."
                    break
                fi
                
                META_FILE="${DB_PATH}/${TABLE_NAME}.meta"
                DATA_FILE="${DB_PATH}/${TABLE_NAME}.data"
                
                # Check for path traversal/invalid paths using realpath
                REAL_META_PATH=$(realpath -m "$META_FILE")
                REAL_DB_PATH=$(realpath "$DB_PATH")
                
                if [[ "$REAL_META_PATH" != "$REAL_DB_PATH"/* ]]; then
                     echo "Error: Invalid table name."
                     read -p "Press Enter..."
                     break
                fi

                if [[ ! -f "$META_FILE" ]]; then
                    echo "Error: Table '$TABLE_NAME' does not exist."
                    read -p "Press Enter..."
                    break
                fi

                read -p "Are you sure you want to delete table '$TABLE_NAME'? (y/n): " CONFIRM
                if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                    rm -f "$META_FILE" "$DATA_FILE"
                    # Also remove binary storage directory if it exists
                    BIN_DIR="${DB_PATH}/${TABLE_NAME}.bin"
                    if [[ -d "$BIN_DIR" ]]; then
                        rm -rf "$BIN_DIR"
                    fi
                    echo "Table '$TABLE_NAME' dropped successfully."
                    # Update DBS metadata - decrement table count and update last_modified
                    awk -F',' -v db="$DB_NAME" -v ts="$(date +%s)" '
                    BEGIN{OFS=","}
                    $1==db {$2=($2>0?$2-1:0); $4=ts}
                    {print}
                    ' "$META_DIR/DBS" > "$META_DIR/DBS.tmp" && mv "$META_DIR/DBS.tmp" "$META_DIR/DBS"
                else
                    echo "Operation cancelled."
                fi

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
            		elif [[ "${COL_TYPES[$i]}" == "date" ]]; then
            			PARSED_DATE=""
            			if [[ "$VALUE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                			PARSED_DATE="$VALUE"
            			elif [[ "$VALUE" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
                			PARSED_DATE="${VALUE}-01"
            			elif [[ "$VALUE" =~ ^[0-9]{4}$ ]]; then
                			PARSED_DATE="${VALUE}-01-01"
            			elif [[ "$VALUE" =~ ^[0-9]+$ ]]; then
                			PARSED_DATE=$(date -d "@$VALUE" +"%Y-%m-%d" 2>/dev/null)
            			fi
            			if [[ -z "$PARSED_DATE" ]]; then
                			echo "you stupid :)"
                			echo "Hint: Use format YYYY-MM-DD (e.g., 2024-12-25)"
                			continue
            			fi
            			VALUE="$PARSED_DATE"
            		elif [[ "${COL_TYPES[$i]}" == "binary" ]]; then
            			if [[ ! -f "$VALUE" ]]; then
                			echo "Error: File '$VALUE' does not exist."
                			continue
            			fi
            			FILE_SIZE=$(stat -c%s "$VALUE" 2>/dev/null || stat -f%z "$VALUE" 2>/dev/null)
            			if [[ "$FILE_SIZE" -gt 1048576 ]]; then
                			echo "Error: File exceeds 1MB limit."
                			continue
            			fi
            			BIN_DIR="${DB_PATH}/${TABLE_NAME}.bin"
            			mkdir -p "$BIN_DIR"
            			TIMESTAMP=$(date +%s%N)
            			ARCHIVE_NAME="${TIMESTAMP}.tar.gz"
            			tar -czf "${BIN_DIR}/${ARCHIVE_NAME}" -C "$(dirname "$VALUE")" "$(basename "$VALUE")"
            			VALUE="$ARCHIVE_NAME"
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
                # - Prompt for table name
                read -p "Enter table name: " TABLE_NAME
    		META_FILE="${DB_PATH}/${TABLE_NAME}.meta"
    		DATA_FILE="${DB_PATH}/${TABLE_NAME}.data"
    		
    		if [[ ! -f "$META_FILE" || ! -f "$DATA_FILE" ]]; then
        		echo "Error: Table does not exist."
        		read -p "Press Enter..."
       			break
    		fi
    		
    		COL_NAMES=()
    		COL_TYPES=()
    		COL_PKS=()
    		while IFS=: read -r NAME TYPE PK; do
        		COL_NAMES+=("$NAME")
        		COL_TYPES+=("$TYPE")
        		COL_PKS+=("$PK")
    		done < "$META_FILE"
                # - Prompt for columns to select (* for all)
                echo ""
    		echo "=== Columns to Display ==="
    		echo "1) Display all columns"
    		echo "2) Choose specific columns to display"
    		read -p "Enter your choice (1 or 2): " SEL_OPTION
    		SELECT_INDICES=()
    		if [[ "$SEL_OPTION" == "1" ]]; then
        		for i in "${!COL_NAMES[@]}"; do
            			SELECT_INDICES+=("$i")
       			done
       		elif [[ "$SEL_OPTION" == "2" ]]; then
        		echo "Available columns:"
        	for i in "${!COL_NAMES[@]}"; do
        	echo "$((i+1))) ${COL_NAMES[$i]}"
        	done
        	read -p "Enter column numbers separated by space (e.g., 1 3): " COL_INPUT
        	INVALID_COL_INPUT=0
        		for num in $COL_INPUT; do
            		# User enters 1-based column numbers; convert to 0-based index for arrays
            		if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 && "$num" -le "${#COL_NAMES[@]}" ]]; then
                		SELECT_INDICES+=($((num-1)))
            		else
                		echo "Invalid column number: $num"
                		read -p "Press Enter..."
                		break 2
            		fi
        		done
        		else
        		echo "Invalid option."
        		read -p "Press Enter..."
        		break
        	fi
                # Ensure at least one column was selected before displaying results
                if [[ ${#SELECT_INDICES[@]} -eq 0 ]]; then
                    echo "No valid columns selected."
                    read -p "Press Enter to continue..."
                    break
                fi
                # - Display results in formatted table
                HEADER=""
    		SEPARATOR=""
    		for idx in "${SELECT_INDICES[@]}"; do
        		HEADER+="| $(printf "%-15s" "${COL_NAMES[$idx]}") "
        		SEPARATOR+="------------------"
    		done
    		HEADER+="|"
    		SEPARATOR+="-"
    		
    		# - Ask if user wants to filter/search
    		echo ""
    		echo "Filter Option:"
    		echo "1) Show all records"
    		echo "2) Search by value"
    		read -p "Enter your choice (1 or 2): " FILTER_OPTION
    		
    		FILTER_COL=""
    		FILTER_VAL=""
    		if [[ "$FILTER_OPTION" == "2" ]]; then
    		    echo ""
    		    echo "Filter by which displayed column?"
    		    for i in "${!SELECT_INDICES[@]}"; do
    		        idx="${SELECT_INDICES[$i]}"
    		        echo "$((i+1))) ${COL_NAMES[$idx]}"
    		    done
    		    read -p "Enter choice: " SEARCH_CHOICE
    		    if [[ ! "$SEARCH_CHOICE" =~ ^[1-9][0-9]*$ ]] || [[ "$SEARCH_CHOICE" -gt "${#SELECT_INDICES[@]}" ]]; then
    		        echo "Error: Invalid choice."
    		        read -p "Press Enter..."
    		        break
    		    fi
    		    # Convert choice to actual column index (1-based for awk)
    		    FILTER_COL=$((SELECT_INDICES[$((SEARCH_CHOICE-1))]+1))
    		    read -p "Enter value to match: " FILTER_VAL
    		fi
    		
    		echo ""
    		echo "$SEPARATOR"
    		echo "$HEADER"
    		echo "$SEPARATOR"
    		
    		if [[ ! -s "$DATA_FILE" ]]; then
        		echo "| $(printf "%-15s" "No records found") |"
    		else
    		# - Use awk to filter and format results
        		awk -F: -v cols="$(IFS=,; echo "${SELECT_INDICES[*]}")" -v filter_col="$FILTER_COL" -v filter_val="$FILTER_VAL" '
        		BEGIN { split(cols, arr, ",") }
        		{
            		    # Apply filter if set
            		    if (filter_col != "" && filter_val != "") {
            		        if ($filter_col != filter_val) next
            		    }
            			printf "|"
            			for (i=1; i<=length(arr); i++) {
                			idx = arr[i]+1
                			printf " %-15s |", $idx
            			}
            			print ""
        		}' "$DATA_FILE"
    		fi
    		echo "$SEPARATOR"
                read -p "Press Enter to continue..."
                break
                ;;
            6)
                echo ""
                echo "=== Update Table ==="
                read -p "Enter table name: " TABLE_NAME
                 
                 # Table Name Validation
                 if [[ -z "$TABLE_NAME" ]]; then
                     echo "Error: Table name cannot be empty."
                     read -p "Press Enter..."
                     break
                 fi
                 META_FILE="${DB_PATH}/${TABLE_NAME}.meta"
                 DATA_FILE="${DB_PATH}/${TABLE_NAME}.data"
                 
                 # Security/Path Validation
                 REAL_META_PATH=$(realpath -m "$META_FILE")
                 REAL_DB_PATH=$(realpath "$DB_PATH")
                 if [[ "$REAL_META_PATH" != "$REAL_DB_PATH"/* ]]; then
                     echo "Error: Invalid table name."
                     read -p "Press Enter..."
                     break
                 fi
				
                 if [[ ! -f "$META_FILE" || ! -f "$DATA_FILE" ]]; then
                    echo "Error: Table does not exist."
                    read -p "Press Enter..."
                    break
                 fi

                 if [[ ! -s "$DATA_FILE" ]]; then
                    echo "Error: (empty table)"
                    read -p "Press Enter..."
                    break
                 fi

                 # Load Metadata
                 COL_NAMES=()
                 COL_TYPES=()
                 PK_INDEX=-1
                 # Use array to map columns
                 i=0
                 while IFS=: read -r NAME TYPE PK; do
                     COL_NAMES+=("$NAME")
                     COL_TYPES+=("$TYPE")
                     if [[ "$PK" == "PK" ]]; then
                         PK_INDEX=$((i+1))  # 1-based index for awk
                     fi
                     ((i = i + 1))
                 done < "$META_FILE"

                 read -p "Enter Primary Key of row to update: " PK_VALUE
                 if [[ -z "$PK_VALUE" ]]; then
                     echo "Error: PK cannot be empty."
                     read -p "Press Enter..."
                     break
                 fi

                 # Validate PK exists
                 # Looking for exact match in data file
                 if ! awk -F: -v pk="$PK_VALUE" -v idx="$PK_INDEX" '$idx == pk {found=1; exit} END {if (!found) exit 1}' "$DATA_FILE"; then
                     echo "Error: Row with Primary Key '$PK_VALUE' not found."
                     read -p "Press Enter..."
                     break
                 fi
                 
                 echo "Available Columns:"
                 for j in "${!COL_NAMES[@]}"; do
                      # Skip Primary Key from being updated? Usually safe to prevent updating PK but user requirements didn't specify. Assuming allow all for now but PK updation is dangerous.
                      # Let's check constraints: "Prompt for column to update."
                      echo "$((j+1))) ${COL_NAMES[$j]} (${COL_TYPES[$j]})"
                 done

                 read -p "Enter column number to update: " COL_NUM
                 
                 if [[ ! "$COL_NUM" =~ ^[1-9][0-9]*$ ]] || [[ "$COL_NUM" -gt "${#COL_NAMES[@]}" ]]; then
                     echo "Error: Invalid column number."
                     read -p "Press Enter..."
                     break
                 fi
                 
                 TARGET_IDX=$((COL_NUM-1)) # 0-based index for arrays
                 TARGET_COL_TYPE="${COL_TYPES[$TARGET_IDX]}"
                 TARGET_COL_NAME="${COL_NAMES[$TARGET_IDX]}"
                 
                 # Cannot update PK to duplicate value - simplistic check if user tries to update PK
                 if [[ $((TARGET_IDX+1)) -eq $PK_INDEX ]]; then
                     echo "Warning: Updating Primary Key."
                 fi

                 read -p "Enter new value for '$TARGET_COL_NAME' ($TARGET_COL_TYPE): " NEW_VALUE

                 # Validate Type
                 if [[ "$TARGET_COL_TYPE" == "int" ]]; then
                     if [[ ! "$NEW_VALUE" =~ ^-?[0-9]+$ ]]; then
                         echo "Error: Value must be an integer."
                         read -p "Press Enter..."
                         break
                     fi
                 elif [[ "$TARGET_COL_TYPE" == "string" ]]; then
                      if [[ "$NEW_VALUE" == *:* ]]; then
                          echo "Error: ':' is not allowed in string."
                          read -p "Press Enter..."
                          break
                      fi
                 elif [[ "$TARGET_COL_TYPE" == "date" ]]; then
                       PARSED_DATE=""
                       if [[ "$NEW_VALUE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                           PARSED_DATE="$NEW_VALUE"
                       elif [[ "$NEW_VALUE" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
                           PARSED_DATE="${NEW_VALUE}-01"
                       elif [[ "$NEW_VALUE" =~ ^[0-9]{4}$ ]]; then
                           PARSED_DATE="${NEW_VALUE}-01-01"
                       elif [[ "$NEW_VALUE" =~ ^[0-9]+$ ]]; then
                           PARSED_DATE=$(date -d "@$NEW_VALUE" +"%Y-%m-%d" 2>/dev/null)
                       fi
                       if [[ -z "$PARSED_DATE" ]]; then
                           echo "you stupid :)"
                           echo "Hint: Use format YYYY-MM-DD (e.g., 2024-12-25)"
                           read -p "Press Enter..."
                           break
                       fi
                       NEW_VALUE="$PARSED_DATE"
                  elif [[ "$TARGET_COL_TYPE" == "binary" ]]; then
                       if [[ ! -f "$NEW_VALUE" ]]; then
                           echo "Error: File '$NEW_VALUE' does not exist."
                           read -p "Press Enter..."
                           break
                       fi
                       FILE_SIZE=$(stat -c%s "$NEW_VALUE" 2>/dev/null || stat -f%z "$NEW_VALUE" 2>/dev/null)
                       if [[ "$FILE_SIZE" -gt 1048576 ]]; then
                           echo "Error: File exceeds 1MB limit."
                           read -p "Press Enter..."
                           break
                       fi
                       BIN_DIR="${DB_PATH}/${TABLE_NAME}.bin"
                       mkdir -p "$BIN_DIR"
                       TIMESTAMP=$(date +%s%N)
                       ARCHIVE_NAME="${TIMESTAMP}.tar.gz"
                       tar -czf "${BIN_DIR}/${ARCHIVE_NAME}" -C "$(dirname "$NEW_VALUE")" "$(basename "$NEW_VALUE")"
                       NEW_VALUE="$ARCHIVE_NAME"
                  fi
                 
                 # If updating PK, check text uniqueness (omitted for strict simplicity unless requested, but good practice. User didn't ask for it specifically in 'update', but implied by constraints. Let's just do update.)
                 if [[ $((TARGET_IDX+1)) -eq $PK_INDEX ]]; then
                      if awk -F: -v pk="$NEW_VALUE" -v idx="$PK_INDEX" '$idx == pk {found=1; exit} END {if (found) exit 1}' "$DATA_FILE" ; then
                          :
                      else 
                          echo "Error: Duplicate Primary Key value."
                          read -p "Press Enter..."
                          break
                      fi
                 fi

                 # Perform Update
                 # Using awk to rewrite the file
                 awk -F: -v pk="$PK_VALUE" -v pk_idx="$PK_INDEX" -v target_idx="$((TARGET_IDX+1))" -v val="$NEW_VALUE" 'BEGIN{OFS=":"} $pk_idx == pk { $target_idx = val } 1' "$DATA_FILE" > "${DATA_FILE}.tmp" && mv "${DATA_FILE}.tmp" "$DATA_FILE"

                 echo "Row updated successfully."
                 read -p "Press Enter to continue..."
                break
                ;;
            7)
            	echo ""
    		echo "=== Delete from Table ==="
    		echo ""
    		echo "💡 Tip: You can create a snapshot to undo deletions if needed."
    		echo "       Use Recovery → Create Table Snapshot before deleting."
    		echo ""
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

    		if [[ ! -s "$DATA_FILE" ]]; then
        		echo "Error: (empty table)"
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
                # Recovery
                echo ""
                echo "Launching Recovery System..."
                "$SCRIPT_DIR/recovery.sh" "$DB_NAME"
                break
                ;;
            9)
                echo ""
                echo "Returning to main menu..."
                break 2
                ;;
            *)
                echo ""
                echo "Invalid option. Please select 1-9."
                read -p "Press Enter to continue..."
                break
                ;;
        esac
    done
done
