# gh-fetch

Generic authenticated GitHub file fetcher - downloads and executes files from any repository you have access to.

## What is this?

A minimal PowerShell bootstrap script that:
1. Installs GitHub CLI (`gh`) if not present
2. Authenticates with GitHub if needed
3. Downloads a file from any GitHub repository (public or private)
4. Executes the file (for `.ps1` scripts) or outputs its content

Perfect for one-liner bootstraps from internal or private repositories.

## Usage

### Download and run a PowerShell script

```powershell
iex "& { $(irm https://raw.githubusercontent.com/steffenvv/gh-fetch/main/gh-fetch.ps1) } -Repo owner/repo -Path path/to/script.ps1"
```

### Download a file without executing

```powershell
iex "& { $(irm https://raw.githubusercontent.com/steffenvv/gh-fetch/main/gh-fetch.ps1) } -Repo owner/repo -Path config.json -Execute:$false"
```

## Example

If you have a private repository at `myorg/bootstrap` with an installer at `setup.ps1`:

```powershell
iex "& { $(irm https://raw.githubusercontent.com/steffenvv/gh-fetch/main/gh-fetch.ps1) } -Repo myorg/bootstrap -Path setup.ps1"
```

The script will:
- Install GitHub CLI via winget (if needed)
- Prompt for GitHub authentication (one-time, if needed)
- Download and execute the installer from your repository

## Parameters

- **`-Repo`** (required): Repository in `owner/name` format
- **`-Path`** (required): File path within the repository
- **`-Execute`** (optional): Execute downloaded content (default: `$true` for `.ps1` files)

## Requirements

- Windows with winget (App Installer) - usually pre-installed on Windows 11
- PowerShell 5.1 or later

## License

MIT License - feel free to use, modify, and distribute.

## Author

Created to simplify bootstrapping from private GitHub repositories.
