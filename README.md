# TovarTech Asset Manager Web — Version 2.3.0

GitHub-ready **source and build kit** for the ASP.NET Core Razor Pages asset management app. This package includes the application source from the provided 2.3 source archive, with package references updated to the versions validated by the user's latest NuGet audit: **Microsoft.Data.SqlClient 7.1.1** and **System.Security.Cryptography.Pkcs 10.0.13**. It includes the corrected MSI generator. **The MSI binary is not included; build it on Windows.** This kit has not been compiled or installer-tested in the package creation environment. The user's local 2.3 MSI build succeeded; validate this reconstructed package on your own machine before release.

## 1. Software required on a NEW Windows build computer

- Windows 11 or supported Windows Server, x64; PowerShell 5.1 or later.
- **.NET 10 SDK (x64)** (not merely the runtime): https://dotnet.microsoft.com/download/dotnet/10.0
- **WiX Toolset CLI** via .NET global tool: `dotnet tool install --global wix` (if already installed: `dotnet tool update --global wix`). This project uses WiX v4+ schema and has been built with WiX 7. `wix --version` verifies installation.
- Internet access to NuGet for the initial restore; the NuGet source must be enabled.
- Git for Windows: https://git-scm.com/download/win
- Optional: Visual Studio Code with C# extension, or Visual Studio with ASP.NET/web workload.
- Optional for testing/deployment: IIS with ASP.NET Core Hosting Bundle and SQL Server; these are **not needed to compile the MSI**.

In PowerShell:

```powershell
winget install Microsoft.DotNet.SDK.10
winget install Git.Git
# Open a NEW PowerShell window after installation
 dotnet --info
 dotnet tool install --global wix
 wix --version
 git --version
```

If `wix` is not recognized, restart PowerShell and check `$env:USERPROFILE\.dotnet\tools` is in PATH. Install tools only from trusted sources.

## 2. Get source and configure your database

Clone the repository, or extract the ZIP. **Do not commit passwords, production hostnames, or real asset records.** `TovarTech.AssetManager.Web/appsettings.json` contains a placeholder SQL Server address and uses Windows integrated authentication. Replace the placeholder on the **deployment server** with the appropriate server/instance and certificate configuration. Do not assume `TrustServerCertificate=False` works without a valid SQL Server certificate. For production use a trusted TLS certificate and appropriate authentication/permissions. For a public demo, use a test database containing synthetic records only.

```powershell
cd C:\path\to\TovarTech_Asset_Manager_2_3_GitHub_Release_Kit
notepad .\TovarTech.AssetManager.Web\appsettings.json
```

`AllowedHosts` is `*` as a portable template; restrict it to expected hostnames before production exposure.

## 3. Restore, audit, build, and create MSI

```powershell
dotnet --version
wix --version
dotnet restore .\TovarTech.AssetManager.Web\TovarTech.AssetManager.Web.csproj
dotnet list .\TovarTech.AssetManager.Web\TovarTech.AssetManager.Web.csproj package --vulnerable --include-transitive
dotnet build .\TovarTech.AssetManager.Web\TovarTech.AssetManager.Web.csproj -c Release
powershell -ExecutionPolicy Bypass -File .\Build-MSI.ps1
Get-Item .\output\TovarTech_Asset_Manager_Web_2.3.0_x64.msi
```

Expect `MSI built: ...\output\TovarTech_Asset_Manager_Web_2.3.0_x64.msi`. Review any NuGet or WiX warnings; do not suppress security warnings. The script removes/recreates only its local `publish` directory and replaces the MSI in `output`; it does **not** modify IIS or SQL Server.

### What the build script does

1. Publishes the web project in Release mode for `win-x64`, framework-dependent.
2. Enumerates the published files and their subdirectories.
3. Creates unique WiX Directory references for language satellite assemblies and `wwwroot` files.
4. Creates file components with stable IDs and GUIDs.
5. Builds a per-machine MSI under `output/` using the existing UpgradeCode `5e0d9f2b-6b5a-4e71-9d61-9c6a2d86d7ac`.

**Important:** This kit's MSI is a **file-staging installer**, not an automated IIS/SQL setup. Its default install directory is under Program Files (`TovarTech Asset Manager Web`). It does not create an IIS site, configure a SQL login, create the database, or install the ASP.NET Core runtime. Do not use it as a drop-in upgrade of an existing IIS website. Do not assume the MSI is code-signed.

## 4. Deploy on another Windows Server — safe procedure

Prerequisites on the TARGET server (different from build prerequisites):

- Supported Windows Server x64, IIS with appropriate web features, and the **.NET 10 ASP.NET Core Hosting Bundle** matching the app's architecture: https://dotnet.microsoft.com/download/dotnet/10.0 (install or repair the Hosting Bundle after enabling IIS; restart IIS services as required).
- SQL Server/SQL Server Express reachable from the web server, with the `TovarTechAssets` database and `dbo.Assets` table schema compatible with the application. **This package does not include a verified production database migration script.** Create/restore the schema from your tested SQL deployment scripts and validate it in a lab first.
- Dedicated IIS application pool using **No Managed Code** (ASP.NET Core runs out of process or in-process under the Hosting Bundle), an appropriate identity with least-privilege SQL access, and a configured binding/port and firewall policy.

