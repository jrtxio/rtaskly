param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("windows", "macos", "linux", "all")]
    [string]$Platform
)

$VERSION = racket ./build/get-version.rkt

switch ($Platform) {
    "windows" {
        raco exe --gui --ico icons/48x48.ico -o taskly.exe taskly.rkt
        Compress-Archive -Path taskly.exe -DestinationPath taskly-$VERSION-windows.zip -Force
    }
    "macos" {
        Write-Host "macOS build not supported on Windows"
    }
    "linux" {
        Write-Host "Linux build not supported on Windows"
    }
    "all" {
        raco exe --gui --ico icons/48x48.ico -o taskly.exe taskly.rkt
        Compress-Archive -Path taskly.exe -DestinationPath taskly-$VERSION-windows.zip -Force
    }
}