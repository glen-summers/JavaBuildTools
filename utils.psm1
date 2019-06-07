$ErrorActionPreference = "Stop"

$Temp="$PSScriptRoot\temp"
$Downloads = "$temp\downloads"
$DepDir='ExternalDependencies'

$WGetVer='1.20.3'
$WGetUrl="https://eternallybored.org/misc/wget/${WGetVer}/64/wget.exe"
$WGet="$Downloads\wget.exe"

$NugetVer='v4.9.4'
$NugetUrl="https://dist.nuget.org/win-x86-commandline/${NugetVer}/nuget.exe"
$Nuget="$Downloads\nuget.exe"

$SevenZipVer='18.1.0'
$SevenZip="$Downloads\7-Zip.CommandLine.${SevenZipVer}\tools\x64\7za.exe"

$JdkVer='12.0.1'
$JdkFlavour='windows-x64'
$JdkStem="jdk-${JdkVer}"
$JdkZip="$Downloads\${JdkStem}_${JdkFlavour}.bin.zip"
$JdkUrl="https://download.oracle.com/otn-pub/java/jdk/${JdkVer}+12/69cfe15208a647278a19ef0990eea691/${JdkStem}_${JdkFlavour}_bin.zip"

$GradleVer='5.4.1'
$GradleStem="gradle-${GradleVer}"
$GradleUrl="https://services.gradle.org/distributions/${GradleStem}-bin.zip"
$GradleZip="$Downloads\${GradleStem}-bin.zip"

function Install-Jdk
{
	if (! (Test-Path $JdkDir))
	{
		md $Downloads -Force | Out-Null
		Download-File $NugetUrl $Nuget
		Download-Nuget $SevenZip $SevenZipVer

		Download-File $WGetUrl $WGet
		Download-File-WGet $JdkUrl $JdkZip 'oraclelicense=accept-securebackup-cookie'
		ExtractZip $JdkZip $Temp\$JdkStem
		echo move $Temp\$JdkStem\$JdkStem $JdkDir
		move $Temp\$JdkStem\$JdkStem $JdkDir
		rm $Temp\$JdkStem
	}
	echo "Jdk   : $JdkDir"
}

function Install-Gradle
{
	if (! (Test-Path $GradleDir))
	{
		md $Downloads -Force | Out-Null
		Download-File $NugetUrl $Nuget
		Download-Nuget $SevenZip $SevenZipVer

		Download-File $WGetUrl $WGet
		Download-File-WGet $GradleUrl $GradleZip

		ExtractZip $GradleZip $Temp\$GradleStem
		echo move $Temp\$GradleStem\$GradleStem $GradleDir
		move $Temp\$GradleStem\$GradleStem $GradleDir
		rm $Temp\$GradleStem
	}
	echo "Gradle: $GradleDir"
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

function Remove-Tree
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
	Write-Host "failed to remove"
}

$Above = Get-DirectoryAbove $PSScriptRoot $DepDir $Temp
$JdkDir = Join-Path $Above $JdkStem
$GradleDir = Join-Path $Above $GradleStem

Export-ModuleMember -Variable Temp
Export-ModuleMember -Variable JdkDir
Export-ModuleMember -Variable GradleDir

Export-ModuleMember -Function Remove-Tree
Export-ModuleMember -Function Install-Jdk
Export-ModuleMember -Function Install-Gradle