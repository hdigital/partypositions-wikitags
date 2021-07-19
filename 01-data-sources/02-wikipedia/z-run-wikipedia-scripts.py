from glob import glob
from os import remove
from subprocess import call


# remove data files
for csv_zip in ["csv", "zip"]:
    for dt_file in glob(f"*.{csv_zip}"):
        remove(dt_file)

# run local Python files
for py_file in sorted(glob("0*.py")):
    print(f"\n\nRunning '{py_file}'\n")
    call(["python3", py_file])
