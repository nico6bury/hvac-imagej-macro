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

// get a filename of an image with multiple grids.
multiImg = File.openDialog("Please select an image with multiple grids.");
// open up the image
open(multiImg);

//// STEP 1: TRANSFORM the image to what we expect based on what we expect
transformImg();

//// STEP 2: Find a bunch of CELL STRIPS in the grid
// adds all the cells we could find to the roi manager
DynamicCoordGetter(false);

//// STEP 3: GROUP the strips together by the grid they appear to belong to
// uses the rois in the roi manager
groupGrids();

//// STEP 4: Create DUPLICATE images from the supposed BOUNDS of each grid


//// STEP 5: EXPORT each image to where it needs to go


////////////////////////////////////////////////////////////////
////////////////////// END OF MAIN PROGRAM /////////////////////
////////////////// BEGINNING OF FUNCTION LIST //////////////////
////////////////////////////////////////////////////////////////
/*
 * Transforms the current image in order to make the grids look
 * vertical + the right orientation (flipped horizontally)
 */
function transformImg(){
	run("Flip Horizontally");
	run("Rotate 90 Degrees Right");
}// end transformImg()

/**
 * Groups the cell strips together based on probably grid location
 * helper functions:
 * isAdjacent(i, j)
 */
function groupGrids(){
	// number of cells
	cellSum = roiManager("count");
	// parallel arrays of [x lower bound, x upper bound, count]
	gridCounts = newArray(0);
	gridLowBound = newArray(0);
	gridUpBound = newArray(0);
	// counter for setting up loop guard
	numAssigned = 0; // might not be used ¯\_(ツ)_/¯
	// iterate over each cell in the grid
	for(i = 0; i < cellSum; i++){
		// only proceed if the current grid hasn't been assigned
		roiManager("select", i);
		if(Roi.getGroup() == 0){
			// figure out a group to assign it to based off of x-position
			/*
			 * Okay, so figuring out which group to assign the cell will
			 * be sorta difficult. If we don't have any groups, then we
			 * should create a new group by adding our current one to
			 * that new group. Otherwise, if we want to assign the roi
			 * to a new group, we should cycle through the current groups.
			 * If we find a group that the roi ether fits inside of or is
			 * very close to, then we should put this roi there. Otherwise,
			 * if it doesn't fit into any group, then we should probably
			 * yeet the grid into a new group. Now, there is an immediate
			 * problem with this method. If a group has very few roi in it
			 * when we check it, it's possible that our roi would eventually
			 * fit into the group, but it just doesn't fit yet. In that case,
			 * we're almost guarenteed that for a lot of images, we'll end up
			 * with overlapping groups. This is kinda a problem. As a result,
			 * we'll need to have a separate function with the purpose of
			 * merging groups that overlap. It would also be good to have some
			 * sort of debug function which allows you to flatten the rois which
			 * belong to the same group together, as that way we can directly see
			 * the regions on the image, which will be useful for debugging.
			 */
		}//end if we need to assign this grid
	}// end iterating over each cell in the grid many times
}//end groupGrids

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
	coordsArray = getCoordinateResults();
	// open the backup
	openBackup("coord", true);
	setOption("Show All", true);
	return coordsArray;
}//end DynamicCoordGetter(shouldWait)

