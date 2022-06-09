/*
 * Author: Nicholas Sixbury
 * File: NS-MultiGridSeparation.ijm
 * Purpose: To process images with multiple grids by
 * breaking the image up into multiple images which
 * can then be processed separately.
 */

// Overview of process for getting grid boundaries
// 1. Flip and rotate the image so that each of the grids is vertical. We'll
// just assume that the grid is in a particular configuration.
// 2. Use particle analysis to find big ol' strips of cells in each grid
// 3. Group those strips together in order to find the bounds of each grid.
// 4. Create duplicate images from the bounds of each grid.
// 5. Export the images

// Additional things that should be added
// 1. Command line options/parameters in order to allow other macros to use this macro
// like a function.
// 2. A fancy dialog box/qol features in the event that the macro isn't opened from
// somewhere else.

// Things that should be added in things that call this macro
// 1. Some sort of function in order to detect if a particular image has multiple grids.
// One way that I envision this happening would be if the original macro or whatever
// use a cell-detection method in order to count how many cells are present. In this case,
// if the number of cells detected after normalization are above a certain constant, then
// we can hand off the task of breaking up the image to this macro. This could work nice
// with the progress bar, as when new images are obtained from such a method, then we can
// get rid of the multi-grid image, add the new images to the end of our queue, and then
// continue with the next image. In this way, when processing a folder of multi-grid
// images, we'll blow through all the multi-grid images quickly before going into the
// process of actually processing each individual grid. The images obtained from the
// multi-grid image should also be outputted somewhere so that the user can view them.

////////////////////////////////////////////////////////////////
////////////////// BEGINNING OF MAIN PROGRAM ///////////////////
//// STEP 0: DIALOG and INITIALIZATION
// valid operating systems
validOSs = newArray("Windows 10", "Windows 7");
// chosen operating system
chosenOS = validOSs[0];
// just a debug switch
debugMessages = true;
// whether or not we'll use batch mode, which really speeds things up
useBatchMode = false;
// all the valid selection methods we might use
selectionMethods = newArray("Single File", "Multiple Files", "Directory", "Multiple Directories");
// the selection method we're actually going with
selectionMethod = selectionMethods[0];

// whether or not we should output separated images to a new subdirectory
outputNewDirectory = true;
// the filetypes that are allowed in directory selection
allowedFiletypes = newArray(".tif");
// files whose path contains one of these will be ignored by directory selection
forbiddenStrings = newArray("-Fx","-fA2","-F","-Skip");

showDialog();

// read new values from dialog box
// first line
selectionMethod = Dialog.getChoice();
chosenOS = Dialog.getChoice();
// second line
useBatchMode = Dialog.getCheckbox();
debugMessages = Dialog.getCheckbox();
// third line
outputNewDirectory = Dialog.getCheckbox();
// fourth and fifth lines
allowedFiletypes = split(Dialog.getString(), ",");
forbiddenStrings = split(Dialog.getString(), ",");

// save the settings from the dialog for the next execution
saveDialogConfig();

// get the images we're supposed to process
imgToPrc = getFilepaths(selectionMethod);

if(useBatchMode == true){
	setBatchMode("hide");
}//end if we're using batch mode

// loop over all the images to process
for(i = 0; i < lengthOf(imgToPrc); i++){
	// open up the image
	open(imgToPrc[i]);
	
	//// STEP 1: TRANSFORM (flip and rotate) the image to what we expect
	nsTransformImg();
	
	//// STEP 2: Find a bunch of CELL STRIPS in the grid
	// adds all the cells we could find to the roi manager
	DynamicCoordGetter(debugMessages);
	
	//// STEP 3: GROUP the strips together by the grid they appear to belong to
	// uses the rois in the roi manager
	serializedGroups = groupGrids();
	// deserialize the bounds
	numberOfGrids = lengthOf(serializedGroups);
	
	//// STEP 4: Create DUPLICATE images from the supposed BOUNDS of each grid
	imgKeys = separateGrids(serializedGroups);
	
	//// STEP 5: EXPORT each image to where it needs to go
	// loop over each image we want to open
	for(j = 0; j < lengthOf(imgKeys); j++){
		// open the current image
		openBackup(imgKeys[j], false);
		
		// save the image of one grid somewhere near the original
		exportImage(imgToPrc[i], "g" + (j+1));
		
		// close the current image
		close();
	}//end looping over separated images
}//end looping over all the images to process

