<#
Builds the OwnAudioSharp.Contract library bridge host and runs the ContraChip
demo against it (consuming the library by namespace import).

  .\run.ps1            # build library bridge + run demo (mock-free, needs a device or file)
  .\run.ps1 -NoBuild   # skip the bridge build, just run from the last build

Uses:  ccl --bind <lib-bridge-dll> src/main.ct
The bridge lives in the standalone library repo: D:/git/OwnAudioSharp.Contract.
contract.ctproj declares ImportRoots -> that library's src/, so `import
OwnAudioSharp;` resolves by declared namespace.
#>
param(
    [switch]$NoBuild,
    [string]$Cli = "ccl",
    [string]$BridgeDll = "../OwnAudioSharp.Contract/bridge/bin/Debug/net10.0/OwnAudioSharp.Contract.dll",
    [string]$Main = "src/main.ct"
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path ".\"

if (-not $NoBuild) {
    Write-Host "== Building OwnAudioSharp.Contract bridge (library) ==" -ForegroundColor Cyan
    Push-Location "../OwnAudioSharp.Contract/bridge"
    try { dotnet build -c Debug 2>&1 | ForEach-Object { $_.ToString() } | Write-Host }
    finally { Pop-Location }
}

if (-not (Test-Path $BridgeDll)) { throw "Bridge DLL not found: $BridgeDll (run without -NoBuild)" }

Write-Host "`n== Running: $Main ==" -ForegroundColor Cyan
Push-Location $root
try { & $Cli --bind $BridgeDll $Main }
finally { Pop-Location }
exit $LASTEXITCODE
