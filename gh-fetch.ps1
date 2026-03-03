#Requires -Version 5.1
<#
.SYNOPSIS
    Fetch and execute a file from a GitHub repository using authenticated access.

.DESCRIPTION
    This script:
    1. Installs GitHub CLI (gh) if not present
    2. Authenticates with GitHub if needed
    3. Downloads a file from the specified repository
    4. Executes the file content (for .ps1 files) or outputs it

    Useful for downloading and running scripts from internal/private repositories.

.PARAMETER Repo
    The GitHub repository in owner/name format (e.g., "gim-home/skills")

.PARAMETER Path
    The file path within the repository (e.g., "install-copilot-cli.ps1")

.PARAMETER Execute
    Execute the downloaded content (default for .ps1 files). Use -Execute:$false to just output.

.EXAMPLE
    # Download and run a script from an internal repo:
    iex "& { $(irm https://raw.githubusercontent.com/stvikenv_microsoft/gh-fetch/main/gh-fetch.ps1) } -Repo gim-home/skills -Path install-copilot-cli.ps1"

.EXAMPLE
    # Download and output a file without executing:
    iex "& { $(irm https://raw.githubusercontent.com/stvikenv_microsoft/gh-fetch/main/gh-fetch.ps1) } -Repo myorg/myrepo -Path config.json -Execute:$false"

.NOTES
    This is a generic bootstrap script for fetching files from authenticated GitHub repos.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Repo,

    [Parameter(Mandatory = $true)]
    [string]$Path,

    [bool]$Execute = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '╔══════════════════════════════════════════════════════╗' -ForegroundColor Cyan
Write-Host '║   GitHub Authenticated File Fetch                    ║' -ForegroundColor Cyan
Write-Host '╚══════════════════════════════════════════════════════╝' -ForegroundColor Cyan
Write-Host ''
Write-Host "  Repository: $Repo" -ForegroundColor DarkGray
Write-Host "  File: $Path" -ForegroundColor DarkGray
Write-Host ''

# Check winget is available
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw @'
winget (App Installer) not found.
Install it from the Microsoft Store: https://www.microsoft.com/store/productId/9NBLGGH4NNS1
Or via: Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
'@
}

# Install GitHub CLI if needed
Write-Host '[1/3] GitHub CLI...' -ForegroundColor Yellow
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host '  ✓ GitHub CLI already installed' -ForegroundColor Green
} else {
    Write-Host '  → Installing GitHub CLI via winget...' -ForegroundColor Cyan
    winget install --id GitHub.cli --exact --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install GitHub CLI (exit code: $LASTEXITCODE)"
    }

    # Refresh PATH to pick up gh
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path    = "$machinePath;$userPath"

    Write-Host '  ✓ GitHub CLI installed' -ForegroundColor Green
}

# Authenticate if needed
Write-Host '[2/3] GitHub authentication...' -ForegroundColor Yellow
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host '  ✓ Already authenticated' -ForegroundColor Green
} else {
    Write-Host '  → Please authenticate with GitHub...' -ForegroundColor Cyan
    gh auth login
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub authentication failed"
    }
    Write-Host '  ✓ Authenticated' -ForegroundColor Green
}

# Download the file
Write-Host "[3/3] Downloading $Path..." -ForegroundColor Yellow
try {
    # Get base64 content and join all lines (GitHub API returns base64 with newlines)
    $base64Content = (gh api "repos/$Repo/contents/$Path" --jq -r '.content') -replace '\s', ''
    $fileContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64Content))

    if (-not $fileContent) {
        throw "Failed to download file from $Repo/$Path"
    }

    Write-Host '  ✓ File downloaded' -ForegroundColor Green
    Write-Host ''

    # Execute or output
    if ($Execute -and $Path -match '\.ps1$') {
        Write-Host '═══════════════════════════════════════════════════════' -ForegroundColor DarkGray
        Write-Host "Executing $Path..." -ForegroundColor Cyan
        Write-Host '═══════════════════════════════════════════════════════' -ForegroundColor DarkGray
        Write-Host ''
        Invoke-Expression $fileContent
    } else {
        Write-Output $fileContent
    }

} catch {
    Write-Error "Failed to download or execute file: $_"
    Write-Host ''
    Write-Host 'Manual alternative:' -ForegroundColor Yellow
    Write-Host "  gh api repos/$Repo/contents/$Path --jq '.content' | base64 -d" -ForegroundColor White
    throw
}
