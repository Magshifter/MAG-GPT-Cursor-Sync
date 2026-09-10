# [MAG] GPT|Cursor|Sync setup
# by Magshifter
#
# Installs the Cursor extension from this repository.
# Does not enable Windows startup.
# Does not launch ChatGPT, Cursor, or Windows Terminal.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExtensionDir = Join-Path $RepoRoot "cursor-extension"
$PackageJsonPath = Join-Path $ExtensionDir "package.json"
$ExtensionId = "magshifter.mag-workflow-bridge"

function Write-Step([string]$Message) {
	Write-Host $Message
}

function Find-AutoHotkey {
	$programFiles = ${env:ProgramFiles}
	if (-not $programFiles) {
		$programFiles = "C:\Program Files"
	}
	$candidates = @(
		(Join-Path $programFiles "AutoHotkey\v2\AutoHotkey64.exe"),
		(Join-Path $programFiles "AutoHotkey\AutoHotkey64.exe")
	)
	if ($env:LOCALAPPDATA) {
		$candidates += (Join-Path $env:LOCALAPPDATA "Programs\AutoHotkey\v2\AutoHotkey64.exe")
	}
	foreach ($candidate in $candidates) {
		if (Test-Path $candidate) {
			return $candidate
		}
	}
	return $null
}

function Find-CursorCli {
	$cmd = Get-Command cursor.cmd -ErrorAction SilentlyContinue
	if ($cmd) {
		return $cmd.Source
	}
	$cmd = Get-Command cursor -ErrorAction SilentlyContinue
	if ($cmd) {
		return $cmd.Source
	}
	if ($env:LOCALAPPDATA) {
		$fallback = Join-Path $env:LOCALAPPDATA "Programs\cursor\resources\app\bin\cursor.cmd"
		if (Test-Path $fallback) {
			return $fallback
		}
	}
	return $null
}

function Get-ExtensionIdentity {
	if (-not (Test-Path $PackageJsonPath)) {
		throw "cursor-extension/package.json was not found next to setup.ps1."
	}
	$package = Get-Content $PackageJsonPath -Raw | ConvertFrom-Json
	if (-not $package.publisher -or -not $package.name -or -not $package.version) {
		throw "cursor-extension/package.json is missing publisher, name, or version."
	}
	return [pscustomobject]@{
		Publisher    = [string]$package.publisher
		Name         = [string]$package.name
		Version      = [string]$package.version
		DisplayName  = [string]$package.displayName
		Description  = [string]$package.description
		Engine       = [string]$package.engines.vscode
	}
}

function Add-ZipFileEntry {
	param(
		[System.IO.Compression.ZipArchive]$Archive,
		[string]$EntryName,
		[byte[]]$Bytes
	)
	$entry = $Archive.CreateEntry($EntryName, [System.IO.Compression.CompressionLevel]::Optimal)
	$stream = $entry.Open()
	try {
		$stream.Write($Bytes, 0, $Bytes.Length)
	}
	finally {
		$stream.Dispose()
	}
}

function New-LocalVsix([object]$Identity, [string]$OutputPath) {
	$requiredFiles = @("package.json", "extension.js", "cursorUsageProvider.js", "helper.ahk", "agent-helper.ahk")
	foreach ($fileName in $requiredFiles) {
		$path = Join-Path $ExtensionDir $fileName
		if (-not (Test-Path $path)) {
			throw "Required extension file is missing: $fileName"
		}
	}

	$utf8 = New-Object System.Text.UTF8Encoding $false
	$manifest = @"
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" xmlns:d="http://schemas.microsoft.com/developer/vsx-schema-design/2011">
	<Metadata>
		<Identity Language="en-US" Id="$($Identity.Name)" Version="$($Identity.Version)" Publisher="$($Identity.Publisher)" />
		<DisplayName>$($Identity.DisplayName)</DisplayName>
		<Description xml:space="preserve">$($Identity.Description)</Description>
		<Properties>
			<Property Id="Microsoft.VisualStudio.Code.Engine" Value="$($Identity.Engine)" />
		</Properties>
	</Metadata>
	<Installation>
		<InstallationTarget Id="Microsoft.VisualStudio.Code"/>
	</Installation>
	<Dependencies/>
	<Assets>
		<Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true" />
	</Assets>
</PackageManifest>
"@
	$contentTypes = @"
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
	<Default Extension=".json" ContentType="application/json" />
	<Default Extension=".vsixmanifest" ContentType="text/xml" />
	<Default Extension=".js" ContentType="application/javascript" />
	<Default Extension=".ahk" ContentType="text/plain" />
</Types>
"@

	if (Test-Path $OutputPath) {
		Remove-Item -LiteralPath $OutputPath -Force
	}

	Add-Type -AssemblyName System.IO.Compression
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	$archive = [System.IO.Compression.ZipFile]::Open($OutputPath, [System.IO.Compression.ZipArchiveMode]::Create)
	try {
		Add-ZipFileEntry -Archive $archive -EntryName "extension.vsixmanifest" -Bytes ($utf8.GetBytes($manifest))
		Add-ZipFileEntry -Archive $archive -EntryName "[Content_Types].xml" -Bytes ($utf8.GetBytes($contentTypes))
		foreach ($fileName in $requiredFiles) {
			$bytes = [System.IO.File]::ReadAllBytes((Join-Path $ExtensionDir $fileName))
			Add-ZipFileEntry -Archive $archive -EntryName ("extension/" + $fileName) -Bytes $bytes
		}
	}
	finally {
		$archive.Dispose()
	}
}

Write-Step "[MAG] GPT|Cursor|Sync setup"
Write-Step ("Repository: " + $RepoRoot)

$ahkPath = Find-AutoHotkey
if ($ahkPath) {
	Write-Step ("AutoHotkey v2: " + $ahkPath)
}
else {
	Write-Warning "AutoHotkey v2 was not found. Install it before running MAG-Workflow-Bridge.ahk."
}

$cursorCli = Find-CursorCli
if (-not $cursorCli) {
	throw "Cursor CLI was not found. Install Cursor and ensure 'cursor' is on PATH, then run setup.ps1 again."
}
Write-Step ("Cursor CLI: " + $cursorCli)

$identity = Get-ExtensionIdentity
$vsixName = "{0}.{1}-{2}.vsix" -f $identity.Publisher, $identity.Name, $identity.Version
$vsixPath = Join-Path $env:TEMP $vsixName
Write-Step ("Packaging " + $vsixName)
New-LocalVsix -Identity $identity -OutputPath $vsixPath
Write-Step ("VSIX: " + $vsixPath)

Write-Step ("Installing " + $ExtensionId)
& $cursorCli --install-extension $vsixPath --force
if ($LASTEXITCODE -ne 0) {
	throw "Cursor CLI failed to install the extension (exit $LASTEXITCODE)."
}

Write-Host ""
Write-Host ("Setup finished (v" + $identity.Version + ").")
Write-Host "Next:"
Write-Host "  1. Reload Cursor if it is already open."
Write-Host "  2. Run MAG-Workflow-Bridge.ahk"
Write-Host "  3. Optional: tray menu -> Enable startup"
Write-Host ""
Write-Host "Cursor -> ChatGPT: AGT -> GPT, Ctrl+Alt+Shift+G, or tray Send to ChatGPT"
Write-Host "ChatGPT -> Cursor: Copy, then companion TER or AGT"
Write-Host ("Uninstall extension: cursor --uninstall-extension " + $ExtensionId)
