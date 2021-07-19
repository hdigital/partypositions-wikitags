""" Get data from Wikipedia

Use wptools package to get Wikipedia infobox and Wikidata data.
Results are stored in a json file.
"""

import urllib

import pycurl
import pandas as pd
import wptools


timeout_seconds = 30


def wp_page(wiki_url):
    """Retrieve a Wikipedia page"""
    wiki_path = urllib.parse.urlparse(wiki_url).path
    wiki_title = urllib.parse.unquote(wiki_path.replace("/wiki/", ""))

    try:
        page = wptools.page(wiki_title, timeout=timeout_seconds)
    except (LookupError, pycurl.error):
        page = None

    return page


def wp_data(wiki_url):
    """Get selected data for Wikipedia page"""
    page = wp_page(wiki_url)

    try:
        page.get_parse(timeout=timeout_seconds)
        page.get_wikidata(timeout=timeout_seconds)
    except (LookupError, pycurl.error):
        return None

    return {key: page.data[key] for key in ["label", "infobox", "wikidata"]}


pf = pd.read_csv("../01-partyfacts/core-parties.csv")
pf = pf.loc[pd.notna(pf.wikipedia), ["country", "partyfacts_id", "wikipedia"]]

# pf = pf.loc[:500, ]

pf["wikipedia_data"] = pf.wikipedia.apply(lambda x: wp_data(x))
pf = pf.loc[
    pd.notna(pf.wikipedia_data),
]

pf.to_json("wikipedia-data/01-wp-data-json.zip", orient="records")
