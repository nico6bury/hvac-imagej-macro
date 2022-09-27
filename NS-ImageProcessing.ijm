/*
 * Author: Nicholas Sixbury
 * File: NS-ImageProcessing.ijm
 * Purpose: To handle all the processing for a single grid and 
 * output results quickly and efficiently.
 */
///////////////////////////////////////////////////////////////
//////////// BEGINNING OF MAIN FUNCTION ///////////////////////
// "Global" variables that we'll use "throughout"
// just a switch to use in order to disable options for debugging information.
shouldUseDebuggingOptions = true;
// whether we should ignore error prevention checks in case they cause issues
ignorePossibleErrors = false;
// the high and low thresholds are not saved, so they are always set to these defaults
// threshold for detecting the entire kernel
lowTH = 60;
// threshold for detecting the chalky region
hiTH = 185;
// number of pixels per milimeter
ppm = 11.5;

// whether or not we'll use batch mode, which really speeds things up
useBatchMode = false;
// all the valid selection methods we might use
selectionMethods = newArray("Single File", "Multiple Files", "Directory");
// the path of the file we're processing. Might be a directory
chosenFilePath = "";
// the selection method we're actually going with
selectionMethod = selectionMethods[2];
// whether we should output chalk pictures
shouldOutputChalkPics = false;
// whether we should output flipped images for human reference
shouldOutputFlipped = false;
// whether or not we should show routine error messages during processing
shouldShowRoutineErrors = true;
// whether or not we should display a helpful progress bar for the user
shouldDisplayProgress = true;
// whether we should wait for the user during processing
shouldWaitForUserProc = false;
shouldOutputAnyResults = true;
// valid operating systems
validOSs = newArray("Windows 10", "Windows 7");
// chosen operating system
chosenOS = validOSs[0];
// valid scanners
validScanners = newArray("EPSON V600","EPSON V850");
// chosen scanner that was used
chosenScanner = validScanners[0];

// whether or not we should output to a new folder for proccessed stuff
outputToNewFolderProc = true;
// what we should name our folder if we are using one
newFolderNameProc = "Results Folder";
// whether or not we should output a file of processed results
shouldOutputProccessed = true;
// the name of the file with processed results
procResultFilename = "Processed Results";
// the strings we don't allow in files we open via directory
forbiddenStrings = newArray("-Fx","-fA2","-F","-Skip");

// whether we should wait for the user during raw coordinate finding
shouldWaitForUserRaw = false;
shouldOutputAnyCoords = false;

// raw coordinate variables
// whether or not we should output to a new folder for raw coordinates
outputToNewFolderRaw = true;
// what we should name our folder if we are using one
newFolderNameRaw = "Results Folder";
// whether or not we should output a file of raw coordinates
shouldOutputRawCoords = true;
// the name of the file with the raw coordinates for the cells
rawCoordFilename = "Raw Cell Coordinates";

// processed coorindates variables
outputToNewFolderProcCoord = true;
newFolderNameProcCoord = "Results Folder";
shouldOutputProcCoords = true;
crctCoordsFilename = "Corrected Coordinates";
formCoordsFilename = "Formatted Coordinates";

// grouped coordinates variables
outputToNewFolderGroups = true;
newFolderNameGroups = "Results Folder";
shouldOutputGroups = true;
rawGroupsFilename = "Raw Group Coordinates";
procGroupsFilename = "Re-Processed Group Coordinates";

// the name of the file we'll open
chosenFilePath = "Default String Value For chosenFilePath";

// a somehwat helpful array for later
chalkNames = newArray(
		   "00-0","00-1","00-2","00-3",
	"01-0","01-1","01-2","01-3","01-4","01-5",
	"02-0","02-1","02-2","02-3","02-4","02-5",
	"03-0","03-1","03-2","03-3","03-4","03-5",
	"04-0","04-1","04-2","04-3","04-4","04-5",
	"05-0","05-1","05-2","05-3","05-4","05-5",
	"06-0","06-1","06-2","06-3","06-4","06-5",
		   "07-0","07-1","07-2","07-3",
	"08-0","08-1","08-2","08-3","08-4","08-5",
	"09-0","09-1","09-2","09-3","09-4","09-5",
	"10-0","10-1","10-2","10-3","10-4","10-5",
	"11-0","11-1","11-2","11-3","11-4","11-5",
	"12-0","12-1","12-2","12-3","12-4","12-5",
	"13-0","13-1","13-2","13-3","13-4","13-5",
		   "14-0","14-1","14-2","14-3");

arguments = getArgument();
if(arguments == ""){
	// try to load settings from file
	deserializeAndShowDialog();
	
	// and now we'll want to actually grab that information from the box
	selectionMethod = Dialog.getChoice();
	chosenOS = Dialog.getChoice();
	chosenScanner = Dialog.getChoice();
	lowTH = Dialog.getNumber();
	hiTH = Dialog.getNumber();
	useBatchMode = Dialog.getCheckbox();
	shouldShowRoutineErrors = Dialog.getCheckbox();
	shouldDisplayProgress = Dialog.getCheckbox();
	shouldOutputChalkPics = Dialog.getCheckbox();
	shouldOutputFlipped = Dialog.getCheckbox();
	// processed results
	shouldWaitForUserProc = Dialog.getCheckbox();
	shouldOutputAnyResults = Dialog.getCheckbox();
	outputToNewFolderProc = Dialog.getCheckbox();
	newFolderNameProc = Dialog.getString();
	shouldOutputProccessed = Dialog.getCheckbox();
	procResultFilename = Dialog.getString();
	if(shouldUseDebuggingOptions == true){
		// raw results stuff
		shouldWaitForUserRaw = Dialog.getCheckbox();
		shouldOutputAnyCoords = Dialog.getCheckbox();
		outputToNewFolderRaw = Dialog.getCheckbox();
		newFolderNameRaw = Dialog.getString();
		shouldOutputRawCoords = Dialog.getCheckbox();
		rawCoordFilename = Dialog.getString();
		// processed coords
		outputToNewFolderProcCoord = Dialog.getCheckbox();
		newFolderNameProcCoord = Dialog.getString();
		shouldOutputProcCoords = Dialog.getCheckbox();
		crctCoordsFilename = Dialog.getString();
		Dialog.getCheckbox();
		formCoordsFilename = Dialog.getString();
		// groups
		outputToNewFolderGroups = Dialog.getCheckbox();
		newFolderNameGroups = Dialog.getString();
		shouldOutputGroups = Dialog.getCheckbox();
		rawGroupsFilename = Dialog.getString();
		Dialog.getCheckbox();
		procGroupsFilename = Dialog.getString();
	}//end if we want to show debugging options
	
	// save what we just got
	serialize();
	
	// correct some variables based on some other variables
	if(shouldOutputAnyResults == false){
		shouldOutputProcessed = false;
	}//end if we shouldn't output any results
	if(shouldOutputAnyCoords == false){
		shouldOutputRawCoords = false;
		shouldOutputProcCoords =false;
		shouldOutputGroups = false;
	}//end if we shouldn't output any coordinates
}//end if there are not arguments
else{
	// this section kinda just straight up doesn't work right now
	chosenFilePath = arguments;
	useBatchMode = true;
}//end else we do have arguments (we don't really have that set up atm)

// speed up the program a little bit (supposedly 20 times faster)
if(useBatchMode){
	setBatchMode("hide");
}//end if we might as well just enter batch mode

filesToPrc = newArray(0);
chalkPicDir = "";
if(shouldOutputChalkPics == true && selectionMethod != "Directory"){
	showMessage("Unfortunitely chalk picture output is not supported for " +
	"selection methods other than \"Directory\". \nTherefore I'll just " +
	"pretend that you didn't select that, as without Directory selection,\n" +
	"I won't know how to put those pictures in a separate directory...");
	shouldOutputChalkPics = false;
}//end if we don't want to output chalk pics

if(selectionMethod == "Single File"){
	filesToPrc = newArray(1);
	filesToPrc[0] = File.openDialog("Please choose a grid to process");
}//end if we're just processing a single file
else if(selectionMethod == "Multiple Files"){
	numOfFiles = getNumber("How many files would you like to process?", 1);
	filesToPrc = newArray(numOfFiles);
	for(i = 0; i < numOfFiles; i++){
		filesToPrc[i] = File.openDialog("Please choose file " + (i+1) + 
		"/" + (numOfFiles) + ".");
	}//end looping to get all the files we need
}//end if we're processing multiple single files
else if(selectionMethod == "Directory"){
	chosenDirectory = getDirectory("Please choose a directory to process");

	// gets all the filenames in the directory path
	filesToPrc = getValidFilePaths(chosenDirectory, forbiddenStrings);

	// set chalkPicDir since we know what it is
	chalkPicDir = chosenDirectory;
}//end if we're processing an entire directory

// make sure we actually have files to process
if(lengthOf(filesToPrc) <= 0){
	// tell user what happened
	waitForUser("No Files Selected",
	"It seems that you either gave me an empty directory to process " +
	"or just said\n you want to process a number of files less " +
	"than or equal to zero. \n\nWell... okay then. \n\n" + 
	"It's also possible that you have given a directory that only had " + 
	"images in it \nwhich have a forbidden suffix in the name. Images " + 
	"with certain suffixes \nindicating they've already been processed " +
	"are ignored when selecting \nimages in directory mode, as we only " +
	"want unflipped, untouched images here.\n" + 
	"Guess I'll just exit, after saving your settings, of course.");
	// save settings for next time
	// (actually, they've already been saved ¯\_(ツ)_/¯)
	serialize();
	// exit the macro
	exit();
}//end if we don't have any files to process.

// array that will hold names of files we failed to process
failedFilenames = newArray(0);
// initialize stuff for progress bar
prgBarTitle = "[Progress]";
timeBeforeProc = getTime();
if(shouldDisplayProgress){
	run("Text Window...", "name="+ prgBarTitle +"width=70 height=2.5 monospaced");
}//end if we should display progress

