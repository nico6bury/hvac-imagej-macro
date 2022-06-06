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
debugMessages = false;


// get a filename of an image with multiple grids.
multiImg = File.openDialog("Please select an image with multiple grids.");
// open up the image
open(multiImg);

//// STEP 1: TRANSFORM the image to what we expect based on what we expect
transformImg();

//// STEP 2: Find a bunch of CELL STRIPS in the grid
// adds all the cells we could find to the roi manager
DynamicCoordGetter(debugMessages);

//// STEP 3: GROUP the strips together by the grid they appear to belong to
// uses the rois in the roi manager
serializedGroups = groupGrids();
// deserialize the bounds
numberOfGrids = lengthOf(serializedGroups);

//// STEP 4: Create DUPLICATE images from the supposed BOUNDS of each grid
separateGrids(serializedGroups);

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
	
	// now that we've gotten our images, open them instead of original
	close("*");
	roiManager("reset");
	if(isOpen("ROI Manager")){selectWindow("ROI Manager"); run("Close");}
	// open all the images back up
	for(i = 0; i < lengthOf(imageKeys); i++){
		openBackup(imageKeys[i], false);
	}//end opening all the duplicated images
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
			 		boundBools = locationRelation(gridLowBound[j],gridUpBound[j],adjacencyTol,roiBounds[0],roiBounds[1]);
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
				 			print("Group " + (k+1) + " has bounds " + gridLowBound[k] + ", " + gridUpBound[k]);
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
			boundBools = locationRelation(gridLowBound[i],gridUpBound[i],6,gridLowBound[j],gridUpBound[j]);
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
