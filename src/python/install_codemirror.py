# Import the required libraries.
import sys, urllib.request, zipfile, os, re, shutil

# Build a list of addons that we require.
codemirror_addon_file_paths = [
    "display/rulers.js",
    "search/search.js",
    "search/searchcursor.js",
    "dialog/dialog.js",
    "dialog/dialog.css"
]

# Parse our arguments and make sure we have everything.
if len(sys.argv) < 6:
    sys.exit("Not enough arguments supplied")

presto_root_directory = sys.argv[1]
source_directory      = os.path.join(presto_root_directory, sys.argv[2])
destination_directory = os.path.join(presto_root_directory, sys.argv[3])
nodejs_directory      = os.path.join(presto_root_directory, sys.argv[4])
codemirror_directory  = os.path.join(destination_directory, "codemirror")
mode_names            = sys.argv[5].split(",")

# Remove old installation files.
print("Cleaning up old installation files")
os.chdir(os.path.join(codemirror_directory, ".."))
shutil.rmtree("codemirror")

# Move into the source directory and get the CodeMirror source.
print("Getting CodeMirror source from web")
os.chdir(source_directory)
urllib.request.urlretrieve ("http://codemirror.net/codemirror.zip", "codemirror.zip")

# Make sure we have a folder to unzip into and unzip the source files.
print("Unzipping codemirror.zip")
if not os.path.isdir("codemirror"):
	os.mkdir("codemirror")
codemirror_zip = zipfile.ZipFile("codemirror.zip", 'r')
codemirror_zip.extractall("codemirror")
codemirror_zip.close()

# Find and enter the CodeMirror source directory within the unzipped files.
os.chdir("codemirror")
for dirname in os.listdir():
	codemirror_dir = re.match("^codemirror-[\d.]+$", dirname)
	if codemirror_dir != None:
		os.chdir(codemirror_dir[0])
		break

# Use NodeJS's NPM to build CodeMirror.
print("Building CodeMirror with NodeJS")
os.system("%s/npm install" % nodejs_directory)

# Now move the CodeMirror JS and CSS into the system folder.
print("Moving CodeMirror JS and CSS")
if not os.path.isdir(codemirror_directory):
	os.mkdir(codemirror_directory)
shutil.copyfile("lib/codemirror.js",  os.path.join(codemirror_directory, "codemirror.js" ))
shutil.copyfile("lib/codemirror.css", os.path.join(codemirror_directory, "codemirror.css"))

# Copy over the addon files that we require.
print("Moving addon files")
for addon_path in codemirror_addon_file_paths:
    addon_name = re.search("/([^/]+)$", addon_path).group(1)
    shutil.copyfile("addon/{}".format(addon_path), os.path.join(codemirror_directory, addon_name))

# Copy over the modes we want to use.
print("Moving mode files")
mode_directory = os.path.join(codemirror_directory, "modes")
if not os.path.isdir(mode_directory):
    os.mkdir(mode_directory)
for mode in mode_names:
    shutil.copyfile("mode/{0}/{0}.js".format(mode), mode_directory + "/" + mode + ".js")

# Clean up the downloaded zip and files.
os.chdir(source_directory)
os.remove("codemirror.zip")
try:
	shutil.rmtree("codemirror")
except PermissionError:
	print("Could not remove old working directory, files are in use")
    
# All done!
print("CodeMirror installation complete")
sys.exit(0)