for(iijjkk = 0; iijjkk < lengthOf(filesToPrc); iijjkk++){
	if(shouldDisplayProgress){
		// display a progress window thing
		timeElapsed = getTime() - timeBeforeProc;
		timePerFile = timeElapsed / (iijjkk+1);
		eta = timePerFile * (lengthOf(filesToPrc) - iijjkk);
		print(prgBarTitle, "\\Update:" + iijjkk + "/" + lengthOf(filesToPrc) +
		" files have been processed.\n" + "Time Elapsed: " + timeToString(timeElapsed) + 
		" sec.\tETA: " + timeToString(eta) + " sec."); 
	}//end if we should display progress
	// get the file path and start processing
	chosenFilePath = filesToPrc[iijjkk];
	open(chosenFilePath);
	// start getting coordinates of cells
	// TODO: Refactoriing Starts here
	DynamicCoordGetter(shouldWaitForUserRaw);
	// delete corners
	deleteCorners();
	// displays options explanation
	if(shouldWaitForUserRaw){
		showMessageWithCancel("Action Required",
		"The raw coordinates rois have been saved from the results window.");
	}//end if we should wait for the user
	// make sure that the rois show up properly
	setOption("Show All", false);
	setOption("Show All", true);
	// save things to where they need to go
	if(shouldOutputRawCoords == true){
		if(shouldWaitForUserRaw){
			showMessageWithCancel("Action Required",
			"We will now save the raw coords file.");
		}//end if we should wait for user
		printGroups("RawCoords");
		if(shouldWaitForUserRaw){
			showMessageWithCancel("Action Required",
			"The raw coords file has been successfully saved.");
		}//end if we should wait for user
	}//end if we should save the raw coords
	
	
	// start processing cell coordinates
	// number of cells in grid
	gridCells = 84;
	// max number of rows in the grid
	maxRows = 15;
	// max length of rows in the grid
	maxRowLen = 6;
	// how close Y needs to be to be in a group
	groupTol = 8;
	// the preferred sizes for coordinate selections
	pCellWidth = 58;
	pCellHeight = 114;
	mmCellWidth = pCellWidth / 11.5; // should be ~5
	mmCellHeight = pCellHeight / 11.5; // should be ~10
	//pre-sort 2d array for coordinates before group selection
	/*preNormalizationSort(rawCoordResults,rawCoordResultsRowCount,
	rawCoordResultsColCount,2);*/
	// delete some duplicates so we have an easier time of things
	deleteDuplicates();
	// initialize 2d array we'll put our coordinates into before group construction
	normalizeCellCount();
	if(shouldWaitForUserRaw){
		showMessageWithCancel("Finished Cell Count Normalization",
		"Macro has finished trying to normalize cell count.");
	}//end if we want to wait for the user
	// check that we actually did do our normalization correctly
	if(roiManager("count") == 0){
		if(shouldShowRoutineErrors == true){
			showMessageWithCancel("Unfortunately, it seems like the previous error " +
		"isn't something we can solve easily at the moment. As such, I'm going " +
		"\nto skip this grid and move on to the next one. If you want to know " +
		"which grid we're skipping, it's " + File.getName(chosenFilePath) + ".");
		}//end if we want to show a routine error
		failedFilenames = Array.concat(failedFilenames, chosenFilePath);
	}//end if we failed to normalize cell count
	else if(roiManager("count") != gridCells){
		if(shouldShowRoutineErrors == true){
			showMessageWithCancel("Cell Count Normalization Failed",
		"It seems we have found too many or too few cells. This happens from time\n" + 
		" to time, but we also run some procedures to correct this. Those procedures\n" +
		" have failed. The file whose path is \n\"" + chosenFilePath + "\"\n will be" + 
		"skipped. \nThere should have been " + gridCells + " cells, but instead we\n" +
		"detected " + roiManager("count") +
		" cells instead. If there are too few\n" +
		"cells, this can be caused by certain tolerance values within the program\n" + 
		"being a little bit off for some outlier images. If there are too many cells\n" +
		", that can be caused by an abundance of seeds which are horizontal and\n" + 
		"splitting their cell in half. We already cut some of them out, but if there\n" +
		"are multiple in the same row, that causes problems.\n\n" + 
		"To automatically skip this file in the future when using directory" + 
		"selection,\n append \"-Skip\" to the name of this file.");
		}//end if we want to show a routine error
		failedFilenames = Array.concat(failedFilenames, chosenFilePath);
	}//end if we have the wrong number of cells STILL
	else{
		// initialize array of groups of coordinate sets
		coordGroups = constructGroups(maxRows, maxRowLen, groupTol);
		
		// check that groups went okay
		if(false){// TODO: Fix up this error message somehow. Maybe Delete it?
			if(shouldShowRoutineErrors == true){
				showMessageWithCancel("It seems something went wrong when constructing" +
			"groups that would have caused an array out of bounds exception. \nAs " +
			"such, I'm going to just skip this grid, which is called " +
			File.getName(chosenFilePath) + ".");
			}//end if we want to show a routine error
			failedFilenames = Array.concat(failedFilenames, chosenFilePath);
		}//end if we need to skip a grid
		else{
			// print out the raw groups if we need to
			if(shouldOutputRawCoords == true && false){
				printGroups(coordGroups,maxRows,maxRowLen,4,"Raw Groups");
			}//end if we're outputting raw coordinates
			// reprocess the coordinates so they conform to each other a bit more
			reprocessRois(pCellWidth, pCellHeight);
			// sort the rois so that they're in order and labelled
			sortGroupedRois();
			// print out the re-processed groups if we need to
			if(shouldOutputRawCoords == true){
				printGroups("ReProcessedGroups");
			}//end if we're outputting raw coordinates
			// rows grid, plus newrowflag for each row, plus 1 at the beginning
			//formCoordCount = maxRows + (maxRows * maxRowLen) + 1;
						////////////////////////////////////////////////////////
								STOP!!!  OUTDATED CODE BEYOND THIS POINT!		
						////////////////////////////////////////////////////////
			// Puts all the coords from the 3d array into a 2d array with proper flags
			formedCoords = moveTo2d(coordGroups, maxRows, formCoordCount);
			// prints out formatted groups if necessary
			if(shouldOutputRawCoords && false){
				printGroups("FormattedCoordinates")
			}//end if we're outputting raw coordinates
			
			// start processing seed information from each cell
			// clear results thing
			run("Clear Results");
			// size limit for analyzing whole kernel in mm^2
			minSz1 = 4;
			// size limit for analyzing as chalky area
			minSz2 = 1;
			maxSz2 = 35;// amusingly, setting this to 15 is actually too small
			// set line counter, which is a global variable
			currentLine = 0;
			// define all the possible column headers in results
			columns = newArray("Area", "X", "Y", "Perim.", "Major", "Minor",
			"Angle", "Circ.", "AR", "Round", "Solidity");
			
			/* loop through all the coordinates and process them */
			processResults(formedCoords, formCoordCount, 4, lowTH, hiTH, minSz1,
			minSz2, columns, shouldOutputProccessed, outputToNewFolderProc,
			shouldWaitForUserProc, procResultFilename, newFolderNameProc,
			chosenFilePath);
		}//end else we have business as usual
	}//end else we have the right number of cells
}//end looping over all the files we want to process

if(shouldDisplayProgress){
	timeElapsed = getTime() - timeBeforeProc;
	print(prgBarTitle, "\\Update:" + lengthOf(filesToPrc) + "/" + lengthOf(filesToPrc) +
	" files have been processed.\n" + "Time Elapsed: " + timeToString(timeElapsed)
	+ " sec.\tETA: 0 sec."); 
}//end if we should display our progress

if(lengthOf(failedFilenames) > 0){
	// build up our message
	sb = "Unfortunitely, it seems that several files failed to be processed.\n" +
	"This is something I'm still working on, but either way, here are the stats:\n" +
	lengthOf(failedFilenames) + " files out of " + lengthOf(filesToPrc) +
	" were unable to be processed." +
	"I'll go ahead and list them below:\n";
	for(i = 0; i < lengthOf(failedFilenames); i++){
		sb += File.getName(failedFilenames[i]) + " at ";
		sb += File.getDirectory(failedFilenames[i]) + "\n";
	}//end looping over each failed file
	// print this message to a log file
	baseDir = getDirectory("macros");
	baseDir += "Macro-Logs" + File.separator;
	File.makeDirectory(baseDir);
	baseDir += "NS-MacroDriver-FailureLog.txt";
	if(File.exists(baseDir) != true){
		File.close(File.open(baseDir));
	}//end if we need to make the file first
	File.append(buildTime() + "\n" + sb + "\n", baseDir);
	// display our message to the user
	showMessageWithCancel("Failed Files Information",sb);
}//end displaying messages about files which failed.

////////////////// END OF MAIN FUNCTION ///////////////////////
///////////////////////////////////////////////////////////////

///////////////////// MAIN FUNCTIONS //////////////////////////

function timeToString(mSec){
	floater = d2s(mSec, 0);
	floater2 = parseFloat(floater);
	floater3 = floater2 / 1000;
	return floater3;
}//end timeToString()

function buildTime(){
	MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug",
	"Sep","Oct","Nov","Dec");
    DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
    TimeString ="Date: "+DayNames[dayOfWeek]+" ";
    if (dayOfMonth<10) {TimeString = TimeString+"0";}
    TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+"\nTime: ";
    if (hour<10) {TimeString = TimeString+"0";}
    TimeString = TimeString+hour+":";
    if (minute<10) {TimeString = TimeString+"0";}
    TimeString = TimeString+minute+":";
    if (second<10) {TimeString = TimeString+"0";}
    TimeString = TimeString+second;
    return TimeString;
}//end buildTime()

