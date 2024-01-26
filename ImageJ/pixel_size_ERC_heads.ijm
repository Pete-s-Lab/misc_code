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
 

// read folder list text file(s)
//this is a test file file:
//folder_file_list =  Array.concat("//DATASTORAGE/users/pruehr/Pub/2023/Sander_Data_upload/pixel_size_ERC_heads/folder_lists/folders_hexa_test2.txt");

//this is the serious file:
folder_file_list = Array.concat("//DATASTORAGE/users/pruehr/Pub/2023/Sander_Data_upload/pixel_size_ERC_heads/folder_lists/folders_rawdata.txt");

//define iutput file for results
outputFile = "//DATASTORAGE/users/pruehr/Pub/2023/Sander_Data_upload/pixel_size_ERC_heads/folder_lists/results.txt";

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
	//Array.print(text);
	//print(text[1]);
	
	for(i = 0; i < folders.length; i++){
		if (matches(folders[i], ".+xxx_head$")) {
			curr_head_folder = folders[i];
	 		curr_head_folder = replace(curr_head_folder, "/mnt/ssander@blanke-nas-1/RAWDATA", "//blanke-nas-1/DATA/RAWDATA");
	 		curr_head_folder = replace(curr_head_folder, '/', '\\');
//			print(curr_head_folder);
			files = getFileList(curr_head_folder);
//			Array.print(files);
			flag = 0;
			tiff_stack_files = 0;
			for (k = 0; k < files.length; k++) {
					if(endsWith(files[k], "tif")){
						curr_file = curr_head_folder+dir_sep+files[k];
//						print(curr_file);
						if (matches(files[k], ".+xxx_head.*") == false) {
							folder_name = File.getName(curr_head_folder);
							if(flag == 0){
								curr_ERC = substring(folder_name,0,4);
								curr_ERC = String.pad(curr_ERC,4);
								print(curr_head_folder);
								print("ERC: " + curr_ERC);
								open(curr_file);
								getPixelSize(unit, px_size, ph, pd);
								if(unit == "µm"){
									unit = "um";
								}
								print("File and pixel size extracted: " + files[k] + " : " + px_size + " " + unit);
								setResult("ERC", row, curr_ERC);
								setResult("folder", row, curr_head_folder);
								setResult("file", row, files[k]);
								setResult("px_size", row, px_size);
								setResult("unit", row, unit);
								curr_bitDepth = bitDepth();
								
//								get stack resloution
								Stack.getDimensions(width, height, channels, slices, frames);
								setResult("res_x", row, width);
								setResult("res_y", row, height);
								close();
								flag = 1;
							}
							tiff_stack_files++;
//							print("****");
//							print(files.length-1);
//							print(tiff_stack_files);
						}
				}
				
				if(k == files.length-1){
//					Get number of files in stack
//					print(tiff_stack_files);
					setResult("res_z", row, tiff_stack_files);
					setResult("size_x", row, width*px_size);
					setResult("size_y", row, height*px_size);
					setResult("size_z", row, tiff_stack_files*px_size);
					setResult("bit_depth", row, curr_bitDepth);
					print("Stack resolution: " + width + " x " + height + " x " +tiff_stack_files);
					print("Bit depth:: " + curr_bitDepth);
//					end loop
//					k = files.length;
					run("Collect Garbage");
					row++;
				}	
			}
			print("***************");
		}
		else {
			print(folders[i] + "does not seem to be a head ROI folder.");
			print("***************");
		}
	}

}

// Save the results
print("Results being saved to:");
log_name = substring(File.getName(outputFile),0,lengthOf(File.getName(outputFile))-4);
print(File.getParent(outputFile) + dir_sep + log_name + "_log.txt");
print(outputFile);

saveAs("results", outputFile);
setBatchMode(false);

// save log
getInfo("log");
save(File.getParent(outputFile) + dir_sep + log_name + "_log.txt");
