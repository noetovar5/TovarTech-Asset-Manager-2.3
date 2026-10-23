
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ============================================================
# TovarTech Asset Manager Web
# MSI Build Script - Version 2.3.0
# Requires .NET 10 SDK and WiX Toolset
# ============================================================

$root = $PSScriptRoot

$project = Join-Path $root 'TovarTech.AssetManager.Web\TovarTech.AssetManager.Web.csproj'
$publish = Join-Path $root 'publish'
$output = Join-Path $root 'output'

$version = '2.3.0'
$upgradeCode = '5e0d9f2b-6b5a-4e71-9d61-9c6a2d86d7ac'

$wxsPath = Join-Path $root 'installer.generated.wxs'
$msiPath = Join-Path $output 'TovarTech_Asset_Manager_Web_2.3.0_x64.msi'

# ============================================================
# Helper functions
# ============================================================

function XmlEscape([string]$value) {
    return [System.Security.SecurityElement]::Escape($value)
}

# Keep the same GUID algorithm as the original script.
# This avoids unnecessary changes to component identity.
function StableGuid([string]$value) {

    $bytes = [System.Text.Encoding]::UTF8.GetBytes(
        $value.ToLowerInvariant()
    )

    $md5 = [System.Security.Cryptography.MD5]::Create()

    try {
        $hash = $md5.ComputeHash($bytes)
    }
    finally {
        $md5.Dispose()
    }

    return New-Object Guid (,$hash)
}

# Generate stable WiX identifiers from relative paths.
function StableId([string]$prefix, [string]$value) {

    $bytes = [System.Text.Encoding]::UTF8.GetBytes(
        $value.ToLowerInvariant()
    )

    $sha = [System.Security.Cryptography.SHA256]::Create()

    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }

    $hex = [BitConverter]::ToString($hash).
        Replace('-', '').
        Substring(0, 24)

    return "$prefix$hex"
}

# ============================================================
# Verify required tools
# ============================================================

Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ' TovarTech Asset Manager - MSI Build' -ForegroundColor Cyan
Write-Host " Version $version" -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path $project)) {
    throw "Project file not found: $project"
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw 'The .NET SDK is not installed or is not in PATH.'
}

if (-not (Get-Command wix -ErrorAction SilentlyContinue)) {
    $env:PATH += ";$env:USERPROFILE\.dotnet\tools"
}

if (-not (Get-Command wix -ErrorAction SilentlyContinue)) {
    throw 'WiX Toolset was not found. Install WiX before continuing.'
}

# ============================================================
# Clean and publish the application
# ============================================================

Write-Host 'Preparing publish and output folders...' -ForegroundColor Yellow

if (Test-Path $publish) {
    Remove-Item -Path $publish -Recurse -Force
}

New-Item -ItemType Directory -Path $publish -Force | Out-Null
New-Item -ItemType Directory -Path $output -Force | Out-Null

Write-Host 'Publishing the ASP.NET Core application...' -ForegroundColor Yellow

& dotnet publish $project `
    -c Release `
    -r win-x64 `
    --self-contained false `
    -o $publish

if ($LASTEXITCODE -ne 0) {
    throw 'dotnet publish failed.'
}

$files = @(
    Get-ChildItem -Path $publish -File -Recurse |
        Sort-Object FullName
)

if ($files.Count -eq 0) {
    throw 'Publish folder is empty.'
}

Write-Host "Published files: $($files.Count)" -ForegroundColor Green

# ============================================================
# Generate the WiX directory and component definitions
# ============================================================

Write-Host 'Generating WiX directory structure...' -ForegroundColor Yellow

$directoryIds = @{}
$directoryIds[''] = 'INSTALLFOLDER'

$directoryDefinitions =
    New-Object 'System.Collections.Generic.List[string]'

$componentDefinitions =
    New-Object 'System.Collections.Generic.List[string]'

$componentReferences =
    New-Object 'System.Collections.Generic.List[string]'

