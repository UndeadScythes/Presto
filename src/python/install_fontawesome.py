# Import the required libraries.
import sys, urllib.request, zipfile, os, re, shutil

# Parse our args and make sure we have everything.
if len(sys.argv) < 4:
	sys.exit("Not enough arguments supplied")

root_directory        = sys.argv[1]
src_destination       = os.path.join(root_directory, sys.argv[2])
system_directory      = os.path.join(root_directory, sys.argv[3])
fontawesome_directory = os.path.join(system_directory, "fontawesome")
fonts_directory       = "{}/fonts".format(system_directory)

# Move into the source directory and get the FontAwesome source.
print("Getting Font Awesome source from web")
os.chdir(src_destination) # Path: C:/presto/external/
urllib.request.urlretrieve ("http://fontawesome.io/assets/font-awesome-4.7.0.zip", "FontAwesome.zip")

# Make sure we have a folder to unzip into and unzip the source files.
print("Unzipping fontawesome.zip")
if not os.path.isdir("FontAwesome"):
	os.mkdir("FontAwesome")
code_mirror_zip = zipfile.ZipFile("FontAwesome.zip", 'r')
code_mirror_zip.extractall("FontAwesome")
code_mirror_zip.close()

# Find and enter the Font Awesome source directory within the unzipped files.
os.chdir("fontawesome") # Path: C:/presto/external/fontawesome/
for dirname in os.listdir():
	fontawesome_dir = re.match("^font-awesome-[\d.]+$", dirname)
	if fontawesome_dir != None:
		os.chdir(fontawesome_dir[0]) # Path: C:/presto/external/fontawesome/font-awesome-4.7.0/
		break

# Now move the Font Awesome CSS into the system folder.
print("Moving Font Awesome CSS")
if not os.path.isdir(fontawesome_directory):
	os.mkdir(fontawesome_directory)
shutil.copyfile("css/font-awesome.min.css", os.path.join(fontawesome_directory, "fontawesome.css"))

# Now move the Font Awesome fonts into the system folder.
print("Moving Font Awesome fonts")
if not os.path.isdir(fonts_directory):
	os.mkdir(fonts_directory)
fonts_to_copy = [
    "fontawesome-webfont.woff2",
    "fontawesome-webfont.woff",
    "fontawesome-webfont.ttf"
]
for font in fonts_to_copy:
    shutil.copyfile("fonts/{}".format(font), os.path.join(fonts_directory, font))

# All done!
print("Font Awesome installation complete")