// exit batch mode if we were in it
if(is("Batch Mode")){
	setBatchMode("exit and display");
}//end exiting from batch mode


////////////////////////////////////////////////////////////////
////////////////////// END OF MAIN PROGRAM /////////////////////
////////////////// BEGINNING OF FUNCTION LIST //////////////////
////////////////////////////////////////////////////////////////

function exportImage(originalFile, imageSuffix){
	// tries to export part of a multi-grid image
	// the image we want to export should be already open
	
	// get the original filepath of the image, minus file name and extension
	baseDir = substring(originalFile, 0, lastIndexOf(originalFile, File.separator) + 1);
	originalName = substring(originalFile, lastIndexOf(originalFile,
		File.separator), lastIndexOf(originalFile, "."));
	
	// figure out the location to put the image
	if(outputNewDirectory == true){
		// create folder name with original image name + suffix of separated
		newDirName = originalName + " separated";
		// add to end of baseDir and create new directory
		newDir = baseDir + newDirName + File.separator;
		File.makeDirectory(newDir);
		// change baseDir to newDir so that image gets added to it
		baseDir = newDir;
	}//end if we need to create new directory and append to path
	
	// add an appropriate suffix to the image name
	imagePath = baseDir + originalName + "-" + imageSuffix + ".tif";
	
	// once we have a directory, save the image there
	save(imagePath);
}//end exportImage

/*
 * Reads prior configuration from file, creates dialog, updates variables
 */
function showDialog(){
	// read all the junk from the config file
	serializationPath = serializationDirectory();
	// a temporary variable required because of ImageJ's syntactic bitterness
	temp = "\0";
	if(File.exists(serializationPath)){
		// get each line from the file
		lines = split(File.openAsString(serializationPath), "\n");
		for(i = 0; i < lengthOf(lines); i++){
			currentLine = lines[i];
			if(lengthOf(currentLine) >= 18){
				if(substring(currentLine, 0, 18) == "outputNewDirectory"){
					temp = split(currentLine, "=");
					temp = temp[1];
					outputNewDirectory = parseInt(temp);
				}//end if this line has the outputNewDirectory information
			}//end if 
			if(lengthOf(currentLine) >= 16){
				if(substring(currentLine, 0, 16) == "allowedFiletypes"){
					listing = substring(currentLine, 18, lengthOf(currentLine)-1);
					allowedFiletypes = split(listing, "|");
				}//end if this line has the allowed file types information
				else if(substring(currentLine, 0, 16) == "forbiddenStrings"){
					listing = substring(currentLine, 18, lengthOf(currentLine) - 1);
					forbiddenStrings = split(listing, "|");
				}//end if this line has the forbidden strings information
			}//end if
			if(lengthOf(currentLine) >= 15){
				if(substring(currentLine, 0, 15) == "selectionMethod"){
					temp = split(currentLine, "=");
					selectionMethod = temp[1];
				}//end if this line has the selection method information
			}//end if 
			if(lengthOf(currentLine) >= 13){
				if(substring(currentLine, 0, 13) == "debugMessages"){
					temp = split(currentLine, "=");
					temp = temp[1];
					debugMessages = parseInt(temp);
				}//end if this line has the debugging message information
			}//end if 
			if(lengthOf(currentLine) >= 12){
				if(substring(currentLine, 0, 12) == "useBatchMode"){
					temp = split(currentLine, "=");
					temp = temp[1];
					useBatchMode = parseInt(temp);
				}//end if this line has the useBatchMode information
			}//end if 
			if(lengthOf(currentLine) >= 8){
				if(substring(currentLine, 0, 8) == "chosenOS"){
					temp = split(currentLine, "=");
					chosenOS = temp[1];
				}//end if this line has the chosen operating system information
			}//end if 
		}//end looping over each line of the file
	}//end if the config file exists
	
	// actually build the dialog now
	Dialog.create("Multi-Grid-Separation Macro Options");
	// first line
	Dialog.addChoice("Selection Method", selectionMethods, selectionMethod);
	Dialog.addToSameRow();
	Dialog.addChoice("Operating System", validOSs, chosenOS);
	// second line
	Dialog.addCheckbox("Batch Mode", useBatchMode);
	Dialog.addToSameRow();
	Dialog.addCheckbox("Debugging Messages", debugMessages);
	// third line
	Dialog.addCheckbox("Output new Directory", outputNewDirectory);
	// fourth + fifth line
	Dialog.addMessage("The following options are used when selecting files in Directory Selection Mode.");
	Dialog.addString("Allowed Filetypes", String.join(allowedFiletypes, ","), 30);
	Dialog.addString("Forbidden Strings", String.join(forbiddenStrings, ","), 30);
	// actually make the window show up
	Dialog.show();
}//end showDialog()

