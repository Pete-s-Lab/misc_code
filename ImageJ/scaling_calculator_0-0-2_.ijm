/*
 * Calculate how much you need to scale a 3D stack
 * to reach a certain stack size
 *   
 *   Should run on Linux, Win & iOS.
 *   
 *   Peter T.Ruehr (2016)
 */

if (isOpen("Log")) { 
     selectWindow("Log"); 
     run("Close"); 
} 
if (isOpen("Results")) { 
     selectWindow("Results"); 
     run("Close"); 
}

Dialog.create("User input");
Dialog.addNumber("Original stack size", 0);
Dialog.addNumber("Desired stack size", 0);
Dialog.addString("Unit", 'GB');
Dialog.show();
o = Dialog.getNumber;
d = Dialog.getNumber;
unit = Dialog.getString;

if(o == 0){
	showMessage("!!! Wrong original size input (" + o + ") !!!");
}
else{
	print("Original stack size: " + o + " " + unit + ".");
	if(d == 0){
		print("No correct desired file size input (" + d + ").");
	}
	else{
		perc_d = 100 * pow(d/o,1/3);
		print("*************************");
		print("Desired file size of " + d + " " + unit + " reached by reduction to " + perc_d + "%.");
	}
	print("*************************");
	print("The scaling to ...% results in a file size of:");
	for(i=5; i<=100; i=i+5){
		curr_size = pow(i/100,3);
		print(i + "% --> " + curr_size * o + " " + unit);
	}
}
print("*************************");