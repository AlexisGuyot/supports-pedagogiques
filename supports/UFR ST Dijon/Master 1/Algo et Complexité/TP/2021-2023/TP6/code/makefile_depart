# Ce makefile est une version modifiee de celui disponible sur le site INRIA de ocaml.

OCAMLC=ocamlfind ocamlc
OCAMLOPT=ocamlfind ocamlopt
INCLUDES=                 # all relevant -I options here
OCAMLFLAGS=$(INCLUDES) -unsafe    # add other options for ocamlc here
OCAMLOPTFLAGS=$(INCLUDES)  -unsafe # add other options for ocamlopt here

EXECUTABLES=#exemple exemplex

all: ray_top.cma ray_top.cmxa $(EXECUTABLES)


################# pour compiler sans optimisation 
ray_top.cma: image.cmo bernstein.cmo lu_decompose.cmo transfo.cmo ray_tracer.cmo ray_top.cmo
	$(OCAMLC) -a -o ray_top.cma image.cmo bernstein.cmo lu_decompose.cmo transfo.cmo ray_tracer.cmo ray_top.cmo
#exemple: tp6_commun.cma tp6_exemple.ml
#	$(OCAMLC) -o exemple graphics.cma tp6_commun.cma tp6_exemple.ml


################# pour compiler avec optimisation 
ray_top.cmxa: image.cmx bernstein.cmx lu_decompose.cmx transfo.cmx ray_tracer.cmx ray_top.cmx
	$(OCAMLOPT) -a -o ray_top.cmxa image.cmx bernstein.cmx lu_decompose.cmx transfo.cmx ray_tracer.cmx ray_top.cmx
#exemplex: tp6_commun.cma tp6_exemple.ml
#	$(OCAMLOPT) -o exemplex graphics.cmxa tp6_commun.cma tp6_exemple.ml


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
#	rm -f $(EXECUTABLES)
	rm -f *.cm[iox] *.o *.cma *.cmxa *.a