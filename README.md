# NOTE:

As of November 2022, the code in the root branch is not up to date, as it contains unfinished refactoring that isn't going to be worked on in the near future. For stable code, use the "legacy-version" branch.


# usda-hvac-imagej-macro

Macro for Hard V Amber Class Durum Kernel Scanning project for USDA-ARS

## Directory Requirements

Requires the macro file to be in directory ~/Fiji.app/macros/usda-hvac-imagej-macro/.
This is required in order to locate sub macros due to current language limitations of the imagej macro language. Also, Fiji.app needs to be in the home directory of the current user.

## How to Run

In order to run this macro the conventional way, open ImageJ. Then, navigate in the menus Plugins > Macros > Edit. From here, you'll want to open NS-ImageProcessing.ijm in order to run the main program, though you can also run NS-MultiGridSeparation.ijm by itself if you just want to separate multi-grid images.
