## Synopsis
Command line tools (currently windows only) to automate downloading dependencies and compiling java\gradle projects

## Motivation
Having struggled to create a composite gradle application with IDE tools I wanted to capture the requirements in a script. I also wanted to automate the downloading of run-time dependencies and store them in a location above the source tree to be shared with multiple projects and require no admin privileges for installation

## Prerequisites
Windows powershell

## Build 
using **go.cmd** in project root:
```
> go
Syntax: build|gradle|gen|cmd|jshell|clean|nuke|create
  build : compile basic java test project
  gradle: compile and run gradle test project
  gen   : generate prototype gradle app
  cmd   : open gradle command prompt
  jshell: run jshell
  clean : remove all temp files
  nuke  : remove jdk\gradle generated directories
  
  create <RootDir> <PackageName>
    : create external prototype gradle app
```
### > go build
Verifies a checked in simple java HelloWorld app compiles and runs ok
```
>Hello, World
```
### > go gradle
Verifies a checked in composite gradle app\lib project compiles and runs ok
```
> Task :app:test
com.crapola.AppTest > testAppHasAGreeting PASSED
> Task :lib:test
com.crapola.LibraryTest > testSomeLibraryMethod PASSED
```
### > go gen
Regenerates and runs the checked in composite gradle project

### > go cmd
Opens a shell with JDK and gradle on the path for diagnostics

### > go jshell
Opens a [JShell]([https://docs.oracle.com/javase/9/jshell/introduction-jshell.htm#JSHEL-GUID-630F27C8-1195-4989-9F6B-2C51D46F52C8](https://docs.oracle.com/javase/9/jshell/introduction-jshell.htm#JSHEL-GUID-630F27C8-1195-4989-9F6B-2C51D46F52C8))
```
|  Welcome to JShell -- Version 12.0.1
|  For an introduction type: /help intro
jshell>
```
### > go create <RootDir> <PackageName>
e.g. 
```
go create C:\Users\RobbieTheRobot\source\repos\ForbiddenPlanet Com.Monster.From.The.Id
```
Creates a composite gradle project, with root : [app,lib] using the gradle init plugin, then runs 'gradle test' to verify the build...
```
> Task :app:test
Com.Monster.From.The.Id.AppTest > testAppHasAGreeting PASSED
> Task :lib:test
Com.Monster.From.The.Id.LibraryTest > testSomeLibraryMethod PASSED

BUILD SUCCESSFUL in 5s
9 actionable tasks: 7 executed, 2 up-to-date
```
Finally it creates a local git repo and adds all the generated files to it, including git attributes\ignore files, Intellij formatting rules and a *go.cmd* root bootstrap file.

The created project can now be run independently via:
```
> cd C:\Users\RobbieTheRobot\source\repos\ForbiddenPlanet
> go.cmd cleanTest test

> Task :app:test
Com.Monster.From.The.Id.AppTest > testAppHasAGreeting PASSED
> Task :lib:test
Com.Monster.From.The.Id.LibraryTest > testSomeLibraryMethod PASSED

BUILD SUCCESSFUL in 3s
9 actionable tasks: 4 executed, 5 up-to-date
```