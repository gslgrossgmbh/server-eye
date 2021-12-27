# Check for existing config file or create one from config_template.txt
if (Test-Path "config.txt") {
    Write-Host "[INFO] File config.txt exists"
} else {
    Write-Host "[ERROR] File config.txt does not exist and has been created"
    Copy-Item -Path "config_template.txt" -Destination "config.txt"
    Write-Host "[WARN] Adjust the configuration and re-run the script"
    exit 1
}

# Check if config is valid and load config keys
$config=@{}
$configContent = Get-Content "config.txt"

foreach ($key in $configContent) {
    $key = [regex]::split($key,' = ')
    $config.Add($key[0], $key[1])
    if ($key[0].StartsWith("*")) {
        if ($key[1] -eq "") {
            Write-Host "[ERROR] Config key" $key[0] "is empty but required"
            exit 2
        }
    }
}

Write-Host "[INFO] Config loaded successfully"

# TODO Installing
