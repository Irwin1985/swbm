load "globals.ring"
load "stdlib.ring"
load "consolecolors.ring"

#
# prints the commands information in the screen
#
func printHelp
	?cc_print(CC_FG_GRAY, copy("=", 75))
	?cc_print(CC_FG_GRAY, "Swift Builder Manager (sbm) v" + _VERSION)
	?cc_print(CC_FG_GRAY, "2023, Irwin Rodriguez <rodriguez.irwin@gmail.com>")
	?cc_print(CC_FG_GRAY, copy("=", 75))
	?cc_print(CC_FG_GRAY, "Usage    : swbm [command]")
	cc_print(CC_FG_GRAY, "Command  : ")
	?cc_print(CC_FG_DARK_YELLOW, "new <project name>")
	cc_print(CC_FG_GRAY, "Command  : ")
	?cc_print(CC_FG_DARK_YELLOW, "run <project name>")
	cc_print(CC_FG_GRAY, "Command  : ")
	?cc_print(CC_FG_DARK_YELLOW, "build <project name>")
	?cc_print(CC_FG_GRAY, copy("=", 75))
	

#
# Evaluates the entered commands
#
func runCommands
	aCommands = getCommands()
	nLen = len(aCommands)

	if nLen = 0 # no commands passed
		printHelp()
		return
	ok
	
	cCommand  = aCommands[1]
	cProjectName = ""
	
	# get the project name
	if len(aCommands) > 1
		cProjectName = aCommands[2]
	ok

	# get the arguments	
	aArgs = []
	if len(aCommands) > 2
		for i=3 to len(aCommands)
			add(aArgs, aCommands[i])
		next
	ok

	switch cCommand
	on "new"
		validateCommand(len(aArgs))
		createProject(cProjectName)
	on "run"		
		# validateCommand(len(aArgs))
		runProject(cProjectName, aArgs)
	on "build"
		# validateCommand(len(aArgs))
		buildProject(cProjectName)
	on "version"
		?cc_print(CC_FG_YELLOW, "Swift Builder Manager (sbm) v" + _VERSION)
	else
		cc_print(CC_FG_RED, "Unknown command ")
		?cc_print(CC_FG_DARK_YELLOW, cCommand)
		return
	off

#
# Validate 2 arguments
#
func validateCommand tnLen
	if tnLen > 0
		?cc_print(CC_FG_RED, "Unexpected arguments...")
		printHelp()
		bye
	ok

#
# create a project
#
func createProject tcProjectName
	cCurDir = currentDir()
	OSCreateOpenFolder(tcProjectName)
	createSwiftFile()	
	createBuildFile(tcProjectName)
	chDir(cCurDir)
	printOperationCompleted()	

#
# run an existing project
#
func runProject tcProjectName, taArgs
	if len(tcProjectName) = 0
		tcProjectName = getProjectName()
	ok

	# are we going to build a single swift file?
	if right(tcProjectName, 6) = ".swift"
		# Build and run single file
		if buildSingleFile(tcProjectName)
			cName = substr(tcProjectName, 1, len(tcProjectName)-6)
			cExecutable = currentDir() + "\" + cName + ".exe"
			runProgram(cExecutable, taArgs)
		ok
		return
	ok

	# we need to build the project first
	if buildProject(tcProjectName)
		cExecutable = getExecutableName()		
		runProgram(cExecutable, taArgs)
	ok


#
# run the final executable
#
func runProgram tcExecutable, taArgs
	if not fExists(tcExecutable)
		cc_print(CC_FG_RED, "Executable not found: ")
		? tcExecutable
		return
	ok
	# detructure arguments
	cArgs = ""
	for arg in taArgs
		cArgs += " " + arg
	next
	# run the executable
	? cc_print(CC_FG_YELLOW, "Running executable...")
	system(tcExecutable + " " + cArgs)

#
# builds the project
#
func buildProject tcProjectName
	if len(tcProjectName) = 0
		tcProjectName = getProjectName()
	ok

	# are we going to build a single swift file?
	if right(tcProjectName, 6) = ".swift"		
		buildSingleFile(tcProjectName)
		return
	ok

	aBuildSettings = loadConfigFile()

	cc_print(CC_FG_YELLOW, "Building project: ")
	? aBuildSettings[:PROJECTNAME]

	# Prepare the source files
	cSourceFiles = aBuildSettings[:MAIN]
	checkFile(cSourceFiles)
	for x=1 to len(aBuildSettings[:FILES])
		cFile = aBuildSettings[:FILES][x][1]
		checkFile(cFile)
		if substr(cSourceFiles, cFile) = 0
			cSourceFiles += " " + cFile
		ok
	next
	cOutput = aBuildSettings[:OUTPUT]

	# Prepare the output file name
	if len(cOutput) = 0
		cOutput = tcProjectName
	ok
	if lower(right(cOutput, 4)) = ".exe"
		cOutput = substr(cOutput, 1, len(cOutput)-4)
	ok

	return buildProgram(cOutput, cSourceFiles)


