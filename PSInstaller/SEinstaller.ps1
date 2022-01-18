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
    'SecretKey',
    'ScriptUrl'
)

foreach ($required_config_key in $required_config_keys) {
    if ($config.Get_Item($required_config_key).length -eq 0) {
        Write-Host "[ERROR] Config key" $required_config_key "is not given" -ForegroundColor Red
        exit 3
    }
}

Write-Host "[INFO] Config loaded successfully" -ForegroundColor Green

# Check for existing deployment script or download from ScriptUrl
if (Test-Path "Deploy-ServerEye.ps1") {
    Write-Host "[INFO] File Deploy-ServerEye.ps1 exists" -ForegroundColor Green
} else {
    Write-Host "[INFO] File Deploy-ServerEye.ps1 does not exist and will be downloaded" -ForegroundColor Green
    Invoke-WebRequest $config.Get_Item($ScriptUrl) -OutFile "Deploy-ServerEye.ps1"
    Write-Host "[INFO] File Deploy-ServerEye.ps1 has been downloaded successfully" -ForegroundColor Green
}

# Check installation type
if ($config.Get_Item("ParentGuid").length -ne 0) {
    # Install SensorhubOnly
    Write-Host "[INFO] Installing Sensorhub"
    Deploy-ServerEye.ps1 -Download -Install -Deploy SensorhubOnly -Customer $config.Get_Item("CustomerNumber") -Secret $config.Get_Item("SecretKey") -ParentGuid $config.Get_Item("ParentGuid")
} else {
    # Install Sensorhub and OCC Connector
    Write-Host "[INFO] Installing OCC Connector and Sensorhub"
    Deploy-ServerEye.ps1 -Download -Install -Deploy all -Customer $config.Get_Item("CustomerNumber") -Secret $config.Get_Item("SecretKey")
}
