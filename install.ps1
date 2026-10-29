# Links Coordinator into Claude Code from this checkout on Windows, so `git pull` updates it.
#   coord, coord.cmd -> $env:COORD_BIN_DIR (default ~\.local\bin, added to your user PATH)
#   /coordinate      -> ~\.claude\skills\coordinate (a junction)
foreach ($py in @(@("py", "-3"), @("python"), @("python3"))) {
    $exe = Get-Command $py[0] -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $exe) { continue }
    $rest = @($py | Select-Object -Skip 1)
    & $exe.Source @rest -c "import sys; sys.exit(sys.version_info < (3, 9))" 2>$null
    if ($LASTEXITCODE -eq 0) {
        & $exe.Source @rest -X utf8 (Join-Path $PSScriptRoot "bin\coord") _install
        exit $LASTEXITCODE
    }
}
Write-Host "Coordinator needs Python 3.9+: winget install Python.Python.3.13"
exit 1
