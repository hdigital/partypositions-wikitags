""" Convert Wikipedia data into csv

Transform Wikipedia data from json into a dataframe and save as csv.
Clean-up the Infobox data by removing some subsections. 
"""

import pandas as pd


results_folder = "wikipedia-data/"

pf = pd.read_json(results_folder + "01-wp-data-json.zip")

wp_data = []
for elem in pf.to_dict(orient="records"):
    pf_id = elem["partyfacts_id"]
    elem_dt = elem["wikipedia_data"]
    wp_data.append([pf_id, "page", "label", elem_dt["label"]])
    for source in ["infobox", "wikidata"]:
        if not elem_dt.get(source) or "boxes" in elem_dt[source]:
            continue
        for key, val in elem_dt[source].items():
            if type(val) is list and not isinstance(val, str):
                for val_elem in val:
                    wp_data.append([pf_id, source, key, val_elem])
            else:
                wp_data.append([pf_id, source, key, val])

col_names = ["partyfacts_id", "source", "field", "value"]
pf_val = pd.DataFrame.from_records(wp_data, columns=col_names)

pf_val.to_csv(results_folder + "02a-wp-dataset-csv.zip", index=False)


# extract ideology/position and remove historical/faction section

ib = pf_val[
    (pf_val.source == "infobox") & (pf_val.field.isin(["ideology", "position"]))
]
ib = ib[["partyfacts_id", "field", "value"]]

str_remove = "'''(Faction|Historical|Formerly)(.*)'''"
ib["value_clean"] = ib["value"].str.replace(str_remove, "", regex=True)

ib.to_csv(results_folder + "02b-infobox.csv", index=False)
