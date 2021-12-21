# Parent image
FROM rocker/tidyverse:4.1.2

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install dependencies
RUN apt-get update && apt-get install -y python3-pip python3-pycurl
COPY 01-data-sources/02-wikipedia/requirements.txt /home/requirements.txt
RUN pip3 install -r /home/requirements.txt
RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository ppa:marutter/rrutter4.0
RUN add-apt-repository ppa:c2d4u.team/c2d4u4.0+
RUN apt-get update && apt-get --fix-missing install -y r-cran-rstan
RUN mkdir /home/.R
COPY 03-estimation/Makevars.txt /home/.R/Makevars.txt
RUN install2.r ggrepel rstan


# Notes building image and container
## # https://www.rocker-project.org
## # https://github.com/rocker-org/rocker-versioned2

## docker build -t wp-rstudio .
## docker run --rm -it -v $(pwd):/home/rstudio -p 8787:8787 -e DISABLE_AUTH=true wp-rstudio
## # use '${PWD}' instead of '$(pwd)' on Windows 10 Powershell
## # http://localhost:8787/
