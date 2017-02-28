FC=gfortran
FFLAGS=-fdefault-real-8 -fdefault-double-8\
 				-Ofast\
				-g -Wall -Wextra -Warray-temporaries -Wconversion -fimplicit-none -fbacktrace\
				-ffree-line-length-0 -fcheck=all -ffpe-trap=zero,overflow,underflow,invalid -finit-real=nan\
				-fopenmp

SRC=\
	const.f90\
	kernel/base_cubic.f90\
	kernel/base_quintic.f90\
	kernel/base_external.f90\
	kernel/base_gaus.f90\
	kernel/base_sinq.f90\
	kernel/n2movedgaus.f90\
	kernel/n2ext.f90\
	kernel/kernel.f90\
	args.f90\
	printer.f90\
	eos.f90\
	BC.f90\
	utils.f90\
	IC/initpositions.f90\
	IC/semiuniform.f90\
	IC/IC.f90\
	neighbour_search.f90\
	circuit1.f90\
	circuit2.f90\
	errcalc.f90\
	bias.f90\
	iterator.f90\
	main.f90

OBJ=$(SRC:.f90=.o)
SUBSRC=$(addprefix src/, $(SRC))
SUBOBJ=$(addprefix obj/, $(OBJ))

ifndef dim
$(warning dimention is not set, `dim=1` will be used)
dim=1
endif

%.o : src/%.f90
	@mkdir -p obj
	$(FC) $(FFLAGS) -J mod/ -o obj/$@ -c $<
IC/%.o : src/IC/%.f90
	@mkdir -p obj/IC
	@mkdir -p mod
	$(FC) $(FFLAGS) -J mod/ -o obj/$@ -c $<
kernel/%.o : src/kernel/%.f90
	@mkdir -p obj/kernel
	$(FC) $(FFLAGS) -J mod/ -o obj/$@ -c $<

execute: $(OBJ)
	@mkdir -p output
	$(FC) $(FFLAGS) -I mod/ -o $@ $(SUBOBJ)

hydroshock1:
	make && time ./execute $(dim) hydroshock 0.1 runresult.info fab

infslb:
	make && time ./execute $(dim) infslb 0.1 runresult.info fab 5

hc-sinx:
	make && time ./execute $(dim) hc-sinx 0.1 runresult.info fab .5

chi-only:
	make && time ./execute $(dim) hc-sinx 0.002 runresult.info fab -1.5

pheva:
	make && time ./execute $(dim) pheva 0.002 runresult.info fab -1.5

difflaplace:
	make && time ./execute $(dim) diff-laplace .4 runresult.info fab 0.1 1.2

diffgraddiv:
	make && time ./execute $(dim) diff-graddiv .4 runresult.info fab 0.1 1.2

.PHONY: execute

clean:
	rm -rf obj/*; rm -rf mod/*; rm -r *.png; rm execute; rm -f output/*