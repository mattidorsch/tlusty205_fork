SHELL:=/bin/bash
UNAME_M := $(shell uname -m)
FC = gfortran
FFLAGS = -g -std=legacy -fno-automatic -fno-align-commons -ffixed-form -fcheck=mem -O3 -Wall

ifeq ($(UNAME_M),x86_64)
    FFLAGS += -mcmodel=medium
endif

all:
	$(FC) $(FFLAGS) -o t205_fork tlusty205_fork.f90

small:
	$(FC) $(filter-out -mcmodel=medium,$(FFLAGS)) -o t205_fork tlusty205_fork.f90

# Variant builds, e.g. "make O70_d4_low" -> t205_O70_d4_low.
# gfortran resolves INCLUDE relative to the source file, so each variant is
# compiled from a symlink next to its own INCLUDE/, where INCLUDE/<variant>/
# overrides BASICS.FOR and ODFPAR.FOR and the remaining files are shared.
#
# Named <type><ND>_d<DDNU>_<levels>: the spectral type it was dimensioned for,
# the depth points, the DDNU its frequency bounds assume, and how many ion
# levels fit (low, mid, high, vhigh).
VARIANTS = sdOstar2020 sdO_full O70_d4_vhigh O70_d4_low O70_d0.75_low

$(VARIANTS): %: tlusty205_fork.f90 INCLUDE/%/BASICS.FOR INCLUDE/%/ODFPAR.FOR
	mkdir -p build/$@/INCLUDE
	ln -sf $(CURDIR)/INCLUDE/*.FOR build/$@/INCLUDE/
	ln -sf $(CURDIR)/INCLUDE/$@/*.FOR build/$@/INCLUDE/
	ln -sf $(CURDIR)/tlusty205_fork.f90 build/$@/tlusty205_fork.f90
	$(FC) $(FFLAGS) -o t205_$@ build/$@/tlusty205_fork.f90

clean:
	rm -rf build t205_fork $(addprefix t205_,$(VARIANTS))

.PHONY: all small clean $(VARIANTS)
