param(
	[switch]$WhatIf
)

$ErrorActionPreference = "Stop"

function Invoke-Step($Description, $ScriptBlock) {
	Write-Host ""
	Write-Host "==> $Description"
	& $ScriptBlock
}

if (-not $IsWindows -and $PSVersionTable.PSEdition -eq "Core") {
	throw "Run this script from Windows PowerShell, not from WSL/Linux PowerShell."
}

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
	throw "winget is required. Install App Installer from the Microsoft Store, then rerun this script."
}

$vsArgs = @(
	"install",
	"--id", "Microsoft.VisualStudio.2022.BuildTools",
	"--exact",
	"--source", "winget",
	"--accept-package-agreements",
	"--accept-source-agreements",
	"--override", "--wait --quiet --norestart --add Microsoft.VisualStudio.Workload.MSBuildTools --add Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --add Microsoft.VisualStudio.Component.NuGet.BuildTools --add Microsoft.VisualStudio.Component.VSTest --add Microsoft.Net.Component.4.7.2.TargetingPack --add Microsoft.Net.Component.4.7.2.SDK --includeRecommended"
)

$sdkArgs = @(
	"install",
	"--id", "Microsoft.DotNet.SDK.8",
	"--exact",
	"--source", "winget",
	"--accept-package-agreements",
	"--accept-source-agreements"
)

Invoke-Step "Install Visual Studio 2022 Build Tools for .NET Framework 4.7.2 and native components" {
	if ($WhatIf) {
		Write-Host "winget $($vsArgs -join ' ')"
	} else {
		& $winget.Source @vsArgs
	}
}

Invoke-Step "Install .NET SDK for SDK-style test project restore/build support" {
	if ($WhatIf) {
		Write-Host "winget $($sdkArgs -join ' ')"
	} else {
		& $winget.Source @sdkArgs
	}
}

Write-Host ""
Write-Host "Done. Open a new Windows PowerShell session, then run:"
Write-Host "  .\scripts\windows\Test.ps1"
