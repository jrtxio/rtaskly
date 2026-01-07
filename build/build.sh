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
    cat > "${DEB_DIR}"/usr/share/applications/taskly.desktop << EOF
[Desktop Entry]
Name=Taskly
Comment=A simple task manager built with Racket
Exec=/usr/bin/taskly
Icon=taskly
Terminal=false
Type=Application
Categories=Utility;Office;
EOF
    
    # Create control file
    cat > "${DEB_DIR}"/DEBIAN/control << EOF
Package=taskly
Version=${VERSION}
Section=utils
Priority=optional
Architecture=amd64
Depends=libc6 (>= 2.34)
Maintainer=jrtxio <jrtxio@gmail.com>
Description=A simple and intuitive task management tool.
EOF
    
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
    cat > "${DEB_DIR}"/usr/share/applications/taskly.desktop << EOF
[Desktop Entry]
Name=Taskly
Comment=A simple task manager built with Racket
Exec=/usr/bin/taskly
Icon=taskly
Terminal=false
Type=Application
Categories=Utility;Office;
EOF
    
    # Create control file
    cat > "${DEB_DIR}"/DEBIAN/control << EOF
Package=taskly
Version=${VERSION}
Section=utils
Priority=optional
Architecture=amd64
Depends=libc6 (>= 2.34)
Maintainer=jrtxio <jrtxio@gmail.com>
Description=A simple and intuitive task management tool.
EOF
    
    # Build deb package
    dpkg-deb --build "${DEB_DIR}" "taskly-${VERSION}-linux.deb"
    ;;
  *)
    echo "Usage: $0 {windows|macos|linux|all}"
    exit 1
    ;;
esac