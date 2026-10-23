TovarTech Asset Manager v2.3 source and MSI generator only.
This archive contains no compiled executables, MSI, or IIS deployment scripts.
Review Build-MSI.ps1 before running. It uses dotnet publish and wix build; if wix is absent it installs the official wix .NET tool.
Run from PowerShell: powershell -ExecutionPolicy Bypass -File .\Build-MSI.ps1
Security note: NuGet may report vulnerabilities in transitive dependencies; resolve these before distribution.
Do not install over a live IIS deployment without backup and testing.
No guarantee can be made about antivirus classification.
