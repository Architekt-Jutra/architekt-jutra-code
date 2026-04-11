# PowerShell script equivalent to remote-claude zsh script
# Requires PowerShell 5.1+ and Windows 10+ (for OpenSSH)

# Set UTF-8 encoding for symbols
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Error handling
$ErrorActionPreference = "Stop"

# Configuration
$ONA_HOST = "https://flexdev.roche.com"
$ENV_CLASS_ID = "019a0712-0662-7bc0-accd-65d0f577f0d8"
$PROXY_HOST = "internal-proxy-prod-euc1-alb-1093957483.eu-central-1.elb.amazonaws.com"
$PROXY_PORT = 80
$BASE_PORT = 34431
$ENV_TIMEOUT = "3h"

# Colors - ANSI escape codes using [char]27 for PS 5.1 compatibility
$ESC = [char]27
$RED = "$ESC[0;31m"
$GREEN = "$ESC[0;32m"
$YELLOW = "$ESC[0;33m"
$NC = "$ESC[0m"

# Global variable for SSH PID
$script:SSH_PID = $null

# Helper functions
function Write-Log {
    param([string]$msg)
    $checkmark = [char]0x2713
    Write-Host "$GREEN$checkmark$NC $msg"
}

function Write-ErrorAndExit {
    param([string]$msg)
    $cross = [char]0x2717
    [Console]::Error.WriteLine("$RED$cross$NC $msg")
    exit 1
}

function Write-Info {
    param([string]$msg)
    $arrow = [char]0x2192
    Write-Host "$YELLOW$arrow$NC $msg"
}

# Find available port
function Find-AvailablePort {
    $port = $BASE_PORT
    while ($port -le ($BASE_PORT + 100)) {
        $conn = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue 2>$null
        if (-not $conn) {
            return $port
        }
        $port++
    }
    return $null
}

# Cleanup function
function Cleanup {
    if ($script:SSH_PID) {
        Stop-Process -Id $script:SSH_PID -Force -ErrorAction SilentlyContinue
    }
    $arrow = [char]0x2192
    Write-Host "`n$YELLOW$arrow$NC SSH tunnel terminated"
}

