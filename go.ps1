param ([string] $Target)
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

function Main
{
	cls
	$Above = Get-DirectoryAbove $PSScriptRoot $DepDir $Temp
	$JdkDir = Join-Path $Above $JdkStem
	$GradleDir = Join-Path $Above $GradleStem

	Switch ($Target)
	{
		'build'
		{
			Build
		}

		'gradle'
		{
			BuildGradleApp
		}

		'gen'
		{
			GenerateGradleApp
		}

		'cmd'
		{
			GetJdk
			GetGradle
			$Env:Path="$JdkDir\bin;$GradleDir\bin;$Env:Path"
			cmd /k PROMPT [$`p] GO`$g
		}

		'jshell'
		{
			JShell
		}

		'clean'
		{
			Delete-Tree $Temp
			git clean -fdx
		}

		'nuke'
		{
			Delete-Tree $JdkDir
			Delete-Tree $GradleDir
		}

		default
		{
			'Syntax: build|gradle|gen|cmd|jshell|clean|nuke
  build : compile basic java test project
  gradle: compile and run gradle test project
  gen   : generate prototype gradle app
  cmd   : oprn gradle command prompt				
  jshell: run jshell
  clean : remove all temp files
  nuke  : remove jdk\gradle generated directories
'
		}
	}
}

###########################################################################

function Build
{
	GetJdk
	$Env:Path="$JdkDir\bin;$Env:Path"
	pushd javaSource
	javac HelloWorld.java
	java HelloWorld
	popd
}

function GenerateGradleApp
{
	GetJdk
	GetGradle

	$Env:Path="$JdkDir\bin;$GradleDir\bin;$Env:Path"
	gradle.bat --stop
	#gradle.bat help --task :init

	$GradleAppDir="$PSScriptRoot\gradleSource"
	Delete-Tree $GradleAppDir

	md $GradleAppDir -Force | Out-Null
	pushd $GradleAppDir
	gradle.bat init --type basic --dsl groovy --project-name root
	popd

	md $GradleAppDir\app -Force | Out-Null
	pushd $GradleAppDir\app
	gradle.bat init --type java-application --dsl groovy --test-framework junit --project-name Project1 --package Project1
	popd

	md $GradleAppDir\lib -Force | Out-Null
	pushd $GradleAppDir\lib
	gradle.bat init --type java-library --dsl groovy --test-framework junit --project-name Library1 --package Library1
	popd

	pushd "$PSScriptRoot\groovySource"
	gradle.bat run
	popd

	#.\gradlew.bat run
	gradle.bat --stop
}

function BuildGradleApp
{
	GetJdk
	GetGradle
	$Env:Path="$JdkDir\bin;$GradleDir\bin;$Env:Path"
	$GradleAppDir="$PSScriptRoot\gradleSource"
	pushd $GradleAppDir
	.\gradlew.bat run
	popd
}

function JShell
{
	GetJdk
	$Env:Path="$JdkDir\bin;$Env:Path"
	JShell.exe
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
		ExtractZip $JdkZip $Temp\$JdkStem
		move $Temp\$JdkStem\$JdkStem $JdkDir
		rm $Temp\$JdkStem
	}
	echo "Jdk   : $JdkDir"
}

function GetGradle
{
	if (! (Test-Path $GradleDir))
	{
		md $Downloads -Force | Out-Null
		Download-File $NugetUrl $Nuget
		Download-Nuget $SevenZip $SevenZipVer

		Download-File $WGetUrl $WGet
		Download-File-WGet $GradleUrl $GradleZip

		ExtractZip $GradleZip $Temp\$GradleStem
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