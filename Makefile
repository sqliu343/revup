BUILD_DIR=build

PYTHON ?= /usr/bin/env python3.8

all: deps lint man package install

# Install dependent pip packages, needed to lint or build
deps:
	$(PYTHON) -m pip install black isort pylint mypy build twine
	$(PYTHON) -m pip install .

# Format using black
BLACK_CMD=$(PYTHON) -m black --line-length 100 -t py38 --preview --exclude "build/.*|\.eggs/.*"
ISORT_CMD=$(PYTHON) -m isort --profile black --py 38
format:
	$(BLACK_CMD) .
	$(ISORT_CMD) .

# Check formatting using black
check_format:
	$(BLACK_CMD) --check --diff .
	$(ISORT_CMD) --check --diff .

MYPY_COMMAND=$(PYTHON) -m mypy --show-error-code
check_types:
	$(MYPY_COMMAND) revup

pylint:
	$(PYTHON) -m pylint revup

# Lint check for formatting and type hints
# This needs pass before any merge.
lint: check_types check_format pylint

# Clean all artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -rf .mypy_cache

package: man
	$(PYTHON) -m build --outdir $(BUILD_DIR)

REVUP_VERSION:=$(shell $(PYTHON) revup/__init__.py)
REVUP_DATE ?= Apr 21, 2021
REVUP_HEADER=---\ntitle: TITLE\nsection: 1\nheader: Revup Manual\nfooter: revup VERSION\ndate: DATE\n---\n

install:
	$(PYTHON) -m pip install build/revup-$(REVUP_VERSION)-py3-none-any.whl --force-reinstall

upload:
	$(PYTHON) -m twine upload build/revup-$(REVUP_VERSION).tar.gz

man:
	cd docs ; \
	for file in *.md ; do \
		CMD_NAME=`echo $${file} | awk -F'[.]' '{print $$1}'` ; \
		echo "$(REVUP_HEADER)" | m4 -DTITLE=$${CMD_NAME} -DVERSION=$(REVUP_VERSION) -DDATE="$(REVUP_DATE)" - | \
		cat - $${file} | pandoc -s -t man > ../revup/man1/$${CMD_NAME}.1 ; \
		gzip -n -f -k ../revup/man1/$${CMD_NAME}.1 ; \
	done ;

.PHONY: all deps man install package format check_format check_types pylint lint clean
