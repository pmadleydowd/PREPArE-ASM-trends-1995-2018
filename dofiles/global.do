******************************************************************************
* Author: 	Paul Madley-Dowd
* Date: 	21 April 2021
* Description:  Runs all global macros for the CPRD PREPArE project. To be run at the start of all stata sessions. 
******************************************************************************
clear 

global Projectdir 	"YOUR_PROJECT_DIRECTORY"

global Dodir 		"YOUR_GITHUB_DIRECTORY\dofiles"
global Logdir 		"$Projectdir\logfiles"
global Datadir 		"$Projectdir\datafiles"
global Rawdatdir 	"$Projectdir\rawdatafiles"
global Rawtextdir	"YOUR_RAW_DATA_FOLDER"
global Graphdir 	"$Projectdir\graphfiles"
global Codelsdir	"$Projectdir\datafiles\codelists"

cd "$Projectdir"

