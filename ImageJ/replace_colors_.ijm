print("v. 1.0.0");

Dialog.create("Settings");
	Dialog.addMessage("___________________________________");
	Dialog.addChoice("Define single color value(s) or replace color range", newArray("values", "range"), "values");
	Dialog.show();
	values_range = Dialog.getChoice();

if(values_range == "values"){
	Dialog.create("Settings");
		Dialog.addNumber("How many colors should be replaced", 1);
		Dialog.show();
		no_cols = Dialog.getNumber;
}

if(values_range == "values"){
	Dialog.create("Settings");
		Dialog.addMessage("Welcome to the automatic color replacement plugin.\n \nPlease choose your desired settings.")
		Dialog.addMessage("___________________________________")
		for(i=0; i<no_cols; i++){
			Dialog.addNumber("orig. color", i+1);
			Dialog.addNumber("replace with", 0);
			Dialog.addMessage("___________________________________")
		}
		
		Dialog.addMessage("\n \nPeter T. Ruehr\nNovember 2015\n \nSugadaira Montane Research Institute\n(Laboratory for the Insect Comparative Embryology), \nSugadadaira-kogen, Ueda, Nagano, Japan.\n \nZoological Research Museum Alexander Koenig\n(Center for Molecular Biodiversity Research),\nBonn, Germany")
		Dialog.show();
		
		list_of_colors = newArray("x");

		for(k=0; k<no_cols*2; k++){
			 curr_color = Dialog.getNumber();
			 list_of_colors = Array.concat(list_of_colors, curr_color);
		}
		
		print("Replaicing the following " + no_cols + " colors:");
}

if(values_range == "range"){
	Dialog.create("Settings");
		Dialog.addMessage("Welcome to the automatic color replacement plugin.\n \nPlease choose your desired settings.")
		Dialog.addMessage("___________________________________")
		Dialog.addNumber("Range Color 1", 0);
		Dialog.addNumber("Range Color 2", 255);
		Dialog.addNumber("replace with", 0);
		Dialog.addMessage("\n \nPeter T. Ruehr\nNovember 2015\n \nSugadaira Montane Research Institute\n(Laboratory for the Insect Comparative Embryology), \nSugadadaira-kogen, Ueda, Nagano, Japan.\n \nZoological Research Museum Alexander Koenig\n(Center for Molecular Biodiversity Research),\nBonn, Germany")
		Dialog.show();
		c3 = Dialog.getNumber();
		c4 = Dialog.getNumber();
		c5 = Dialog.getNumber();
		print("Replaicing the following color range:");
		print(c3 + " - " + c4 + " --> " + c5);
}

Stack.getDimensions(width, height, channels, slices, frames);
for (j=1; j<slices+1; j++) { 
	Stack.setSlice(j); 
	if(values_range == "values"){
		for(m=1; m<=list_of_colors.length-1; m=m+2){
			print(list_of_colors[m] + " --> " + list_of_colors[m+1]);
			changeValues(list_of_colors[m], list_of_colors[m], list_of_colors[m+1]);
		}
	}
	if(values_range == "range"){
		changeValues(c3, c4, c5);
	}
}

print("All done!");