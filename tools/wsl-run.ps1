Param([string]$ExampleDir = "0.0.0_example")
$ErrorActionPreference = "Stop"
wsl bash -lc "cd '$ExampleDir' && ../1mount.sh"
wsl bash -lc "cd '$ExampleDir' && ../3patch.sh"
wsl bash -lc "cd '$ExampleDir' && ../6pack.sh"
Write-Host "Done. Check '$ExampleDir/out'."
