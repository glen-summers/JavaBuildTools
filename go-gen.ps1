$ErrorActionPreference = "Stop"

import-module $PSScriptRoot\utils.psm1 #-verbose

function Main
{
	param ([string[]] $parms)
	cls
	Install-Jdk
	Install-Gradle
	$Env:Path="$JdkDir\bin;$GradleDir\bin;$Env:Path"
	& $PSScriptRoot\gradlew.bat $parms
}

Main $args
