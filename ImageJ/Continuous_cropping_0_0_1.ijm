/*
 *   Cuts out an (inverted) selection and fills it with black.
 *   
 *   Should run on Linux, Win & iOS.
 *   
 *   Peter T. Rühr, Univeristy of Cologne (2020)
 */
 
 requires("1.39l");
if (isOpen("Log")) { 
     selectWindow("Log"); 
     run("Close"); 
} 
if (isOpen("Results")) { 
     selectWindow("Results"); 
     run("Close"); 
}

Dialog.create("Invert selection?");
Dialog.addMessage("Invert selection to crop outside?");
Dialog.addCheckbox("Invert?", true);
Dialog.show();
invert_ = Dialog.getCheckbox();

setTool("oval");

setForegroundColor(0, 0, 0);
setBackgroundColor(0, 0, 0);

// draw first selection
waitForUser("1) Draw selection on first slide with the oval selection tool.\n2) AFTERWARDS, click 'Ok'."); 

getSelectionBounds(xc1, yc1, width1, height1);
z1 = getSliceNumber();

// draw second selection
waitForUser("1) Draw selection on second slide with the oval selection tool.\n2) AFTERWARDS, click 'Ok'."); 

getSelectionBounds(xc2, yc2, width2, height2);
z2 = getSliceNumber();

// calculate slopes and y-intercepts for x-coordinates, y-coordinates, width & height
mxc = (xc2-xc1)/(z2-z1);
xc0 = xc1 - (mxc * z1);

myc = (yc2-yc1)/(z2-z1);
yc0 = yc1 - (myc * z1);

mwidth = (width2-width1)/(z2-z1);
width0 = width1 - (mwidth * z1);

mheight = (height2-height1)/(z2-z1);
height0 = height1 - (mheight * z1);

// check if first slice number is smaller then second <-- reverse if not
if(z1>z2){
	z1bkp = z1;
	z1=z2;
	z2=z1bkp;
}

// calculate x-coordinate, y-coordinate, width & height of selection, make selection, inverse selection if necessary and cut
for(z=z1; z<=z2; z++){
	setSlice(z);
	xc = mxc * z + xc0;
	yc = myc * z + yc0;
	width = mwidth * z + width0;
	height = mheight * z + height0;
	
	makeOval(xc, yc, width, height);
	
	if(invert_ == true){
		run("Make Inverse");
	}
	
	run("Cut");
}


run("Select None");