function serialize(){
	// serialization for dialogue stuff
	serializationPath = serializationDirectory();
	fileVar = File.open(serializationPath);
	print(fileVar, "useBatchMode=" + useBatchMode);
	print(fileVar, "selectionMethod=" + selectionMethod);
	print(fileVar, "shouldOutputChalkPics=" + shouldOutputChalkPics);
	print(fileVar, "shouldOutputFlipped=" + shouldOutputFlipped);
	print(fileVar, "shouldShowRoutineErrors=" + shouldShowRoutineErrors);
	print(fileVar, "shouldWaitForUserProc=" + shouldWaitForUserProc);
	print(fileVar, "shouldOutputAnyResults=" + shouldOutputAnyResults);
	print(fileVar, "outputToNewFolderProc=" + outputToNewFolderProc);
	print(fileVar, "newFolderNameProc=" + newFolderNameProc);
	print(fileVar, "shouldOutputProcessed=" + shouldOutputProccessed);
	print(fileVar, "procResultFilename=" + procResultFilename);
	print(fileVar, "shouldWaitForUserRaw=" + shouldWaitForUserRaw);
	print(fileVar, "shouldOutputAnyCoords=" + shouldOutputAnyCoords);
	print(fileVar, "outputToNewFolderRaw=" + outputToNewFolderRaw);
	print(fileVar, "newFolderNameRaw=" + newFolderNameRaw);
	print(fileVar, "shouldOutputRawCoords=" + shouldOutputRawCoords);
	print(fileVar, "rawCoordFilename=" + rawCoordFilename);
	print(fileVar, "outputToNewFolderProcCoord=" + outputToNewFolderProcCoord);
	print(fileVar, "newFolderNameProcCoord=" + newFolderNameProcCoord);
	print(fileVar, "shouldOutputProcCoords=" + shouldOutputProcCoords);
	print(fileVar, "crctCoordsFilename=" + crctCoordsFilename);
	print(fileVar, "formCoordsFilename=" + formCoordsFilename);
	print(fileVar, "outputToNewFolderGroups=" + outputToNewFolderGroups);
	print(fileVar, "newFolderNameGroups=" + newFolderNameGroups);
	print(fileVar, "shouldOutputGroups=" + shouldOutputGroups);
	print(fileVar, "rawGroupsFilename=" + rawGroupsFilename);
	print(fileVar, "procGroupsFilename=" + procGroupsFilename);
	print(fileVar, "shouldDisplayProgress=" + shouldDisplayProgress);
	print(fileVar, "chosenOS=" + chosenOS);
	print(fileVar, "chosenScanner="+ chosenScanner);
	File.close(fileVar);
}//end serialize()

function deserializeAndShowDialog(){ // TODO: Update deserialization
	// deserialization for dialogue stuff
	// get our file io out of the way
	serializationPath = serializationDirectory();
	// actually do all the parsing stuff
	if(File.exists(serializationPath)){
		fullFile = File.openAsString(serializationPath);
		// get each line of the file
		lines = split(fullFile, "\n");
		if(lengthOf(lines) >= 28){
			// try to get an array of just the data of each line
			justData = newArray();
			for(i = 0; i < lengthOf(lines); i++){
				if(lengthOf(lines[i]) > 1){
					splitLine = split(lines[i], "=");
					if(lengthOf(splitLine) <= 1){
						justData = Array.concat(justData,"");
					}//end if we have blank data here
					else{
						justData = Array.concat(justData,splitLine[1]);
					}//end else we can add as usual
				}//end if we don't have a blank line
			}//end looping to just get data from each line
			// now we can do things by index of justData
			if(lengthOf(justData) > 29){
				useBatchMode = parseInt(justData[0]);
				selectionMethod = justData[1];
				shouldOutputChalkPics = parseInt(justData[2]);
				shouldOutputFlipped = parseInt(justData[3]);
				shouldShowRoutineErrors = parseInt(justData[4]);
				shouldWaitForUserProc = parseInt(justData[5]);
				shouldOutputAnyResults = parseInt(justData[6]);
				outputToNewFolderProc = parseInt(justData[7]);
				newFolderNameProc = justData[8];
				shouldOutputProcessed = parseInt(justData[9]);
				procResultFilename = justData[10];
				shouldWaitForUserRaw = parseInt(justData[11]);
				shouldOutputAnyCoords = parseInt(justData[12]);
				outputTonewFolderRaw = parseInt(justData[13]);
				newFolderNameRaw = justData[14];
				shouldOutputRawCoords = parseInt(justData[15]);
				rawCoordFilename = justData[16];
				outputToNewFolderProcCoord = parseInt(justData[17]);
				newFolderNameProcCoord = justData[18];
				shouldOutputProcCoords = parseInt(justData[19]);
				crctCoordsFilename = justData[20];
				formCoordsFilename = justData[21];
				outputToNewFolderGroups = parseInt(justData[22]);
				newFolderNameGroups = justData[23];
				shouldOutputGroups = parseInt(justData[24]);
				rawGroupsFilename = justData[25];
				procGroupsFilename = justData[26];
				shouldDisplayProgress = parseInt(justData[27]);
				chosenOS = justData[28];
				chosenScanner = justData[29];
			}//end if we have enough lines
		}//end if we can load data from the file
	}//end if the file exists
	
	
	// some simple little dialogue constants
	strWdt = 25;
	// We'll go ahead and make a fancy dialog box because why not?
	Dialog.createNonBlocking("Macro Options");
	//Dialog.addMessage("Please specify the preferred behavior of the macro.");
	Dialog.addChoice("File Selection Method", selectionMethods, selectionMethod);
	Dialog.addToSameRow();
	Dialog.addChoice("Current Operating System", validOSs, chosenOS);
	Dialog.addToSameRow();
	Dialog.addChoice("Scanner", validScanners, chosenScanner);
	Dialog.addSlider("Kernel threshold (to 255)", 0, 255, lowTH);
	Dialog.addToSameRow();
	Dialog.addSlider("Chalk threshold (to 255)", 0, 255, hiTH);
	Dialog.addCheckboxGroup(2, 3, newArray("Don't Show Images for Better Performance",
	"Show Routine Errors", "Show Progress","Output Chalk Detection Pictures",
	"Output Flipped Image Copies"),newArray(useBatchMode, shouldShowRoutineErrors,
	shouldDisplayProgress,shouldOutputChalkPics,shouldOutputFlipped));
	// stuff for processed results
	Dialog.addMessage("Final Seed Processing");
	Dialog.addCheckbox("Wait For User", shouldWaitForUserProc);
	Dialog.addToSameRow();
	Dialog.addCheckbox("Output Any Results at All", shouldOutputAnyResults)
	Dialog.addCheckbox("Output Results To Folder", outputToNewFolderProc);
	Dialog.addToSameRow();
	Dialog.addString("Optional Folder Name", newFolderNameProc, strWdt);
	Dialog.addCheckbox("Output File of Processed Results",
	shouldOutputProccessed);
	Dialog.addToSameRow();
	Dialog.addString("Results Filename",
	procResultFilename, strWdt);
	if(shouldUseDebuggingOptions == true){
		// stuff for raw coordinates
		Dialog.addMessage("Raw Coordinate Output Options");
		Dialog.addCheckbox("Wait For User", shouldWaitForUserRaw);
		Dialog.addToSameRow();
		Dialog.addCheckbox("Output any Debugging Coordinates at All", shouldOutputAnyCoords);
		// raw coords
		Dialog.addCheckbox("Output Coordinatess To Folder", outputToNewFolderRaw);
		Dialog.addToSameRow();
		Dialog.addString("Optional Folder Name", newFolderNameRaw, strWdt);
		Dialog.addCheckbox("Output File of Raw Cell Coordinatess",
		shouldOutputRawCoords);
		Dialog.addToSameRow();
		Dialog.addString("Raw Cell Coordinates Filename", rawCoordFilename, strWdt);
		// processed coords
		Dialog.addMessage("Processed Coordinate Output Options");
		Dialog.addCheckbox("Processed Coordinates to Folder", outputToNewFolderProcCoord);
		Dialog.addToSameRow();
		Dialog.addString("Optional Folder Name", newFolderNameProcCoord, strWdt);
		Dialog.addCheckbox("Output Processed Coordinates",shouldOutputProcCoords);
		Dialog.addToSameRow();
		Dialog.addString("Corrected Coordinates Filename", crctCoordsFilename, strWdt);
		Dialog.addCheckbox("",shouldOutputProcCoords);
		Dialog.addToSameRow();
		Dialog.addString("Formatted Coordinates Filename", formCoordsFilename, strWdt);
		// groups
		Dialog.addMessage("Grouped Coordinate Output Options");
		Dialog.addCheckbox("Output Coordinates To Folder", outputToNewFolderGroups);
		Dialog.addToSameRow();
		Dialog.addString("Optional Folder Name", newFolderNameGroups, strWdt);
		Dialog.addCheckbox("Output Raw Grouped Coordinates",shouldOutputGroups);
		Dialog.addToSameRow();
		Dialog.addString("Raw Grouped Coordinate Filename", rawGroupsFilename, strWdt);
		Dialog.addCheckbox("",shouldOutputGroups);
		Dialog.addToSameRow();
		Dialog.addString("Processed Group Coordinate Filename", procGroupsFilename, strWdt);
	}//end if we should show options for debugging information
	// actually show the dialog box
	Dialog.show();
}//end deserialize()

function serializationDirectory(){
	// generates a directory for serialization
	macrDir = fixDirectory(getDirectory("macros"));
	macrDir += "Macro-Configuration/";
	File.makeDirectory(macrDir);
	macrDir += "DurumImageProcessingConfig.txt";
	return macrDir;
}//end serializationDirectory()

/*
 * returns an array of valid file paths in the specified
 * directory. Any file whose base name contains a string within
 * the forbiddenStrings array will not be added.
 */
