<#
.SYNOPSIS
    Synchronizes an LP-ALM developer environment with the current source control state.

.DESCRIPTION
    Packs all four pipeline-managed layers from the local source directory (current
    branch state) and imports them as unmanaged solutions into the target environment.

    Use this to:
      - Set up a new individual developer environment from scratch
      - Bring an existing individual dev environment up to date with main
      - Initialize an Integration Dev environment after cloning the repo

    _Config is intentionally NOT synced by this script. Apply _Config manually
    per the Config Reference Sheet for the target environment (see Section 6.3
    of LP-ALM.md and docs/onboarding-checklist.md Part 4).

.PARAMETER ProjectCode
    The project code used in solution names (e.g., SYSTRK).

.PARAMETER EnvironmentUrl
    The full URL of the target Power Platform environment.
    GCC High example:  https://yourorg-dev.crm.microsoftdynamics.us
    Commercial example: https://yourorg-dev.crm.dynamics.com

.PARAMETER Cloud
    The Power Platform cloud for PAC CLI authentication.
    Valid values: Public, UsGov, UsGovHigh, UsGovDod, China
    Default: UsGovHigh

.PARAMETER ApplicationId
    App ID of the service principal to authenticate with.
    If not provided, the script will use the currently active PAC auth profile.

.PARAMETER TenantId
    Tenant ID for service principal authentication.
    Required when ApplicationId is provided.

.PARAMETER ClientSecret
    Client secret for service principal authentication.
    Will be prompted securely if ApplicationId is provided and this is omitted.
    NOTE: Never pass this as a plain-text argument from a script or CI system.

.PARAMETER SkipAuth
    Skip the PAC auth create step and use the currently active auth profile.
    Use this when you have already authenticated and do not want to re-authenticate.

.PARAMETER SolutionsPath
    Path to the solutions directory in the repository.
    Default: ./solutions (relative to the repository root)

.PARAMETER SyncPath
    Temporary path for packed sync ZIPs.
    Default: ./sync (created and cleaned up automatically)

.EXAMPLE
    # Sync using existing auth profile
    .\sync-dev-environment.ps1 -ProjectCode SYSTRK -EnvironmentUrl https://yourorg-dev.crm.microsoftdynamics.us -SkipAuth

.EXAMPLE
    # Sync with service principal authentication (GCC High)
    .\sync-dev-environment.ps1 `
        -ProjectCode SYSTRK `
        -EnvironmentUrl https://yourorg-dev.crm.microsoftdynamics.us `
        -ApplicationId "00000000-0000-0000-0000-000000000000" `
        -TenantId "00000000-0000-0000-0000-000000000000" `
        -Cloud UsGovHigh

.NOTES
    Requires PAC CLI to be installed and available on the PATH.
    Install: dotnet tool install --global Microsoft.PowerApps.CLI.Tool
    Or via npm: npm install -g @microsoft/powerplatform-vscode

    _Config is NOT synced. After this script completes, manually apply
    _Config for this environment using the Config Reference Sheet.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectCode,

    [Parameter(Mandatory = $true)]
    [string]$EnvironmentUrl,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Public', 'UsGov', 'UsGovHigh', 'UsGovDod', 'China')]
    [string]$Cloud = 'UsGovHigh',

    [Parameter(Mandatory = $false)]
    [string]$ApplicationId,

    [Parameter(Mandatory = $false)]
    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [SecureString]$ClientSecret,

    [Parameter(Mandatory = $false)]
    [switch]$SkipAuth,

    [Parameter(Mandatory = $false)]
    [string]$SolutionsPath = './solutions',

    [Parameter(Mandatory = $false)]
    [string]$SyncPath = './sync'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ----------------------------------------------------------------
# Verify PAC CLI is available
# ----------------------------------------------------------------
if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    Write-Error "PAC CLI not found. Install with: dotnet tool install --global Microsoft.PowerApps.CLI.Tool"
    exit 1
}

# ----------------------------------------------------------------
# Verify solutions directory exists
# ----------------------------------------------------------------
$resolvedSolutionsPath = Resolve-Path $SolutionsPath -ErrorAction SilentlyContinue
if (-not $resolvedSolutionsPath) {
    Write-Error "Solutions path not found: $SolutionsPath`nRun this script from the repository root."
    exit 1
}

# ----------------------------------------------------------------
# Layers to sync (in deployment order — _Config deliberately excluded)
# ----------------------------------------------------------------
$layers = @('Security', 'Core', 'Automation', 'UI')

