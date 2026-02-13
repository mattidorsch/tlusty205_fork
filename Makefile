all:
	gfortran -g -std=legacy -fno-automatic -ffixed-form -fcheck=mem -O3 -mcmodel=medium -o t205_fork tlusty205_fork.f90

small:
	gfortran -g -std=legacy -fno-automatic -ffixed-form -fcheck=mem -O3 -o t205_fork tlusty205_fork.f90

cluster:
#	module load gcc/6.5.0
	gfortran -fno-automatic -fno-align-commons -ffixed-form -fcheck=all,no-bounds -O3 -mcmodel=medium -g -Wall -Wl,--rpath=/software/Ubuntu-20.04/Programming/gcc/6.5.0/lib64 -Wl,--disable-new-dtags -o t205_fork tlusty205_fork.f90
