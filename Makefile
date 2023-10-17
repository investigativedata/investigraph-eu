DATA_DIR := data
SRC_DIR := docs
BUILD_DIR := site
TMPL_DIR := templates
REMOTE_DATA := https://data.ftm.store
GITHUB_REPO := https://github.com/investigativedata/investigraph-eu
CATALOG := catalog.yml
DATASET_NAMES := ec_meetings eu_transparency_register eu_fts eu_authorities eu_meps eu_cor_members eu_fsf eu_horizon_europe eu_fp7
DATASETS := $(DATASET_NAMES:%=$(SRC_DIR)/datasets/%.md)

all: clean $(BUILD_DIR)

$(BUILD_DIR): content
	mkdocs build -c -d $(BUILD_DIR)

$(DATA_DIR):
	mkdir -p $(DATA_DIR)

$(DATA_DIR)/catalog.json: $(DATA_DIR)
	investigraph build-catalog $(CATALOG) > $(DATA_DIR)/catalog.json

$(DATA_DIR)/eu_meps.json: REMOTE_DATA = https://data.opensanctions.org/datasets/latest
$(DATA_DIR)/eu_fsf.json: REMOTE_DATA = https://data.opensanctions.org/datasets/latest
$(DATA_DIR)/eu_cor_members.json: REMOTE_DATA = https://data.opensanctions.org/datasets/latest
$(DATA_DIR)/%.json: $(DATA_DIR)
	curl -s $(REMOTE_DATA)/$*/index.json > $(DATA_DIR)/$*.json

$(SRC_DIR)/datasets:
	mkdir -p $(SRC_DIR)/datasets

$(SRC_DIR)/index.md: $(DATA_DIR)/catalog.json
	jinja -d $(DATA_DIR)/catalog.json $(TMPL_DIR)/index.md.j2 > $(SRC_DIR)/index.md

README.md: $(DATA_DIR)/catalog.json
	jinja -d $(DATA_DIR)/catalog.json $(TMPL_DIR)/index.md.j2 > README.md

$(SRC_DIR)/datasets/ec_meetings.md: collection_id = 437
$(SRC_DIR)/datasets/eu_authorities.md: collection_id = 439
$(SRC_DIR)/datasets/eu_transparency_register.md: collection_id = 438
$(SRC_DIR)/datasets/eu_fts.md: collection_id = 63
$(SRC_DIR)/datasets/eu_meps.md: collection_id = 8
$(SRC_DIR)/datasets/eu_cor_members.md: collection_id = 292
$(SRC_DIR)/datasets/eu_fsf.md: collection_id = 291
$(SRC_DIR)/datasets/eu_horizon_europe.md: collection_id = 515
$(SRC_DIR)/datasets/eu_fp7.md: collection_id = 514
$(SRC_DIR)/datasets/%.md: $(SRC_DIR)/datasets $(DATA_DIR)/%.json
	jinja -D collection_id $(collection_id) -d $(DATA_DIR)/$*.json $(TMPL_DIR)/dataset.md.j2 > $(SRC_DIR)/datasets/$*.md

mkdocs.yml: $(DATA_DIR)/catalog.json
	jinja -d $(DATA_DIR)/catalog.json $(TMPL_DIR)/mkdocs.yml.j2 > mkdocs.yml

.PHONY: content
content: mkdocs.yml $(SRC_DIR)/index.md $(DATASETS)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(DATA_DIR)
	rm -rf $(SRC_DIR)/index.md
	rm -rf $(SRC_DIR)/datasets/
	rm -rf mkdocs.yml

.PHONY: clean_content
clean_content:
	rm -rf $(SRC_DIR)/index.md
	rm -rf $(SRC_DIR)/datasets/
	rm -rf mkdocs.yml

.PHONY: serve
serve: clean_content content
	mkdocs serve

.PHONY: generate
generate: clean_content content