/*
 * Saves the settings read from the dialog in a configuration file
 */
function saveDialogConfig(){
	serializationPath = serializationDirectory();
	fileVar = File.open(serializationPath);
	// write all the important variables to the file
	print(fileVar, String.join(newArray("chosenOS", chosenOS), "="));
	print(fileVar, String.join(newArray("debugMessages", debugMessages), "="));
	print(fileVar, String.join(newArray("useBatchMode", useBatchMode), "="));
	print(fileVar, String.join(newArray("selectionMethod", selectionMethod), "="));
	print(fileVar, String.join(newArray("outputNewDirectory", outputNewDirectory), "="));
	// now for the annoying ones
	allowedFileTypesStr = String.join(allowedFiletypes, "|");
	print(fileVar, String.join(newArray("allowedFiletypes", "[" + allowedFileTypesStr + "]"), "="));
	forbiddenStringsStr = String.join(forbiddenStrings, "|");
	print(fileVar, String.join(newArray("forbiddenStrings", "[" + forbiddenStringsStr + "]"), "="));
}//end saveDialogConfig()

function serializationDirectory(){
	// generates a directory for serialization
	macrDir = getDirectory("macros");
	macrDir += "Macro-Configuration/";
	File.makeDirectory(macrDir);
	macrDir += "MultiGridSeparationConfig.txt";
	return macrDir;
}//end serializationDirectory()

/*
 * Transforms the current image in order to make the grids look
 * vertical + the right orientation (flipped horizontally)
 */
function nsTransformImg(){
	run("Flip Horizontally");
	run("Rotate 90 Degrees Right");
}// end nsTransformImg()

/**
 * Separates the grids by creating a separate image for each grid,
 * based on the bounds of the groups. Does a little deserialization.
 */
function separateGrids(groupBounds){
	// Value for how thick we think the grid is, added to group bounds
	gridThickness = 4 * 11.5;
	// get the dimensions of overall image
	dims = imgDimensions();
	// get title of current image
	overallTitle = getTitle();
	// list of snapshot keys for the images
	imageKeys = newArray(lengthOf(groupBounds));
	// create an image for each grid
	for(i = 0; i < lengthOf(groupBounds); i++){
		// deserialize the bounds of this group
		bounds = split(groupBounds[i], ":");
		// prevent us from processing invalid input
		if(lengthOf(bounds) <= 0){
			waitForUser("Something wrong with bounds", groupBounds[i]);
			continue;
		}//end if something went wrong
		// get x and width for group
		imgX = parseFloat(bounds[0]) * 11.5;
		imgW = (parseFloat(bounds[1]) * 11.5) - (parseFloat(bounds[0]) * 11.5);
		// compensate for thickness
		imgX -= gridThickness;
		imgW += (2 * gridThickness);
		// get y and height for group
		imgY = 0;
		imgH = dims[1];
		// make sure we aren't out of bounds
		imgX = Math.max(imgX, 0);
		imgX = Math.min(imgX, dims[0]);
		imgW = Math.max(imgW, 0);
		imgW = Math.min(imgW, dims[0]);
		// create the selection
		makeRectangle(imgX, imgY, imgW, imgH);
		// duplicate and save selection
		imgKey = "dup" + i;
		imageKeys[i] = imgKey;
		run("Duplicate...", imgKey);
		makeBackup(imgKey);
		// close the duplicated image (should be on top)
		close();
	}//end looping over each group
	
	// now that we've gotten our images, close the original
	close("*");
	roiManager("reset");
	if(isOpen("ROI Manager")){selectWindow("ROI Manager"); run("Close");}
	return imageKeys;
}//end separateGrids(groupBounds)

