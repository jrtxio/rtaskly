# Changelog

## [Unreleased]

## [0.0.21] - 2026-01-08
### Fixed
- 修复了构建脚本中找不到taskly.rkt文件的问题 / Fixed issue where taskly.rkt file couldn't be found in build scripts
- 更新了构建脚本，使用正确的src/taskly.rkt文件路径 / Updated build scripts to use correct src/taskly.rkt file path

## [0.0.20] - 2026-01-08
### Fixed
- 修复了ARM64平台上Racket安装失败的问题 / Fixed Racket installation failure on ARM64 platforms
- 使用GitHub Actions原生Arm64运行器构建ARM64版本 / Used GitHub Actions native Arm64 runners for ARM64 builds
- 简化了setup-racket配置，使用默认值 / Simplified setup-racket configuration, using default values
- 移除了不必要的QEMU配置，使用原生构建 / Removed unnecessary QEMU configuration, using native builds

## [0.0.19] - 2026-01-08
### Fixed
- 修复了Linux arm64平台上Racket安装失败的问题 / Fixed Racket installation failure on Linux arm64 platforms
- 为Linux arm64使用current版本和full发行版 / Used current version and full distribution for Linux arm64
- 恢复了Linux arm64的snapshot_site: 'utah'配置 / Restored snapshot_site: 'utah' configuration for Linux arm64

## [0.0.18] - 2026-01-08
### Fixed
- 修复了Linux arm64平台上Racket安装失败的问题 / Fixed Racket installation failure on Linux arm64 platforms
- 为Linux arm64使用了具体的Racket版本8.14 / Used specific Racket version 8.14 for Linux arm64
- 添加了distribution参数，使用minimal发行版 / Added distribution parameter, using minimal distribution
- 移除了Linux arm64的snapshot_site参数，使用默认值'auto' / Removed snapshot_site parameter for Linux arm64, using default value 'auto'

## [0.0.17] - 2026-01-08
### Fixed
- 修复了ARM64平台上Racket安装失败的问题 / Fixed Racket installation failure on ARM64 platforms
- 为setup-racket添加了variant参数，明确指定CS变体 / Added variant parameter to setup-racket, explicitly specifying CS variant
- 为ARM64构建添加了snapshot_site参数，根据平台选择合适的快照站点 / Added snapshot_site parameter for ARM64 builds, selecting appropriate snapshot site based on platform

## [0.0.16] - 2026-01-08
### Fixed
- 修复了ARM64平台上Racket安装失败的问题 / Fixed Racket installation failure on ARM64 platforms
- 为不同平台和架构设置了合适的Racket版本 / Set appropriate Racket versions for different platforms and architectures

## [0.0.15] - 2026-01-08
### Added
- 为所有平台添加了ARM架构支持 / Added ARM architecture support for all platforms
- 更新了setup-racket动作到v1.14 / Updated setup-racket action to v1.14
- 升级了Racket版本到8.18 / Upgraded Racket version to 8.18

## [0.0.14] - 2026-01-07
### Changed
- 为Linux平台添加了压缩步骤，将deb包压缩成ZIP格式，与macOS和Windows平台保持一致

## [0.0.13] - 2026-01-07
### Fixed
- 修复了DEBIAN/control文件中的变量展开问题，将单引号改为双引号

## [0.0.12] - 2026-01-07
### Fixed
- 修复了DEBIAN/control文件的字段格式，将等号(=)改为冒号(:)

## [0.0.11] - 2026-01-07
### Fixed
- 修复了GitHub Actions构建脚本中的here-document语法错误
- 修复了构建脚本中的文件创建方式，使用printf替代cat命令

## [0.0.10] - 2026-01-07
### Changed
- 将Linux版本打包格式从tar.gz改为deb格式 / Changed Linux packaging format from tar.gz to deb

## [0.0.9] - 2026-01-07

## [0.0.8] - 2026-01-07
### Fixed
- 修复了 GitHub 构建过程中 get-version.rkt 脚本的路径错误 / Fixed path error in get-version.rkt script during GitHub builds
- 修复了构建脚本中的路径问题，确保跨平台构建正常工作 / Fixed path issues in build scripts to ensure cross-platform builds work correctly

## [0.0.7] - 2026-01-06
### Added
- 重构：改进主文件中的对话框处理和代码组织 / refactor: improve dialog handling and code organization in main file
- 重构：将构建脚本重组到 build 目录 / refactor(build): reorganize build scripts into build directory
- 修复：将临时文件移至测试目录并修复时区处理 / fix(test): move temp files to test dir and fix timezone handling
- 文档：改进 README 结构和内容 / docs: improve README structure and content

## [0.0.6] - 2026-01-06
### Fixed
- 修复了列表名过长导致输入框和列表名重叠的问题 / Fixed issue where long list names caused input box overlap
- 修复了输入框变形的问题 / Fixed input box distortion issue
- 优化了任务面板的布局结构 / Optimized task panel layout structure

## [0.0.5] - 2026-01-06
### Fixed
- 修复了任务勾选完成后不会从当前列表隐藏的问题 / Fixed issue where completed tasks weren't hidden from current list

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