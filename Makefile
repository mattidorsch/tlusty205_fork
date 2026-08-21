SHELL:=/bin/bash
UNAME_M := $(shell uname -m)
FC = gfortran
FFLAGS = -g -std=legacy -fno-automatic -fno-align-commons -ffixed-form -fcheck=mem -O3 -Wall

# The small code model addresses at most 2 GB of static data, and the COMMON
# blocks of the larger dimensionings exceed that, so those builds need
# -mcmodel=medium.  It is not applied everywhere: it forces the slower/larger
# addressing modes on builds that fit comfortably (the "low" variants sit near
# 0.9 GB of .bss).  Only x86_64 has the flag at all.
ifeq ($(UNAME_M),x86_64)
    MCMODEL = -mcmodel=medium
endif

all:
	$(FC) $(FFLAGS) $(MCMODEL) -o t205_fork tlusty205_fork.f90

# Same as "all", but forced into the small code model; only useful if the
# default dimensioning in INCLUDE/BASICS.FOR has been cut down enough to fit.
small:
	$(FC) $(FFLAGS) -o t205_fork tlusty205_fork.f90

# Variant builds, e.g. "make O70_d4_low" -> t205_O70_d4_low.
# gfortran resolves INCLUDE relative to the source file, so each variant is
# compiled from a symlink next to its own INCLUDE/, where INCLUDE/<variant>/
# overrides BASICS.FOR and ODFPAR.FOR and the remaining files are shared.
#
# Named <type><ND>_d<DDNU>_<levels>: the spectral type it was dimensioned for,
# the depth points, the DDNU its frequency bounds assume, and how many ion
# levels fit (low, mid, high, vhigh).
VARIANTS = sdOstar2020 sdO_full O70_d4_vhigh O70_d4_low O70_d0.75_low \
           B70_d4_low sdO_full_hot O70_d8_vhigh

# Variants that overflow the small code model and therefore need $(MCMODEL);
# the others link without it.  Re-check with "make check-mcmodel" after
# changing any BASICS.FOR.
BIG_VARIANTS = sdOstar2020 sdO_full sdO_full_hot O70_d4_vhigh O70_d8_vhigh

$(BIG_VARIANTS): MCMODEL_VAR = $(MCMODEL)

$(VARIANTS): %: tlusty205_fork.f90 INCLUDE/%/BASICS.FOR INCLUDE/%/ODFPAR.FOR
	mkdir -p build/$@/INCLUDE
	ln -sf $(CURDIR)/INCLUDE/*.FOR build/$@/INCLUDE/
	ln -sf $(CURDIR)/INCLUDE/$@/*.FOR build/$@/INCLUDE/
	ln -sf $(CURDIR)/tlusty205_fork.f90 build/$@/tlusty205_fork.f90
	$(FC) $(FFLAGS) $(MCMODEL_VAR) -o t205_$@ build/$@/tlusty205_fork.f90

# Rebuild every variant in the small code model and report which ones fail to
# link, i.e. which ones actually belong in BIG_VARIANTS.
check-mcmodel:
	@for v in $(VARIANTS); do \
	    mkdir -p build/$$v/INCLUDE; \
	    ln -sf $(CURDIR)/INCLUDE/*.FOR build/$$v/INCLUDE/; \
	    ln -sf $(CURDIR)/INCLUDE/$$v/*.FOR build/$$v/INCLUDE/; \
	    ln -sf $(CURDIR)/tlusty205_fork.f90 build/$$v/tlusty205_fork.f90; \
	    if $(FC) $(filter-out -Wall,$(FFLAGS)) -w -o build/$$v/probe \
	           build/$$v/tlusty205_fork.f90 >build/$$v/probe.log 2>&1; then \
	        echo "$$v: fits the small code model"; \
	    else \
	        echo "$$v: needs $(MCMODEL)"; \
	    fi; \
	done

clean:
	rm -rf build t205_fork $(addprefix t205_,$(VARIANTS))

.PHONY: all small clean check-mcmodel $(VARIANTS)
