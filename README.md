# ShQL
**Bash Script-Based Database Management System**

A lightweight, production-grade Database Management System (DBMS) implemented entirely in Bash, demonstrating advanced shell scripting techniques without using functions.

## Features

- **Pure Bash Implementation**: No external dependencies beyond standard Unix tools (`sed`, `awk`)
- **No Functions Constraint**: Entire codebase uses flow control structures (if/else, case, while, select)
- **Database Operations**: Create, list, connect, and drop databases
- **Table Operations**: Create, insert, select, update, delete, and drop tables
- **Production Structure**: Clear separation of concerns and modular design

## Quick Start

1. **Setup the project**:
   ```bash
   make setup
   ```

2. **Run ShQL**:
   ```bash
   ./src/db.sh
   ```

3. **Follow the interactive menus** to manage databases and tables

## Project Structure

```
ShQL/
├── src/          # Source code
│   ├── db.sh     # Database management
│   └── table.sh  # Table management
├── data/         # Database storage (gitignored)
├── docs/         # Documentation
├── Makefile      # Setup and maintenance
└── README.md     # This file
```

## Documentation

For detailed architecture and design decisions, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Makefile Commands

- `make setup` - Initialize project and set permissions
- `make clean` - Remove all databases and temporary files
- `make help` - Display help information

## Requirements

- Bash 4.0 or higher
- Standard Unix utilities: `sed`, `awk`, `grep`

## License

MIT License

## Authors

Built with collaboration as a demonstration of advanced Bash scripting techniques.
