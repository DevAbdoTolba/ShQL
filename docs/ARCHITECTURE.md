# ShQL Architecture

## Overview
ShQL is a Database Management System (DBMS) implemented entirely in Bash, following strict constraints:
- **NO FUNCTIONS ALLOWED**: All logic uses flow control structures (if/else, case, while, select)
- **Production-grade structure**: Clear separation of concerns
- **Standard tools**: Uses `sed`, `awk`, and Bash built-ins

## Directory Structure

```
ShQL/
├── src/                    # Source code directory
│   ├── db.sh              # Database management (CRUD for databases)
│   └── table.sh           # Table management (CRUD for tables)
├── data/                  # Runtime data storage (gitignored)
│   └── <database_name>/   # Each database is a directory
│       ├── .metadata      # Database metadata
│       └── <table_name>   # Table files (CSV-like format)
├── docs/                  # Documentation
│   └── ARCHITECTURE.md    # This file
├── Makefile              # Setup and maintenance tasks
├── .gitignore            # Excludes data/ and temporary files
└── README.md             # Project overview
```

## Design Principles

### 1. No Functions Constraint
All scripts avoid function definitions. Instead, we use:
- `select` loops for interactive menus
- `case` statements for option handling
- `while` loops for repetitive operations
- Inline logic with proper variable scoping

### 2. Separation of Concerns
- **db.sh**: Handles database-level operations (create, list, connect, drop)
- **table.sh**: Handles table-level operations (create, insert, select, update, delete, drop)
- **data/**: Physical storage layer, separated from logic

### 3. Data Storage Format
- Each database is a directory under `data/`
- Each table is stored as a file within its database directory
- Metadata files use simple key-value format
- Table data uses delimited format (CSV-like) for `awk`/`sed` processing

## Script Workflow

### db.sh (Database Management)
```
User -> Select Menu -> Case Statement -> Operation
                                      -> Loop back to Menu
```

Operations:
1. **Create Database**: Creates directory under `data/`
2. **List Databases**: Lists all directories in `data/`
3. **Connect to Database**: Launches `table.sh` for specific database
4. **Drop Database**: Removes database directory and contents
5. **Exit**: Terminates program

### table.sh (Table Management)
```
Database Name (arg) -> Validate -> Select Menu -> Case Statement -> Operation
                                                                  -> Loop back to Menu
```

Operations:
1. **Create Table**: Prompts for schema, creates table file and metadata
2. **List Tables**: Shows all tables in current database
3. **Drop Table**: Removes table file
4. **Insert**: Appends row to table file (validates types)
5. **Select**: Filters and displays rows using `awk`
6. **Update**: Modifies rows using `sed`/`awk`
7. **Delete**: Removes rows using `sed`/`awk`
8. **Back**: Returns to main menu (exits table.sh)

## Tools and Techniques

### Text Processing
- **awk**: Used for filtering, column selection, and formatted output
- **sed**: Used for in-place updates and deletions
- **grep**: Used for searching and pattern matching

### Data Validation
- Input validation using regex patterns in `[[ ]]` conditionals
- Type checking before insert/update operations
- Existence checks for databases and tables

### Error Handling
- `set -euo pipefail` for strict error handling
- Explicit validation before destructive operations
- User confirmation prompts for drops and deletes

## Usage

### Setup
```bash
make setup
```

### Running
```bash
./src/db.sh
```

### Operations Example Flow
1. User runs `db.sh`
2. Selects "Create Database" -> enters name -> database directory created
3. Selects "Connect to Database" -> enters name -> `table.sh` launched
4. In `table.sh`, creates table, inserts data, queries data
5. Exits `table.sh` -> returns to `db.sh`
6. Exits `db.sh` -> program terminates

## Future Enhancements
- Advanced WHERE clause parsing
- JOIN operations across tables
- Indexing for faster queries
- Transaction support
- Backup and restore functionality
- Export/Import (SQL dump format)
