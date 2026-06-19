.PHONY: help check clean example test

help:
	@echo "make check                  validate this submission (files, metadata, data)"
	@echo "make clean INPUT=raw.csv    clean a raw Tier-1 survey export into predictions/"
	@echo "make example                (maintainers) regenerate codebook, examples, questionnaire"
	@echo "make test                   (maintainers) run the parity + validator test suite"

check:
	Rscript scripts/check.R

clean:
	@test -n "$(INPUT)" || (echo "usage: make clean INPUT=your_raw_export.csv" && exit 1)
	Rscript scripts/clean.R "$(INPUT)"

example:
	Rscript build/make_codebook.R
	Rscript build/make_examples.R
	Rscript build/make_questionnaire.R

test:
	Rscript build/test_materials.R
