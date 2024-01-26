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


setBatchMode(true);
row = 0;
for (f = 0; f < folder_file_list.length; f++) {
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
		curr_head_folder = folders[i];
		folder_name = curr_head_folder;
		print(folder_name);
		File.openSequence(folder_name);
		d_size = 50/1024;
		
		// calculate if scaling is necessary later
		Stack.getDimensions(width_orig, height_orig, channels, slices, frames);
		o_size = width_orig*height_orig*slices/(1024*1024*1024);
		print("Target directory loaded. Stack size: "+o_size+" GB.");
		d = pow(d_size/o_size,1/3);
		perc_d = round(100 * d);
		d = perc_d/100;
		
		
		if(perc_d < 100){
			print("Scaling stack to "+perc_d+"% to reach stack size of ~"+d_size+" GB...");
			run("Scale...", "x="+d+" y="+d+" z="+d+" interpolation=Bicubic average process create");
			getPixelSize(unit_, px_size, ph, pd);
			print("New px size = "+px_size+" um.");
		}
		else{
			print("No scaling necessary; stack is already smaller than ~"+d_size+" GB.");
			print("************************************");
		}
		
		run("Median...", "radius=1 stack");
		run("3D Project...", "projection=[Brightest Point] axis=Y-Axis initial=0 total=360 rotation=90 lower=1 upper=255 opacity=0 surface=100 interior=50");
		
		folder_name = "X:/Pub/2023/Sander_Data_upload/unzips/projections/";
		File.makeDirectory(folder_name);
		tiff_name = File.getName(curr_head_folder)+"_";
		
		
		print("************************************");
		print("Saving stack as "+tiff_name+"[..].tif");
		target_dir_projections = folder_name+"/"+File.getName(curr_head_folder);
		File.makeDirectory(target_dir_projections);
		run("Image Sequence... ", "format=TIFF dir="+target_dir_projections+" name="+tiff_name);
		print("Saved stack.");
		print("************************************");
	}
	print("***************");
}

setBatchMode(false);
print("***************");
print("All done!");










