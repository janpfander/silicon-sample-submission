.PHONY: help check clean

help:
	@echo "make check                  validate this submission (files, metadata, data)"
	@echo "make clean                  clean the raw Tier-1 export in raw_data_deposit/ into predictions/"
	@echo "make clean INPUT=raw.csv    clean a specific raw export instead"

check:
	Rscript scripts/check.R

clean:
	@if [ -n "$(INPUT)" ]; then Rscript scripts/clean.R "$(INPUT)"; else Rscript scripts/clean.R; fi
