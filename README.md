# Taskly
📝 To-Do Tool — A Simple and Intuitive Task Manager Built with Racket

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

## Overview
Taskly is a simple and intuitive task management tool built with Racket. It provides a clean graphical interface for creating, organizing, and tracking your tasks efficiently.

## Features
- ✅ Create, edit, and delete tasks
- 📋 Organize tasks into lists
- 📅 Set due dates for tasks
- 🎯 Mark tasks as complete
- 💾 Automatic data persistence with SQLite
- 🌐 Cross-platform compatibility (Windows, macOS, Linux)
- 🎨 Simple and clean user interface

## Installation

### Prerequisites
- Racket 8.0 or later

### From Source
1. Clone the repository:
   ```bash
git clone https://github.com/jrtxio/taskly.git
cd taskly
   ```

2. Build the application:
   - On Windows:
     ```powershell
     ./build.ps1
     ```
   - On macOS/Linux:
     ```bash
     ./build.sh
     ```

3. Run the application:
   ```bash
   racket taskly.rkt
   ```

## Usage

### Getting Started
1. Launch the application by running `racket taskly.rkt`
2. If it's your first time, you'll be prompted to select or create a database file
3. Once the main window opens, you can start creating tasks

### Creating Tasks
1. Click on the "New Task" button
2. Enter the task title and description
3. Optionally set a due date
4. Select the list you want to add the task to
5. Click "Save" to create the task

### Managing Lists
1. Use the sidebar to view different task lists
2. Create new lists by clicking the "New List" button
3. Edit or delete lists as needed

### Marking Tasks Complete
- Click the checkbox next to a task to mark it as complete
- Completed tasks can be filtered or archived

## Architecture
Taskly follows a modular architecture with the following main components:

- **core/**: Core functionality including task management, list management, and database operations
- **gui/**: Graphical user interface components
- **utils/**: Utility functions for date handling, path management, etc.
- **test/**: Test suite for verifying functionality

## Contributing
Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development Setup
1. Clone the repository
2. Install dependencies (if any)
3. Run the tests to ensure everything works correctly:
   ```bash
   racket test/run-all-tests.rkt
   ```

## License
Taskly is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
