(*
 * pricer.ml
 * This is the entry point for the pricer executable
 * The last function below is the 'main'
 *)

(* Wrap input_line in a try to be tail-recursion friendly *)
let get_row u =
    try
        Some (input_line stdin)
    with End_of_file ->
        None

let () =
    let target = int_of_string(Sys.argv.(1)) in
    let order_book = Orderbook.create target in

    let rec proc () =
        match get_row() with
        | Some ordstr ->
                Orderbook.handle_order order_book ordstr;
                proc ()
        | None -> ()
    in proc()

