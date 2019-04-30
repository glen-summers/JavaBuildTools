param ([string] $Target)
$ErrorActionPreference = "Stop"
$Temp="$PSScriptRoot\temp"
$Downloads = "$temp\downloads"
$DepDir='ExternalDependencies'

$WGetVer='1.20.3'
$WGetUrl="https://eternallybored.org/misc/wget/$WGetVer/64/wget.exe"
$WGet="$Downloads\wget.exe"

$NugetVer='v4.9.4'
$NugetUrl="https://dist.nuget.org/win-x86-commandline/$NugetVer/nuget.exe"
$Nuget="$Downloads\nuget.exe"

$SevenZipVer='18.1.0'
$SevenZip="$Downloads\7-Zip.CommandLine.$SevenZipVer\tools\x64\7za.exe"

$JdkVer='12.0.1'
$JdkFlavour='windows-x64'
$JdkZip="$Downloads\jdk-${JdkVer}_${JdkFlavour}.bin.zip"
$JdkUrl="https://download.oracle.com/otn-pub/java/jdk/${JdkVer}+12/69cfe15208a647278a19ef0990eea691/jdk-${JdkVer}_${JdkFlavour}_bin.zip"

function Main
{
	cls
	$JdkDir = Join-Path (Get-DirectoryAbove $PSScriptRoot $DepDir $Temp) jdk-$JdkVer

	Switch ($Target)
	{
		'clean'
		{
			Delete-Tree $Temp
		}

		'nuke'
		{
			Delete-Tree $JdkDir
		}

		'build'
		{
			Build
		}

		default
		{
			'Syntax: build|clean|nuke'
		}
	}
}

###########################################################################

function Build
{
	GetJdk
	$Env:Path="$JdkDir\bin;$Env:Path"
	javac HelloWorld.java
	java HelloWorld
}

###########################################################################

function GetJdk
{
	if (! (Test-Path $JdkDir))
	{
		md $Downloads -Force | Out-Null
		Download-File $NugetUrl $Nuget
		Download-Nuget $SevenZip $SevenZipVer

		Download-File $WGetUrl $WGet
		Download-File-WGet $JdkUrl $JdkZip 'oraclelicense=accept-securebackup-cookie'
		ExtractZip $JdkZip ${Temp}\jdk-$JdkVer
		move ${Temp}\jdk-$JdkVer\jdk-$JdkVer $JdkDir
		rm ${Temp}\jdk-$JdkVer
	}
}

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
	if ( -Not (Test-Path $OutDir))
	{
		Write-Host "Extracting $Archive -> $OutDir"
		(& cmd /c $SevenZip x $Archive -so `| $SevenZip x -aoa -si -ttar -o"$OutDir") 2>&1 | Out-Null
	}
}

function ExtractZip
{
	param ([string]$Archive, [string]$OutDir)
	if ( -Not (Test-Path $OutDir))
	{
		Write-Host "Extracting $Archive -> $OutDir"
		(& $SevenZip x -o"$OutDir" $Archive ) 2>&1 | Out-Null
	}
}

function Delete-Tree
{
	param ([string]$Dir)

	if (-not (Test-Path $Dir))
	{
		return
	}

	Write-Host "deleting $Dir..."
	$tries = 10
	while ((Test-Path $Dir) -and ($tries-ge 0)) 
	{
		Try 
		{
			rm -r -fo $Dir
			return
		}
		Catch 
		{
		}
		Start-Sleep -seconds 1
		--$tries
	}
	Write-Host "failed to delete"
}

###########################################################################

Main