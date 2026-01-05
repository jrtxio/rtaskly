# Changelog

## [Unreleased]

## [0.0.4] - 2026-01-05
### Fixed
- 修复了GitHub Pages主页上中英文切换时导航栏链接不会切换的问题 / Fixed navigation links not switching language on GitHub Pages

## [0.0.3] - 2026-01-05
### Added
- 修复了macOS ARM64构建问题 / Fixed macOS ARM64 build issue
- 改进了GitHub Actions工作流，添加了环境信息输出 / Improved GitHub Actions workflow with environment info output
- 添加了构建产物验证步骤 / Added build artifact verification step
- 更新了构建脚本，确保在所有架构上正常工作 / Updated build script to work on all architectures

## [0.0.2] - 2026-01-04
### Added
- 支持多架构构建（x86_64和arm64） / Added multi-architecture support (x86_64 and arm64)
- 改进了GitHub Actions工作流，为每个操作系统构建两个架构版本 / Enhanced GitHub Actions workflow to build for two architectures per OS
- 更新了产物命名规则，包含版本、操作系统和架构信息 / Updated artifact naming convention to include version, OS, and architecture

## [0.0.1] - 2026-01-04
### Added
- 初始版本发布 / Initial release
- 支持Windows、macOS和Linux平台 / Support for Windows, macOS, and Linux platforms
- 完整的测试套件 / Comprehensive test suite
- 自动化构建和发布流程 / Automated build and release workflow
- 切换到MIT许可证 / Switched to MIT license
- 为所有平台添加了应用图标支持 / Added application icon support for all platforms
- 改进了窗口图标显示，解决了标题栏图标显示不完整的问题 / Improved window icon display, fixing incomplete title bar icon
- 优化了构建脚本，确保所有平台都生成纯图形界面应用 / Optimized build scripts to ensure pure GUI apps for all platforms
- 为Windows构建添加了图标嵌入支持 / Added icon embedding support for Windows builds
- 添加了多种尺寸的图标文件，支持不同分辨率显示 / Added various sized icon files for different resolution displays