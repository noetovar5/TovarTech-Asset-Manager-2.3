# TovarTech-Asset-Manager-2.3
TovarTech Asset Manager 2.3 GitHub Release Kit


I'll prepare a TovarTech Asset Manager 2.3 GitHub Release Kit that you can download, keep as your master source package, and use for future deployments and YouTube training demonstrations.

The package will include the application source, the corrected MSI build script, GitHub-ready files, and a step-by-step README covering the software required on a new Windows computer, building the installer, and deploying to another Windows Server.

One important distinction for your training videos: building the MSI and deploying the ASP.NET Core application to IIS are separate operations. The MSI stages the application files; the IIS website, SQL Server connection, and database still require configuration.

## Your GitHub release package is ready

TovarTech Asset Manager 2.3 — GitHub Release Kit

ZIP archive · 22 files · Approximately 92 KB

&#x20;Download the complete release kit

The package contains the available Version 2.3 application source, corrected `Build-MSI.ps1`, updated package references for SQL Client 7.1.1 and PKCS 10.0.13, `.gitignore`, and two guides.

You can also download the instructions separately:

&#x20;Step-by-step README

&#x20;Release checklist

## What you'll need on a future build computer

| Software                        | Purpose                                    |
| ------------------------------- | ------------------------------------------ |
| .NET 10 SDK (x64)               | Compile and publish the application        |
| WiX Toolset CLI                 | Generate the Windows MSI                   |
| Git for Windows                 | Manage and upload source to GitHub         |
| Visual Studio Code              | Edit and maintain the project (optional)   |
| IIS + .NET 10 Hosting Bundle    | Run the application on a target web server |
| SQL Server / SQL Server Express | Store application data                     |

The README includes installation links, PowerShell commands, security checks, deployment guidance, and a suggested YouTube tutorial outline.

Important: The downloadable ZIP contains source and build instructions, not a precompiled MSI or database. It was assembled from your previously provided Version 2.3 source package and the corrections we made together. Your latest working Windows project may contain additional local changes, so compare the two before treating this as your final GitHub master. I verified the ZIP archive's integrity, but I haven't compiled this reconstructed package on Windows.

### Recommended GitHub structure

TovarTech-Asset-Manager/ ├── TovarTech.AssetManager.Web/ │   ├── Pages/ │   ├── wwwroot/ │   ├── Asset.cs │   ├── AssetRepository.cs │   ├── Program.cs │   └── TovarTech.AssetManager.Web.csproj ├── Build-MSI.ps1 ├── README.md ├── RELEASE-CHECKLIST.md └── .gitignore

My recommendation is to keep the source code in your GitHub repository and publish each tested MSI as a downloadable GitHub Release. That gives viewers two options: learn how to compile the application themselves, or download a tested installer.

For your first public release, I recommend creating a separate lab deployment video demonstrating installation on Windows Server with IIS and SQL Server Express, using sample asset data rather than your production database.
