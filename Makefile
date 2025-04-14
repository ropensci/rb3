# Makefile for generating README.RData and README.md

# Define the R command
RSCRIPT = Rscript

RMD_FILES := $(wildcard vignettes/*.Rmd)
HTML_FILES := $(RMD_FILES:.Rmd=.html)
VIGNETTE_DATA_SCRIPTS := $(wildcard vignettes/save_*.R)
VIGNETTE_RDATA_FILES := $(VIGNETTE_DATA_SCRIPTS:vignettes/save_%.R=vignettes/data_%.RData)

# Targets
all: README.RData README.md

# Generate README.RData
README.RData: README.R
	$(RSCRIPT) README.R

# Generate README.md
README.md: README.Rmd README.RData
	$(RSCRIPT) -e "devtools::build_readme()"

vignettes: $(HTML_FILES) $(VIGNETTE_RDATA_FILES)

vignettes-data: $(VIGNETTE_RDATA_FILES)

vignettes/data_%.RData: vignettes/save_%.R
	$(RSCRIPT) $<

vignettes/%.html: vignettes/%.Rmd
	$(RSCRIPT) -e "devtools::load_all(); rmarkdown::render('$<', output_format = 'html_document', output_file = '$@')"

clean-vignettes:
	rm vignettes/*.html vignettes/*.RData

clean:
	rm README.md README.RData
