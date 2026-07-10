param(
  [string]$OutDir = "reports"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root
New-Item -ItemType Directory -Force $OutDir | Out-Null

function Measure-Step($Name, [scriptblock]$Body) {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    $global:LASTEXITCODE = 0
    & $Body | Out-Null
    if ($global:LASTEXITCODE -ne 0) {
      throw "Command exited with code $global:LASTEXITCODE"
    }
    $sw.Stop()
    [pscustomobject]@{ name = $Name; ok = $true; ms = [int]$sw.ElapsedMilliseconds; note = "" }
  } catch {
    $sw.Stop()
    [pscustomobject]@{ name = $Name; ok = $false; ms = [int]$sw.ElapsedMilliseconds; note = $_.Exception.Message }
  }
}

function Size-Of($Pattern) {
  $files = Get-ChildItem -Recurse -File _build -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like $Pattern }
  if (!$files) { return 0 }
  ($files | Measure-Object -Property Length -Sum).Sum
}

$rows = @()
$rows += Measure-Step "check-all" { moon check --target all }
$rows += Measure-Step "test-wasm" { moon test --target wasm }
$rows += Measure-Step "test-wasm-gc" { moon test --target wasm-gc }
$rows += Measure-Step "run-bench-wasm-gc" { moon run --target wasm-gc cmd/bench }
$rows += Measure-Step "run-bench-js" { moon run --target js cmd/bench }
$rows += Measure-Step "build-native" { moon build --target native }

$sizes = @(
  [pscustomobject]@{ artifact = "wasm"; bytes = Size-Of "*\wasm\*\*.wasm" },
  [pscustomobject]@{ artifact = "wasm-gc"; bytes = Size-Of "*\wasm-gc\*\*.wasm" },
  [pscustomobject]@{ artifact = "js"; bytes = Size-Of "*\js\*\*.js" },
  [pscustomobject]@{ artifact = "native"; bytes = Size-Of "*\native\*\*.exe" }
)

$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$csv = Join-Path $OutDir "perf-report.csv"
$md = Join-Path $OutDir "perf-report.md"
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 $csv

$lines = @()
$lines += "# MoonNavKit Performance Report"
$lines += ""
$lines += "Generated: $stamp"
$lines += ""
$lines += "## Command Timings"
$lines += ""
$lines += "| command | ok | ms | note |"
$lines += "|---|---:|---:|---|"
foreach ($row in $rows) {
  $note = ($row.note -replace "\r?\n", " ") -replace "\|", "/"
  $lines += "| $($row.name) | $($row.ok) | $($row.ms) | $note |"
}
$lines += ""
$lines += "## Artifact Sizes"
$lines += ""
$lines += "| artifact | bytes |"
$lines += "|---|---:|"
foreach ($item in $sizes) {
  $lines += "| $($item.artifact) | $($item.bytes) |"
}
$lines += ""
$lines += "Native rows may be marked failed on machines without a C compiler. GitHub Actions hosted runners provide native compilers."
$lines | Set-Content -Encoding UTF8 $md

Write-Host "Wrote $csv"
Write-Host "Wrote $md"
