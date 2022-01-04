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
    $key = [regex]::split($key,' = ')
    if ($key[0].StartsWith("*")) { # Check if line is a required key
        if ($key[1] -eq "") { # Check if required key is empty
            Write-Host "[ERROR] Config key" $key[0] "is empty but required" -ForegroundColor Red
            exit 2
        } else {
            $config.Add($key[0].Substring(1), $key[1])
        }
    } elseif (-Not $key[0].StartsWith("#")) { # Check if line is not a comment
        $config.Add($key[0], $key[1])
    }
}

$required_config_keys = @(
    'AgentDownloadUrl',
    'ApiKey',
    'ConnectorId',
    'CustomerId'
)

foreach ($required_config_key in $required_config_keys) {
    if ($config.Get_Item($required_config_key).length -eq 0) {
        Write-Host "[ERROR] Config key" $required_config_key "is not given" -ForegroundColor Red
        exit 3
    }
}

Write-Host "[INFO] Config loaded successfully" -ForegroundColor Green

# TODO Installing, Fix variable with * not getting found

# https://servereye.freshdesk.com/support/solutions/articles/14000113669-wie-installiere-ich-se-via-kommandozeile