/**
 * Returns array with elements:
 * [0] : width
 * [1] : height
 */
function imgDimensions(){
	tempWidth = -1;
	tempHeight = -1;
	temp = -2;
	getDimensions(tempWidth, tempHeight, temp, temp, temp);
	return newArray(tempWidth, tempHeight);
}//end imgDimensions()

/**
 * Groups the cell strips together based on x-location
 */
function groupGrids(){
	// number of cells
	cellSum = roiManager("count");
	// parallel arrays of [count, x lower bound, x upper bound]
	/*
	 * One complication of using imagej is that in order to avoid janky
	 * multi-dimensional arrays, we might just directly call another function
	 * at the end of this one in order to avoid scraping the information out
	 * of an R^n array
	 */
	gridCounts = newArray(0); // kinda doesn't get used ¯\_(ツ)_/¯
	gridLowBound = newArray(0); // just uses x
	gridUpBound = newArray(0); // uses x + width
	// iterate over each cell in the grid
	for(i = 0; i < cellSum; i++){
		// only proceed if the current grid hasn't been assigned
		roiManager("select", i);
		if(Roi.getGroup() == 0){
			// figure out a group to assign it to based off of x-position
			 if(lengthOf(gridCounts) == 0){
			 	// debug message
			 	if(debugMessages){
			 		waitForUser("First roi","First roi, making new grid.");
			 	}//end if displaying debugging messages
			 	// groups are empty, so we can recreate arrays
			 	gridCounts = newArray(1);
			 	gridLowBound = newArray(1);
				gridUpBound = newArray(1);
				// get information about current roi
				roiBounds = getRoiXBounds();
				// update parallel arrays with new roi
				gridCounts[0] = 1;
				gridLowBound[0] = roiBounds[0];
				gridUpBound[0] = roiBounds[1];
				// update group number of current roi
				Roi.setGroup(1);
			 }//end if we need to make a new group
			 else{
			 	for(j = 0; j < lengthOf(gridCounts); j++){
			 		// reference to make referring to group number easy
			 		groupNum = j+1;
			 		// tolerance for adjacency between edges of roi and group
			 		adjacencyTol = 6;
			 		// get information about current roi
			 		roiBounds = getRoiXBounds();
			 		// find out where the roi stands in relation to this group
			 		boundBools = locationRelation(
			 			gridLowBound[j],gridUpBound[j],adjacencyTol,roiBounds[0],roiBounds[1]);
			 		insideBoundsBool = boundBools[0];
			 		overlapBool = boundBools[1];
			 		adjacentBool = boundBools[2];
			 		
			 		// we should now know how to handle the current roi + variable management
			 		if(insideBoundsBool == true){
			 			// debugging functions
			 			if(debugMessages == true){
				 			sb = "roi " + (i+1) + " bounds " + roiBounds[0] + ", " +
				 			roiBounds[1] + " within with group bounds " +
				 			gridLowBound[j] + ", " + gridUpBound[j];
				 			waitForUser("Roi Inside of group bounds", sb);
			 			}//end if we should show debugging messages
			 			// add roi to current group without changing bounds
			 			gridCounts[j]++;
			 			Roi.setGroup(groupNum);
			 		}//end if the roi is fully within the bounds
			 		else if(overlapBool == true){
			 			// debugging functions
			 			if(debugMessages == true){
				 			sb = "roi " + (i+1) + " bounds " + roiBounds[0] + ", " +
				 			roiBounds[1] + " overlaps with group bounds " +
				 			gridLowBound[j] + ", " + gridUpBound[j];
				 			waitForUser("Roi overlapping with group", sb);
			 			}//end if we should show debugging messages
			 			// add roi to current group, changing one of the bounds
			 			gridLowBound[j] = Math.min(gridLowBound[j], roiBounds[0]);
			 			gridUpBound[j] = Math.max(gridUpBound[j], roiBounds[1]);
			 			// update group number of roi
			 			Roi.setGroup(groupNum);
			 		}//end else if roi is overlapping with the bounds
			 		else if(adjacentBool == true){
			 			// debugging functions
			 			if(debugMessages == true){
				 			sb = "roi " + (i+1) + " bounds " + roiBounds[0] + ", " +
				 			roiBounds[1] + " is adjacent to group bounds " +
				 			gridLowBound[j] + ", " + gridUpBound[j];
				 			waitForUser("Roi is adjacent to a group", sb);
			 			}//end if we should show debugging messages
			 			// add roi to current group, expanding bounds to cover roi
			 			gridUpBound[j] = Math.max(gridUpBound[j], roiBounds[1]);
			 			gridLowBound[j] = Math.min(gridLowBound[j], roiBounds[0]);
			 			// update group number of roi
			 			Roi.setGroup(groupNum);
			 		}//end else if roi is not overlapping but adjacent
			 		
			 		if(insideBoundsBool || overlapBool || adjacentBool){
			 			continue;
			 		}//end if we have found a group for this roi already
			 		
			 		// if roi doesn't fit in this group, it might fit in next group
			 	}//end looping over the groups that we have
			 	if(Roi.getGroup() == 0){
			 		// debug messages
			 		if(debugMessages){
			 			sb = "Roi " + (i+1) + " bounds " + roiBounds[0] + ", " +
				 		roiBounds[1] + " must be put in a new group\n";
				 		// add coordinates of current groups
				 		sb += "Current group coordinates added to log.";
				 		print("\\Clear");
				 		print("Adding bounds of current groups.");
				 		for(k = 0; k < lengthOf(gridCounts); k++){
				 			print("Group " + (k+1) + " has bounds " +
				 			gridLowBound[k] + ", " + gridUpBound[k]);
				 		}//end looping over each group
				 		waitForUser("No group found, must put roi in new group",sb);
			 		}//end if displaying debugging messages
			 		// we'll need to add current roi to its own group
			 		// grap some information needed for updating things
			 		roiBounds = getRoiXBounds();
			 		// our parallel arrays have stuff in them, so we need to append
			 		// concattenation will also update arrays with new values
			 		gridCounts = Array.concat(gridCounts,1);
			 		gridLowBound = Array.concat(gridLowBound,roiBounds[0]);
			 		gridUpBound = Array.concat(gridUpBound,roiBounds[1]);
			 		// update group number of current roi
			 		Roi.setGroup(lengthOf(gridCounts));
			 	}//end if group still hasn't been assigned to roi
			 }//end else we need to cycle through groups in order to check bounds
		}//end if we need to assign this grid
	}// end iterating over each cell in the grid many times
	
	// now that we've assigned our groups, we'll need to find out if any need to be merged
	for(i = 0; i < lengthOf(gridCounts); i++){
		groupNum = i+1;
		// see if another group is close to this one
		for(j = i+1; j < lengthOf(gridCounts); j++){
			// find out where grids stand in relation to each other
			boundBools = locationRelation(gridLowBound[i],
			gridUpBound[i],6,gridLowBound[j],gridUpBound[j]);
			if(boundBools[0] || boundBools[1]){
				// merge groups i and j I guess
				if(debugMessages){
					print("Group " + groupNum + ": " + gridLowBound[i] + ", " + gridUpBound[i]);
					print("Group " + (j+1) + ": " + gridLowBound[j] + ", " + gridUpBound[j]);
					waitForUser("locationRelation", String.join(boundBools));
				}//end if we're doing debugging messages
				// loop over cells, if they're in group j, then set them to group i
				for(k = 0; k < cellSum; k++){
					roiManager("select", k);
					if(Roi.getGroup() == j+1){
						Roi.setGroup(i+1);
					}//end if roi in group to be merged
				}//end looping over all the cells
				// set bounds of group j to -1,-1, count of -1
				gridCounts[j] = -1;
				gridLowBound[j] = -1;
				gridUpBound[j] = -1;
			}//end if groups should be merged
		}//end looping over over groups for group
	}//end looping over the groups
	
	// create a sorted array of serialized bound information for each group
	serializedGroups = newArray(0);
	rankedGroups = Array.rankPositions(gridLowBound);
	for(i = 0; i < lengthOf(gridCounts); i++){
		j = rankedGroups[i];
		if(gridCounts[j] != -1){
			// add upper and lower bound to buffer
			thisGroup = String.join(newArray(gridLowBound[j], gridUpBound[j]), ":");
			serializedGroups = Array.concat(serializedGroups,thisGroup);
		}//end if this group has rois
	}//end looping over the groups
	return serializedGroups;
}//end groupGrids

