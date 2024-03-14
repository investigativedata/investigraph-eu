FROM ghcr.io/investigativedata/investigraph:main

USER root
RUN apt install -y curl
RUN pip install lxml html5lib
RUN pip uninstall -y followthemoney
RUN pip install "followthemoney @ git+https://github.com/investigativedata/followthemoney.git@schema/science-identifiers"
