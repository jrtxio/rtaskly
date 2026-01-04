# Taskly
# Taskly (任务管理工具)
📝 To-Do Tool — A Simple and Intuitive Task Manager Built with Racket

## Table of Contents
## 目录
- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

## Overview
## 概述
Taskly is a simple and intuitive task management tool built with Racket. It provides a clean graphical interface for creating, organizing, and tracking your tasks efficiently.
Taskly 是一个使用 Racket 构建的简单直观的任务管理工具。它提供了一个干净的图形界面，用于高效地创建、组织和跟踪您的任务。

## Features
## 特性
- ✅ Create, edit, and delete tasks
- 📋 Organize tasks into lists
- 📅 Set due dates for tasks
- 🎯 Mark tasks as complete
- 💾 Automatic data persistence with SQLite
- 🌐 Cross-platform compatibility (Windows, macOS, Linux)
- 🎨 Simple and clean user interface
- ✅ 创建、编辑和删除任务
- 📋 将任务组织成列表
- 📅 为任务设置截止日期
- 🎯 将任务标记为完成
- 💾 使用 SQLite 自动数据持久化
- 🌐 跨平台兼容（Windows、macOS、Linux）
- 🎨 简单干净的用户界面

## Installation
## 安装

### Prerequisites
### 前提条件
- Racket 8.0 or later
- Racket 8.0 或更高版本

### From Source
### 从源代码安装
1. Clone the repository:
   ```bash
   git clone https://github.com/jrtxio/taskly.git
   cd taskly
   ```

1. 克隆仓库：
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

2. 构建应用程序：
   - 在 Windows 上：
     ```powershell
     ./build.ps1
     ```
   - 在 macOS/Linux 上：
     ```bash
     ./build.sh
     ```

3. Run the application:
   ```bash
   racket taskly.rkt
   ```

3. 运行应用程序：
   ```bash
   racket taskly.rkt
   ```

## Usage
## 使用方法

### Getting Started
### 入门指南
1. Launch the application by running `racket taskly.rkt`
2. If it's your first time, you'll be prompted to select or create a database file
3. Once the main window opens, you can start creating tasks

1. 通过运行 `racket taskly.rkt` 启动应用程序
2. 如果是第一次使用，系统会提示您选择或创建数据库文件
3. 主窗口打开后，您就可以开始创建任务了

### Creating Tasks
### 创建任务
1. Click on the "New Task" button
2. Enter the task title and description
3. Optionally set a due date
4. Select the list you want to add the task to
5. Click "Save" to create the task

1. 点击 "新建任务" 按钮
2. 输入任务标题和描述
3. 可选：设置截止日期
4. 选择要添加任务的列表
5. 点击 "保存" 创建任务

### Managing Lists
### 管理列表
1. Use the sidebar to view different task lists
2. Create new lists by clicking the "New List" button
3. Edit or delete lists as needed

1. 使用侧边栏查看不同的任务列表
2. 点击 "新建列表" 按钮创建新列表
3. 根据需要编辑或删除列表

### Marking Tasks Complete
### 标记任务完成
- Click the checkbox next to a task to mark it as complete
- Completed tasks can be filtered or archived

- 点击任务旁边的复选框将其标记为完成
- 已完成的任务可以被过滤或归档

## Architecture
## 架构
Taskly follows a modular architecture with the following main components:
Taskly 采用模块化架构，包含以下主要组件：

- **core/**: Core functionality including task management, list management, and database operations
- **gui/**: Graphical user interface components
- **utils/**: Utility functions for date handling, path management, etc.
- **test/**: Test suite for verifying functionality

- **core/**: 核心功能，包括任务管理、列表管理和数据库操作
- **gui/**: 图形用户界面组件
- **utils/**: 工具函数，用于日期处理、路径管理等
- **test/**: 测试套件，用于验证功能

## Contributing
## 贡献
Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.
欢迎贡献！请随时提交问题、功能请求或拉取请求。

### Development Setup
### 开发环境设置
1. Clone the repository
2. Install dependencies (if any)
3. Run the tests to ensure everything works correctly:
   ```bash
   racket test/run-all-tests.rkt
   ```

1. 克隆仓库
2. 安装依赖（如果有）
3. 运行测试以确保一切正常工作：
   ```bash
   racket test/run-all-tests.rkt
   ```

## License
## 许可证
Taskly is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
Taskly 采用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。