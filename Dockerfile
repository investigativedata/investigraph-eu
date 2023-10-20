FROM ghcr.io/investigativedata/investigraph:main

USER root
RUN apt install -y curl
RUN pip install lxml html5lib psycopg2-binary
RUN pip uninstall -y followthemoney
RUN pip install "followthemoney @ git+https://github.com/investigativedata/followthemoney.git@schema/science-identifiers"

USER 1000

COPY ./catalog.yml /datasets/catalog.yml
COPY ./datasets/eu_transparency_register /datasets/eu_transparency_register
COPY ./datasets/eu_authorities /datasets/eu_authorities
COPY ./datasets/ec_meetings /datasets/ec_meetings
