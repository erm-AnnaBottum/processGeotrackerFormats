
DRAFT


Geotracker Data Processing Workflow
This document outlines the process of migrating data from the GeoTracker online database into Exxon Mobil’s EQuIS database using the EDFFlat, Geo_XY, Geo_Z, Geo_Well, and Well_Construction tables of the GeoTracker EDD format.

Downloading data from Geotracker
Notes here on the downloading process:
-	https://geotracker.waterboards.ca.gov/
-	Where to go on the website to get which types of data (Locations, Analytical, etc.)
-	All files automatically download to a .zip folder containing one or more text files (.txt).
-	Any additional notes

Setting up Workspace
Downloading project from GitHub
The following steps require that git, R, and RStudio are installed on your computer. Follow the links for git and R/RStudio for instructions on installing these. Once everything is set up, navigate to https://github.com/erm-AnnaBottum/processGeotrackerFormats in a web browser. Click the green ‘Code’ dropdown, and copy the repository’s URL.
 
Next, open RStudio on your desktop. From the upper left corner, click File->New Project->Version Control->Git. Paste the repository’s URL when prompted, and enter ‘processGeotrackerFormats’ as the project directory name. Lastly, browse to the desired location on your machine to save the project and click ‘Open’. Next click ‘Create Project’. You will now have all of the necessary files from the GitHub repository cloned on your local drive.

Setting up project folders
On your local drive, in the location that you have the processGeotrackerFormats project saved, you will need to set up a few additional folders to match the folder structure that the scripts are anticipating. Within your processGeotrackerFormats folder, ensure the following folders exist (if they do not, create them. Blank folders, particularly data and output, will not come from GitHub).
 
Save the exports from the GeoTracker portal into the data folder; this is where the scripts will read files in from. Script outputs will be written to output. The reference folder contains remap tables, column mapping definitions, and EDD description files, which are all used by the scripts while processing the data. The source folder contains all of the R scripts associated with this project.

Exploratory Review of Data
The first step in the migration process is to review key fields for integrity and to review reference values and handle any potential remapping into Exxon Mobil’s values that might be needed. The table linked below contains a general guide of fields to review and items to take into consideration: exploratory_review_guide.xlsx.

Reference Values
To review reference values, first run the get_ref_vals.R script in the processGeotrackerFormats R project. This will export distinct lists of the reference values being used in the files downloaded from the GeoTracker database.

To assign remap definitions for cas numbers, analytic method, sample matrix, and result unit, add reference values and the value they should be updated to on the appropriate tab in the mapping_definitions.xlsx file within the processGeoTrackerFormats project. The original value (in download from GeoTracker) should go in the left-most column while the replacement value should go in the column labeled ‘EM_<reference value type>’ (‘EM_analytic_method’ in screenshot below)
 






Blank Defaults
In reviewing the data, you may find that there are many fields left blank that are required by either EQuIS or the GeoTracker EDD format. To update or define new default values that should be used in place of blanks, add that default value to the ‘default_value’ column on the ‘mapping_def’ tab of the mapping_definitions.xlsx file.

 

Enumerations
There are a few fields in the GeoTracker EDD format that have enumerations. In the context of EQuIS, an enumeration is predefined list of values that are considered ‘valid’ for a field. These fields may or may not map to a lookup field in EQuIS (many of them map to a custom or remark field). This means that for some fields only the enumeration needs to be updated, while for others both the enumeration and corresponding reference tables need to be updated in order for the EDD to pass the package creation stage in EDP. Whether or not a field requires enumeration and reference table updates is outlined in the exploratory_review_guide.xlsx file.

For the GeoTracker EDD format, the defined list of values for many of these fields exists in the format’s enumeration file, which can be accessed by unzipping the EDD format zip file, and edited if needed. Some fields’ enumeration definitions exist in the format’s DLL file, which is not editable.
 










To update a field’s definition in the enumeration file, open the GeotrackerEDF-enum.xml file in a code editor such as Visual Studio Code and search the file for the name of the field’s enumeration (this can be found in the Lookup column in the EDDDescription_GeotrackerEDF.xlsx). Add new enumeration values as needed, and be sure to add a comment to the addition.
 

Lookups
In addition to enumerations, some fields in the GeoTracker EDD format have lookups. These are another method of supplying a predefined list of ‘valid’ values for a field, however instead of storing those values in the enumeration file, these are stored in rt_lookup. The exploratory_review_guide.xlsx file outlines whether or not a field has a lookup. If a new value does need to be added to a field’s list of lookups, this can be done by loading a reference value EDD to EQuIS.
 
When filling out the reference value EDD, within the rt_lookup table, set lookup_type to the name of the field in the GeoTracker EDD.

Prepare for Load
Once all necessary remaps, enumerations & lookups have been addressed, run the compile_geotracker_suite.R script. This will create a zip file EDD containing the GEO -XY, -Z, -WELL and WellConstruction tables, and a zip file EDD containing the EDFFlat table. If needed, the EDFFlat output can be set to specific batch sizes in the script. These outputs will be ready to load into EDP via the GeoTracker format.
	

Notes to add based on conversation with Jesus 3/10/2026
-	Define what information is coming from the auxiliary (SantaBarbara) dataset
-	

