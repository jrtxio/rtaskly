#!/bin/bash

# 获取版本号
VERSION=$(racket get-version.rkt)

# 构建可执行文件
case $1 in
  "windows")
    raco exe -o taskly.exe taskly.rkt
    zip taskly-$VERSION-windows.zip taskly.exe
    ;;
  "macos")
    raco exe -o taskly taskly.rkt
    zip taskly-$VERSION-macos.zip taskly
    ;;
  "linux")
    raco exe -o taskly taskly.rkt
    tar -czf taskly-$VERSION-linux.tar.gz taskly
    ;;
  "all")
    # Windows (模拟)
    raco exe -o taskly.exe taskly.rkt
    zip taskly-$VERSION-windows.zip taskly.exe
    
    # macOS
    raco exe -o taskly taskly.rkt
    zip taskly-$VERSION-macos.zip taskly
    
    # Linux
    tar -czf taskly-$VERSION-linux.tar.gz taskly
    ;;
  *)
    echo "Usage: $0 {windows|macos|linux|all}"
    exit 1
    ;;
esac