foreach ($file in $files) {

    # Convert the absolute path to a relative publish path.
    $relative = $file.FullName.Substring($publish.Length + 1)

    # CRITICAL FIX:
    # Normalize Windows backslashes to forward slashes.
    # This preserves cs/, de/, wwwroot/css/, etc.
    $relative = $relative.Replace('\', '/')

    $segments = $relative.Split('/')

    $parentId = 'INSTALLFOLDER'
    $currentPath = ''

    # Create directory definitions for each subfolder.
    for ($i = 0; $i -lt ($segments.Length - 1); $i++) {

        $segment = $segments[$i]

        if ($currentPath -eq '') {
            $currentPath = $segment
        }
        else {
            $currentPath += '/' + $segment
        }

        if (-not $directoryIds.ContainsKey($currentPath)) {

            $directoryId = StableId 'DIR_' $currentPath

            $directoryIds[$currentPath] = $directoryId

            $safeDirectoryName = XmlEscape $segment

            $directoryDefinitions.Add(
                "<DirectoryRef Id=`"$parentId`">" +
                "<Directory Id=`"$directoryId`" Name=`"$safeDirectoryName`" />" +
                "</DirectoryRef>"
            )
        }

        $parentId = $directoryIds[$currentPath]
    }

    # Stable identifiers for each published file.
    $componentId = StableId 'CMP_' $relative
    $fileId = StableId 'FIL_' $relative

    # Preserve the original component GUID formula.
    $componentGuid = StableGuid (
        "TovarTechAssetManager2.3/" + $relative.Replace('/', '\')
    )

    $sourcePath = XmlEscape $file.FullName
    $fileName = XmlEscape $file.Name

    $componentDefinitions.Add(
        "<DirectoryRef Id=`"$parentId`">" +
        "<Component Id=`"$componentId`" Guid=`"$componentGuid`">" +
        "<File Id=`"$fileId`" Name=`"$fileName`" Source=`"$sourcePath`" KeyPath=`"yes`" />" +
        "</Component>" +
        "</DirectoryRef>"
    )

    $componentReferences.Add(
        "<ComponentRef Id=`"$componentId`" />"
    )
}

$directoryXml = $directoryDefinitions -join "`r`n"
$componentXml = $componentDefinitions -join "`r`n"
$referenceXml = $componentReferences -join "`r`n"

# ============================================================
# Create the complete WiX installer definition
# ============================================================

$wxs = @"
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">

  <Package
      Name="TovarTech Asset Manager Web"
      Manufacturer="TovarTech"
      Version="$version"
      UpgradeCode="$upgradeCode"
      Scope="perMachine">

    <MajorUpgrade
        DowngradeErrorMessage="A newer version is already installed." />

    <MediaTemplate EmbedCab="yes" />

    <StandardDirectory Id="ProgramFiles64Folder">
      <Directory
          Id="INSTALLFOLDER"
          Name="TovarTech Asset Manager Web" />
    </StandardDirectory>

$directoryXml

$componentXml

    <Feature
        Id="MainFeature"
        Title="TovarTech Asset Manager Web"
        Level="1">

$referenceXml

    </Feature>

  </Package>

</Wix>
"@

Set-Content -Path $wxsPath -Value $wxs -Encoding UTF8

Write-Host "Directory count: $($directoryIds.Count - 1)" -ForegroundColor Cyan
Write-Host "Component count: $($componentReferences.Count)" -ForegroundColor Cyan

# ============================================================
# Build the MSI
# ============================================================

Write-Host 'Building the Windows MSI installer...' -ForegroundColor Yellow

if (Test-Path $msiPath) {
    Remove-Item -Path $msiPath -Force
}

& wix build $wxsPath -arch x64 -out $msiPath

if ($LASTEXITCODE -ne 0) {
    throw 'WiX MSI build failed. Review the errors above.'
}

if (-not (Test-Path $msiPath)) {
    throw 'The MSI file was not created.'
}

# ============================================================
# Final build report
# ============================================================

Write-Host ''
Write-Host '=============================================' -ForegroundColor Green
Write-Host ' MSI BUILD COMPLETED SUCCESSFULLY' -ForegroundColor Green
Write-Host '=============================================' -ForegroundColor Green

Write-Host "MSI: $msiPath" -ForegroundColor Cyan

Get-Item $msiPath |
    Select-Object Name, Length, LastWriteTime |
    Format-Table -AutoSize

Write-Host ''
Write-Host 'IMPORTANT:' -ForegroundColor Yellow
Write-Host 'This MSI stages application files only.'
Write-Host 'IIS deployment requires a separate administrator step.'
Write-Host 'Your existing IIS website and SQL database have not been modified.'