function getValidFilePaths(directory, forbiddenStrings){
	// gets array of valid file paths without forbidden strings
	// just all the filenames
	baseFileNames = getAllFilesFromDirectories(newArray(0), directory);
	// just has booleans for each filename
	q = forbiddenStrings;
	boolArray = areFilenamesValid(baseFileNames, q, false);
	// number of valid filenames we found
	correctFileNamesCount = countTruths(boolArray);
	// initialize our new array of valid names
	filenames = newArray(correctFileNamesCount);
	// populate filenames array
	j = 0;
	for(i = 0; i < lengthOf(boolArray) && j < lengthOf(filenames); i++){
		if(boolArray[i] == true){
			filenames[j] = baseFileNames[i];
			j++;
		}//end if we have a truth
	}//end looping for each element of boolArray
	return filenames;
}//end getValidFilePaths(directory)

/*
 * just returns the number of elements in array which are true
 */
function countTruths(array){
	truthCounter = 0;
	for(i = 0; i < lengthOf(array); i++){
		if(array[i] == true){
			truthCounter++;
		}//end if array[i] is a truth
	}//end looping over array
	return truthCounter;
}//end countTruths(array)

/*
 * 
 */
function getAllFilesFromDirectories(filenames, directoryPath){
	// recursively gets all the files from all the subdirectories of specified path
	// get all the files in the specified directory, including subdirectories
	subFiles = getFileList(directoryPath);
	//print("subFiles before:"); Array.print(subFiles);
	// find number of files in subFiles
	filesInDir = 0;
	for(i = 0; i < lengthOf(subFiles); i++){
		// add full path back to name
		subFiles[i] = directoryPath + subFiles[i];
		if(File.isDirectory(subFiles[i]) == false){
			filesInDir++;
		}//end if we found a file
	}//end looping over sub files
	//print("subFiles after:"); Array.print(subFiles);
	// get list of new filenames
	justNewPaths = newArray(filesInDir);
	indexInNewPaths = 0;
	for(i = 0; i < lengthOf(subFiles); i++){
		if(File.isDirectory(subFiles[i]) == false){
			justNewPaths[indexInNewPaths] = subFiles[i];
			indexInNewPaths++;
		}//end if we found a file
	}//end looping over subFiles to get filenames
	// add new filenames to old array
	returnArray = Array.concat(filenames,justNewPaths);
	//print("returnArray before:"); Array.print(returnArray);
	// recursively search all subdirectories
	for(i = 0; i < lengthOf(subFiles); i++){
		if(File.isDirectory(subFiles[i])){
			tempArray = Array.copy(returnArray);
			newFiles = getAllFilesFromDirectories(filenames, subFiles[i]);
			//print("newFiles:"); Array.print(newFiles);
			returnArray = Array.concat(tempArray,newFiles);
			//print("returnArray after:"); Array.print(returnArray);
		}//end if we found a subDirectory
	}//end looping to get all the subDirectories
	return returnArray;
}//end getAllFilesFromDirectories(filenames, directoryPath)

/*
 * Generates an array with true or false depending on whether each
 * filename is valid. Validity is determined by not having any part
 * of the filename including a string in the forbiddenStrings array.
 * If allowDirectory is set to false, then names ending in the file
 * separator will be determined to be invalid. Otherwise, whether
 * a file is a directory or not will be ignored.
 */
function areFilenamesValid(filenames, forbiddenStrings, allowDirectory){
	// returns true false array on whether files are valid
	booleanArray = newArray(lengthOf(filenames));
	// loop to find out which are valid
	for(i = 0; i < lengthOf(filenames); i++){
		// check if filenames[i] is a directory
		if(allowDirectory == false && File.isDirectory(filenames[i])){
			booleanArray[i] = false;
		}//end if this is a subdirectory
		else{
			// loop to look for all the forbidden strings
			foundString = false;
			tempVar = filenames[i];
			fileExtension = substring(tempVar, lastIndexOf(tempVar, "."));
			if(fileExtension != ".tif"){
				booleanArray[i] = false;
			}//end if 
			else{
				filename = File.getName(filenames[i]);
				for(j = 0; j < lengthOf(forbiddenStrings); j++){
					if(indexOf(filename, forbiddenStrings[j]) > -1){
						foundString = true;
						j = lengthOf(forbiddenStrings);
					}//end if we found a forbidden string
				}//end looping over forbiddenStrings
				if(foundString){
					booleanArray[i] = false;
				}//end if we found a forbidden string
				else{
					booleanArray[i] = true;
				}//end else we have a valid file on our hands
			}//end else we need to look for forbidden strings
				
		}//end else it might be good
	}//end looping over each element of baseFileNames
	return booleanArray;
}//end areFilenamesValid(filenames, forbiddenStrings, allowDirectory)

/*
 * Performs the first step of the algorithm, finding all the cell
 * coords. Parameter Explanation: shouldWait specifies whether or
 * not the program will give an explanation to the user as it steps
 * through execution.
 */
function DynamicCoordGetter(shouldWait){
	// gets all the coordinates of the cells
	// horizontally flip the image so we have things alligned properly
	run("Flip Horizontally");
	// save a copy of the image so we don't screw up the original
	makeBackup("coord");
	if(shouldWait){
		showMessageWithCancel("Action Required",
		"Image has been flipped");
	}//end if we need to wait
	//save copy of our flipped image if we feel like it
	if(shouldOutputFlipped){
		newPth = File.getDirectory(chosenFilePath);
		newPth += "FlippedImages" + File.separator;
		File.makeDirectory(newPth);
		newPth += File.getNameWithoutExtension(chosenFilePath) + "-F.tif";
		save(newPth);
	}//end if we should output a flipped image
	// Change image to 8-bit grayscale to we can set a threshold
	run("8-bit");
	// set threshold to only detect the cells
	// threshold we set is 0-126 as of 8/12/2021 12:15
	// now it's 0-160 as of 8/31/2021 4:00
	if(chosenOS == validOSs[0]){
		setThreshold(0, 126);
	}//end if we're on Windows 10
	else if(chosenOS == validOSs[1]){
		setThreshold(0, 160);
	}//end else if we're on Windows 7
	if(shouldWait){
		showMessageWithCancel("Action Required",
		"Threshold for Cells has been Set");
	}//end if we need to wait
	// set scale so we have the right dimensions
	run("Set Scale...", "distance=11.5 known=1 unit=mm global");
	// set measurements to only calculate what we need(X,Y,Width,Height)
	run("Set Measurements...",
	"bounding redirect=None decimal=1");
	// set particle analysis to only detect the cells as particles
	run("Analyze Particles...", "size=25-Infinity circularity=0.05-1.00 "+
	"exclude clear include add");
	if(shouldWait){
		showMessageWithCancel("Action Required",
		"Scale and Measurements were set, so now " + 
		"we have detected what cells we can.");
	}//end if we need to wait
	// We should have all the coordinates in the roi manager
	/*/ extract coordinate results from results display
	//coordsArray = getCoordinateResults();*/
	// open the backup
	openBackup("coord", true);
}//end DynamicCoordGetter(shouldWait)

function deleteCorners(){
	/* deletes regions of intererst which touch the corners of the image.
	 This function is meant to work on rois that correspond to a cell, not
	 a seed.*/
	// tolerance for left x
	xTolL = 3;
	// tolerance for right x
	xTolR = 3;
	// tolerance for top y
	yTolUp = 3;
	// tolerance for bottom y
	yTolBot = 3;
	// find borders of image
	imgWidth = 0;
	imgHeight = 0;
	temp = 0;
	// out parameter configuration ???
	getDimensions(imgWidth, imgHeight, temp, temp, temp);
	// account for pixels-to-milimeter
	imgWidth = imgWidth / ppm;
	imgHeight = imgHeight / ppm;
	// make array to keep track of indexes with corners
	badInd = newArray();
	// loop through and find corners
	for(i = 0; i < roiManager("count"); i++){
		// retrieve x,y,width,height for this index
		roiManager("select", i);
	 	d2x = -1; d2y = -1;
	 	d2w = -1; d2h = -1;
	 	Roi.getBounds(d2x, d2y, d2w, d2h);
	 	// test for top left corner
	 	if(abs(d2x - 0) < xTolL && abs(d2y - 0) < yTolUp){
	 		// keep track of index of corner
	 		badInd = Array.concat(badInd,i);
	 	}//end if we found top left corner
	 	else if(abs((d2x+d2w) - imgWidth) < xTolR && abs(d2y - 0) < yTolUp){
	 		// keep track of index of corner
	 		badInd = Array.concat(badInd,i);
	 	}//end else if we found the top right corner
	 	else if(abs(d2x - 0) < xTolL && abs((d2y+d2h) - imgHeight) < yTolBot){
	 		// keep track of index of corner
	 		badInd = Array.concat(badInd,i);
	 	}//end else if we found the bottom left corner
	 	else if(abs((d2x+d2w) - imgWidth) < xTolR &&
	 			abs((d2y+d2h) - imgHeight) < yTolBot){
	 		// keep track of index of corner
	 		badInd = Array.concat(badInd,i);
	 	}//end else if we found the bottom right corner
	}//end looping over d2Array
	// just delete the non-corners
	if(lengthOf(badInd) != 0){
		roiManager("select", badInd);
		roiManager("delete");
	}// end if we have indices to delete
}//end deleteCorners()

function deleteDuplicates(){
	// deletes elements in 2d array with very similar X and Y, returns new array
	// tolerance for x values closeness
	xTol = 2;
	// tolerance for y values closeness
	yTol = 5;
	//Array.print(d2Array);
	// array to hold index of bad coordinates
	badInd = newArray(0);
	// find extremely similar indexes
	for(i = 0; i < roiManager("count"); i++){
		// Note: might want to exclude processing of bad indexes here
		roiManager("select", i);
		if(contains(badInd, i) == false){
			// get x and y for i
			d2x = -1;//twoDArrayGet(d2Array, xT, yT, i, 0);
			d2y = -1;//twoDArrayGet(d2Array, xT, yT, i, 1);
			temp = -2;
			Roi.getBounds(d2x, d2y, temp, temp);
			for(j = i+1; j < roiManager("count"); j++){
				roiManager("select", j);
				d2x2 = -1;
				d2y2 = -1;
				Roi.getBounds(d2x, d2y, temp, temp);
				diffX = abs(d2x - d2x2);
				diffY = abs(d2y - d2y2);
				if(diffX < xTol && diffY < yTol){
					badInd = Array.concat(badInd,j);
				}//end if this is VERY close to d2Array[i]
			}//end looping all the rest of the array
		}//end if this array is good
	}//end looping over d2Array
	// just delete the bad indices
	if(lengthOf(badInd) != 0){
		roiManager("select", badInd);
		roiManager("delete");
	}//end if we have bad indices to delete
}//end deleteDuplicates()