/**
 * Parameter Explanation
 * obj1Low : Lower x bound of first object
 * obj1Up : Upper x bound of first object
 * adjTol : applied to obj1, closeness required for obj2 to be adjacent
 * obj2Low : Lower x bound of second object
 * obj2Up : Upper x bound of second object
 */
function locationRelation(obj1Low,obj1Up,adjTol,obj2Low,obj2Up){
	insideBoundsBool = false;
	overlapBool = false;
	adjacencyBool = false;
	if(obj1Low <= obj2Low && obj1Up >= obj2Up)
	{insideBoundsBool = true;}
	if(
		((obj1Low <= obj2Up) && (obj1Up >= obj2Up))
							 ||
		((obj1Up >= obj2Low) && (obj1Low <= obj2Low))
	)
	{overlapBool = true;}
	if(
		( ((obj1Up + adjTol) >= obj2Low) && (obj1Up <= obj2Low) )
										 ||
		( ((obj1Low - adjTol) <= obj2Up) && (obj1Low >= obj2Up) )
	)
	{adjacencyBool = true;}
	return newArray(insideBoundsBool, overlapBool, adjacencyBool);
}//end locationRelation(obj1Low,obj1Up,adjTol,obj2Low,obj2Up)

/*
 * Returns length 2 array with x and (x+width) of currently selected roi
 * tries to automatically convert things to mm by dividing by 11.5
 */
