/********************************************************
Calibrates image according to SD card.

Peter T. Rühr, March 2020
v. 1.0.0
 *******************************************************/

unit = "mm";

if (isOpen("Log")) { 
     selectWindow("Log"); 
     run("Close"); 
} 
if (isOpen("Results")) { 
     selectWindow("Results"); 
     run("Close"); 
}
if (isOpen("Profile")) { 
     selectWindow("Profile"); 
     run("Close"); 
}

setTool("line");
waitForUser("Define card", "Use line tool to mark the SD card from side to side along its short axis and click okay.");

getSelectionCoordinates( x, y );
x1 = x[0];
y1 = y[0];
x2 = x[1];
y2 = y[1];

distance_px = sqrt(pow((x1 - x2),2) + pow((y1 - y2),2));

print(distance_px);

print("distenace = "+distance_px+" pxiels.");
pixel_size = 24/distance_px;
print("SD card size = 24 mm --> pixel size = "+pixel_size+" mm");

run("Properties...", "unit=unit pixel_width=pixel_size pixel_height=pixel_size voxel_depth=pixel_size");