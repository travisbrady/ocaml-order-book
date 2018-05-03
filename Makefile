CCFLAGS = -cc cc -ccopt -O3
OCAMLFLAGS = -inline 1000 -unsafe -nodynlink

.PHONY: all clean download tarball

all: pricer

src/order.cmx: src/order.ml
	ocamlopt -I src $(CCFLAGS) $(OCAMLFLAGS) -c src/order.ml

src/ordergrid.cmx: src/ordergrid.ml src/order.cmx
	ocamlopt -I src $(CCFLAGS) $(OCAMLFLAGS) order.cmx -c src/ordergrid.ml

src/orderbook.cmx: src/orderbook.ml src/order.cmx src/ordergrid.cmx
	ocamlopt -I src $(CCFLAGS) $(OCAMLFLAGS) order.cmx ordergrid.cmx -c src/orderbook.ml

pricer: src/pricer.ml src/orderbook.cmx
	ocamlopt -I src  $(CCFLAGS) $(OCAMLFLAGS) order.cmx ordergrid.cmx orderbook.cmx -o pricer src/pricer.ml

clean:
	rm -f pricer src/*.cmx src/*.o src/*.cmi src/*.cmo order_book.tar.gz

tarball:
	git archive --format=tar.gz --prefix=order_book/ HEAD > order_book.tar.gz

download:
	wget -P input_data http://www.rgmadvisors.com/problems/orderbook/pricer.in.gz
	wget -P output_reference http://www.rgmadvisors.com/problems/orderbook/pricer.out.1.gz
	wget -P output_reference http://www.rgmadvisors.com/problems/orderbook/pricer.out.200.gz
	wget -P output_reference http://www.rgmadvisors.com/problems/orderbook/pricer.out.10000.gz
	gunzip input_data/pricer.in.gz
	gunzip output_reference/pricer.out.1.gz
	gunzip output_reference/pricer.out.200.gz
	gunzip output_reference/pricer.out.10000.gz

