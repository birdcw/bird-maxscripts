/*

DESCRIPTION:
Will rotate all geometry objects in max file(s) (6 degree increments, z axis by default),
Saves a 2D png image at each rotation (i.e. images at 0,6,12,18,...,354 degrees). 
Images are taken using any pre-existing camera within the max file.

FILES, FILENAMES, AND SAVE DIRECTORIES:
Upon running this script, you will be prompted by GUI to
	1.Select all the max file(s) to use for rendering.
	2.Select a destination folder for all rendered images.
This script does not save any changes to max files.
"_###" is appended to each new filename (i.e. _006 for a six degree rotation)

ROTATING OBJECTS:
Only objects of type "Geometry" will be rotated
Rotation angle can be modified as needed (A),
Rotation angle must divide evenly into 360 degrees
Z axis of rotation.

CAMERAS:
Each max file must include a camera and camera target.
Camera target should already be set to the desired rotation pivot point.
Make sure that the script is pointing to the camera you want to use (B)

2D IMAGE RENDERING:
The image width (C) and height (D) can be adjusted as needed
Objects can be re-scaled if they do not fit in the render area (E)

*/

rotateAngle = 6 --A
camIndex = 1 -- B
renderWidth = 800 --C
renderHeight = 640 --D
sizeObj = 0.7 --E
setRenderType #view

fn showOpen = (
	--max file gui
	theDialog = dotNetObject "System.Windows.Forms.OpenFileDialog"
	theDialog.Title = "Select max files(s)"
	theDialog.Multiselect = true
	theDialog.Filter = "3dsMax scene file (.max)|*.max"
	theDialog.FilterIndex = 1
	theDialog.InitialDirectory = (getFileNamePath (getSourceFileName()))
	inputFiles = theDialog.showDialog()
	theDialog.fileNames
)

fn showSave = (
	--save directory gui
	outputDir = getSavePath caption:"Folder destination for output" \
	initialDir:(getFileNamePath (getSourceFileName()))
	outputDir += "\\"
	outputDir
)

fn checkFileName f  = (
	
	while doesFileExist f do (
		f = getFilenamePath f + getFilenameFile f + " - Copy" + getFilenameType f
	)
	
	f
	
)

fn groupGeometries groupName = (

	for obj in helpers where isGroupHead obj do (
		ungroup obj --any pre-existing groups would be excluded from the pending geometry loop.
	)
		
	--geometries are grouped together prior to rotation
	-- Assuming all objects to be rotated are geometries.
	select (for obj in Geometry collect obj)
	group Selection name: groupName
		
)

theFileNames = showOpen()
outputDir = showSave()
checkForSave()

for f in theFilenames do (
	
	loadMAXFile f quiet:true -- will not save max files
	
	groupGeometries "theGroup"
	
	--camera must already be centred and its target should be the desired pivot point.
	--resized if necessary to keep everything on-screen when rotating.
	$theGroup.pivot = cameras[camIndex].target.pivot
	scale $theGroup [sizeObj,sizeObj,sizeObj]
	
	-- the rotate incrementally and render loop
	for i = 0 to 360/rotateAngle - 1 do (
		
		--axis of rotation can be modified here
		z_rotate = i * rotateAngle
		$theGroup.rotation.z_rotation = z_rotate
		
		-- render filenames can be modified here
		renderImage = outputDir + (getFilenameFile maxFilename) \
		+ "_" + (formattedPrint z_rotate format: "3.3d") + ".png"
		
		renderImage = checkFileName renderImage
		
		--render image
		undisplay (render camera:cameras[camIndex] outputfile:renderImage vfb:false)
	)
	
)
	
--To avoid unnecessary "save changes" prompt for the last opened max file in the batch.
resetMaxFile #noPrompt
--generally a good sign if we get all the way to here.
outputDir = "All images were saved to " + outputDir
messagebox outputDir title:"MAXScript" beep:true
