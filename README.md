🌍 [English](README.md) | [中文](README.zh-CN.md)

# Taskly
📝 To-Do Tool — A Simple and Intuitive Task Manager Built with Racket

## Table of Contents
- [Project Overview](#project-overview)
- [Features](#features)
- [Technical Architecture](#technical-architecture)
- [Development Environment Setup](#development-environment-setup)
- [Development Guide](#development-guide)
- [Contributing](#contributing)
- [Deployment and Release](#deployment-and-release)
- [License](#license)

## Project Overview
Taskly is a simple and intuitive task management tool built with Racket. It provides a clean graphical interface for creating, organizing, and tracking tasks efficiently.

For end-user documentation, please visit our [GitHub Pages](https://taskly.jrtx.site).

## Features
- ✅ Create, edit, and delete tasks
- 📋 Organize tasks into lists
- 📅 Set due dates for tasks with smart shortcuts
- 🎯 Mark tasks as complete
- 💾 Automatic data persistence with SQLite
- 🌐 Cross-platform compatibility (Windows, macOS, Linux)
- 🎨 Simple and clean user interface
- 🌍 Multi-language support

## Technical Architecture

### Modular Design
Taskly follows a modular architecture with clear separation of concerns:

- **core/**: Core functionality including task management, list management, and database operations
  - `database.rkt`: SQLite database operations and schema management
  - `list.rkt`: Task list management (create, read, update, delete)
  - `task.rkt`: Task management (create, read, update, delete, due date handling)
  
- **gui/**: Graphical user interface components built with Racket GUI toolkit
  - `main-frame.rkt`: Main application window and layout
  - `sidebar.rkt`: Sidebar with list navigation
  - `task-panel.rkt`: Task display and management panel
  - `dialogs.rkt`: Dialog boxes for task and list operations
  - `language.rkt`: Multi-language support
  
- **utils/**: Utility functions for various operations
  - `date.rkt`: Date and time handling, including smart shortcut parsing
  - `path.rkt`: File path management and database file handling
  
- **test/**: Comprehensive test suite
  - Unit tests for core functionality
  - Integration tests for end-to-end workflows
  - Edge case testing

### Data Flow
1. User interacts with the GUI components
2. GUI events trigger core functionality calls
3. Core functions perform database operations via SQLite
4. Database changes are reflected in the GUI
5. All data is automatically persisted

### Database Schema
Taskly uses SQLite for data persistence with a simple schema:

```sql
-- Lists table
CREATE TABLE IF NOT EXISTS lists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    created_at TEXT NOT NULL
);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    due_date TEXT,
    completed INTEGER DEFAULT 0,
    list_id INTEGER,
    created_at TEXT NOT NULL,
    FOREIGN KEY (list_id) REFERENCES lists(id)
);
```

## Development Environment Setup

### Prerequisites
- Racket 8.0 or later
- Git

### Installation Steps
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

## Development Guide

### Running Tests
Taskly has a comprehensive test suite to ensure functionality works as expected:

```bash
# Run all tests
racket test/run-all-tests.rkt

# Run specific test files
racket test/test-task.rkt
racket test/test-list.rkt
```

### Code Structure
- All code follows Racket's style guide
- Modules are designed to be independent and testable
- Comments are used to explain complex logic

### Debugging Tips
- Use Racket's built-in debugger for GUI applications
- Enable verbose logging for database operations
- Test core functionality in isolation before GUI integration

## Contributing
Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Contribution Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Run the test suite to ensure everything works
5. Commit your changes (`git commit -m 'Add some feature'`)
6. Push to the branch (`git push origin feature/your-feature`)
7. Open a pull request

### Code Review Guidelines
- All changes must pass the test suite
- Code must follow the project's style guide
- Changes should be focused and minimal
- Add tests for new functionality

## Deployment and Release

### Build Process
1. Run the appropriate build script for your platform
2. The build process compiles the application and prepares distribution packages
3. Distribution packages are generated in the `dist/` directory

### Release Management
- Releases are managed through GitHub Releases
- Version numbers follow semantic versioning
- Release notes are automatically generated from commit messages

### CI/CD Configuration
- GitHub Actions are used for continuous integration
- Tests are run on every push to main branch
- GitHub Pages are automatically deployed on every push to main branch

## License
Taskly is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.