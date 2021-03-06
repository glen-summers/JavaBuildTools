param ([string] $Target, [string] $TargetDir='', [string] $Package='')
$ErrorActionPreference = "Stop"

import-module $PSScriptRoot\boilerplate\utils.psm1

function Main
{
	cls

	Switch ($Target)
	{
		'build'
		{
			Build
		}

		'gradle'
		{
			BuildGradleApp $PSScriptRoot\gradleSource
		}

		'gen'
		{
			$GenDir = "$PSScriptRoot\gradleSource"
			Remove-Tree $GenDir
			GenerateGradleApp $GenDir 'com.crapola'
			BuildGradleApp $GenDir
		}

		'create'
		{
			if ((!$TargetDir) -or (!$Package))
			{
				"Syntax: create <RootDir> <PackageName>"
				return
			}

			if (Test-Path $TargetDir)
			{
				"Error: $TargetDir already exists"
				return;
			}

			$RootProjectDir = "$TargetDir\project"
			md $RootProjectDir -Force | Out-Null
			GenerateGradleApp $RootProjectDir $Package

			Get-ChildItem -Path $PSScriptRoot\boilerplate | Copy-Item -Destination $TargetDir -Recurse -Container -force

			pushd $TargetDir
			git init
			git add .
			git commit -m "Initial commit"
			popd

			BuildGradleApp $RootProjectDir

			#& $TargetDir\go.cmd test
			# git --git-dir=$TargetDir\.git --work-tree=$TargetDir status -s
		}

		'cmd'
		{
			Install-Jdk
			Install-Gradle
			$Env:Path="$JdkDir\bin;$GradleDir\bin;$Env:Path"
			cmd /k PROMPT [$`p] GO`$g
		}

		'jshell'
		{
			JShell
		}

		'clean'
		{
			# gradle clean?
			git clean -fdx
		}

		'nuke'
		{
			$Env:Path="$JdkDir\bin;$GradleDir\bin;$Env:Path"
			if (Test-Path $GradleDir\bin\gradle.bat)
			{
				Write-Host attempting to stopping gradle
				& cmd.exe /c $GradleDir\bin\gradle.bat --stop
			}
			else
			{
				try { taskkill /IM java.exe /f 2>&1}
				catch {}
			}

			Remove-Tree $GradleDir
			Remove-Tree $JdkDir
		}

		default
		{
			'Syntax: build|gradle|gen|cmd|jshell|clean|nuke|create
  build : compile basic java test project
  gradle: compile and run gradle test project
  gen   : generate prototype gradle app
  cmd   : open gradle command prompt
  jshell: run jshell
  clean : remove all temp files
  nuke  : remove jdk\gradle generated directories

  create <RootDir> <PackageName> 
    : create external prototype gradle app
'
		}
	}
}

###########################################################################

function Build
{
	Install-Jdk
	$Env:Path="$JdkDir\bin;$Env:Path"
	pushd javaSource
	javac HelloWorld.java
	java HelloWorld
	popd
}

function GenerateGradleApp
{
	param ([string] $GradleAppDir, $PackageName)

	Install-Jdk
	Install-Gradle

	$Env:Path="$JdkDir\bin;$GradleDir\bin;$Env:Path"
	#gradle --status
	#gradle --stop
	#gradle help --task :init

	# add parms
	$RootProjectName='RootProject'
	$AppName='app'
	$LibName='lib'

	md $GradleAppDir -Force | Out-Null
	pushd $GradleAppDir
	gradle init --type basic --dsl groovy --project-name $RootProjectName

	md $AppName -Force | Out-Null
	pushd $AppName
	gradle init --type java-application --dsl groovy --test-framework junit --project-name $AppName --package $PackageName
	Remove-Item gradle -r
	Remove-Item .gitignore
	Remove-Item gradlew
	Remove-Item gradlew.bat
	popd

	md $LibName -Force | Out-Null
	pushd $LibName
	gradle init --type java-library --dsl groovy --test-framework junit --project-name $LibName --package $PackageName
	Remove-Item gradle -r
	Remove-Item .gitignore
	Remove-Item gradlew
	Remove-Item gradlew.bat
	popd

	pushd "$PSScriptRoot\groovySource"
	gradle run --args="'$GradleAppDir'"
	popd

	#gradle --stop
}

function BuildGradleApp
{
	param ([string] $GradleAppDir)

	Install-Jdk
	Install-Gradle
	$Env:Path="$JdkDir\bin;$GradleDir\bin;$Env:Path"

	pushd $GradleAppDir
	.\gradlew cleanTest test
	popd
}

function JShell
{
	Install-Jdk
	$Env:Path="$JdkDir\bin;$Env:Path"
	JShell.exe
}

###########################################################################

Main