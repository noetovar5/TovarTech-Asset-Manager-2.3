# Release checklist — 2.3.0

- [ ] Compare packaged source to latest local working copy (including csproj and Build-MSI.ps1).
- [ ] Confirm appsettings.json contains no real server names, passwords, or production data.
- [ ] Install .NET 10 SDK and WiX CLI on a clean Windows build machine.
- [ ] Restore and run NuGet vulnerability audit; address any advisories.
- [ ] Build app and MSI without errors or WiX collision warnings.
- [ ] Install MSI on a disposable lab VM; confirm nested resource/wwwroot files.
- [ ] Install ASP.NET Core Hosting Bundle on test IIS server.
- [ ] Connect to disposable SQL test database; verify CRUD and static assets.
- [ ] Back up database and existing IIS website before any production cutover.
- [ ] Check Microsoft Defender and generate SHA256 hash.
- [ ] Consider signing MSI for public distribution.
- [ ] Push source to GitHub and upload tested MSI to GitHub Releases.
