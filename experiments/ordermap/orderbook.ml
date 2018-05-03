(*
 * Orderbook type
 * Parses orders and then routes
 *)
open Order
open Ordermap

type t = {
    buy_grid    : BuyMap.order_box;                (* hold bids *)
    sell_grid   : SellMap.order_box;               (* hold asks *)
    oid_map     : (string, side * int) Hashtbl.t;   (* map from order id to side and price *)
    out_buff    : Buffer.t                          (* Shared output buffer *)
}

let create target =
    let out_buff = Buffer.create 800_000 in
    {
        buy_grid    = BuyMap.create target out_buff;
        sell_grid   = SellMap.create target out_buff;
        oid_map     = Hashtbl.create 1_000_000;
        out_buff    = out_buff
    }

(*
 * parse an order string and then route to appropriate side and operation
 *)
let handle_order order_book ordstr =
    match (order_of_string ordstr) with
    | BuyOrder order -> 
            Hashtbl.replace order_book.oid_map order.oid (Buy, order.price);
            BuyMap.add_order order_book.buy_grid order
    | SellOrder order -> 
            Hashtbl.replace order_book.oid_map order.oid (Sell, order.price);
            SellMap.add_order order_book.sell_grid order
    | ReduceOrder order ->
            match Hashtbl.find order_book.oid_map order.oid with
            | Buy,price ->
                BuyMap.reduce_order order_book.buy_grid {order with price = price}
            | Sell,price ->
                SellMap.reduce_order order_book.sell_grid {order with price = price}



