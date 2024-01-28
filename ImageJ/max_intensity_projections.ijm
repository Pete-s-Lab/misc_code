requires("1.39l");
if (isOpen("Log")) { 
     selectWindow("Log"); 
     run("Close"); 
} 
if (isOpen("Results")) { 
     selectWindow("Results"); 
     run("Close"); 
}
if (isOpen("Progress")){
	selectWindow("Progress");
	run("Close");
}

plugins = getDirectory("plugins");
unix = '/plugins/';
windows = '\\plugins\\';

if(endsWith(plugins, unix)){
	print("Running on Unix...");
	dir_sep = "/";
}
else if(endsWith(plugins, windows)){
	print("Running on Windows...");
	dir_sep = "\\";
}

function getBar(p1, p2) {
    n = 20;
    bar1 = "--------------------";
    bar2 = "********************";
    index = round(n*(p1/p2));
    if (index<1) index = 1;
    if (index>n-1) index = n-1;
    return substring(bar2, 0, index) + substring(bar1, index+1, n);
}

//this is the serious file:
folder_file_list = Array.concat("//DATASTORAGE/users/pruehr/Pub/2023/Sander_Data_upload/max_intensity_projections/folders_bonndata_crops.txt");
file = folder_file_list[0];

setBatchMode(true);

print("------------------------------------------------");
print("------------------------------------------------");
print(file);
print("------------------------------------------------");

allText = File.openAsString(file);
//print(allText);


folders = split(allText, "\n");
print("Found "+folders.length+" stack folder names:");
for (i = 0; i < folders.length; i++){
	if(i<=4 || i>(folders.length-5)){
		print(folders[i]);
	} else if (i==5){
		print("[...]");
	}
}

title = "[Progress]";
run("Text Window...", "name="+ title +" width=35 height=3 monospaced");
for(i = 0; i < folders.length; i++){
	print(title, "\\Update:"+(i+1)+"/"+folders.length+" ("+((i+1)*100)/folders.length+"%)\n"+getBar((i+1), folders.length));
	print("***************");
	print("Closing all images.");
	while (nImages>0) { 
	  selectImage(nImages); 
	  close();
	}
	
	print("Attempting to clear memory.");
	wait(1000);
	run("Collect Garbage");
	wait(2000);
	
	//setBatchMode(true);
	curr_folder = folders[i];
	folder_name = curr_folder;
	print("Working on folder "+i+1+":");
	print(folder_name);
	print("Loading stack.");
	File.openSequence(folder_name);
	
	title_A = getTitle();
	Stack.getDimensions(width_orig, height_orig, channels, slices_original, frames);
	
	print("Creating projections.");
	run("3D Project...", "projection=[Brightest Point] axis=Y-Axis initial=0 total=90 rotation=45 lower=1 upper=255 opacity=0 surface=100 interior=50");
	projections_title = getTitle();
	
	print("Creating folder "+folder_name+".");
	folder_name = "X:/Pub/2023/Sander_Data_upload/max_intensity_projections/projections/";
	File.makeDirectory(folder_name);
	tiff_name = File.getName(curr_folder)+"_";
	
	
	print("************************************");
	print("Saving projections.");
	target_dir_projections = folder_name+"/"+File.getName(curr_folder);
	print("Creating folder "+target_dir_projections+".");
	selectWindow(projections_title);
	File.makeDirectory(target_dir_projections);
	run("Image Sequence... ", "format=TIFF dir="+target_dir_projections+" name="+tiff_name);
	print("Projections stack.");
	print("************************************");
	
	// run("Median...", "radius=2 stack");
	//resetMinAndMax();
	
	print("Creating sdv graph.");
	selectWindow(title_A);
	run("Duplicate...", "duplicate");
	title_duplicate = getTitle();
	
	max_sdv = 0;
	mean_values = newArray();
	sdv_values = newArray();
	for(k=1; k<=1; k++){ // slices_original
		selectWindow(title_A);
		setSlice(k);
		for(j=k+1; j<=slices_original-1; j++){ // slices_original
			selectWindow(title_duplicate);
			setSlice(j+1);
			imageCalculator("Subtract create", title_A, title_duplicate);
			title_C = getTitle();
			selectWindow(title_C);
			
			run("Clear Results");
			run("Measure");
			curr_mean = getResult('Mean', 0);
			curr_sdv = getResult('StdDev', 0);
			
			selectWindow(title_C);
			run("Close");
			
			mean_values = Array.concat(mean_values,curr_mean);
			sdv_values = Array.concat(sdv_values,curr_sdv);
			
			//save current sdv as new max sdv if larger than present max
			if(curr_sdv > max_sdv){
				max_sdv = curr_sdv;
			}
			
			//save value of first image pair
			if(k==1 && j==k+1){
				first_sdv = curr_sdv;
			}
			
		}
	}
	
	if (isOpen("Results")){
		selectWindow("Results");
		run("Close");
	}
	
	setBatchMode(false);
	Plot.create("Results", "slice", "red = mean; blue = StdDev");
	Plot.setLimits(-3, slices_original+3, 0, max_sdv+0.2*max_sdv);
	Plot.setLineWidth(2);
	Plot.setColor("lightGray");
	Plot.add("line", mean_values);
	Plot.add("line", sdv_values);
	Plot.setColor("red");
	Plot.add("circles", mean_values);
	Plot.setColor("blue");
	Plot.add("circles", sdv_values);
	Plot.setColor("green");
	Plot.show();
	print("Saving sdv graph.");
	saveAs("PNG", target_dir_projections+"\\"+tiff_name+"graph.png");
	
	setBatchMode(true);
	print("***************");
}
print(title, "\\Close");
print("***************");

setBatchMode(false);
print("***************");
print("All done!");