function contains(array, val){
	foundVal = false;
	for(ijkm = 0; ijkm < lengthOf(array) && foundVal == false; ijkm++){
		if(array[ijkm] == val){
			foundVal = true;
		}//end if we found the value
	}//end looping over array
	return foundVal;
}//end contains

/*
 * Returns:
 * +0 if everything is fine
 * -1 if not enough cells located
 * -2 if an issue that would cause failure to change rois
 */
function normalizeCellCount(){
	// normalize the cell count of rawCoords to gridCells
	// initialize 2d array we'll put our coordinates into before group construction
	//coordRecord = twoDArrayInit(gridCells, 4);
	// check to make sure we have the right number of cells
	if(roiManager("count") < gridCells){
		if(shouldShowRoutineErrors == true){
			showMessageWithCancel("Unexpected Cell Number",
		"In the file " + File.getName(chosenFilePath) + ", which is located at \n" +
		chosenFilePath + ", \n" +
		"it seems that we were unable to detect the location of every cell. \n" + 
		"There should be " + gridCells + " cells in the grid, but we have only \n" + 
		"detected " + roiManager("count") + " of them. This could be very problematic later on.");
		}//end if we want to show a routine error
		return -1;
	}//end if we haven't detected all the cells we should have
	else if(nResults > gridCells){
		// we'll need to delete extra cells
		curCellCt = roiManager("count");
		// if less than tol, then on same row
		inCelTol = 2.7;// was 1.5
		// if more than tol, then on different row
		outCelTol = 10;
		// current index we're putting stuff into for coordRecord
		curRecInd = 0;
		// set most recent Y by default as first Y
		roiManager("select", 0);
		temp = -1;
		mRecY = -1;//twoDArrayGet(d2Arr,xT,yT,0,1);
		Roi.getBounds(temp, mRecY, temp, temp);
		// set most recent difference to 0
		mRecDiff = 0;
		for(i = 0; i < roiManager("count"); i++){
			// figure out how this Y compares to last one
			thisY = -1;
			x = -1;
			w = -1;
			h = -1;
			roiManager("select", i);
			Roi.getBounds(x, thisY, w, h);
			diffFromRec = abs(thisY - mRecY);
			if(diffFromRec < inCelTol || diffFromRec > outCelTol){
				// keep this index in the list
				// print something to the log
				print("found a normal cell, indexed to "+curRecInd +
				", diffFromRec of " + diffFromRec);
				// increment curRecInd to account for addition
				curRecInd++;
			}//end if we think differences look normal
			else if(mRecDiff > inCelTol && mRecDiff < outCelTol){
				// keep this index in the list
				twoDArraySet(coordRecord,gridCells,4,curRecInd,0,x);
				twoDArraySet(coordRecord,gridCells,4,curRecInd,1,thisY);
				twoDArraySet(coordRecord,gridCells,4,curRecInd,2,w);
				twoDArraySet(coordRecord,gridCells,4,curRecInd,3,h);
				// print something to the log
				print("found a bad cell, but it's only bad because of last");
				// increment curRecInd to account for addition
				curRecInd++;
			}//end else if last one was not good, so this one is bad because of that
			else{
				// print something to the log
				print("found the start of a bad cell, deleting it");
				roiManager("delete");
			}//end else we found the start of a bad cell

			// set most recent Y again so it's updated for next iteration
			mRecDiff = diffFromRec;
			mRecY = thisY;
		}//end looping over cells in rawCoordResults
		// quick fix for renaming files
		if(shouldOutputRawCoords == true){
			printGroups("CorrectedCorrdinates");
		}//end if we're outputting a file
	}//end else if there are too many cells
	else{
		// we don't have to do anything
	}//end else we have the right number of cells
	return 0;
}//end normalizeCellCount()

/*
 * coords2d is the array we want to convert, rcX is the row count of that
 * array, and rcY is the column count of the array. maxRows is the number
 * of rows in in the new 3d array, and maxRowLen is the number of columns
 * in the 3d array. groupTol is used to determine which coordinates should
 * be put within groups, as only items within groupTol of each other can
 * be within a group.
 */
function constructGroups(maxRows,maxRowLen,groupTol){
	// initialize group bounds arrays
	gridLowBound = newArray(0);
	gridUpBound = newArray(0);
	for(i = 0; i < roiManager("count"); i++){
		// select current roi
		roiManager("select", i);
		// figure out current roi Y bounds
		roiBounds = getRoiYBounds(); // y and (y+height)
		// start testing all the groups to see if we can find something that works
		for(j = 0; j < lengthOf(gridLowBound); j++){
			// test location relation of roi and group
			relLoc = locationRelation(gridLowBound[j],gridUpBound[j],0,roiBounds[0],roiBounds[1]);
			if(relLoc[0] || relLoc[1]){
				Roi.setGroup(j+1);
				gridLowBound[j] = Math.min(gridLowBound[j], roiBounds[0]);
				gridUpBound[j] = Math.max(gridUpBound[j], roiBounds[1]);
				// don't try adding this roi to any new groups
				break;
			}//end if we've found a matching group for this roi
		}//end looping over the groups we want to test out
		if(Roi.getGroup() == 0){
			// change set group of selected roi
			Roi.setGroup(lengthOf(gridLowBound)+1);
			// expand size of parallel arrays
			gridLowBound = Array.concat(gridLowBound,roiBounds[0]);
			gridUpBound = Array.concat(gridUpBound,roiBounds[1]);
		}//end if we couldn't find a group and need to make a new one
	}//end looping over rois we want to group
	return 0;
}//end constructGroups(maxRows,maxRowLen,groupTol)

/**
 * Parameter Explanation
 * obj1Low : Lower y bound of first object
 * obj1Up : Upper y bound of first object
 * adjTol : applied to obj1, closeness required for obj2 to be adjacent
 * obj2Low : Lower y bound of second object
 * obj2Up : Upper y bound of second object
 * 
 * Return Explanation
 * Array Containing:
 * insideBounds : Whether obj2 is inside obj1 or vice versa.
 * overlapBool : Whether the objects have overlapping bounds
 * adjacencyBool[REMOVED] : Whether the objects are adjacent 
 */
function locationRelation(obj1Low,obj1Up,adjTol,obj2Low,obj2Up){
	insideBoundsBool = false;
	overlapBool = false;
	//adjacencyBool = false;
	
	if(obj1Low <= obj2Low && obj1Up >= obj2Up)
	{insideBoundsBool = true;}
	if(
		((obj1Low <= obj2Up) && (obj1Up >= obj2Up))
							 ||
		((obj1Up >= obj2Low) && (obj1Low <= obj2Low))
	)
	{overlapBool = true;}
	/*if(
		( ((obj1Up + adjTol) >= obj2Low) && (obj1Up <= obj2Low) )
										 ||
		( ((obj1Low - adjTol) <= obj2Up) && (obj1Low >= obj2Up) )
	)
	{adjacencyBool = true;}*/
	
	return newArray(insideBoundsBool, overlapBool/*, adjacencyBool*/);
}//end locationRelation(obj1Low,obj1Up,adjTol,obj2Low,obj2Up)

/*
 * Returns length 2 array with y and (y+height) of currently selected roi
 * tries to automatically convert things to mm by dividing by 11.5
 */
function getRoiYBounds(){
	roiY = -1;
	roiHeight = -1;
	temp = -1;
	Roi.getBounds(temp, roiY, temp, roiHeight);
	return newArray(roiY / 11.5, (roiY + roiHeight) / 11.5);
}//end getRoiYBounds

function printGroups(filename){
	// quick fix for renaming files
	fileNameBase = File.getName(chosenFilePath);
	// actually save the coordinates
	finalPath = fileNameBase;
	dirBase = File.getDirectory(chosenFilePath);
	if(outputToNewFolderRaw){
		dirBase += newFolderNameRaw + File.separator;
		File.makeDirectory(dirBase);
	}//end if we're saving to a new folder
	roiManager("save", dirBase + fileNameBase + "-" + filename + ".zip");
}//end printGroups(filename)

/*
 * When given a positive integer, this function converts the number
 * into a string of letters which will have the same alphabetical order
 * as the number's numerical order when compared to other numbers convertd
 * with this function. The digits in the number are converted into letters q-z,
 * and then a prefix is assigned based on length, using letters a-p. This is
 * done so that numbers with 3 digits will come before numbers with 4 digits.
 */
function convertAlpha(n){
	// the alphabet, useful for later probably
	prefixes = newArray("a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p");
	suffices = newArray("q","r","s","t","u","v","w","x","y","z");
	// figure out how many digits in n, assume positive integer
	digits = Math.floor(Math.log10(n)) + 1;
	// convert number to string so we can look at individual digits
	numAsString = toString(n);
	// we'll reserve q-z for replacing digits, and a-p for length prefix
	// we'll stick the components in an array of strings, then join them at end
	cmpnts = newArray(digits);
	for(i = 0; i < lengthOf(numAsString); i++){
		digit = floor(n / pow(10, i) % 10);
		cmpnts[i] = suffices[digit];
	}//end converting each digit of n to a letter
	cmpnts = Array.reverse(cmpnts);
	// the string we'll return
	rtnStr = prefixes[digits] + "-" + String.join(cmpnts, "");
	//print("n: " + n + "    a: " + rtnStr);
	return rtnStr;
}//end convertAlpha(n)

