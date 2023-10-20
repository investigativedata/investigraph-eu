FROM ghcr.io/investigativedata/investigraph:main

USER root
RUN apt install -y curl
RUN pip install lxml html5lib psycopg2-binary
RUN pip uninstall -y followthemoney
RUN pip install "followthemoney @ git+https://github.com/investigativedata/followthemoney.git@schema/science-identifiers"

USER 1000

COPY ./catalog.yml /data/catalog.yml
COPY ./datasets/eu_transparency_register /data/datasets/eu_transparency_register
COPY ./datasets/eu_authorities /data/datasets/eu_authorities
COPY ./datasets/ec_meetings /data/datasets/ec_meetings

RUN investigraph add-block -b local-file-system/datasets -u /data/datasets

ENV DATASETS_BLOCK local-file-system/datasets
