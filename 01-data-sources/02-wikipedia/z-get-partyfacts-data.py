""" Download most recent Party Facts data

Update the Party Facts data before getting data from Wikipedia.
Results are in a parent folder's subfolder ("01-partyfacts").
"""

import urllib.request

url = "https://partyfacts.herokuapp.com/download"
datasets = ["core-parties", "external-parties", "countries"]

for dataset in datasets:
    print(f"downloading Party Facts '{dataset}'")
    urllib.request.urlretrieve(
        f"{url}/{dataset}-csv/", f"../01-partyfacts/{dataset}.csv"
    )
