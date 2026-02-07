SRC=src
OUT=$(SRC)/presenter99.bas

FILES = $(filter-out $(OUT), $(shell find src -name "*.bas"))

assemble: $(OUT) $(FILES) scripts/assemble.sh
$(OUT): $(FILES)
	@scripts/assemble.sh

rebase: scripts/rebase.sh
	@scripts/rebase.sh

locate: scripts/locate.sh
	@scripts/locate.sh

clean:
	rm -f $(OUT)

lint: $(FILES) scripts/check_collisions.sh
	scripts/check_collisions.sh

bump: scripts/bump.sh
	@scripts/bump.sh

.PHONY: assemble rebase clean lint bump
