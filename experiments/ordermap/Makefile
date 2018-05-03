# Makefile for Ordermap
CCFLAGS = -cc cc -ccopt -O3
OCAMLFLAGS = -inline 1000 -unsafe -nodynlink

.PHONY: all clean

all: pricer

order.cmx: order.ml
	ocamlopt $(CCFLAGS) $(OCAMLFLAGS) -c order.ml

ordermap.cmx: ordermap.ml order.cmx
	ocamlopt $(CCFLAGS) $(OCAMLFLAGS) order.cmx -c ordermap.ml

orderbook.cmx: orderbook.ml order.cmx ordermap.cmx
	ocamlopt $(CCFLAGS) $(OCAMLFLAGS) order.cmx ordermap.cmx -c orderbook.ml

pricer: pricer.ml orderbook.cmx
	ocamlopt $(CCFLAGS) $(OCAMLFLAGS) order.cmx ordermap.cmx orderbook.cmx -o pricer pricer.ml

clean:
	rm -f pricer *.cmx *.o *.cmi *.cmo