function getRoiXBounds(){
	roiX = -1;
	roiWidth = -1;
	temp = -1;
	Roi.getBounds(roiX, temp, roiWidth, temp);
	return newArray(roiX / 11.5, (roiX + roiWidth) / 11.5);
}//end getRoiXBounds

function timeToString(mSec){
	floater = d2s(mSec, 0);
	floater2 = parseFloat(floater);
	floater3 = floater2 / 1000;
	return floater3;
}//end timeToString()

/*
 * Given a method of selecting files, prompts user to select files, 
 * and then returns an array of file paths
 */
function getFilepaths(fileSelectionMethod){
	// array to store file paths in
	filesToPrc = newArray(0);
	if(fileSelectionMethod == "Single File"){
		filesToPrc = newArray(1);
		filesToPrc[0] = File.openDialog("Please choose a file to process");
	}//end if we're just processing a single file
	else if(fileSelectionMethod == "Multiple Files"){
		numOfFiles = getNumber("How many files would you like to process?", 1);
		filesToPrc = newArray(numOfFiles);
		for(i = 0; i < numOfFiles; i++){
			filesToPrc[i] = File.openDialog("Please choose file " + (i+1) + 
			"/" + (numOfFiles) + ".");
		}//end looping to get all the files we need
	}//end if we're processing multiple single files
	else if(fileSelectionMethod == "Directory"){
		chosenDirectory = getDirectory("Please choose a directory to process\n"
		+"(Automatically processes subdirectories)");
		// gets all the filenames in the directory path
		filesToPrc = getValidFilePaths(chosenDirectory, forbiddenStrings);
	}//end if we're processing an entire directory
	else if(fileSelectionMethod == "Multiple Directories"){
		numOfDirs = getNumber("How many Directories would you like to select?\n"+
		"(Please note that all subdirectories will be automatically processed.)", 1);
		// get a list of the directories
		tempDirList = newArray(numOfDirs);
		for(i = 0; i < numOfDirs; i++){
			tempDirList[i] = getDirectory("Please choose directory "
			+ (i+1) + "/" + numOfDirs);
		}//end getting numOfDirs directories from the user
		// assemble list of all the files in each of those directories
		for(i = 0; i < lengthOf(tempDirList); i++){
			tempFileList = getValidFilePaths(tempDirList[i], forbiddenStrings);
			filesToPrc = Array.concat(filesToPrc,tempFileList);
		}//end looping over each directory to get
	}//end if we're processing multiple entire directories
	return filesToPrc;
}//end getFilepaths(fileSelectionMethod)

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
			if(!contains(allowedFiletypes, fileExtension)){
				booleanArray[i] = false;
			}//end if wrong file extension
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
 * Parameter Explanation: shouldWait specifies whether or
 * not the program will give an explanation to the user as it steps
 * through execution.
 */
