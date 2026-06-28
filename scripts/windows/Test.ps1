param(
	[string]$Configuration = "Debug",
	[string]$Platform = "x64",
	[string]$Filter = "",
	[switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

function Find-VsWhere {
	$path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
	if (Test-Path $path) {
		return $path
	}
	throw "vswhere.exe was not found. Run .\scripts\windows\Install-BuildTools.ps1 first."
}

function Find-VisualStudioTool($Pattern, $Requires) {
	$vswhere = Find-VsWhere
	$tool = & $vswhere -latest -products * -requires $Requires -find $Pattern | Select-Object -First 1
	if (-not $tool) {
		$tool = & $vswhere -latest -products * -find $Pattern | Select-Object -First 1
	}
	if (-not $tool -or -not (Test-Path $tool)) {
		throw "$Pattern was not found. Run .\scripts\windows\Install-BuildTools.ps1 first."
	}
	return $tool
}

function Invoke-Step($Description, $ScriptBlock) {
	Write-Host ""
	Write-Host "==> $Description"
	& $ScriptBlock
}

function Invoke-Native($FilePath, [string[]]$Arguments) {
	& $FilePath @Arguments
	if ($LASTEXITCODE -ne 0) {
		throw "$FilePath exited with code $LASTEXITCODE."
	}
}

function Ensure-DotNetOnPath {
	$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
	if ($dotnet) {
		return
	}

	$defaultDotNet = Join-Path $env:ProgramFiles "dotnet\dotnet.exe"
	if (Test-Path $defaultDotNet) {
		$dotnetRoot = Split-Path $defaultDotNet
		$env:DOTNET_ROOT = $dotnetRoot
		$env:PATH = "$dotnetRoot;$env:PATH"
		return
	}

	throw "dotnet.exe was not found. Run .\scripts\windows\Install-BuildTools.ps1 first, then open a new PowerShell session."
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
if ($repoRoot.ProviderPath.StartsWith("\\")) {
	Write-Warning "The repository is on a UNC path ($repoRoot). If MSBuild or native tools fail, clone the repo under a Windows path such as C:\src\dmd-extensions and rerun this script there."
}
Set-Location $repoRoot

Ensure-DotNetOnPath

$msbuild = Find-VisualStudioTool "MSBuild\**\Bin\MSBuild.exe" "Microsoft.Component.MSBuild"
$vstest = Find-VisualStudioTool "Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe" "Microsoft.VisualStudio.Component.VSTest"

if (-not $SkipBuild) {
	Invoke-Step "Restore LibDmd.Test NuGet packages" {
		Invoke-Native $msbuild @("LibDmd.Test\LibDmd.Test.csproj", "/t:Restore", "/p:Configuration=$Configuration", "/p:Platform=$Platform", "/m")
	}

	Invoke-Step "Build LibDmd.Test" {
		Invoke-Native $msbuild @("LibDmd.Test\LibDmd.Test.csproj", "/p:Configuration=$Configuration", "/p:Platform=$Platform", "/m")
	}
}

$testDll = Join-Path $repoRoot "LibDmd.Test\bin\$Platform\$Configuration\net472\LibDmd.Test.dll"
if (-not (Test-Path $testDll)) {
	$testDll = Join-Path $repoRoot "LibDmd.Test\bin\$Configuration\net472\LibDmd.Test.dll"
}
if (-not (Test-Path $testDll)) {
	throw "Test assembly not found. Build likely failed or output path changed."
}

$vstestArgs = @($testDll)
if ($Filter) {
	$vstestArgs += "/TestCaseFilter:$Filter"
}

Invoke-Step "Run tests" {
	Invoke-Native $vstest $vstestArgs
}
