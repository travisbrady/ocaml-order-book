Order Book Programming Problem in OCaml
=======================================

This code is quite old but now, keeping around for posterity.

Project Layout
================

- src/ Contains OCaml source code for array-based implementation of OBPP
- src/pricer.ml: entry point, loops over stdin
- src/order.ml: contains order type and parsing code
- src/orderbook.ml: calls order parsing code then routes to appropriate side
- src/ordergrid.ml: the workhouse.  Provides add_order and remove_order
- experiments/ordermap: this directory mirrors the src directory, but includes a tree-based (using OCaml's Map module) implementation of the main data structure
- Makefile: creates the 'pricer' executable and contains utils for downloading data and archiving the project
- input_data: pricer.in
- output_reference: contains output files downloaded (via `make download`) from RGM to compare against my results to verify correctness.
- questions: answers to the 4 questions included in the problem definition
- tools/verify.py: runs both implementations for targets of 1, 200 and 10000 then compares to the output references
- tools/grid_vs_map.py: runs both implementations on many target sizes, times them and generates a csv of results
- grid_vs_map.png: Plot showing median run times for the array-based (Ordergrid) and tree-based (Ordermap) by target size
- summary_stats.R: basic summary stats by target size on grid_vs_map run time data

OCaml Notes
===========

OCaml can be downloaded from: http://caml.inria.fr/download.en.html and is widely-available via standard package managers.
I've successfully installed using apt-get and homebrew. 

## Syntax

- Comments are enclosed in `(* *)`
- `let` : introduces a new identifier
- `let rec` : introduces a recursive function

```ocaml
type my_type = {a: int; b: int} :
(* A record type declaration, fields are named. *)
(* Create a my_type *)
let foo = {a=5; b=10};;
(* Now apply the so called 'functional update'.  Actually creates a new value here with b replaced. *)
{foo with b = 999}

(* `<-` : is used to set mutable record fields OR set a cell in an array 
    For example:
*)
let my_array = Array.make 5 0;;
my_array.(0) <- 999;;
(*
    Sets the 0th element of my_array to 999
*)
```
    
#### Refs:
    A ref is a mutable variable.  Refs are dereferenced with the bang (!) operator and assigned using the := operator.
    Example from interactive session:
```ocaml
        let my_ref = ref 0;;                                                   
        val my_ref : int ref = {contents = 0}                          
        my_ref := 999;;                                                        
        !my_ref;;                                                               
        int = 999
```
