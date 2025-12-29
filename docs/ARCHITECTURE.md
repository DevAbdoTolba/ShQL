# ShQL Architecture

## Overview

ShQL is a Database Management System (DBMS) that is entirely written in Bash, which has a set of strict limitations:
- **NO FUNCTIONS**: all logical operations are implemented by using control-flow structures (if/else, case, while, select)
- **production-level architecture**: Proper distribution of tasks
- **common tools**: `sed`, `awk`, and Bash built-ins are used


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
The entire set of scripts keeps away from function definitions. But in their place:
- `select` loops are for the interactive menus
- `case` statements are for option handling
- `while` loops are for repetitive operations
- Inline logic with proper variable scoping is used

### 2. Separation of Concerns
- **db.sh**: Performs operations at the database level (create, list, connect, drop)
- **table.sh**: Performs operations at the table level (create, insert, select, update, delete, drop)
- **data/**: The physical storage layer is separated from the logic

### 3. Data Storage Format
- The entire database is physically represented as a directory beneath `data/`
- All the tables inside the database are stored as files in the corresponding database directory
- The metadata files are simple key-value pairs
- The table data is stored in a delimited format where the delimiter is usually a comma (CSV)