function DynamicCoordGetter(shouldWait){
	// gets all the coordinates of the cells
	// save a copy of the image so we don't screw up the original
	makeBackup("coord");
	// Change image to 8-bit grayscale to we can set a threshold
	run("8-bit");
	// set threshold to only detect the cells
	// threshold we set is 0-200 as of 5/23/2022 11:18
	if(chosenOS == validOSs[0]){
		setThreshold(0, 200);
	}//end if we're on Windows 10
	else if(chosenOS == validOSs[1]){
		setThreshold(0, 200);
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
	run("Analyze Particles...", 
	"size=60-Infinity circularity=0.05-1.00 show=Nothing " +
	"exclude clear include add");
	if(shouldWait){
		showMessageWithCancel("Action Required",
		"Scale and Measurements were set, so now " + 
		"we have detected what cells we can.");
	}//end if we need to wait
	// extract coordinate results from results display
	// open the backup
	openBackup("coord", true);
	setOption("Show All", true);
}//end DynamicCoordGetter(shouldWait)

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
 * sets a value in a 3d array
 */
function threeDArraySet(array,yT,zT,x,y,z,val){
	// sets a value in a 3d array
	if((x * yT * zT + y * zT + z) >= lengthOf(array)){
		return false;
	}//end if out of bounds
	else{
		array[x * yT * zT + y * zT + z] = val;
		return true;
	}//end else we did fine.
}//end threeDArraySet(array,xT,yT,zT,x,y,z,val)

/*
 * gets a value from a 3d array
 */
function threeDArrayGet(array,yT,zT,x,y,z){
	// gets a value from a 3d array
	return array[x * yT * zT + y * zT + z];
}//end threeDArrayGet(array,xT,yT,zT,x,y,z)

/*
 * creates a 3d array
 */
function threeDArrayInit(xT, yT, zT){
	// creates a 3d array
	return newArray(xT * yT * zT);
}//end threeDArrayInit(xT, yT, zT)

/*
 * swaps two indices of a 3d array
 */
function threeDArraySwap(array,yT,zT,x1,y1,z1,x2,y2,z2){
	// swaps two indices of a 3d array
	arbitraryTempNewVarName1 = threeDArrayGet(array,yT,zT,x1,y1,z1);
	arbitraryTempNewVarName2 = threeDArrayGet(array,yT,zT,x2,y2,z2);
	threeDArraySet(array,yT,zT,x2,y2,z2,arbitraryTempNewVarName1);
	threeDArraySet(array,yT,zT,x1,y1,z1,arbitraryTempNewVarName2);
}//end threeDArraySwap(array,yT,zT,x1,y1,z1,x2,y2,z2)

/*
 * swaps two parts of a 3d array
 */
function threeDArraySwap(array,yT,zT,x1,y1,x2,y2){
	// swaps two parts of a 3d array
	// initialize arrays of what we've got
	index1 = newArray(zT);
	index2 = newArray(zT);
	// figure out values and swap them
	for(qq = 0; qq < zT; qq++){
		arbitraryTempNewVarName1 = threeDArrayGet(array,yT,zT,x1,y1,qq);
		arbitraryTempNewVarName2 = threeDArrayGet(array,yT,zT,x2,y2,qq);
		threeDArraySet(array,yT,zT,x2,y2,qq,arbitraryTempNewVarName1);
		threeDArraySet(array,yT,zT,x1,y1,qq,arbitraryTempNewVarName2);
	}//end creating array from z
}//end threeDArraySwap(array,yT,zT,x1,y1,x2,y2)

////////////////////////////////////////////////////////////////
////////////////////// END OF FUNCTION LIST ////////////////////
////////////////////// BEGINNING OF THE END ////////////////////
////////////////////////////////////////////////////////////////

waitForUser("End of macro", "When this message box is closed, the macro will terminate.");
run("Close All");
if(isOpen("Log")){selectWindow("Log"); run("Close");}
roiManager("reset");
if(isOpen("ROI Manager")){selectWindow("ROI Manager"); run("Close");}
