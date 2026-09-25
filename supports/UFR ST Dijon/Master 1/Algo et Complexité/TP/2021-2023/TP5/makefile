# Ce makefile est une version modifiee de celui disponible sur le site INRIA de ocaml.

OCAMLC=ocamlfind ocamlc
OCAMLOPT=ocamlfind ocamlopt
INCLUDES=                 # all relevant -I options here
OCAMLFLAGS=$(INCLUDES) -unsafe    # add other options for ocamlc here
OCAMLOPTFLAGS=$(INCLUDES)  -unsafe # add other options for ocamlopt here

EXECUTABLES=newton

all: $(EXECUTABLES)


################# pour compiler sans optimisation 
graphics.cma: graphics.cmo
	$(OCAMLC) -a -o graphics.cma graphics.cmo
newton: graphics.cma tp5_correction.ml
	$(OCAMLC) -o newton graphics.cma tp5_correction.ml


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