Safe deployment checklist:

1. Take a **tested SQL backup** and backup the existing IIS site files/configuration. Confirm rollback steps before changing production.
2. On a lab server, install the MSI as an administrator. Example (elevated PowerShell):

   ```powershell
   msiexec.exe /i .\output\TovarTech_Asset_Manager_Web_2.3.0_x64.msi /L*v .\msi-install.log
   ```

3. Verify files exist under `C:\Program Files\TovarTech Asset Manager Web\`, including `web.config`, `wwwroot\css\site.css`, and `wwwroot\images\tovartech-logo.png`.
4. Copy/stage those files to a **separate new IIS site folder** (e.g. `C:\inetpub\TovarTechAssetManager-Lab`), preserving directories. **Do not overwrite the working site until testing passes.**
5. Configure the destination's connection string securely, configure IIS pool and binding, grant filesystem read/execute permissions, and grant the IIS identity the necessary SQL permissions. Do not grant `sysadmin` or `db_owner` merely to make the app work.
6. Browse the lab site and verify the dashboard, asset list, create/edit/delete operations using **test data**, static assets, and application logs.
7. Only then schedule a production cutover with rollback. Database backups and IIS configuration backups are separate from the MSI.

For a clean lab site, IIS Manager can create an Application Pool named `TovarTechAssetManager-Lab` with `.NET CLR Version: No Managed Code`; create a new Website with a free port and physical path to the staged files, assign that pool, and test locally. Port `8080` may already be used on your existing host, so choose an unused port. Do not assume SQL Integrated Security will work under `ApplicationPoolIdentity` on a remote SQL host without explicit domain authentication configuration.

## 5. GitHub — source vs release assets

From the project root:

```powershell
git init
git add .
git status
git commit -m "TovarTech Asset Manager Web v2.3.0 source and MSI builder"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
git push -u origin main
```

Create an **empty repository** on GitHub first and replace the example URL. Authentication may require a browser sign-in or Git credential manager. The `.gitignore` excludes generated MSI, `publish`, `output`, and local settings. If you want to distribute the compiled MSI, attach the validated MSI as a **GitHub Release asset**, not to source control. Verify Defender and the MSI hash, and consider Authenticode signing with your own trusted code-signing certificate for public distribution.

```powershell
Get-FileHash .\output\TovarTech_Asset_Manager_Web_2.3.0_x64.msi -Algorithm SHA256
Get-AuthenticodeSignature .\output\TovarTech_Asset_Manager_Web_2.3.0_x64.msi
```

A missing signature is not proof of malware; public distribution benefits from signing and reproducible release practices. Never disable antivirus to install this package.

## 6. Suggested YouTube walkthrough

- 00:00 — Overview and source structure
- 02:00 — Install .NET 10 SDK, Git, and WiX CLI
- 05:00 — Restore and NuGet security audit
- 07:00 — Compile and publish the ASP.NET Core app
- 10:00 — Explain WiX directories and component IDs
- 13:00 — Build and inspect the MSI
- 16:00 — Install IIS Hosting Bundle on a lab server
- 19:00 — Stage the MSI files and configure a separate IIS lab site
- 24:00 — Configure SQL connection and verify sample assets
- 28:00 — Validate logs, rollback, and GitHub release

Adjust chapter timestamps after recording; these are planning estimates, not timestamps from a finished video.

## 7. Troubleshooting

- `dotnet not recognized`: install .NET **SDK**, reopen terminal, run `dotnet --info`.
- `wix not recognized`: install/update WiX global tool, reopen PowerShell, inspect PATH.
- `NU1902`/`NU1903`: audit NuGet dependencies and upgrade to a verified patched version; never suppress the audit to pass a build.
- `WIX1070`/`WIX1071`: verify the generated WiX directories preserve resource-language and `wwwroot` subfolders.
- `HTTP 500.30`: inspect Windows Event Viewer / ASP.NET Core Module logs, installed hosting bundle, and app startup configuration.
- SQL login failures: verify SQL endpoint, authentication mode, IIS pool identity, database permissions, firewall and certificate trust.
- Missing CSS/images: ensure `wwwroot` subfolders are preserved in the deployed directory.

## 8. Provenance and limitations

The included source is based on the **2.3 source-only ZIP** available in this conversation, not a live export of the user's current Windows project folder. Its package references were updated to match the versions the user confirmed (`7.1.1` and `10.0.13`), and the successful directory-preserving build script was reconstructed from the conversation. If any other edits were made locally after that ZIP was created, copy/merge them before publishing to GitHub. No real database, SQL backup, server-specific secrets, compiled MSI, or verified IIS deployment script is included.