/*
 * Sorts the rois by equalizing the height of each row, 
 * renaming each roi to match the row and column it's in,
 * and then sorting the rois at the end to match the right order.
 * 
 * At this point, the rois are grouped by row; we just need to
 * ensure they're of the right order within each row
 */
function sortGroupedRois(){
	// stopgap solution to a problem I don't want to tangle with
	letters = newArray("a","b","c","d","e","f","g","h","i","j","k","l","m","n",
	"o","p","q","r","s","t","u","v","w","x","y","z");
	// array to hold recent group, set to first group
	lastIndexGroup = -1;
	// array to hold height of last index
	lastIndexHeight = -1; // this should be y pos
	// do initlialization for first index
	if(roiManager("count") > 0){
		roiManager("select", 0);
		lastIndexGroup = Roi.getGroup();
		temp = -1; x0 = -1;
		Roi.getBounds(x0, lastIndexHeight, temp, temp);
		roiManager("rename", letters[lastIndexGroup] + "-" + convertAlpha(x0));
	}//end if we have any rois at all
	// sort rois within each roi by equalizing height
	for(i = 1; i < roiManager("count"); i++){
		// make sure we have the current index selected
		roiManager("select", i);
		curGroup = Roi.getGroup();
		if(curGroup == lastIndexGroup){
			// change just current roi height to last heigh
			x1 = -1; y1 = -1; h1 = -1; w1 = -1;
			Roi.getBounds(x1, y1, w1, h1);
			makeRectangle(x1, lastIndexHeight, w1, h1);
			roiManager("update");
			roiManager("select", i);
			Roi.setGroup(curGroup);
			// rename roi to hopefully make it be sorted
			roiManager("rename", letters[curGroup] + "-" + convertAlpha(x1));
		}//end if we should equalize height
		else{
			// update variables for new group
			lastIndexGroup = curGroup;
			temp = -1; x2 = -1;
			Roi.getBounds(x2, lastIndexHeight, temp, temp);
			roiManager("rename", letters[curGroup] + "-" + convertAlpha(x2));
		}//end else we should move to next group
	}//end looping over rois
	roiManager("sort");
	roiManager("show none");
	roiManager("show all with labels");
}//end sortGroupedRois()

// shrinks one coordinate to match Width and Height
function shrinkRoi(w,h){
	// get the bounds of the current roi
	xi = -1; yi = -1; wi = -1; hi = -1;
	Roi.getBounds(xi, yi, wi, hi);
	diffW = wi - w;
	diffH = hi - h;
	if(diffW > 0){
		xi += diffW / 2;
		wi -= diffW;
		// Change bounds of roi
		updateRoi(xi, yi, wi, hi);
	}//end if difference between widths is greater than 0
	if(diffH > 0){
		yi += diffH / 2;
		hi -= diffH;
		// Change bounds of roi
		updateRoi(xi, yi, wi, hi);
	}//end if difference between heights is greater than 0
}//end shrinkRoi(w,h)

function updateRoi(x, y, w, h){
	// figure out what group is selected
	index = roiManager("index");
	// save group information
	groupNum = Roi.getGroup();
	// create rectangle with selected bounds
	makeRectangle(x, y, w, h);
	// update roi with selection
	roiManager("update");
	// reslect the roi we want
	roiManager("select", index);
	// add back the group information
	Roi.setGroup(groupNum);
}//end updateRoi(x,y,w,h)

// grows one coordinate to match width and height
function growRoi(w,h){
	// get the bounds of the current roi
	xi = -1; yi = -1; wi = -1; hi = -1;
	Roi.getBounds(xi, yi, wi, hi);
	diffW = w - wi;
	diffH = h - hi;
	if(diffW > 0){
		wi += diffW;
		// Change bounds of roi
		updateRoi(xi, yi, wi, hi);
	}//end if difference between widths is greater than 0
	if(diffH > 0){
		hi += diffH;
		// Change bounds of roi
		updateRoi(xi, yi, wi, hi);
	}//end if difference between heights is greater than 0
}//end growRoi(w,h)

function reprocessRois(w,h){
	// reprocesses groups so the values line up a bit better
	for(i = 0; i < roiManager("count"); i++){
		roiManager("select", i);
		// get the bounds of the current roi
		xi = -1; yi = -1; wi = -1; hi = -1;
		Roi.getBounds(xi, yi, wi, hi);
		// shrink this coor if it's too big
		if(wi > w || hi > h){
			// Shrink current roi
			shrinkRoi(w,h);
		}//end if we need to shrink this roi
		if(wi < w || hi < h){
			// Grow current roi
			growRoi(w,h);
		}//end if we need to grow this roi
	}//end looping over each roi
}//end reprocessRois(w,h)

/*
 * 
 */
function processKernel(X,Y,W,H,windowPattern,shouldWait,fileVar){ // TODO: Overhall processKernel
	// make a selection and process the kernel

	// make our selection, multiplying in order to convert to pixels from mm
	makeRectangle(X * 11.5, Y * 11.5,
	W * 11.5, H * 11.5);
	if(shouldWait){
		showMessageWithCancel("Action Required",
		"Selection Made");
	}//end if we should wait
	// make a copy to work with
	// get a little debugging info first
	
	run("Duplicate...", "title=[" + windowPattern + "]");
	if(shouldWait){
		showMessageWithCancel("Action Required",
		"Selection Duplicated");
	}//end if we should wait
	// take a snapshot so we can reset later
	makeBackup("Dup");
	// set which things should be measured
	run("Set Measurements...",
	"area centroid perimeter fit shape redirect=None decimal=2");
	// set the threshold
	run("8-bit");
	setAutoThreshold("Default dark");
	setThreshold(lowTH, 255);
	if(shouldWait){
		showMessageWithCancel("Action Required",
		"Kernel Threshold Set");
	}//end if we should wait
	resultsBefore = nResults;
	// analyze particles
	run("Analyze Particles...",
	"size=minSz1-maxSz2 circularity=0.1-1.00" + 
	" show=[Overlay Masks] display");
	if(shouldWait){
		showMessageWithCancel("Action Required",
		"Kernel Particles Analyzed");
	}//end if we should wait
	resultsAfter = nResults;
	if(resultsAfter - resultsBefore > 0){
		// print kernel results over the log
		kernelStuff = getAllResults(columns);
		kernelForLog = newArray(lengthOf(columns));
		kCount = lengthOf(kernelForLog);
		for(j = 0; j < kCount; j++){
			kernelForLog[j] = twoDArrayGet(kernelStuff,
			lengthOf(kernelStuff)/lengthOf(columns),
			lengthOf(columns), nResults-1, j);
		}//end looping over all the columns of this line
		currentLine++;
		print(currentLine + "     " + dATS(1, kernelForLog, "     "));
		if(fileVar != false){
			print(fileVar, currentLine + "\t" + dATS(1, kernelForLog, "\t"));
		}//end if we're doing a file
		if(shouldWait){
			showMessageWithCancel("Action Required",
			"Kernel Results Printed");
		}//end if we should wait
	}//end if we detected a kernel
}//end processKernel(x,y,width,height)

/*
 * 
 */
function processChalk(windowPattern, shouldWait, fileVar){ // TODO: Overhall processChalk
	// process the duplicate for chalk
	
	// reset our copy so we can get chalk
	close(windowPattern);
	openBackup("Dup", false);
	rename(windowPattern);
	// set which things should be measured
	run("Set Measurements...",
	"area centroid perimeter fit shape redirect=None decimal=2");
	// try to smooth image and trim tips
	run("Subtract Background...", "rolling=5 create");
	// set the threshold for the chalk
	run("8-bit");
	setAutoThreshold("Default dark");
	setThreshold(hiTH, 255);
	if(shouldWait){
		showMessageWithCancel("Action Required",
		"Chalk Threshold Set");
	}//end if we should wait	
	// analyze particles
	resultNumBefore = nResults;
	run("Analyze Particles...",
	"size=minSz2-maxSz2 circularity=0.1-1.00" + 
	" show=[Overlay Masks] display");
	if(shouldWait){
		showMessageWithCancel("Action Required", 
		"Chalk Particles Analyzed");
	}//end if we should wait
	if(shouldOutputChalkPics){
		// folder directory for our files to go in
		chalkDir = getChalkPicPath(chosenDirectory, chosenFilePath,
		File.getName(chosenFilePath));
		// figure out what we want to name our file
		chalkPicNm = chalkNames[chalkCounter] + ".tif";
		// flatten image to keep overlays
		run("Flatten");
		// hopefully save the image
		save(chalkDir + chalkPicNm);
		// close the image we just saved to prevent ROI problems
		close();
	}//end if we're outputting chalk pics
	// print chalk results to the log if there are any
	chalkStuff = getAllResults(columns);
	resultNumAfter = nResults;
	if(resultNumBefore != resultNumAfter){
		chalkRowT = resultNumAfter - resultNumBefore;
		chalkColT = lengthOf(columns);
		chalkForLog = twoDArrayInit(chalkRowT,chalkColT);
		// put all the recent chalk data into chalkForLog
		for(jj = 0; jj < chalkRowT; jj++){
			currentLine++;
			sb1 = "" + currentLine + "     ";
			sb2 = "" + currentLine + "\t";
			for(kk = 0; kk < chalkColT; kk++){
				// put right data into chalkForLog
				twoDArraySet(chalkForLog,chalkRowT,chalkColT,jj,kk,
				twoDArrayGet(chalkStuff,lengthOf(chalkStuff) /
				lengthOf(columns), lengthOf(columns), resultNumBefore
				 + jj, kk));
				// add stuff to be put in log or printed
				val = twoDArrayGet(chalkForLog,chalkRowT,chalkColT,jj,kk);
				sb1 += d2s(val, 1) + "     ";
				if(fileVar != false) sb2 += d2s(val, 1) + "\t";
			}//end looping through data for this particle
			// print that stuff out if we need to do so
			print(sb1);
			if(fileVar != false){
				print(fileVar, sb2);
			}//end if we're print stuff to a file
			if(shouldWait){
				showMessageWithCancel("Action Required",
				"Chalk Results Printed to Log");
			}//end if we should wait
		}//end looping over each particle detected
	}//end if we detected something
}//end processChalk(windowPattern)

