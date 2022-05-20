/*
 * Author: Nicholas Sixbury
 * File: NS-MultiGridSeparation.ijm
 * Purpose: To process images with multiple grids by
 * breaking the image up into multiple images which
 * can then be processed separately.
 */

// Overview of process for getting grid boundaries
// 1. Get location of all the cells in the grids
// 2. Come up with some sort of algorithm for snaking through all the cells in order
// to group all the cells that belong to a particular grid together. Primarily, I was
// thinking of testing for adjacency, as cells that are in the same grid will have
// very similar locations after accounting for cell size. It might take some work in
// order to come up with an algorithm that is actually efficient, but I don't know
// when I'll ever get a chance to refactor things, so I'll have to spend some upfront
// time on figuring this out.
// 3. Once I have figured out groups which separate the cells from each grid, I'll need
// to come up with coordinates for the boundaries of the grids in terms of topmost,
// bottommost, rightmost, leftmost of the coordinates for the cells. Then I can
// extrapolate outwards a constant value from those boundaries in order to acquire
// some new boundaries from the entire grid.
// 4. From here, create regions of interest within the original picture, and then create
// copy images for each grid.
// 5. Now, for each grid, do some sort of shape analysis in order to determine if the
// grid needs to be flipped or rotated. I'll leave this up to the future me.
// 6. Once these new, edited images are exported, this macro will be done

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
// valid operating systems
validOSs = newArray("Windows 10", "Windows 7");
// chosen operating system
chosenOS = validOSs[0];

// get a filename of an image with multiple grids.
multiImg = File.openDialog("Please select an image with multiple grids.");
// open up the image
open(multiImg);
// get coordinates of all the cells in the grids
rawCellCoords = DynamicCoordGetter(true);
rawCellRows = nResults;
rawCellCols = rawCellRows / 4;
// do a bunch of processing to cut out the false positives

////////////////////////////////////////////////////////////////
////////////////////// END OF MAIN PROGRAM /////////////////////
////////////////// BEGINNING OF FUNCTION LIST //////////////////
////////////////////////////////////////////////////////////////
/*
 * Parameter Explanation: shouldWait specifies whether or
 * not the program will give an explanation to the user as it steps
 * through execution.
 */
function DynamicCoordGetter(shouldWait){
	// gets all the coordinates of the cells
	// save a copy of the image so we don't screw up the original
	makeBackup("coord");
	// horizontally flip the image so we have things alligned properly
	run("Flip Horizontally");
	if(shouldWait){
		showMessageWithCancel("Action Required",
		"Image has been flipped");
	}//end if we need to wait
	/*
	//save copy of our flipped image if we feel like it
	if(shouldOutputFlipped){
		newPth = File.getDirectory(chosenFilePath);
		newPth += "FlippedImages" + File.separator;
		File.makeDirectory(newPth);
		newPth += File.getNameWithoutExtension(chosenFilePath) + "-F.tif";
		save(newPth);
	}//end if we should output a flipped image
	*/
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
	run("Analyze Particles...", 
	"size=25-Infinity circularity=0.05-1.00 show=[Overlay Masks] " +
	"display exclude clear include");
	if(shouldWait){
		showMessageWithCancel("Action Required",
		"Scale and Measurements were set, so now " + 
		"we have detected what cells we can.");
	}//end if we need to wait
	// extract coordinate results from results display
	coordsArray = getCoordinateResults();
	// open the backup
	openBackup("coord", true);
	return coordsArray;
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
 * Gets all the info from the results window, storing it
 * in a 2d array. the columns argument should be the name of
 * all the columns in the results window
 */
function getAllResults(columns){
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
 * This function returns a 2d array of coordinates for all the particles
 * detected in particle analysis or whatever else. It needs to be able
 * to access the X, Y, Width, and Height columns from the results 
 * diplay, so please make sure to set those properly with Set
 * Measurements. Returns the coordinates in the order of X, Y, Width,
 * and Height, with the "row" index of the 2d array accessing a
 * particular coordinate, and the "column" index of the array accessing
 * a particular feature (X, Y, Width, or Height) of that coordinate.
 * It should be noted that the number of rows will be nResults and the
 * number of columns 4 for the array returned.
 */
function getCoordinateResults(){
	// gets coordinate results from results windows. Need bound rect
	// save result columns we want
	coordCols = newArray("BX","BY","Width","Height");
	// first dimension length
	rowNum = nResults;
	// second dimension length
	colNum = lengthOf(coordCols);
	// initialize 2d array
	coords = twoDArrayInit(rowNum, colNum);
	// populate array with data
	for(i = 0; i < rowNum; i++){
		for(j = 0; j < colNum; j++){
			twoDArraySet(coords, rowNum, colNum, i, j,
			getResult(coordCols[j], i));
		}//end looping through coord props
	}//end looping through each coord
	return coords;
}//end getCoordinateResults()

/*
 * saves the data results to the specified path
 */
function saveDataResultsArray(resultsArray, rowT, colT, path, columns){
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
function saveRawResultsArray(array,rowT,colT,path,headers,folder,name){
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
function saveRawResultsArrayIOHelper(path, folder, name){
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
function saveRawResultsArrayIOHelperDialogHelper(){
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
