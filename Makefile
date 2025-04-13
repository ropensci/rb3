# Makefile for generating README.RData and README.md

# Define the R command
RSCRIPT = Rscript

# Targets
all: README.RData README.md

# Generate README.RData
README.RData: README.R
	$(RSCRIPT) README.R

# Generate README.md
README.md: README.Rmd README.RData
	$(RSCRIPT) -e "devtools::build_readme()"

clean:
	rm README.md README.RData
