# Ce makefile est une version modifiee de celui disponible sur le site INRIA de ocaml.

OCAMLC=ocamlfind ocamlc
OCAMLOPT=ocamlfind ocamlopt
INCLUDES=                 # all relevant -I options here
OCAMLFLAGS=$(INCLUDES) -unsafe    # add other options for ocamlc here
OCAMLOPTFLAGS=$(INCLUDES)  -unsafe # add other options for ocamlopt here

EXECUTABLES=ex_cube ex_tore ex_menger ex_cubex ex_torex ex_mengerx

all: $(EXECUTABLES)


################# pour compiler sans optimisation 
tp6_commun.cma: image.cmo bernstein.cmo lu_decompose.cmo transfo.cmo ray_tracer.cmo ray_top.cmo tp6_commun.cmo
	$(OCAMLC) -a -o tp6_commun.cma image.cmo bernstein.cmo lu_decompose.cmo transfo.cmo ray_tracer.cmo ray_top.cmo tp6_commun.cmo
ex_cube: tp6_commun.cma tp6_cube.ml
	$(OCAMLC) -o ex_cube graphics.cma tp6_commun.cma tp6_cube.ml
ex_tore: tp6_commun.cma tp6_tore.ml
	$(OCAMLC) -o ex_tore graphics.cma tp6_commun.cma tp6_tore.ml
ex_menger: tp6_commun.cma tp6_menger.ml
	$(OCAMLC) -o ex_menger graphics.cma tp6_commun.cma tp6_menger.ml


################# pour compiler avec optimisation 
tp6_commun.cmxa: image.cmx bernstein.cmx lu_decompose.cmx transfo.cmx ray_tracer.cmx ray_top.cmx tp6_commun.cmx
	$(OCAMLOPT) -a -o tp6_commun.cmxa image.cmx bernstein.cmx lu_decompose.cmx transfo.cmx ray_tracer.cmx ray_top.cmx tp6_commun.cmx
ex_cubex: tp6_commun.cmxa tp6_cube.ml
	$(OCAMLOPT) -o ex_cubex graphics.cmxa tp6_commun.cmxa tp6_cube.ml
ex_torex: tp6_commun.cmxa tp6_tore.ml
	$(OCAMLOPT) -o ex_torex graphics.cmxa tp6_commun.cmxa tp6_tore.ml
ex_mengerx: tp6_commun.cmxa tp6_menger.ml
	$(OCAMLOPT) -o ex_mengerx graphics.cmxa tp6_commun.cmxa tp6_menger.ml


################# common rules
.SUFFIXES: .ml .mli .cmo .cmi .cmx

.ml.cmo:
	$(OCAMLC) $(OCAMLFLAGS) -c $<

.mli.cmi:
	$(OCAMLC) $(OCAMLFLAGS) -c $<

.ml.cmx:
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -c $<


################# clean up
clean:
	rm -f $(EXECUTABLES)
	rm -f *.cm[iox] *.o *.cma *.cmxa *.a