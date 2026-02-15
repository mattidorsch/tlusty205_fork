SHELL:=/bin/bash
UNAME_M := $(shell uname -m)
FC = gfortran
FFLAGS = -g -std=legacy -fno-automatic -fno-align-commons -ffixed-form -fcheck=mem -O3 -Wall

ifeq ($(UNAME_M),x86_64)
    FFLAGS += -mcmodel=medium
endif

all:
	$(FC) $(FFLAGS) -o t205_fork tlusty205_fork.f90
