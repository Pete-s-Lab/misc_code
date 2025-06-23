/********************************************************
Calibrates image according to underlying mesh.

Peter T. Rühr, June 2025
v. 0.0.9064
 *******************************************************/
 
 // User input at start
Dialog.create("Image Annotation Settings");
Dialog.addNumber("Start Number", 1);
Dialog.addString("Prefix", "PTR_MG_");
Dialog.addString("Location", "MyLocation");
Dialog.show();
startNum = Dialog.getNumber();
prefix = Dialog.getString();
locationText = Dialog.getString();

mesh_size = 0.612; // Leifs Duschvorhang: 0.612 or 0.42

scalebarSize_mm = 1;
unit = "mm";



// Select input folder
inputDir = getDirectory("Choose input folder");
list = getFileList(inputDir);

// Create output folder
outputDir = inputDir + "Annotated/";
File.makeDirectory(outputDir);

// Clear Log and Results
if (isOpen("Log")) { selectWindow("Log"); run("Close"); }
run("Clear Results");
print("=== Image Log");
print("ID\tLocation\tTimestamp");

// Main loop
counter = 0;
for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".jpg") || endsWith(list[i], ".jpeg") || endsWith(list[i], ".JPG")) {
        
        fullPath = inputDir + list[i];
        open(fullPath);
        title = getTitle();
        selectWindow(title);

        // Ask if this image should be calibrated
        Dialog.create("Calibrate Image?");
        Dialog.addMessage("Image: " + title);
        Dialog.addCheckbox("Calibrate with mesh?", true);
        Dialog.show();
        doCalibrate = Dialog.getCheckbox();

        // Create temporary file for metadata
		tmpFile = File.getParent(fullPath) + File.separator + "temp_info.txt";
		
		// Run Show Info and export to temp file
		run("Show Info...");
		wait(500);
		saveAs("Text", tmpFile);
		
		// Close the "Info for ..." window if open
		if (isOpen("Info for " + title)) {
		    selectWindow("Info for " + title);
		    run("Close");
		}
		
		// Read the info content
		infoText = File.openAsString(tmpFile);
		lines = split(infoText, "\n");
		
		// Try to find the line with Date/Time Original
		datetime_raw = "unknown_time";
		
		for (j = 0; j < lines.length; j++) {
		    if (indexOf(lines[j], "Date/Time Original") != -1) {
		        lineParts = split(lines[j], "\t");
		        if (lineParts.length > 1)
		            datetime_raw = trim(lineParts[1]);
		        break;
		    }
		}
		
		// Reformat if found
		formatted_datetime = "unknown_time";
		if (datetime_raw != "unknown_time") {
		    parts = split(datetime_raw, " ");
		    datePart = parts[0];
		    timePart = parts[1];
		
		    datePart = replace(datePart, ":", "-");
		    timePart = replace(timePart, ":", "-");
		
		    formatted_datetime = datePart + "_" + timePart;
		    timeStr = formatted_datetime;
		}
		
		// Print results
		print("EXIF Date/Time Original: " + datetime_raw);
		print("Formatted datetime: " + formatted_datetime);
		
		// Clean up
		File.delete(tmpFile);

        // Calibration (optional)
        if (doCalibrate) {
            setTool("line");
            waitForUser("Draw a line on the mesh scale");

            unit = unit;
            if(mesh_size == 0.612) {
            	print("Leif's curtain");
	            smoothing_window = 25;
	            tolerance = 40;
	            invert_ = false;
            } else {
            	print("BioForm lighthouse");
	            smoothing_window = 15;
	            tolerance = 20;
	            invert_ = false;
            }

            getSelectionCoordinates(x, y);
            run("Duplicate...", "title=img_copy");
            run("8-bit");
            if (invert_) run("Invert");
            makeLine(x[0], y[0], x[1], y[1]);
            profile = getProfile();

            profile_smooth = newArray;
            setOption("ExpandableArrays", true);
            for (k = smoothing_window / 2; k < profile.length - smoothing_window / 2; k++) {
                total = 0;
                for (j = k - smoothing_window / 2; j < k + smoothing_window / 2; j++)
                    total += profile[j];
                profile_smooth[k - smoothing_window / 2] = total / smoothing_window;
            }

            Plot.create("Profile", "px", "color", profile_smooth);
            minima_x = Array.sort(Array.findMinima(profile_smooth, tolerance));
            minima_y = newArray;
            for (m = 0; m < minima_x.length; m++)
                minima_y[m] = profile_smooth[minima_x[m]];
            Plot.add("Circle", minima_x, minima_y);

            distances = newArray;
            for (m = 1; m < minima_x.length; m++)
                distances[m - 1] = minima_x[m] - minima_x[m - 1];

            Array.getStatistics(distances, min, max, mean, std);
            distances = Array.sort(distances);
            pixel_size = mesh_size / mean;

            selectWindow("img_copy");
            close();

            run("Properties...", "channels=1 slices=1 frames=1 unit=" + unit +
                " pixel_width=" + pixel_size + " pixel_height=" + pixel_size +
                " voxel_depth=" + pixel_size);

            // Add scalebar
            run("Scale Bar...", "width=" + scalebarSize_mm + " height=8 font=36 color=White background=Black location=[Lower Right] bold");
        }

        // Draw labels (white, top-left stacked)
        imageIndex = startNum + counter;
        imageNum = IJ.pad(parseInt(imageIndex), 3);
        label = prefix + imageNum;

        getDimensions(width, height, channels, slices, frames);
        fontSize = 32; // fixed size, adjust if needed
		lineSpacing = round(1.4 * fontSize); // dynamic spacing
		
		setFont("SansSerif", fontSize, "bold");
		setColor("white");
		
		baseY = 40; // top margin
		drawString(label, 10, baseY);
		drawString(locationText, 10, baseY + lineSpacing);
		drawString(timeStr, 10, baseY + 2 * lineSpacing);

        // Save and log
        saveName = label + "_" + timeStr + ".jpg";
        saveAs("Jpeg", outputDir + saveName);
        print(label + "\t" + locationText + "\t" + timeStr);
        close();
        
        counter++;
    }
}