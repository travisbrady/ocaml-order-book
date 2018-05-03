(*
 * order.ml
 * Contains the order type t and functions for parsing pricer.in records to
 * orders
 *)

type order_record = {
    ts: string; 
    oid: string; 
    price: int; 
    size: int
}

type t = 
        | BuyOrder of order_record
        | SellOrder of order_record
        | ReduceOrder of order_record

let string_after s n = String.sub s n (String.length s - n)

let parse_common ordstr = 
    let ts = String.sub ordstr 0 8 in
    let order_type = ordstr.[9] in
    let oid_end_idx = String.index_from ordstr 11 ' ' in
    let oid = String.sub ordstr 11 (oid_end_idx - 11) in
    let size_start_idx = String.rindex ordstr ' ' in

    let size_str = string_after ordstr (size_start_idx + 1) in
    let rest = String.sub ordstr (oid_end_idx + 1) (size_start_idx - oid_end_idx) in
    let size = int_of_string size_str in
    (ts, order_type, oid, size, rest)

let parse_add_order ts oid size ordstr =
    let price_str = String.sub ordstr 2 (String.length ordstr - 3) in
    (* Abuse the fact that OCaml ignores underscores when parsing numbers *)
    price_str.[String.length price_str - 3] <- '_';
    let price = int_of_string price_str in
    let record = {
        ts      = ts; 
        oid     = oid; 
        price   = price; 
        size    = size
    } in
    match ordstr.[0] with
    | 'B' -> BuyOrder record
    | 'S' -> SellOrder record
    | _ -> failwith "Invalid side char"

let parse_reduce_order ts oid size =
    ReduceOrder ({ts = ts; oid = oid; price = -999; size = size})

(* parse an order from a string *)
let order_of_string ordstr =
    let ts,order_type,order_id,size,rest = parse_common ordstr in
    match order_type with
    | 'R' -> parse_reduce_order ts order_id size
    | 'A' -> parse_add_order ts order_id size rest
    | _ -> failwith "Invalid order_type char"

