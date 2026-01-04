param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("windows", "macos", "linux", "all")]
    [string]$Platform
)

$VERSION = racket get-version.rkt

switch ($Platform) {
    "windows" {
        raco exe -o taskly.exe taskly.rkt
        Compress-Archive -Path taskly.exe -DestinationPath taskly-$VERSION-windows.zip
    }
    "macos" {
        Write-Host "macOS build not supported on Windows"
    }
    "linux" {
        Write-Host "Linux build not supported on Windows"
    }
    "all" {
        raco exe -o taskly.exe taskly.rkt
        Compress-Archive -Path taskly.exe -DestinationPath taskly-$VERSION-windows.zip
    }
}