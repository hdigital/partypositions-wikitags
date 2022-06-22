""" Get missing redirect pages

Get missing redirect pages that are not provided by WP tools
"""

import pandas as pd
import requests


results_folder = "wikipedia-data/"
timeout_seconds = 60


tag_redirect_buffer = {}


def get_redirect_title(link):
    """Get title of Wikipedia redirect page"""
    link_quoted = requests.utils.quote(link)
    url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{link_quoted}"
    r = requests.get(url, timeout=timeout_seconds)
    try:
        return r.json()["title"]
    except (KeyError):
        return pd.NA


def get_or_redirect(link, page):
    """Get page if it is already available or redirect"""
    global tag_redirect_buffer
    if pd.isna(page):
        return tag_redirect_buffer.setdefault(link, get_redirect_title(link))
    else:
        return page


wd_raw = pd.read_csv(results_folder + "03-infobox-tags.csv")

wd = wd_raw.assign(
    page=wd_raw.apply(lambda df: get_or_redirect(df["link"], df["page"]), axis=1)
)

wd.to_csv(results_folder + "04-tags-redirect.csv", index=False)