// hold off on this one as well :-(
function deleteEdges(d2Array, xT, yT){
	/* deletes elements in 2d array which touch the edges of the image.
	 returns new array. This function is meant to work on an array of cell
	 coords, not an array of seed coords.*/
	 // tolerance for left x
	 xTolL = 5;
	 // tolerance for right x
	 xTolR = 5;
	 // tolerance for top y
	 yTolUp = 5;
	 // tolerance for bottom y
	 yTolBot = 5;
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
	 for(i = 0; i < xT; i++){
		// retrieve x,y,width,height for this index
	 	d2x = twoDArrayGet(d2Array, xT, yT, i, 0);
	 	d2y = twoDArrayGet(d2Array, xT, yT, i, 1);
	 	d2w = twoDArrayGet(d2Array, xT, yT, i, 2);
	 	d2h = twoDArrayGet(d2Array, xT, yT, i, 3);
	 	// test for top left corner
	 	if(abs(d2x - 0) < xTolL){
	 		// keep track of index of corner
	 		badInd = Array.concat(badInd,i);
	 	}//end if we found left edge
	 	else if(abs(d2y - 0) < yTolUp){
	 		// keep track of index of corner
	 		badInd = Array.concat(badInd,i);
	 	}//end else if we found the top edge
	 	else if(abs((d2y+d2h) - imgHeight) < yTolBot){
	 		// keep track of index of corner
	 		badInd = Array.concat(badInd,i);
	 	}//end else if we found the bottom edge
	 	else if(abs((d2x+d2w) - imgWidth) < xTolR){
	 		// keep track of index of corner
	 		badInd = Array.concat(badInd,i);
	 	}//end else if we found the right edge
	 }//end looping over d2Array
	 // now that we know how many corners there are, we can
	 // create an array to hold the non-corners
	 xT2 = (lengthOf(d2Array) / yT) - lengthOf(badInd);
	 d2Array2 = twoDArrayInit(xT2, yT);
	 // create a reference variable for next index in d2Array
	 nxtInd = 0;
	 // add all the non-corner indexes to the new array
	 for(i = 0; i < xT; i++){
	 	if(!contains(badInd, i)){
	 		for(j = 0; j < yT; j++){
	 			temp = twoDArrayGet(d2Array, xT, yT, i, j);
	 			twoDArraySet(d2Array2, xT2, yT, nxtInd, j, temp);
	 		}//end copying each 2d elem over
	 		nxtInd++;
	 	}//end if this element isn't a corner
	 }//end copying parts of the old array into new array
	 //debugthis
	 return d2Array2;
}//end deleteEdgess(d2Array, xT, yT)

function deleteDuplicates(d2Array, xT, yT){
	// deletes elements in 2d array with very similar X and Y, returns new array
	// tolerance for x values closeness
	xTol = 2;
	// tolerance for y values closeness
	yTol = 5;
	Array.print(d2Array);
	// array to hold index of bad coordinates
	badInd = newArray(0);
	// find extremely similar indexes
	for(i = 0; i < xT; i++){
		// Note: might want to exclude processing of bad indexes here
		if(contains(badInd, i) == false){
			// get x and y for i
			d2x = twoDArrayGet(d2Array, xT, yT, i, 0);
			d2y = twoDArrayGet(d2Array, xT, yT, i, 1);
			for(j = i+1; j < xT; j++){
				diffX = abs(d2x - twoDArrayGet(d2Array, xT, yT, j, 0));
				diffY = abs(d2y - twoDArrayGet(d2Array, xT, yT, j, 1));
				if(diffX < xTol && diffY < yTol){
					/*print(twoDArrayGet(d2Array, xT, yT, j, 0));
					print(twoDArrayGet(d2Array, xT, yT, j, 1));
					print(twoDArrayGet(d2Array, xT, yT, j, 2));
					print(twoDArrayGet(d2Array, xT, yT, j, 3));
					waitForUser("diffX:" + diffX + " diffY:" + diffY +
					"\nx:" + d2x + " y:" + d2y);*/
					badInd = Array.concat(badInd,j);
				}//end if this is VERY close to d2Array[i]
			}//end looping all the rest of the array
		}//end if this array is good
	}//end looping over d2Array
	// make array based on learned dimensions
	rnLng = xT - lengthOf(badInd);
	rtnArr = twoDArrayInit(rnLng, yT);
	curRtnInd = 0;
	// add good indices to new array
	for(i = 0; i < xT; i++){
		if(contains(badInd, i) == false){
			x = twoDArrayGet(d2Array, xT, yT, i, 0);
			y = twoDArrayGet(d2Array, xT, yT, i, 1);
			w = twoDArrayGet(d2Array, xT, yT, i, 2);
			h = twoDArrayGet(d2Array, xT, yT, i, 3);
			twoDArraySet(rtnArr, rnLng, yT, curRtnInd, 0, x);
			twoDArraySet(rtnArr, rnLng, yT, curRtnInd, 1, y);
			twoDArraySet(rtnArr, rnLng, yT, curRtnInd, 2, w);
			twoDArraySet(rtnArr, rnLng, yT, curRtnInd, 3, h);
			curRtnInd++;
		}//end if this isn't a bad index
	}//end looping over original array
	return rtnArr;
}//end deleteDuplicates(d2Array, xT, yT)