function getChalkPicPath(directory, imgPath, fldrName){
	// gets the path that the chalk pictures for an image should be writ to
	imgLclDir = File.getDirectory(imgPath);
	dirPar = File.getParent(directory);
	imgDirPar = substring(imgPath,lengthOf(dirPar));
	imgDirChld = substring(imgLclDir, lengthOf(dirPar), lengthOf(imgLclDir));
	nwDir = dirPar + File.separator + "Chalk-Pictures" + imgDirChld;
	nwDir += fldrName + File.separator;
	recursiveMakeDirectory(nwDir);
	return nwDir;
}//end getChalkPicPath

function recursiveMakeDirectory(directory){
	// makes directory even if it has to make multiple directories
	if(directory != 0){
		recursiveMakeDirectory(File.getParent(directory));
	}//end if we can go ahead and recurse
	File.makeDirectory(directory);
}//end recursiveMakeDirectory(directory)

/*
 * 
 */
function processResults(fm2dCrd,x,y,lT,hT,mS1,mS2,col,f1,f2,wFP,fn1,fn2,od){ // TODO: Overhall processResults
	// set the scale
	run("Set Scale...", "distance=11.5 known=1 unit=mm global");
	// save a copy of the image so we don't mess up the original
	makeBackup("resultProcess");
	// flip the image horizontally
	run("Flip Horizontally");
	// clear the log
	print("\\Clear");;

	// quick fix for renaming files
	fileBase = File.getName(od);
	fn1 += " - " + fileBase + " " + lowTH + "-"+hiTH;
	
	// set up stuff for the file
	outputFileVar = false;
	if(f1 == true){
		if(f2 == true){
			// get the base directory of the file we already have
			baseDir = File.getDirectory(od);
			// build the new directory
			newDir = baseDir + fn2;
			// build the new filename
			newName = newDir + File.separator + fn1 + ".txt";
			// make sure the folder actually exists
			File.makeDirectory(newDir + File.separator);
			// get our file variable figured out
			outputFileVar = File.open(newName);
		}//end if we should output to a new folder
		else{
			// get the directory of the file we're proccing
			baseDir = File.getDirectory(od);
			// build the new filename from that directory
			newName = baseDir + File.separator + fn1 + ".txt";
			// get our file variable figured out
			outputFileVar = File.open(newName);
		}//end else we can just drop it in the old folder
	}//end if we should output a file of processed stuff
	
	// make the header
	sb = "\t"; sb1 = "       ";
	for(i = 0; i < lengthOf(col); i++){
		sb += col[i] + "\t";
		sb1 += col[i] + "    ";
	}//end looping for each column
	// output headers to log
	print(sb1);
	// output headers to file (if we want to)
	if(outputFileVar != false){
		print(outputFileVar, sb);
	}//end if we're outputting a file

	// helpful counter for later
	chalkCounter = 0;
	
	for(i = 0; i < x; i++){
		// check for flags
		if(isMissingCellFlag(fm2dCrd,x,y,i,0) == true){
			if(wFP){
				showMessageWithCancel("Action Required",
				"Found Missing Cell Flag");
			}//end if we should wait
			// add cell start
			currentLine++;
			startFlag = CellStartFlag(11);
			if(f1){
				print(outputFileVar, currentLine + "\t"
				+ dATS(1, startFlag, "\t"));
			}//end if we're outputting to the files
			print(currentLine + "     " + dATS(1, startFlag, "     "));
			// add the cell end
			currentLine++;
			endFlag = CellEndFlag(11);
			if(f1){
				print(outputFileVar, currentLine + "\t" +
				dATS(1, endFlag, "\t"));
			}//end if we're outputting to the files
			print(currentLine + "     " + dATS(1, endFlag, "     "));
		}//end if we have a missing cell flag
		else if(isNewRowFlag(fm2dCrd,x,y,i,0) == true){
			if(wFP){
				showMessageWithCancel("Action Required",
				"Found New Row Flag");
			}//end if we should wait
			// new row flag
			currentLine++;
			rowFlag = NewRowFlag(11);
			if(f1){
				print(outputFileVar,currentLine + "\t" +
				dATS(1, rowFlag, "\t"));
			}//end if we're outputting files
			print(currentLine + "     " + dATS(1, rowFlag, "     "));
		}//end else if we have a new row flag
		else{
			// the bounding X for this cell
			thisBX = twoDArrayGet(fm2dCrd, x, y, i, 0);
			// the bounding Y for this cell
			thisBY = twoDArrayGet(fm2dCrd, x, y, i, 1);
			// the bounding width for this cell
			thisWidth = twoDArrayGet(fm2dCrd, x, y, i, 2);
			// the bounding height for this cell
			thisHeight = twoDArrayGet(fm2dCrd, x, y, i, 3);

			if(wFP){
				showMessageWithCancel("Action Required",
				"Coordinates Recieved");
			}//end if we should wait

			currentLine++;

			// add cell start
			startFlag = CellStartFlag(11);
			if(f1){
				print(outputFileVar, currentLine + "\t"
				+ dATS(1, startFlag, "\t"));
			}//end if we're outputting to the files
			print(currentLine + "     " + dATS(1, startFlag, "     "));
	
			// set the pattern for the window
			windowPattern = "temporary duplicate";
	
			// process the kernel
			processKernel(thisBX, thisBY, thisWidth,
			thisHeight, windowPattern, wFP, outputFileVar);
	
			// process the chalk
			processChalk(windowPattern, wFP, outputFileVar);
			// increment chalk counter
			chalkCounter++;
	
			// add the cell end
			currentLine++;
			endFlag = CellEndFlag(11);
			if(f1){
				print(outputFileVar, currentLine + "\t" +
				dATS(1, endFlag, "\t"));
			}//end if we're outputting to the files
			print(currentLine + "     " + dATS(1, endFlag, "     "));
			// close this duplicate
			close(windowPattern);
			if(wFP){
				waitForUser("Action Required", "Duplcate Closed");
			}//end if we should wait
		}//end else we do things normally
	}//end looping over coordinates

	if(f1 == true){
		File.close(outputFileVar);
	}//end if we need to close our file variable so we don't screw up the file
}//end processResults(fm2dCrd,x,y,lT,hT,mS1,mS2,col,f1,f2,wFP,fn1,fn2,od)

function isMissingCellFlag(d2A,xT,yT,x,y){ // TODO: Maybe Overhaul isMissingCellFlag
	// -1
	val = twoDArrayGet(d2A,xT,yT,x,y);
	if(val == -1) return true;
	else return false;
}//end 

function isNewRowFlag(d2A,xT,yT,x,y){ // TODO: Maybe overhaul isNewRowFlag
	// -2
	val = twoDArrayGet(d2A,xT,yT,x,y);
	if(val == -2) return true;
	else return false;
}//end 

/*
 * returns an array as a string
 */
function ArrayToString(array){
	return String.join(array, "");
}//end ArrayToString(array)

function dATS(n, a, c){
	// a is array, n is number of decimals, array to string
	outputString = "";
	for(i = 0; i < lengthOf(a); i++){
		outputString += d2s(a[i], n) + c;
	}//end looping over a
	return outputString;
}//end dATS(n, a)

////////////////// EXTRA FUNCTIONS ////////////////////////////

/*
 * 
 */
function makeBackup(appendation){
	// make backup in temp folder
	// figure out the folder path
	backupFolderDir = getDirectory("temp") + "imageJMacroBackup" + 
	File.separator;
	File.makeDirectory(backupFolderDir);
	backupFolderDir += "HVAC" + File.separator;
	// make sure the directory exists
	File.makeDirectory(backupFolderDir);
	// make file path
	filePath = backupFolderDir + "backupImage-" + appendation + ".tif";
	// save the image as a temporary image
	save(filePath);
}//end makeBackup()

/*
 * 
 */
function openBackup(appendation, shouldClose){
	// closes active images and opens backup
	// figure out the folder path
	backupFolderDir = getDirectory("temp") + "imageJMacroBackup" + 
	File.separator + "HVAC" + File.separator;
	// make sure the directory exists
	File.makeDirectory(backupFolderDir);
	// make file path
	filePath = backupFolderDir + "backupImage-" + appendation + ".tif";
	// close whatever's open
	if(shouldClose == true) close("*");
	// open our backup
	open(filePath);
}//end openBackup

/*
 * Gets all the info from the results window, storing it
 * in a 2d array. the columns argument should be the name of
 * all the columns in the results window
 */
function getAllResults(columns){ // TODO: update getAllResults
	// gets info from results window, storing it in 2d array
	rowNum = nResults;
	colNum = lengthOf(columns);
	// initialize output 2d array
	output = twoDArrayInit(rowNum, colNum);
	for(i = 0; i < rowNum; i++){
		for(j = 0; j < colNum; j++){
			twoDArraySet(output, rowNum, colNum,
			i, j, getResult(columns[j], i));
		}//end looping through each column
	}//end looping through each row
	
	return output;
}//end getAllResults(columns)

/*
 * saves the data results to the specified path
 */
function saveDataResultsArray(resultsArray, rowT, colT, path, columns){ // TODO: update saveDataResultsArray
	// saves data results to specified path
	fileVar = File.open(path);
	// print columns
	rowToPrint = "\t";
	for(i = 0; i < lengthOf(columns); i++){
		rowToPrint += columns[i] + "\t";
	}//end looping over column headers
	print(fileVar, rowToPrint);
	// print array contents
	for(i = 0; i < rowT; i++){
		rowToPrint = "" + (i+1) + "\t";
		for(j = 0; j < colT; j++){
			thisInd = twoDArrayGet(resultsArray, rowT, colT, i, j);
			rowToPrint = rowToPrint + d2s(thisInd, 2) + "\t";
		}//end looping over columns
		print(fileVar, rowToPrint);
	}//end looping over rows
	File.close(fileVar);
}//end saveDataResultsArray(resultsArray, rowT, colT, path)

