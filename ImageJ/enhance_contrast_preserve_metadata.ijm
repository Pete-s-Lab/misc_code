// Batch Enhance Contrast per image, then copy metadata back with ExifTool.
// No equalization.
// No combined histogram.
// Each image gets its own histogram stretch.
//
// Output:
// input_folder/
// ├── original images
// ├── optional exiftool.exe
// └── contrast_enhanced/
//     ├── image1_contrast.jpg
//     └── image2_contrast.jpg
//
// The Log window reports metadata success or error for every image.

requires("1.53");

print("\\Clear");
print("Starting batch contrast enhancement with metadata preservation.");
print("------------------------------------------------------------");

// ---------------- USER SETTINGS ----------------

saturated = 0.01;   // ImageJ-like default. Try 0.1 gentler, 1.0 stronger.

// ------------------------------------------------

q = "\"";
nl = "\r\n";

inputDir = getDirectory("Choose folder with original images");
outputDir = inputDir + "contrast_enhanced" + File.separator;
File.makeDirectory(outputDir);

print("Input folder:");
print(inputDir);
print("Output folder:");
print(outputDir);
print("");

// First try exiftool.exe inside the input folder.
localExifTool = inputDir + "exiftool.exe";

if (File.exists(localExifTool)) {
    exiftoolPath = localExifTool;
    print("Found local ExifTool:");
    print(exiftoolPath);
} else {
    exiftoolPath = "exiftool";
    print("No local exiftool.exe found. Trying ExifTool from PATH.");
}

// Reject exiftool(-k).exe if selected later, because it can pause/hang.
if (indexOf(toLowerCase(exiftoolPath), "(-k)") >= 0) {
    exit("ERROR: Rename exiftool(-k).exe to exiftool.exe and run the macro again.");
}

// Test ExifTool directly, without cmd.exe or a temporary batch file.
print("");
print("Testing ExifTool directly:");
print(exiftoolPath);

testOut = exec(exiftoolPath, "-ver");

print("ExifTool test output:");
print(testOut);

if (indexOf(testOut, ".") < 0) {

    print("");
    print("Direct ExifTool test failed.");
    print("Please select exiftool.exe manually.");

    exiftoolPath = File.openDialog("Choose exiftool.exe");

    if (exiftoolPath == "") {
        exit("ERROR: No ExifTool selected. Metadata cannot be preserved.");
    }

    if (indexOf(toLowerCase(exiftoolPath), "(-k)") >= 0) {
        exit("ERROR: Rename exiftool(-k).exe to exiftool.exe and run the macro again.");
    }

    print("");
    print("Testing manually selected ExifTool:");
    print(exiftoolPath);

    testOut = exec(exiftoolPath, "-ver");

    print("Manual ExifTool test output:");
    print(testOut);

    if (indexOf(testOut, ".") < 0) {
        exit("ERROR: Selected ExifTool did not return a version number.");
    }
}

print("");
print("ExifTool OK. Version: " + testOut);

// Prepare quoted ExifTool command for the metadata batch files.
toolCmd = q + exiftoolPath + q;

print("------------------------------------------------------------");

list = getFileList(inputDir);

processedCount = 0;
metadataOK = 0;
metadataError = 0;
metadataWarning = 0;

setBatchMode(true);

for (i = 0; i < list.length; i++) {

    name = list[i];
    inputPath = inputDir + name;

    if (File.isDirectory(inputPath))
        continue;

    lower = toLowerCase(name);

    if (!(endsWith(lower, ".tif") ||
          endsWith(lower, ".tiff") ||
          endsWith(lower, ".jpg") ||
          endsWith(lower, ".jpeg") ||
          endsWith(lower, ".png"))) {
        continue;
    }

    print("");
    print("Processing image:");
    print(name);

    open(inputPath);

    // Core contrast enhancement.
    // This is equivalent to using Enhance Contrast with:
    // - no equalize
    // - no global / combined stack histogram
    // - normalize applied to pixel values
    run("Enhance Contrast...", "saturated=" + saturated + " normalize");

    dot = lastIndexOf(name, ".");
    base = substring(name, 0, dot);

    if (endsWith(lower, ".tif") || endsWith(lower, ".tiff")) {
        outputPath = outputDir + base + ".tif";
        saveAs("Tiff", outputPath);
    } else if (endsWith(lower, ".jpg") || endsWith(lower, ".jpeg")) {
        outputPath = outputDir + base + ".jpg";
        saveAs("Jpeg", outputPath);
    } else if (endsWith(lower, ".png")) {
        outputPath = outputDir + base + ".png";
        saveAs("PNG", outputPath);
    }

    close();

    processedCount++;

    // Metadata transfer via temporary batch file.
    // This avoids PowerShell and avoids fragile quoting inside ImageJ's exec().
    metaBat = outputDir + "__copy_metadata_current.bat";

    metaText =
        "@echo off" + nl +
        "echo METADATA_COPY_START" + nl +
        "echo ORIGINAL: " + inputPath + nl +
        "echo OUTPUT:   " + outputPath + nl +
        toolCmd +
            " -overwrite_original" +
            " -TagsFromFile " + q + inputPath + q +
            " -all:all" +
            " -unsafe" +
            " -icc_profile" +
            " " + q + "-FileCreateDate<FileCreateDate" + q +
            " " + q + "-FileModifyDate<FileModifyDate" + q +
            " " + q + outputPath + q + nl +
        "echo EXIFTOOL_EXIT_CODE:%ERRORLEVEL%" + nl +
        "echo METADATA_AFTER_COPY" + nl +
        toolCmd +
            " -a -G1 -s" +
            " -DateTimeOriginal" +
            " -CreateDate" +
            " -ModifyDate" +
            " -FileCreateDate" +
            " -FileModifyDate" +
            " -GPSLatitude" +
            " -GPSLongitude" +
            " -GPSPosition" +
            " -Model" +
            " " + q + outputPath + q + nl +
        "echo QUERY_EXIT_CODE:%ERRORLEVEL%" + nl +
        "echo METADATA_COPY_END" + nl;

    File.saveString(metaText, metaBat);

    metaOut = exec("cmd.exe", "/d", "/c", metaBat);

    print("ExifTool metadata output:");
    print(metaOut);

    if (indexOf(metaOut, "EXIFTOOL_EXIT_CODE:0") >= 0) {
        print("METADATA OK: copied metadata for " + name);
        metadataOK++;
    } else {
        print("METADATA ERROR: metadata transfer failed for " + name);
        metadataError++;
    }

    // Additional warnings for the two things you specifically care about.
    if (indexOf(metaOut, "DateTimeOriginal") < 0 &&
        indexOf(metaOut, "CreateDate") < 0 &&
        indexOf(metaOut, "FileCreateDate") < 0) {
        print("METADATA WARNING: no date metadata visible after copy for " + name);
        metadataWarning++;
    }

    if (indexOf(metaOut, "GPSLatitude") < 0 &&
        indexOf(metaOut, "GPSLongitude") < 0 &&
        indexOf(metaOut, "GPSPosition") < 0) {
        print("METADATA WARNING: no GPS coordinates visible after copy for " + name);
        metadataWarning++;
    }

    print("Finished:");
    print(outputPath);
}

setBatchMode(false);

print("");
print("------------------------------------------------------------");
print("DONE");
print("Images processed: " + processedCount);
print("Metadata OK:      " + metadataOK);
print("Metadata errors:  " + metadataError);
print("Metadata warnings:" + metadataWarning);
print("");
print("Enhanced images saved in:");
print(outputDir);
print("");
print("Note: PNG metadata support is unreliable. JPG -> JPG and TIF -> TIF are safer.");