# ----------------------------------------------------------------
# Validate all layer source directories exist before starting
# ----------------------------------------------------------------
foreach ($layer in $layers) {
    $srcPath = Join-Path $SolutionsPath "${ProjectCode}_${layer}/src"
    if (-not (Test-Path $srcPath)) {
        Write-Error "Layer source not found: $srcPath`nEnsure all layers have been exported and unpacked to source control."
        exit 1
    }
}

Write-Host ""
Write-Host "LP-ALM Dev Environment Sync" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host "Project:     $ProjectCode"
Write-Host "Target:      $EnvironmentUrl"
Write-Host "Cloud:       $Cloud"
Write-Host "Layers:      $($layers -join ', ')"
Write-Host "NOTE: _Config will NOT be synced — apply manually after this script completes."
Write-Host ""

# ----------------------------------------------------------------
# Authenticate
# ----------------------------------------------------------------
if (-not $SkipAuth) {
    if (-not $ApplicationId) {
        Write-Error "Provide -ApplicationId and -TenantId for service principal auth, or use -SkipAuth to use the current active profile."
        exit 1
    }

    if (-not $ClientSecret) {
        $ClientSecret = Read-Host "Enter client secret for app $ApplicationId" -AsSecureString
    }

    $secretPlain = [System.Net.NetworkCredential]::new('', $ClientSecret).Password

    Write-Host "Authenticating to $EnvironmentUrl..." -ForegroundColor Yellow

    pac auth create `
        --kind ServicePrincipal `
        --applicationId $ApplicationId `
        --clientSecret $secretPlain `
        --tenant $TenantId `
        --cloud $Cloud `
        --environment $EnvironmentUrl `
        --name "sync-$(Get-Date -Format 'yyyyMMddHHmm')"

    # Clear the plain-text secret from memory
    $secretPlain = $null
}

# ----------------------------------------------------------------
# Create sync directory
# ----------------------------------------------------------------
if (Test-Path $SyncPath) {
    Remove-Item $SyncPath -Recurse -Force
}
New-Item -ItemType Directory -Path $SyncPath -Force | Out-Null

# ----------------------------------------------------------------
# Pack and import each layer
# ----------------------------------------------------------------
$failedLayers = @()

foreach ($layer in $layers) {
    $solutionName = "${ProjectCode}_${layer}"
    $srcPath = Join-Path $SolutionsPath "${solutionName}/src"
    $zipPath = Join-Path $SyncPath "${solutionName}.zip"

    Write-Host ""
    Write-Host "[$layer] Packing $solutionName..." -ForegroundColor Yellow

    pac solution pack `
        --zipfile $zipPath `
        --folder $srcPath `
        --packagetype Unmanaged

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "[$layer] Pack failed for $solutionName. Skipping import."
        $failedLayers += $layer
        continue
    }

    Write-Host "[$layer] Importing $solutionName to $EnvironmentUrl..." -ForegroundColor Yellow

    $publishChanges = if ($layer -eq 'UI') { 'true' } else { 'false' }

    pac solution import `
        --path $zipPath `
        --force-overwrite true `
        --publish-changes $publishChanges `
        --skip-dependency-check false

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "[$layer] Import failed for $solutionName."
        $failedLayers += $layer
        continue
    }

    Write-Host "[$layer] Done." -ForegroundColor Green
}

# ----------------------------------------------------------------
# Cleanup
# ----------------------------------------------------------------
Remove-Item $SyncPath -Recurse -Force

# ----------------------------------------------------------------
# Summary
# ----------------------------------------------------------------
Write-Host ""
Write-Host "============================" -ForegroundColor Cyan

if ($failedLayers.Count -eq 0) {
    Write-Host "Sync complete. All layers imported successfully." -ForegroundColor Green
} else {
    Write-Host "Sync completed with errors. Failed layers: $($failedLayers -join ', ')" -ForegroundColor Red
    Write-Host "Review PAC CLI output above for error details."
}

Write-Host ""
Write-Host "NEXT STEP: Apply _Config manually for this environment." -ForegroundColor Yellow
Write-Host "  1. Obtain the Config Reference Sheet for this environment tier"
Write-Host "  2. Set environment variable values in the Power Platform maker portal"
Write-Host "  3. Bind connection references to the appropriate credentials"
Write-Host "     (service account if available; personal credentials in dev only)"
Write-Host "  See: docs/onboarding-checklist.md — Part 4: _Config Management Protocol"
Write-Host ""
