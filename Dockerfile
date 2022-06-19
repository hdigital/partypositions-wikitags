# Parent image
FROM rocker/tidyverse:4.1.2

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install dependencies
RUN apt-get update && apt-get install -y python3-pip python3-pycurl libv8-dev

COPY 01-data-sources/02-wikipedia/requirements.txt /home/requirements.txt
RUN pip3 install -r /home/requirements.txt

RUN install2.r ggrepel rstan

RUN mkdir /home/.R
COPY 03-estimation/Makevars.txt /home/.R/Makevars.txt


WORKDIR /home/rstudio
