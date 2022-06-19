""" Tag targets for infobox links

Get the linked tag target for the links of infobox tags ideology and position, including redirects.
"""

import pycurl
import wptools
import pandas as pd
import wikitextparser as wtp


results_folder = "wikipedia-data/"
timeout_seconds = 60


def get_links(wikitext):
    """Extract all link targets from Wikitext"""
    parsed = wtp.parse(wikitext)
    links = [link.title for link in parsed.wikilinks]
    return links


def get_wp_title(link):
    """Get title of Wikipedia page including redirect"""
    try:
        page = wptools.page(link, timeout=timeout_seconds)
        page.get_query(timeout=timeout_seconds)
    except (LookupError, KeyError, ValueError, pycurl.error):
        return None

    return page.data["title"]


# extract infobox links from Wikitext
wd_raw = pd.read_csv(results_folder + "02b-infobox.csv")
wd = wd_raw.assign(links=wd_raw["value_clean"].map(get_links)).drop("value_clean", 1)

# create long dataset with party id / tag observations
li = (
    wd.set_index(["partyfacts_id", "field"])
    .links.apply(pd.Series)
    .stack()
    .reset_index()
    .drop("level_2", 1)
    .rename(columns={0: "link"})
    .drop_duplicates()
)

# get title of linked page (including redirect)
rd = pd.DataFrame({"link": li["link"].unique()})
rd = rd.assign(page=rd["link"].map(get_wp_title))

# combine party links and link titles for final data
df = pd.merge(li, rd, how="left")
df.to_csv(results_folder + "03-infobox-tags.csv", index=False)
