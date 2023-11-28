/* Extracts cutting planes, marks them on the original stack, and optionally creates a montage image.
 *  
 *  v.0.0.9004
 *  (C) 2016-2023 Peter T. Rühr (ZFMK Bonn, Uni Bonn, Uni Cologne)
 */

if (isOpen("Log")) { 
     selectWindow("Log"); 
     run("Close"); 
} 
if (isOpen("Results")) { 
     selectWindow("Results"); 
     run("Close"); 
}

orig_stack = getTitle();
Stack.getDimensions(width, height, channels, slices, frames);

list_of_loading_choices = newArray("load text file", "choose planes manually");
list_of_color_choices = newArray("white", "black");

Dialog.create("Presettings");
	Dialog.addMessage("Marking Cutting Planes Plugin.");
	Dialog.addMessage("___________________________________");
	Dialog.addChoice("How to get plane x values ", list_of_loading_choices, "list_of_loading_choices[0]");
	Dialog.addMessage("___________________________________");
	Dialog.addChoice("Mark planes in ", list_of_color_choices, "list_of_color_choices[0]");
	Dialog.addMessage("___________________________________");
	Dialog.addCheckbox("Create montage image of cutting planes ", true);
	Dialog.addNumber("Number of images in one row in montage ", 5);
	Dialog.addMessage("___________________________________");
	Dialog.addMessage("Ruehr P.T., ZFMK, Bonn (2016)")
Dialog.show();
load_text_file = Dialog.getChoice;
color = Dialog.getChoice;
montage = Dialog.getCheckbox;
columns = Dialog.getNumber;

waitForUser("1) Select slice on which cuting planes should be marked.\n2) Click 'Ok' AFTERWARDS.");

if(load_text_file == list_of_loading_choices[0]){
	cutting_planes_folder = getDirectory("Choose Directory of text file");
	Dialog.create("Name of text file");
	Dialog.addString("Type in the name of the text file ", 'cps.txt');
	Dialog.show();
	cutting_planes_file = cutting_planes_folder + Dialog.getString;
	print("Cutting planes file: \n" + cutting_planes_file);
	filestring = File.openAsString(cutting_planes_file); 
	list_of_cps = split(filestring, "\n");
	no_cps = list_of_cps.length;
}
else {
	Dialog.create("Number of cutting planes");
		Dialog.addNumber("Number of cutting planes ", 2);
	Dialog.show();
	no_cps = Dialog.getNumber();
	
	Dialog.create("x coordinates of cutting planes");
		Dialog.addMessage("Define x coordinates of cutting planes");
		Dialog.addMessage("___________________________________");
		for(i=1; i<=no_cps; i++){
			Dialog.addNumber("x = ", i*10);
		}
	Dialog.show();
	
	print("Creating Array with Cutting Planes...");
	list_of_cps = newArray(0);
	for(j=1; j<=no_cps; j++){
		int_cp = round(Dialog.getNumber());
		list_of_cps = Array.concat(list_of_cps, int_cp);
	}
}

print("Cutting Planes chosen:");
Array.print(list_of_cps);

print("Number of cutting planes: " + no_cps);
print("Marking color: " + color);
print("Make montage: " + montage);

if(color == list_of_color_choices[0]){
	setForegroundColor(255, 255, 255);
	setBackgroundColor(255, 255, 255);
}
else{
	setForegroundColor(0, 0, 0);
	setBackgroundColor(0, 0, 0);
}

print("Processing:");
print("Reslicing...");
run("Reslice [/]...", "output=1 start=Left flip rotate avoid");
reslice_stack = getTitle();

print("Creating image for marking planes...");
selectWindow(orig_stack);
run("Select All");
run("Copy");
newImage("marked_planes", "8-bit black", width, height, 1);
marking_img = getTitle();
run("Paste");

print("Marking cutting planes...");
for(j=1; j<=no_cps; j++){
	for(g=0; g<no_cps; g++){
		curr_cp = list_of_cps[g];
		makeRectangle(curr_cp, 0, 1, height);
		run("Cut");
	}
}
Array.print(list_of_cps);

selectWindow(reslice_stack);
Stack.getDimensions(width, height, channels, slices, frames);
setSlice(1);

print("Creating stack with cutting planes...");
list_of_cps_string = "1";
for(j=0; j<list_of_cps.length; j++){
	list_of_cps_string=list_of_cps_string+","+list_of_cps[j];
}
list_of_cps_string = substring(list_of_cps_string, 2, list_of_cps_string.length);
print(list_of_cps_string);
run("Make Substack...", "  slices=" + list_of_cps_string);
substack_title = getTitle();

if(montage == true){
	print("Creating montage image...");
	rows = -floor(-no_cps/columns);
	
	mont_width = width * columns;
	mont_height = height * rows;
	newImage("montage", "8-bit black", mont_width, mont_height, 1);
	montage_title = getTitle();
	
	col_counter = 0;
	row_counter = 0;
	t=1;
	for(s=1;s<=no_cps;s++){
		selectWindow(substack_title);
		setSlice(s);
		run("Select All");
		run("Copy");
		selectWindow(montage_title);
		if(col_counter==columns){
			col_counter = 0;
			row_counter++;
		}
		curr_x = width*col_counter;
		curr_y = row_counter*height+1;
		makeRectangle(curr_x, curr_y, width, height);
		run("Paste");
		col_counter++;
	}
}

selectWindow(orig_stack);
run("Select None");
selectWindow(marking_img);
run("Select None");
selectWindow(reslice_stack);
run("Select None");

if(montage == true){
	selectWindow(montage_title);
	run("Select None");
}

print("All done!");
print("Thanks for using the script.");
