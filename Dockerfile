FROM ghcr.io/investigativedata/investigraph:develop

USER root
RUN apt install -y curl

USER 1000

COPY ./catalog.yml /data/catalog.yml
COPY ./datasets/eu_transparency_register /data/datasets/eu_transparency_register
COPY ./datasets/eu_authorities /data/datasets/eu_authorities
COPY ./datasets/ec_meetings /data/datasets/ec_meetings

RUN investigraph add-block -b local-file-system/datasets -u /data/datasets

ENV DATASETS_BLOCK local-file-system/datasets
ENV REDIS_URL=redis://redis:6379/0