/*
 * saves an array to a file. is more generic than saveDataResultsArray.
 * Parameter explanation: array=the array you want to save; rowT=the
 * length of the array's first dimension; colT=the length of the array's
 * second dimension; path=the path of your original image; headers=the
 * headers to display above the rows and columns; folder=whether or not
 * you want to save stuff in a new folder. This should be false or empty
 * if you don't want a new folder, or otherwise the name of the folder
 * you want to save stuff to; name=the name of the file you want
 * to save. Make sure this is a valid filename from the start, but
 * don't include the extension
 */
function saveRawResultsArray(array,rowT,colT,path,headers,folder,name){ // TODO: update saveRawResultsArray
	// saves array to specified path with other specifications
	// initialize variable for the file stream
	fileVar = saveRawResultsArrayIOHelper(path, folder, name);
	// print columns
	rowToPrint = "\t";
	for(i = 0; i < lengthOf(headers); i++){
		rowToPrint += headers[i] + "\t";
	}//end looping over column headers
	print(fileVar, rowToPrint);
	// print array contents
	for(i = 0; i < rowT; i++){
		rowToPrint = "" + (i+1) + "\t";
		for(j = 0; j < colT; j++){
			// value at this element
			thisInd = twoDArrayGet(array,rowT,colT,i,j);
			rowToPrint = rowToPrint + d2s(thisInd, 2) + "\t";
		}//end looping over columns
		print(fileVar, rowToPrint);
	}//end looping over rows
	File.close(fileVar);
}//end saveRawResultsArray(array,rowT,colT,path,headers,folder,name)

/*
 * Helper method for saveRawResultsArray()
 */
function saveRawResultsArrayIOHelper(path, folder, name){// TODO: update saveRawResultsArrayIOHelper
	// helper method for saveRawResultsArray
	// figure out our folder schenanigans
	if(folder != false && folder != ""){
		// base directory of the open file
		print("path:"); print(path);
		baseDirectory = File.getDirectory(path);
		// create path of new subdirectory
		baseDirectory += folder;
		print("base directory:"); print(baseDirectory);
		// make sure directory exists
		File.makeDirectory(baseDirectory);
		// add full filename to our new path
		baseDirectory = baseDirectory + File.separator;
		if(name == "" || lengthOf(name) <= 0){
			enteredName = saveRawResultsArrayIOHelperDialogHelper();
			baseDirectory = baseDirectory + enteredName + ".txt";
		}//end if we need to get a name from the user!
		else{
			baseDirectory = baseDirectory + name + ".txt";
			print("name:"); print(name);
			print("base directory:"); print(baseDirectory);
		}//end else we can proceed as normal
		// get the file variable and return it
		return File.open(baseDirectory);
	}//end if we're doing a new folder
	else{
		// base directory of the file
		fileBase = substring(path, 0,
		lastIndexOf(path, File.separator));
		// add separator if it was cut off
		if(endsWith(fileBase, File.separator) == false){
			fileBase += File.separator;
		}//end if we need to add separator back
		// get new name of the new file
		resultFilename = name;
		if(name == "" || lengthOf(name) <= 0){
			resultFilename = saveRawResultsArrayIOHelperDialogHelper();
		}//end if we need to get a new name from the user!
		return File.open(fileBase + resultFilename + ".txt");
	}//end else we don't need to mess with folders
}//end saveRawResultsArrayIOHelper(path, folder, name)

/*
 * A helper method for a helper method
 */
function saveRawResultsArrayIOHelperDialogHelper(){ // TODO: Update saveRawResultsArrayIOHelperDialogueHelper
	// a helper method for saveRawResultsArrayIOHelper
	Dialog.create("Enter File Name");
	Dialog.addMessage(
	"It seems that at an earlier point in this programs execution, \n" +
	"you entered a filename that was either invalid or improperly \n" +
	"passed. Please enter a plain filename without a path or file \n" +
	"extension here, so that I can save it properly.");
	Dialog.addString("Filename:", "log");
	Dialog.show();
	return Dialog.getString();
}//end saveRawResultsArrayIOHelperDialogHelper()

/*
 * Sets a value in a 2d array
 */
function twoDArraySet(array, rowT, colT, rowI, colI, value){
	// sets a value in a 2d array
	if((colT * rowI + colI) >= lengthOf(array)){
		return false;
	}//end if we are out of bounds
	else{
		array[colT * rowI + colI] = value;
		return true;
	}//end else we're fine to do stuff
}//end twoDArraySet(array, rowT, colT, rowI, colI, value)

/*
 * gets a value from a 2d array
 */
function twoDArrayGet(array, rowT, colT, rowI, colI){
	// gets a value from a 2d array
	return array[colT * rowI + colI];
}//end twoDArrayGet(array, rowT, colT, rowI, colI)
 
/*
 * creates a 2d array
 */
function twoDArrayInit(rowT, colT){
	// creates a 2d array
	return newArray(rowT * colT);
}//end twoDArrayInit(rowT, colT)

function twoDArraySwap(array,rowT,colT,rI1,rI2){
	tempArray = newArray(colT);
	for(ijk = 0; ijk < colT; ijk++){
		tempArray[ijk] = twoDArrayGet(array,rowT,colT,rI1,ijk);
		rIV = twoDArrayGet(array,rowT,colT,rI2,ijk);
		twoDArraySet(array,rowT,colT,rI1,ijk,rIV);
		twoDArraySet(array,rowT,colT,rI2,ijk,tempArray[ijk]);
	}//end looping over stuff
}//end twoDArraySwap(array,rowT,colT,rI1,rI2)

/*
 * Just returns an array that represents a new row flag. cols is 
 * the number of columns to include in the flag. It won't work 
 * if you don't have at least one column for the area. 
 * Recommended is 11
 */
function NewRowFlag(cols){// TODO: Update NewRowFlag
	// 121.0
	flagVals = newArray(121.0, 4.3,
	7.0, 45.0, 9.8, 90, 0.8, 1.6, 0.6, 1.0);
	size = cols;
	if(size < 1) size = 11;
	newRowFlag = newArray(cols);
	for(i = 0; i < cols && i < lengthOf(flagVals); i++){
		newRowFlag[i] = flagVals[i];
	}//end adding each arbitrary data point
	if(size > lengthOf(flagVals)){
		for(i = cols; i < lengthOf(newRowFlag); i++){
			newRowFlag[i] = "121.0";
		}//end looping over next indices of thing
	}//end if we don't have enough values
	return newRowFlag;
}//end NewRowFlag(cols)

/*
 * see NewRowFlag
 */
function CellStartFlag(cols){// TODO: Update CellStartFlag
	// 81.7
	flagVals = newArray(81.7, 3.5, 5.9, 37.2, 13.2, 7.8, 90.0, 0.7,
	1.7, 0.6, 1.0);
	size = cols;
	if(size < 1) size = 11;
	cellStartFlag = newArray(cols);
	cellStartFlag[0] = "81.7";
	for(i = 0; i < cols && i < lengthOf(flagVals); i++){
		cellStartFlag[i] = flagVals[i];
	}//end adding each arbitrary data point
	if(size > lengthOf(flagVals)){
		for(i = cols; i < lengthOf(cellStartFlag); i++){
			cellStartFlag[i] = "81.7";
		}//end looping over next indices of thing
	}//end if we don't have enough values
	return cellStartFlag;
}//end CellStartFlag(cols)

/*
 * see NewRowFlag
 */
function CellEndFlag(cols){ // TODO: Update CellEndFlag
	// 95.3
	flagVals = newArray(95.3, 3.9, 6.1, 39.8, 13.7, 8.8, 90.0, 0.8,
	1.6, 0.6, 1.0);
	size = cols;
	if(size < 1) size = 11;
	cellEndFlag = newArray(cols);
	cellEndFlag[0] = "95.3";
	for(i = 1; i < cols && i < lengthOf(flagVals); i++){
		cellEndFlag[i] = flagVals[i];
	}//end adding each arbitrary data point
	if(size > lengthOf(flagVals)){
		for(i = cols; i < lengthOf(cellEndFlag); i++){
			cellEndFlag[i] = "95.3";
		}//end looping over next indices of thing
	}//end if we don't have enough values
	return cellEndFlag;
}//end CellEndFlag(cols)

/*
 * Fixes the directory issues present with all the directory
 * functions other than getDirectory("home"), which seems to
 * be inexplicably untouched and therefore used as a basis
 * for other directories.
 */
function fixDirectory(directory){
	homeDirectory = getDirectory("home");
	homeDirectory = substring(homeDirectory, 0, lengthOf(homeDirectory) - 1);
	username = substring(homeDirectory, lastIndexOf(homeDirectory, File.separator)+1);
	userStartIndex = indexOf(homeDirectory, username);
	userEndIndex = lengthOf(homeDirectory);
	
	firstDirPart = substring(directory, 0, userStartIndex);
	//print(firstDirPart);
	thirdDirPart = substring(directory, indexOf(directory, File.separator, lengthOf(firstDirPart)));
	//print(thirdDirPart);
	
	fullDirectory = firstDirPart + username + thirdDirPart;
	return fullDirectory;
}//end fixDirectory(directory)

////////////////////// END OF EXTRA FUNCTIONS /////////////////
////////////////////// END OF PROGRAM DIALOG  /////////////////

// exit out of batch mode
if(useBatchMode){
	setBatchMode("exit and display");
}//end if we might as well just enter batch mode

//wait for user before closing stuff
if(arguments == ""){
	waitForUser("Program Completion Reached",
	"Macro will terminate after this message box has been closed.");
}//end if there are no arguments
run("Close All");
run("Clear Results");
if(isOpen("Results")){selectWindow("Results"); run("Close");}
if(isOpen("Log")){selectWindow("Log"); run("Close");}
if(shouldDisplayProgress){print(prgBarTitle,"\\Close");}
close("*");
doCommand("Close All");