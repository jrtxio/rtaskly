# Taskly发布操作手册

## 发布步骤
1. 更新info.rkt文件中的版本号
2. 更新CHANGELOG.md，添加新功能和bug修复记录
3. 提交更改：
   ```bash
   git add info.rkt CHANGELOG.md
   git commit -m "Bump version to $(racket get-version.rkt)"
   git push origin main
   ```
4. 创建并推送标签：
   ```bash
   git tag v$(racket get-version.rkt)
   git push origin v$(racket get-version.rkt)
   ```
5. 等待GitHub Actions构建完成
6. 在GitHub上编辑Release说明，添加详细的变更信息

## 回滚步骤

1. 删除GitHub上的Release
2. 删除本地标签：
   ```bash
   git tag -d v$(racket get-version.rkt)
   ```
3. 删除远程标签：
   ```bash
   git push origin :v$(racket get-version.rkt)
   ```
4. 修复问题后重新发布

## 本地构建

* **Linux/macOS**：
  ```bash
  chmod +x build.sh
  ./build.sh all
  ./build.sh windows
  ./build.sh macos
  ./build.sh linux
  ```

* **Windows**：
  ```powershell
  .\build.ps1 -Platform windows
  ```