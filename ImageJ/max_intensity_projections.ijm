requires("1.39l");
if (isOpen("Log")) { 
     selectWindow("Log"); 
     run("Close"); 
} 
if (isOpen("Results")) { 
     selectWindow("Results"); 
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
 
//this is the serious file:
folder_file_list = Array.concat("//DATASTORAGE/users/pruehr/Pub/2023/Sander_Data_upload/max_intensity_projections/folders_bonndata_crops.txt");

Array.print(folder_file_list);


//setBatchMode(true);
row = 0;
for (f = 0; f < folder_file_list.length; f++) {
	
	setBatchMode(true);
	file = folder_file_list[f];
	print("------------------------------------------------");
	print("------------------------------------------------");
	print(file);
	print("------------------------------------------------");
	
	allText = File.openAsString(file);
	//print(allText);
	
	
	folders = split(allText, "\n");
	//Array.print(folders);
	//print(folders[0]);

	for(i = 0; i < folders.length; i++){
		print("Closing all images.");
		while (nImages>0) { 
		  selectImage(nImages); 
		  close();
		}
		
		print("Attempting to clear memory.");
		wait(1000);
		run("Collect Garbage");
		wait(2000);
		
		setBatchMode(true);
		curr_head_folder = folders[i];
		folder_name = curr_head_folder;
		print("Working on folder:");
		print(folder_name);
		print("Loading stack.");
		File.openSequence(folder_name);
//		d_size = 50/1024;
//		
//		// calculate if scaling is necessary later
//		Stack.getDimensions(width_orig, height_orig, channels, slices, frames);
//		o_size = width_orig*height_orig*slices/(1024*1024*1024);
//		print("Target directory loaded. Stack size: "+o_size+" GB.");
//		d = pow(d_size/o_size,1/3);
//		perc_d = round(100 * d);
//		d = perc_d/100;
		
		
//		if(perc_d < 100){
//			print("Scaling stack to "+perc_d+"% to reach stack size of ~"+d_size+" GB...");
//			run("Scale...", "x="+d+" y="+d+" z="+d+" interpolation=Bicubic average process create");
//			getPixelSize(unit_, px_size, ph, pd);
//			print("New px size = "+px_size+" um.");
//		}
//		else{
//			print("No scaling necessary; stack is already smaller than ~"+d_size+" GB.");
//			print("************************************");
//		}
		
		print("Applying median filter.");
		run("Median...", "radius=1 stack");
		
		title_A = getTitle();
		Stack.getDimensions(width_orig, height_orig, channels, slices_original, frames);
		
		print("Creating projections.");
		run("3D Project...", "projection=[Brightest Point] axis=Y-Axis initial=0 total=360 rotation=90 lower=1 upper=255 opacity=0 surface=100 interior=50");
		
		print("Creating folder "+folder_name+".");
		folder_name = "X:/Pub/2023/Sander_Data_upload/max_intensity_projections/projections/";
		File.makeDirectory(folder_name);
		tiff_name = File.getName(curr_head_folder)+"_";
		
		
		print("************************************");
		print("Saving projections.");
		target_dir_projections = folder_name+"/"+File.getName(curr_head_folder);
		print("Creating folder "+target_dir_projections+".");
		File.makeDirectory(target_dir_projections);
		run("Image Sequence... ", "format=TIFF dir="+target_dir_projections+" name="+tiff_name);
		print("Saved stack.");
		print("************************************");
		

		
		//slices_original = slices;
		// run("Median...", "radius=2 stack");
		//resetMinAndMax();
		print("Creating sdv graph.");
		selectWindow(title_A);
		run("Duplicate...", "duplicate");
		title_duplicate = getTitle();
		
		max_sdv = 0;
		mean_values = newArray();
		sdv_values = newArray();
		for(i=1; i<=1; i++){ // slices_original
			selectWindow(title_A);
			setSlice(i);
			for(j=i+1; j<=slices_original-1; j++){ // slices_original
				selectWindow(title_duplicate);
				setSlice(j+1);
				imageCalculator("Subtract create", title_A, title_duplicate);
				title_C = getTitle();
				selectWindow(title_C);
				
				// this takes much longer than run Measure:
		//			curr_mean = getValue("Mean"); // getResult('Mean', 0);
		//			curr_sdv = getValue("StdDev"); //getResult('StdDev', 0);
				
				run("Clear Results");
				run("Measure");
				curr_mean = getResult('Mean', 0);
				curr_sdv = getResult('StdDev', 0);
				
		//			print("mean:");
		//			print(curr_mean);
		//			print("sdv:");
		//			print(curr_sdv);
				
				selectWindow(title_C);
				run("Close");
				
				mean_values = Array.concat(mean_values,curr_mean);
				sdv_values = Array.concat(sdv_values,curr_sdv);
				
				//save current sdv as new max sdv if larger than present max
				if(curr_sdv > max_sdv){
					max_sdv = curr_sdv;
				}
				
				//save value of first image pair
				if(i==1 && j==i+1){
					first_sdv = curr_sdv;
				}
				
			}
		}
			
		//// close stack duplicate
		//selectWindow(title_duplicate);
		//run("Close");
		
		//while (nImages>0) { 
		//  selectImage(nImages); 
		//  close();
		//}
		
		//print(first_sdv);
		//print(slices_original);
		//Array.print(sdv_values);
		//print(max_sdv);
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
		//Plot.add("line", newArray((min_slice_sdv-1),(min_slice_sdv-1)), newArray(0,sdv_values[min_slice_sdv]));
		Plot.show();
		print("Saving sdv graph.");
		saveAs("PNG", target_dir_projections+"\\"+tiff_name+"graph.png");
		
		setBatchMode(true);
		print("***************");
	}
	print("***************");
}

setBatchMode(false);
print("***************");
print("All done!");
