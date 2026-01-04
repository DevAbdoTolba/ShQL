.PHONY: all setup install clean help

# Default shell
SHELL := /bin/bash

# Directories
SRC_DIR := src
DATA_DIR := data
DOCS_DIR := docs

# Scripts
DB_SCRIPT := $(SRC_DIR)/db.sh
TABLE_SCRIPT := $(SRC_DIR)/table.sh

# Default target
all: help

## help: Display this help message
help:
	@echo "ShQL - Database Management System in Bash"
	@echo ""
	@echo "Available targets:"
	@echo "  make setup     - Initial setup (create directories and set permissions)"
	@echo "  make install   - Install/setup the project (alias for setup)"
	@echo "  make clean     - Remove all databases and temporary files"
	@echo "  make help      - Display this help message"
	@echo "  make run       - start the database mangment system"
	@echo ""
	@echo "Usage:"
	@echo "  1. Run 'make setup' to initialize the project"
	@echo "  2. Run 'make run' to start the database management system"
	@echo ""

## setup: Create directories and set executable permissions
setup:
	@echo "Setting up ShQL..."
	@echo "Creating directories..."
	@mkdir -p $(DATA_DIR)
	@mkdir -p $(DATA_DIR)/snapshots/db
	@mkdir -p $(DATA_DIR)/snapshots/table
	@mkdir -p $(DOCS_DIR)
	@echo "Setting executable permissions on scripts..."
	@chmod +x $(DB_SCRIPT)
	@chmod +x $(TABLE_SCRIPT)
	@chmod +x $(SRC_DIR)/recovery.sh
	@echo "Setup complete!"
	@echo ""
	@echo "You can now run './src/db.sh' to start ShQL"

## install: Alias for setup
install: setup

## clean: Remove all databases and temporary files (WARNING: destructive)
clean:
	@echo "Cleaning ShQL..."
	@echo "WARNING: This will delete all databases in $(DATA_DIR)"
	@read -p "Are you sure? [y/N]: " confirm; \
	if [[ $$confirm == [yY] || $$confirm == [yY][eE][sS] ]]; then \
		echo "Removing databases..."; \
		rm -rf $(DATA_DIR)/*; \
		echo "Removing temporary files..."; \
		find . -name "*.tmp" -type f -delete; \
		find . -name "*.temp" -type f -delete; \
		find . -name "*.bak" -type f -delete; \
		find . -name "*.log" -type f -delete; \
		echo "Clean complete!"; \
	else \
		echo "Clean cancelled."; \
	fi

run:
	./src/db.sh
