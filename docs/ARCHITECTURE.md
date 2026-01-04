# ShQL Architecture

## Overview

ShQL is a Database Management System (DBMS) that is entirely written in Bash, which has a set of strict limitations:
- **NO FUNCTIONS**: all logical operations are implemented by using control-flow structures (if/else, case, while, select)
- **production-level architecture**: Proper distribution of tasks
- **common tools**: `sed`, `awk`, and Bash built-ins are used


## Directory Structure

```
ShQL/
├── src/                        # Source code directory
│   ├── db.sh                   # Database management (create, list, connect, drop)
│   ├── table.sh                # Table management (CRUD operations)
│   └── recovery.sh             # Recovery system (snapshots, rollback)
├── data/                       # Runtime data storage (gitignored)
│   ├── meta/
│   │   └── DBS                 # Database metadata (name, table_count, created, modified)
│   ├── snapshots/
│   │   ├── databases/          # Full database snapshots
│   │   │   └── <db_name>_<timestamp>/
│   │   │       ├── snapshot.meta   # Snapshot metadata (description, date)
│   │   │       ├── .metadata       # Database metadata backup
│   │   │       ├── <table>.meta    # All table schemas
│   │   │       ├── <table>.data    # All table data
│   │   │       └── <table>.bin/    # All binary files
│   │   └── tables/             # Individual table snapshots
│   │       └── <db_name>_<table>_<timestamp>/
│   │           ├── snapshot.meta   # Snapshot metadata
│   │           ├── <table>.meta    # Table schema backup
│   │           ├── <table>.data    # Table data backup
│   │           └── <table>.bin/    # Binary files backup (if any)
│   └── <database_name>/        # Each database is a directory
│       ├── <table_name>.meta   # Table metadata (columns, types, PK)
│       ├── <table_name>.data   # Table data (colon-delimited format)
│       └── <table_name>.bin/   # Binary file storage (for binary datatype)
├── docs/                       # Documentation
│   └── ARCHITECTURE.md         # This file
├── Makefile                    # Setup and maintenance tasks
├── .gitignore                  # Excludes data/ and temporary files
└── README.md                   # Project overview
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
- **recovery.sh**: Handles snapshots and rollback operations for disaster recovery
- **data/**: The physical storage layer is separated from the logic

### 3. Data Storage Format
- The entire database is physically represented as a directory beneath `data/`
- All the tables inside the database are stored as `.meta` (schema) and `.data` (records) files
- The metadata files use colon-delimited format: `column_name:type:PK`
- The table data is stored in colon-delimited format (`:` separator)

## Supported Data Types

| Type     | Description                              | Validation                                          |
|----------|------------------------------------------|-----------------------------------------------------|
| `int`    | Integer values                           | Matches `^-?[0-9]+$`                               |
| `string` | Text values                              | Cannot contain colon (`:`) character               |
| `date`   | Date values (stored as YYYY-MM-DD)       | Accepts: `YYYY-MM-DD`, `YYYY-MM`, `YYYY`, or Unix timestamp |
| `binary` | Binary file storage (max 1MB)            | File must exist; archived as `.tar.gz`             |

## Recovery System

The recovery system provides snapshot and rollback capabilities:

### Snapshots
- **Database Snapshots**: Full copy of entire database directory
- **Table Snapshots**: Individual table backup (.meta, .data, .bin)
- Stored with timestamps and user-provided descriptions

### Rollback
- Restore to any previous snapshot state
- Automatic backup created before rollback (safety net)
- Supports both database-level and table-level rollback

