#!/bin/bash

# 获取版本号
VERSION=$(racket ./build/get-version.rkt)

# 构建可执行文件
case $1 in
  "windows")
    raco exe -o taskly.exe taskly.rkt
    zip taskly-$VERSION-windows.zip taskly.exe
    ;;
  "macos")
    raco exe -o taskly taskly.rkt
    raco distribute taskly-dist taskly
    
    # Check if create-dmg is installed, if not, install it
    if ! command -v create-dmg &> /dev/null; then
        echo "Installing create-dmg tool..."
        brew install create-dmg
    fi
    
    # Create application bundle structure
    mkdir -p Taskly.app/Contents/MacOS
    mkdir -p Taskly.app/Contents/Resources
    
    # Copy executable and resources
    cp -r taskly-dist/* Taskly.app/Contents/MacOS/
    
    # Create DMG file
    create-dmg \
      --volname "Taskly" \
      --volicon "icons/taskly.svg" \
      --window-pos 200 120 \
      --window-size 800 400 \
      --icon-size 100 \
      --icon "Taskly.app" 200 190 \
      --hide-extension "Taskly.app" \
      --app-drop-link 600 185 \
      "taskly-$VERSION-macos.dmg" \
      "Taskly.app" 
    
    # Also keep zip for backward compatibility
    zip taskly-$VERSION-macos.zip taskly
    ;;
  "linux")
    raco exe -o taskly taskly.rkt
    raco distribute taskly-dist taskly
    
    # Create deb package structure
    DEB_DIR="taskly-${VERSION}-linux-deb"
    mkdir -p "${DEB_DIR}"/DEBIAN
    mkdir -p "${DEB_DIR}"/usr/bin
    mkdir -p "${DEB_DIR}"/usr/share/applications
    mkdir -p "${DEB_DIR}"/usr/share/icons/hicolor/512x512/apps
    
    # Copy executable to bin directory
    cp -r taskly-dist/* "${DEB_DIR}"/usr/bin/
    
    # Copy icon
    cp icons/taskly.png "${DEB_DIR}"/usr/share/icons/hicolor/512x512/apps/
    
    # Create desktop file
    printf '[Desktop Entry]\nName=Taskly\nComment=A simple task manager built with Racket\nExec=/usr/bin/taskly\nIcon=taskly\nTerminal=false\nType=Application\nCategories=Utility;Office;\n' > "${DEB_DIR}"/usr/share/applications/taskly.desktop
    
    # Create control file
    printf 'Package=taskly\nVersion=${VERSION}\nSection=utils\nPriority=optional\nArchitecture=amd64\nDepends=libc6 (>= 2.34)\nMaintainer=jrtxio <jrtxio@gmail.com>\nDescription=A simple and intuitive task management tool.\n' > "${DEB_DIR}"/DEBIAN/control
    
    # Build deb package
    dpkg-deb --build "${DEB_DIR}" "taskly-${VERSION}-linux.deb"
    ;;
  "all")
    # Windows (模拟)
    raco exe -o taskly.exe taskly.rkt
    zip taskly-$VERSION-windows.zip taskly.exe
    
    # macOS
    raco exe -o taskly taskly.rkt
    raco distribute taskly-dist taskly
    
    # Check if create-dmg is installed, if not, install it
    if ! command -v create-dmg &> /dev/null; then
        echo "Installing create-dmg tool..."
        brew install create-dmg
    fi
    
    # Create application bundle structure
    mkdir -p Taskly.app/Contents/MacOS
    mkdir -p Taskly.app/Contents/Resources
    
    # Copy executable and resources
    cp -r taskly-dist/* Taskly.app/Contents/MacOS/
    
    # Create DMG file
    create-dmg \
      --volname "Taskly" \
      --volicon "icons/taskly.svg" \
      --window-pos 200 120 \
      --window-size 800 400 \
      --icon-size 100 \
      --icon "Taskly.app" 200 190 \
      --hide-extension "Taskly.app" \
      --app-drop-link 600 185 \
      "taskly-$VERSION-macos.dmg" \
      "Taskly.app" 
    
    # Also keep zip for backward compatibility
    zip taskly-$VERSION-macos.zip taskly
    
    # Linux
    raco exe -o taskly taskly.rkt
    raco distribute taskly-dist taskly
    
    # Create deb package structure
    DEB_DIR="taskly-${VERSION}-linux-deb"
    mkdir -p "${DEB_DIR}"/DEBIAN
    mkdir -p "${DEB_DIR}"/usr/bin
    mkdir -p "${DEB_DIR}"/usr/share/applications
    mkdir -p "${DEB_DIR}"/usr/share/icons/hicolor/512x512/apps
    
    # Copy executable to bin directory
    cp -r taskly-dist/* "${DEB_DIR}"/usr/bin/
    
    # Copy icon
    cp icons/taskly.png "${DEB_DIR}"/usr/share/icons/hicolor/512x512/apps/
    
    # Create desktop file
    printf '[Desktop Entry]\nName=Taskly\nComment=A simple task manager built with Racket\nExec=/usr/bin/taskly\nIcon=taskly\nTerminal=false\nType=Application\nCategories=Utility;Office;\n' > "${DEB_DIR}"/usr/share/applications/taskly.desktop
    
    # Create control file
    printf 'Package=taskly\nVersion=${VERSION}\nSection=utils\nPriority=optional\nArchitecture=amd64\nDepends=libc6 (>= 2.34)\nMaintainer=jrtxio <jrtxio@gmail.com>\nDescription=A simple and intuitive task management tool.\n' > "${DEB_DIR}"/DEBIAN/control
    
    # Build deb package
    dpkg-deb --build "${DEB_DIR}" "taskly-${VERSION}-linux.deb"
    ;;
  *)
    echo "Usage: $0 {windows|macos|linux|all}"
    exit 1
    ;;
esac