// hold off on this one for now?
function normalizeCellCount(d2Arr, xT, yT){
	// normalize the cell count of rawCoords to gridCells
	// initialize 2d array we'll put our coordinates into before group construction
	coordRecord = twoDArrayInit(gridCells, 4);
	// check to make sure we have the right number of cells
	if(nResults < gridCells){
		if(shouldShowRoutineErrors == true){
			showMessageWithCancel("Unexpected Cell Number",
		"In the file " + File.getName(chosenFilePath) + ", which is located at \n" +
		chosenFilePath + ", \n" +
		"it seems that we were unable to detect the location of every cell. \n" + 
		"There should be " + gridCells + " cells in the grid, but we have only \n" + 
		"detected " + nResults + " of them. This could be very problematic later on.");
		}//end if we want to show a routine error
		return newArray(0);
	}//end if we haven't detected all the cells we should have
	else if(nResults > gridCells){
		// we'll need to delete extra cells
		curCellCt = nResults;
		// if less than tol, then on same row
		inCelTol = 2.7;// was 1.5
		// if more than tol, then on different row
		outCelTol = 10;
		// current index we're putting stuff into for coordRecord
		curRecInd = 0;
		// set most recent Y by default as first Y
		mRecY = twoDArrayGet(d2Arr,xT,yT,0,1);
		// set most recent difference to 0
		mRecDiff = 0;
		for(i = 0; i < xT; i++){
			// figure out how this Y compares to last one
			thisY = twoDArrayGet(d2Arr,xT,yT,i,1);
			x = twoDArrayGet(d2Arr,xT,yT,i,0);
			w = twoDArrayGet(d2Arr,xT,yT,i,2);
			h = twoDArrayGet(d2Arr,xT,yT,i,3);
			diffFromRec = abs(thisY - mRecY);
			if(diffFromRec < inCelTol || diffFromRec > outCelTol){
				// add this index of rawCoordResults to coordRecord
				a = twoDArraySet(coordRecord,gridCells,4,curRecInd,0,x);
				b = twoDArraySet(coordRecord,gridCells,4,curRecInd,1,thisY);
				c = twoDArraySet(coordRecord,gridCells,4,curRecInd,2,w);
				d = twoDArraySet(coordRecord,gridCells,4,curRecInd,3,h);
				// check that we're in bounds
				if(a == false || b == false || c == false || d == false){
					if(ignorePossibleErrors != true){
						return newArray(0);
					}//end if we don't want to ignore possible errors
				}//end if we found a problem
				// print something to the log
				print("found a normal cell, indexed to "+curRecInd +
				", diffFromRec of " + diffFromRec);
				// increment curRecInd to account for addition
				curRecInd++;
			}//end if we think differences look normal
			else if(mRecDiff > inCelTol && mRecDiff < outCelTol){
				// add this index of rawCoordResults to coordRecord
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
				print("found the start of a bad cell, not adding it");
			}//end else we found the start of a bad cell

			// set most recent Y again so it's updated for next iteration
			mRecDiff = diffFromRec;
			mRecY = thisY;
		}//end looping over cells in rawCoordResults
		// quick fix for renaming files
		if(shouldOutputRawCoords == true){
			fileNameBase = File.getName(chosenFilePath);
			folderSpecifier = newFolderNameRaw;
			if(outputToNewFolderRaw == false) folderSpecifier = false;
			saveRawResultsArray(coordRecord,gridCells,4,
			chosenFilePath,newArray("BX","BY","Width","Height"),
			folderSpecifier,"Corrected Coordinates - " + fileNameBase);
		}//end if we're outputting a file
	}//end else if there are too many cells
	else{
		// just set coordResult to rawCoordResults
		coordRecord = rawCoordResults;
	}//end else we have the right number of cells
	return coordRecord;
}//end normalizeCellCount()

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
