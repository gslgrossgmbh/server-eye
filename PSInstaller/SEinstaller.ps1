# Check for existing config file or create one from config_template.txt
if (Test-Path "config.txt") {
    Write-Host "[INFO] File config.txt exists" -ForegroundColor Green
} else {
    Write-Host "[ERROR] File config.txt does not exist and has been created" -ForegroundColor Red
    Copy-Item -Path "config_template.txt" -Destination "config.txt"
    Write-Host "[WARN] Adjust the configuration and re-run the script" -ForegroundColor Yellow
    exit 1
}

# Check if config is valid and load config keys
$config=@{}
$configContent = Get-Content "config.txt"

foreach ($key in $configContent) {
    if ($key -eq "") { # Skip line if empty
        continue
    }
    $key = [regex]::split($key,' = ')
    if ($key[0].StartsWith("*")) { # Check if line is a required key
        if ($key[1] -eq "") { # Check if required key is empty
            Write-Host "[ERROR] Config key" $key[0] "is empty but required" -ForegroundColor Red
            exit 2
        } else {
            $config.Add($key[0].Substring(1), $key[1])
        }
    } elseif ($key[1] -eq "") { # Skip line if empty value
        continue
    } elseif (-Not $key[0].StartsWith("#")) { # Check if line is not a comment
        $config.Add($key[0], $key[1])
    }
}

$required_config_keys = @(
    'CustomerNumber',
    'SecretKey'
)

foreach ($required_config_key in $required_config_keys) {
    if ($config.Get_Item($required_config_key).length -eq 0) {
        Write-Host "[ERROR] Config key" $required_config_key "is not given" -ForegroundColor Red
        exit 3
    }
}

Write-Host "[INFO] Config loaded successfully" -ForegroundColor Green

# Check for existing deployment script or download
if (Test-Path "Deploy-ServerEye.ps1") {
    Write-Host "[INFO] File Deploy-ServerEye.ps1 exists" -ForegroundColor Green
} else {
    Write-Host "[INFO] File Deploy-ServerEye.ps1 does not exist and will be downloaded" -ForegroundColor Green
    Invoke-WebRequest "https://occ.server-eye.de/download/se/Deploy-ServerEye.ps1" -OutFile "Deploy-ServerEye.ps1"
    Write-Host "[INFO] File Deploy-ServerEye.ps1 has been downloaded successfully" -ForegroundColor Green
}

# Uninstall and cleanup if uninstall is true
if ($config.Get_Item("uninstall") -eq "true") {
    Write-Host "[WARN] Server Eye will be uninstalled" -ForegroundColor Yellow
    Write-Host "[WARN] Press any key to continue ..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Invoke-WebRequest "https://raw.githubusercontent.com/Server-Eye/se-installer-cli/master/de/Uninstall-ServerEye.ps1" -OutFile "Uninstall-ServerEye.ps1"
    .\Uninstall-ServerEye.ps1
    Write-Host "[INFO] Server Eye uninstalled" -ForegroundColor Green
}

# Check installation type
if ($config.Get_Item("ParentGuid").length -ne 0) {
    # Install SensorhubOnly
    Write-Host "[INFO] Installing Sensorhub" -ForegroundColor Green
    .\Deploy-ServerEye.ps1 -Download -Install -Deploy SensorhubOnly -Customer $config.Get_Item("CustomerNumber") -Secret $config.Get_Item("SecretKey") -ParentGuid $config.Get_Item("ParentGuid")
    Write-Host "[INFO] Sensorhub installed!" -ForegroundColor Green
} else {
    # Install Sensorhub and OCC Connector
    Write-Host "[INFO] OCC Connector and Sensorhub installed!" -ForegroundColor Green
    .\Deploy-ServerEye.ps1 -Download -Install -Deploy all -Customer $config.Get_Item("CustomerNumber") -Secret $config.Get_Item("SecretKey")
}