# Main script
try {
    # Find available port
    $LOCAL_PORT = Find-AvailablePort
    if (-not $LOCAL_PORT) {
        Write-ErrorAndExit "No available ports"
    }

    # Check dependencies
    if (-not (Get-Command gitpod -ErrorAction SilentlyContinue)) {
        Write-ErrorAndExit "gitpod CLI not installed"
    }
    if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
        Write-ErrorAndExit "jq not installed (brew install jq)"
    }
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-ErrorAndExit "claude CLI not installed"
    }

    # Authenticate if needed
    $whoamiOutput = & gitpod whoami 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Info "Authenticating to ONA..."
        & gitpod login --host $ONA_HOST
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorAndExit "Authentication failed"
        }
    }
    Write-Log "Authenticated to ONA"

    # Get user info
    $USER_ID = & gitpod whoami -f "user id"
    $userJson = & gitpod user get $USER_ID -o json | ConvertFrom-Json
    $USER_EMAIL = $userJson[0].email

    if (-not $USER_EMAIL.EndsWith("roche.com")) {
        Write-ErrorAndExit "Email must be @roche.com, got: $USER_EMAIL"
    }
    Write-Log "User: $USER_EMAIL"

    # Find or create repo-less environment
    $jqQuery = '[.[] | select(.spec.content.initializer.specs | length == 0)] | sort_by(if .status.phase == \"ENVIRONMENT_PHASE_RUNNING\" then 0 elif .status.phase == \"ENVIRONMENT_PHASE_STARTING\" then 1 else 2 end) | .[0] | {id, phase: .status.phase} | @json'

    $envListOutput = & gitpod env ls -o json 2>$null
    if ($LASTEXITCODE -eq 0) {
        $ENV_JSON = $envListOutput | & jq -r $jqQuery
        if ($ENV_JSON -and $ENV_JSON -ne "null") {
            $envData = $ENV_JSON | ConvertFrom-Json
            $ENV_ID = $envData.id
            $ENV_PHASE = $envData.phase -replace '^ENVIRONMENT_PHASE_', '' | ForEach-Object { $_.ToLower() }
        } else {
            $ENV_ID = $null
            $ENV_PHASE = $null
        }
    } else {
        $ENV_ID = $null
        $ENV_PHASE = $null
    }

    if (-not $ENV_ID) {
        Write-Info "Creating new environment..."
        & gitpod env create from-scratch --class-id $ENV_CLASS_ID --set-as-context --timeout $ENV_TIMEOUT
        Start-Sleep -Seconds 2

        $envListOutput = & gitpod env ls -o json 2>$null
        $ENV_JSON = $envListOutput | & jq -r $jqQuery
        $envData = $ENV_JSON | ConvertFrom-Json
        $ENV_ID = $envData.id
        $ENV_PHASE = "starting"
    }

    Write-Log "Environment: $ENV_ID ($ENV_PHASE)"

    # Start environment if needed
    if ($ENV_PHASE -eq "stopped") {
        Write-Info "Starting environment..."
        & gitpod env start $ENV_ID
    }

    # Wait for environment to be running
    if ($ENV_PHASE -ne "running") {
        Write-Info "Waiting for environment to start (this may take up to 3 minutes for cold starts)..."
        $MAX_WAIT = 180
        $WAIT_INTERVAL = 5
        $ELAPSED = 0

        while ($ELAPSED -lt $MAX_WAIT) {
            $envListOutput = & gitpod env ls -o json 2>$null
            if ($LASTEXITCODE -eq 0) {
                $envArray = $envListOutput | ConvertFrom-Json
                $currentEnv = $envArray | Where-Object { $_.id -eq $ENV_ID }
                if ($currentEnv) {
                    $CURRENT_PHASE = $currentEnv.status.phase -replace '^ENVIRONMENT_PHASE_', '' | ForEach-Object { $_.ToLower() }
                } else {
                    $CURRENT_PHASE = "unknown"
                }
            } else {
                $CURRENT_PHASE = "unknown"
            }

            if ($CURRENT_PHASE -eq "running") {
                break
            } elseif ($CURRENT_PHASE -eq "unknown" -or [string]::IsNullOrEmpty($CURRENT_PHASE)) {
                Write-Info "  Waiting for API response... ($ELAPSED seconds elapsed)"
            } else {
                Write-Info "  Status: $CURRENT_PHASE ($ELAPSED seconds elapsed)"
            }

            Start-Sleep -Seconds $WAIT_INTERVAL
            $ELAPSED += $WAIT_INTERVAL
        }

        if ($CURRENT_PHASE -ne "running") {
            Write-ErrorAndExit "Environment failed to start within $MAX_WAIT seconds. Last status: $CURRENT_PHASE"
        }
    }
    Write-Log "Environment running"

    # Setup SSH tunnel
    Write-Info "Setting up SSH tunnel..."
    & gitpod env ssh-config
    $ENV_URL = "$ENV_ID.gitpod.environment"

    $sshArgs = @("-N", "-L", "${LOCAL_PORT}:${PROXY_HOST}:${PROXY_PORT}", $ENV_URL)
    $sshProcess = Start-Process ssh -ArgumentList $sshArgs -NoNewWindow -PassThru
    $script:SSH_PID = $sshProcess.Id
    Start-Sleep -Seconds 5

    # Health check
    $healthCheck = Test-NetConnection -ComputerName localhost -Port $LOCAL_PORT -InformationLevel Quiet -WarningAction SilentlyContinue 2>$null
    if (-not $healthCheck) {
        Stop-Process -Id $script:SSH_PID -Force -ErrorAction SilentlyContinue
        Write-ErrorAndExit "Tunnel health check failed"
    }
    Write-Log "SSH tunnel established on localhost:$LOCAL_PORT"

    # Set environment variables and launch Claude
    $HEADERS_JSON = '{"_user":"' + $USER_EMAIL + '","ona_user_id":"' + $USER_ID + '","tool":"claude"}'
    $CUSTOM_HEADERS = "x-portkey-metadata: $HEADERS_JSON"

    $env:ANTHROPIC_BASE_URL = "http://localhost:$LOCAL_PORT/proxy"
    $env:ANTHROPIC_AUTH_TOKEN = "dummy"
    $env:ANTHROPIC_CUSTOM_HEADERS = $CUSTOM_HEADERS

    Write-Host ""
    Write-Host "$GREEN======================================================================$NC"
    Write-Host "${GREEN}Starting Claude Code with ONA tunnel (Opus) on port $LOCAL_PORT$NC"
    Write-Host "$GREEN======================================================================$NC"
    Write-Host ""

    # Run claude with opus model by default, user args can override
    & claude --model opus @args

} finally {
    Cleanup
}
