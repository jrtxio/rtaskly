param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("windows", "macos", "linux", "all")]
    [string]$Platform
)

$VERSION = racket ./build/get-version.rkt

# 备份原始main-frame.rkt文件
Copy-Item -Path src/gui/main-frame.rkt -Destination src/gui/main-frame.rkt.bak -Force

# 直接构建应用程序，不修改版本号函数
# 版本号已经在main-frame.rkt中硬编码为0.0.25

switch ($Platform) {
    "windows" {
        raco exe --gui --ico icons/48x48.ico -o taskly.exe src/taskly.rkt
        Compress-Archive -Path taskly.exe -DestinationPath taskly-$VERSION-windows.zip -Force
    }
    "macos" {
        Write-Host "macOS build not supported on Windows"
    }
    "linux" {
        Write-Host "Linux build not supported on Windows"
    }
    "all" {
        raco exe --gui --ico icons/48x48.ico -o taskly.exe src/taskly.rkt
        Compress-Archive -Path taskly.exe -DestinationPath taskly-$VERSION-windows.zip -Force
    }
}

# 恢复原始main-frame.rkt文件
Copy-Item -Path src/gui/main-frame.rkt.bak -Destination src/gui/main-frame.rkt -Force
Remove-Item -Path src/gui/main-frame.rkt.bak -ErrorAction SilentlyContinue