# Makefile to build LaTeX project to PDF into out/

# Configuration
MAIN=main
OUTDIR=out
PDF=$(OUTDIR)/$(MAIN).pdf

# Select engine: xelatex (default), lualatex, or pdflatex
ENGINE ?= xelatex

LATEXMK=latexmk
# Base flags for latexmk; engine flag added via LATEXMK_ENGINE_FLAG
LATEXMK_FLAGS=-interaction=nonstopmode -halt-on-error -file-line-error -outdir=$(OUTDIR)

# Choose engine flag for latexmk
ifeq ($(ENGINE),xelatex)
LATEXMK_ENGINE_FLAG=-xelatex
else ifeq ($(ENGINE),lualatex)
LATEXMK_ENGINE_FLAG=-lualatex
else
LATEXMK_ENGINE_FLAG=-pdf
endif

# Detect whether latexmk is available; if not, fallback commands will be used
HAVE_LATEXMK:=$(shell command -v $(LATEXMK) >/dev/null 2>&1 && echo yes || echo no)

# Tectonic single-binary engine (auto-runs biblatex/biber)
TECTONIC=tectonic
TECTONIC_FLAGS=-X compile --outdir $(OUTDIR) --synctex --keep-logs
HAVE_TECTONIC:=$(shell command -v $(TECTONIC) >/dev/null 2>&1 && echo yes || echo no)

# Fallback tools (engine-aware)
ifeq ($(ENGINE),xelatex)
PDFLATEX=xelatex
else ifeq ($(ENGINE),lualatex)
PDFLATEX=lualatex
else
PDFLATEX=pdflatex
endif
BIBTEX=bibtex
PDFLATEX_FLAGS=-interaction=nonstopmode -halt-on-error -file-line-error -output-directory=$(OUTDIR)

CHAPTERS=$(wildcard chapter*.tex)
TEX_SOURCES=$(MAIN).tex $(CHAPTERS)
BIB_SOURCES=$(wildcard *.bib)

.PHONY: all pdf pdf-tectonic clean watch veryclean

all: pdf

pdf: $(PDF)


$(PDF): $(TEX_SOURCES) $(BIB_SOURCES)
ifeq ($(HAVE_LATEXMK),yes)
	@mkdir -p $(OUTDIR)
	$(LATEXMK) $(LATEXMK_ENGINE_FLAG) $(LATEXMK_FLAGS) $(MAIN).tex

else
ifeq ($(HAVE_TECTONIC),yes)
	@mkdir -p $(OUTDIR)
	$(TECTONIC) $(TECTONIC_FLAGS) $(MAIN).tex

else
	@echo "latexmk not found; using pdflatex/bibtex fallback"
	@mkdir -p $(OUTDIR)
	$(PDFLATEX) $(PDFLATEX_FLAGS) $(MAIN).tex || true
	@if [ -n "$(BIB_SOURCES)" ]; then \
		cd $(OUTDIR) && $(BIBTEX) $(MAIN) || true; \
	fi
	$(PDFLATEX) $(PDFLATEX_FLAGS) $(MAIN).tex || true
	$(PDFLATEX) $(PDFLATEX_FLAGS) $(MAIN).tex || true
endif
endif
	@echo "Built: $(PDF)"

pdf-tectonic: $(TEX_SOURCES) $(BIB_SOURCES)
	@mkdir -p $(OUTDIR)
	$(TECTONIC) $(TECTONIC_FLAGS) $(MAIN).tex

watch:
ifeq ($(HAVE_LATEXMK),yes)
	@mkdir -p $(OUTDIR)
	$(LATEXMK) $(LATEXMK_FLAGS) -pvc $(MAIN).tex
else
	@echo "watch requires latexmk; please install latexmk or use: make pdf"
endif

clean:
ifeq ($(HAVE_LATEXMK),yes)
	$(LATEXMK) -C -outdir=$(OUTDIR)
else
	@# Remove common LaTeX aux files in OUTDIR when latexmk is unavailable
	@rm -f $(OUTDIR)/*.aux $(OUTDIR)/*.bbl $(OUTDIR)/*.blg $(OUTDIR)/*.bcf $(OUTDIR)/*.run.xml \
		$(OUTDIR)/*.toc $(OUTDIR)/*.out $(OUTDIR)/*.log $(OUTDIR)/*.lof $(OUTDIR)/*.lot \
		$(OUTDIR)/*.fls $(OUTDIR)/*.fdb_latexmk $(OUTDIR)/*.synctex.gz
endif

veryclean: clean
	@rm -f $(PDF)
