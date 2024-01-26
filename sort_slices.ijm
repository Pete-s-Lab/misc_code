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
folder_file_list = Array.concat("//DATASTORAGE/users/pruehr/Pub/2023/Sander_Data_upload/sort_slices/bonndata/folder_list.txt");

//	print("all folder list files:");
//	Array.print(folder_file_list);


row = 0;

file = folder_file_list[0];
print("------------------------------------------------");
print("current folder list file:");
print(file);
print("------------------------------------------------");

allText = File.openAsString(file);
//	print("current folder list file text:");
//	print(allText);

folders = split(allText, "\n");
//print(folders[0]);
//	print("stack folder number:");
//	print(folders.length);
print("stack folder names:");
//Array.print(folders);
for (i = 0; i < folders.length; i++) {
	print(folders[i]);
}


folder_name = folders[2]; ; // curr_head_folder;
print("current stack folder:");
print(folder_name);

File.openSequence(folder_name);

// calculate if scaling is necessary later
Stack.getDimensions(width_orig, height_orig, channels, slices, frames);
d_size = 350*350;
o_size = width_orig*height_orig;
print("Target directory loaded.");
d = pow(d_size/o_size,1/3);
perc_d = round(100 * d);
d = perc_d/100;

print(d);
if(perc_d < 100){
	title_raw = getTitle();
	print("Scaling x and y to "+perc_d+"% to reach ~"+d_size+" pixels...");
	run("Scale...", "x="+d+" y="+d+" z=1 interpolation=Bilinear average process create title=scaled");
	getPixelSize(unit_, px_size, ph, pd);
	print("New px size = "+px_size+" um.");
	selectWindow(title_raw);
	run("Close");
}
else{
	print("No scaling necessary; stack is already smaller than ~"+d_size+" pixels.");
	print("************************************");
}

title_A = getTitle();

setBatchMode(true);

Stack.getDimensions(width_orig, height_orig, channels, slices, frames);
slices_original = slices;
// run("Median...", "radius=2 stack");
resetMinAndMax();

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

setBatchMode(true);
// get mean sdv
Array.getStatistics(sdv_values, minimum, maximum, mean);
print("mean sdv:");
print(mean);

// find out if first slice pair has lowest sdv
if(first_sdv == minimum){
	print("Fist slice pair seems to be correct.");
} else {
	print("Fist slice pair seems to not be correct.");
	setBatchMode(false);
	// create new stack and add first image
	selectWindow(title_A);
	run("Duplicate...", "use");
	title_new_stack_raw = getTitle();
	print("new stack title:");
	print(title_new_stack_raw);
	run("Duplicate...", "title=new_stack");
	title_new_stack = getTitle();
	print("new stack title:");
	print(title_new_stack);
	selectWindow(title_new_stack_raw);
	run("Close");
	
	
	// find best fitting slice pair for first image
	reverse_falg = false;
	title = "[Progress]";
	run("Text Window...", "name="+ title +" width=35 height=3 monospaced");
	for(i=1; i<=slices_original; i++){ // slices_original
		selectWindow(title_new_stack);
		Stack.getDimensions(width_orig, height_orig, channels, slices, frames);
		slices_new_stack = slices;
	//		print("selecting slice in new stack:");
	//		print(slices_new_stack);
		setSlice(slices_new_stack);
		
		selectWindow(title_duplicate);
		Stack.getDimensions(width_orig, height_orig, channels, slices, frames);
		slices_duplicate = slices;
		setBatchMode(true);
		min_sdv = 99999999;
		mean_values = newArray();
		sdv_values = newArray();
		for(j=1; j<slices_duplicate-1; j++){ // slices_duplicate
			setBatchMode(true);
			selectWindow(title_duplicate);
			setSlice(j+1);
			imageCalculator("Subtract create", title_new_stack, title_duplicate);
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
			
			// save slice number in duplicate that has lowest sdv		
			if(curr_sdv < min_sdv){
				min_sdv = curr_sdv;
				best_fit = j+1;
			}
		}
		setBatchMode(false);
		
		// reverse stack and start with last image
		if(reverse_falg == false){
			Array.getStatistics(sdv_values, minimum, maximum, mean);
			print(min_sdv+"/"+0.5*mean);
			if(min_sdv > 0.6*mean){
				print("Stack end seems to have been reached. Reversing new stack.");
				selectWindow(title_new_stack);
				run("Reverse");
				reverse_falg = true;
			}
		}
	//		print("Best slice j for slice i");
	//		print(best_fit);
		
	//		print("adding image to new stack...");
	//		print("selecting slice in duplicate stack:");
	//		print(best_fit);
		if(i==slices_original){
			best_fit = 1;
		}
		selectWindow(title_duplicate);
		setSlice(best_fit);
		run("Duplicate...", "use");
		title_extract = getTitle();
	//		print("extract title:");
	//		print(title_extract);
		run("Concatenate...", " title=new_stack image1=["+title_new_stack+"] image2=["+title_extract+"]");
		title_new_stack = getTitle();
		
		selectWindow(title_duplicate);
		setSlice(best_fit);
		if(i!=slices_original){
			run("Delete Slice");
		}
		
		
		print(title, "\\Update:"+i+"/"+slices_original+" ("+(i*100)/slices_original+"%)\n"+getBar(i, slices_original));
	}
}
print(title, "\\Close");
setBatchMode(false);
print("***************");
print("All done!");










