/* Closes all open images.
 *  
 *  v.0.0.9004
 *  (C) 2016 Peter T. Rühr (ZFMK Bonn)
 */
 
while (nImages>0) { 
          selectImage(nImages); 
          close(); 
}
