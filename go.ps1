$ErrorActionPreference = "Stop"
$Temp="$PSScriptRoot\temp"
$Downloads = "$temp\downloads"

$WGetVer='1.20.3'
$WGetUrl="https://eternallybored.org/misc/wget/$WGetVer/64/wget.exe"
$WGet="$Downloads\wget.exe"

$NugetVer='v4.9.4'
$NugetUrl="https://dist.nuget.org/win-x86-commandline/$NugetVer/nuget.exe"
$SevenZipVer='18.1.0'

$Nuget="$Downloads\nuget.exe"
$SevenZip="$Downloads\7-Zip.CommandLine.$SevenZipVer\tools\x64\7za.exe"

$JdkVer='jdk-12.0.1'
$JdkFlavour='windows-x64'
$Jdk="$Downloads\${JdkVer}_${JdkFlavour}.bin.zip"
$JdkUrl="https://download.oracle.com/otn-pub/java/jdk/12.0.1+12/69cfe15208a647278a19ef0990eea691/${JdkVer}_${JdkFlavour}_bin.zip"
$JdkDir="$Downloads\$JdkVer"

function Main
{
	cls

	if (! (Test-Path $JdkDir))
	{
		md $Downloads -Force | Out-Null
		Download-File $NugetUrl $Nuget
		Download-Nuget $SevenZip $SevenZipVer

		Download-File $WGetUrl $WGet
		Download-File-WGet $JdkUrl $Jdk 'oraclelicense=accept-securebackup-cookie'
		ExtractZip $Jdk ${JdkDir}_
		move ${JdkDir}_\$JdkVer $JdkDir
		rm ${JdkDir}_
	}

	$Env:Path="$JdkDir\bin;$Env:Path"
	javac HelloWorld.java
	java HelloWorld
}

###########################################################################

function Get-DirectoryAbove
{
	param ([string] $Start, [string] $Signature, [string] $Fallback)

	for ($dir = $Start; $dir; $dir = Split-Path -Path $dir -Parent)
	{
		$combined = Join-Path $dir $Signature
		if (Test-Path $combined)
		{
			$combined
			return
		}
	}
	$Fallback
}

function Download-File
{
	[CmdletBinding()]
	param ([string]$Url, [string]$Target)

	if ( -Not (Test-Path $Target ))
	{
		Write-Host "downloading $Url -> $Target"
		(New-Object System.Net.WebClient).DownloadFile($Url, $Target)
		if ( -Not (Test-Path $Target ))
		{
			throw 'Download failed'
		}
	}
}

function Download-File-WGet
{
	[CmdletBinding()]
	param ([string]$Url, [string]$Target, [string]$Cookie)

	if ( -Not (Test-Path $Target ))
	{
		Write-Host "downloading $Url -> $Target"
		& $WGet --no-check-certificate -c -c --header "Cookie: $Cookie" $Url -O $Target
	}
}

function Download-Nuget
{
	param ([string]$Name, [string]$Version)
	if ( -Not (Test-Path $Name))
	{
		Write-Host "downloading nuget $Name"
		& $Nuget install 7-Zip.CommandLine -version "$Version" -OutputDirectory "$Downloads" -PackageSaveMode nuspec
	}
}

function ExtractTarGz
{
	param ([string]$Archive, [string]$OutDir)
	Write-Host "Extracting $Archive -> $OutDir"
	(& cmd /c $SevenZip x $Archive -so `| $SevenZip x -aoa -si -ttar -o"$OutDir") 2>&1 | Out-Null
}

function ExtractZip
{
	param ([string]$Archive, [string]$OutDir)
	Write-Host "Extracting $Archive -> $OutDir"
	(& $SevenZip x -o"$OutDir" $Archive ) 2>&1 | Out-Null
}

###########################################################################

Main