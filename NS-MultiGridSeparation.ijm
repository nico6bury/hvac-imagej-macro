/*
 * Author: Nicholas Sixbury
 * File: NS-MultiGridSeparation.ijm
 * Purpose: To process images with multiple grids by
 * breaking the image up into multiple images which
 * can then be processed separately.
 */
////////////////////////////////////////////////////////////////
////////////////// BEGINNING OF MAIN PROGRAM ///////////////////

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