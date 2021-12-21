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


# Notes building image and container
## # https://www.rocker-project.org
## # https://github.com/rocker-org/rocker-versioned2

## docker build -t wp-rstudio .
## docker run --rm -it -v $(pwd):/home/rstudio -p 8787:8787 -e DISABLE_AUTH=true wp-rstudio
## # use '${pwd}' instead of '$(pwd)' on Windows 10 Powershell
## # http://localhost:8787/


# Notes Docker usage shell
## docker ps -a                         # get <CONTAINER-ID>
## docker exec -it <CONTAINER-ID> bash  # access container with Bash shell
## R --vanilla < z-run-all.R            # run in root@<CONTAINER-ID>:/home/rstudio