#
# Loads the configuration file
#
func loadConfigFile
	load "jsonlib.ring"
	cBuildFile = currentDir() + '\build.json'
	if not fexists(cBuildFile)
		cc_print(CC_FG_RED, "File does not exists: ")
		? cBuildFile
		return
	ok
	return JSON2List(read(cBuildFile))
	
#
# Creates the main swift file
#
func createSwiftFile
cBuffer = 
`
//
// main.swift
//
// Created by :USER_NAME
// Copyright ® :YEAR :USER_NAME. All rights reserved.
//

import Foundation

print("Hello, World!")


`
	cBuffer = substr(cBuffer, ":USER_NAME", SysGet("USERNAME"))
	cBuffer = substr(cBuffer, ":YEAR", right(date(), 4))
	write("main.swift", cBuffer)


#
# Create the build file
#
func createBuildFile tcProjectName
cBuffer = 
`{
	"projectName": ":PROJECT_NAME",
	"files": ["main.swift"],
	"main": "main.swift",
	"root": ":ROOT",
	"output": ":PROJECT_NAME.exe"
}`
	cBuffer = substr(cBuffer, ":PROJECT_NAME", tcProjectName)
	cBuffer = substr(cBuffer, ":ROOT", substr(currentDir(), "\", "\\"))
	write("build.json", cBuffer)


#
# Parses the command line arguments
#
func getCommands
	aCommands = []
	aArgs = sysargv
	for i = 2 to len(aArgs)
		add(aCommands, aArgs[i])
	next

	return aCommands


#
# Prints 'Operation completed successfully' on the screen
#
func printOperationCompleted
	cMsg = "The operation completed successfully."
	? cc_print(CC_FG_GREEN, cMsg)


#
# gets the generated executable file name
#
func getExecutableName
	aConfig = loadConfigFile()
	cOutput = aConfig[:OUTPUT]
	if lower(right(cOutput, 4)) != ".exe"
		cOutput += ".exe"
	ok
	return currentDir() + "\" + cOutput

#
# Check if the file exists
#
func checkFile tcFile
	cFile = currentDir() + "\" + tcFile
	if not fExists(cFile)
		cc_print(CC_FG_RED, "File does not exist: ")
		? cFile
		bye
	ok


#
# getProjectName
#
func getProjectName
	aConfig = loadConfigFile()
	return aConfig[:PROJECTNAME]


#
# Build and run a single file
#
func buildSingleFile tcFileName
	cSourceFile = currentDir() + "\" + tcFileName
	if not fExists(cSourceFile)
		cc_print(CC_FG_RED, "File does not exist: ")
		? cSourceFile
		bye
	ok
	
	cOutput = substr(tcFileName, 1, len(tcFileName)-6) # trim .swift

	return buildProgram(cOutput, cSourceFile)


#
# build the swift program
#
func buildProgram tcOutput, tcSourceFiles
	cWinSdk = getWinSDK()

	# if output exists then delete
	cExecutable = currentDir() + "\" + tcOutput + ".exe"
	if fexists(cExecutable)
		system("del " + cExecutable)
	ok

	cBuffer = getBuildMacro()

	# substitute macros
	cBuffer = substr(cBuffer, ":SDK_ROOT", cWinSdk)
	cBuffer = substr(cBuffer, ":OUTPUT", tcOutput)
	cBuffer = substr(cBuffer, ":SOURCE_FILES", tcSourceFiles)
	
	# Create the bat file
	write("build.bat", cBuffer)
	
	if not fexists("build.bat")
		cc_print(CC_FG_RED, "Could not generate the file ")
		? "build.bat"
		return false
	ok
	
	# Run the bat file
	system("build.bat")
	
	return fexists(cExecutable)

#
# Create the build macro
#
func getBuildMacro
	cMacro = `set SDKROOT=:SDK_ROOT
		set SourceFiles=:SOURCE_FILES
		set Output=:OUTPUT

		:: build with optimization
		swiftc -O -o %Output%.exe %SourceFiles% -sdk %SDKROOT% -I %SDKROOT%/usr/lib/swift -L %SDKROOT%/usr/lib/swift/windows/x86_64
		
		::=======================================::
		:: delete temporary files
		::=======================================::
		if exist %Output%.exp del /f %Output%.exp
		if exist %Output%.lib del /f %Output%.lib
		if exist build.bat del /f build.bat`

	return cMacro


#
# get the SDKROOT system variable
#
func getWinSDK
	cWinSdk = SysGet("SDKROOT")
	if len(cWinSdk) = 0
		# if not registered then we build one.
		cPath = "\Library\Developer\Platforms\Windows.platform\Developer\SDKs\Windows.sdk"
		cWinSdk = SysGet("SystemDrive") + cPath
	ok

	return cWinSdk
