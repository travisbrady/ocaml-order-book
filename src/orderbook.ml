(*
 * orderbook.ml
 * Orderbook type
 *)
open Order
open Ordergrid

type t = {
    buy_grid    : BuyGrid.order_box;                (* hold bids *)
    sell_grid   : SellGrid.order_box;               (* hold asks *)
    oid_map     : (string, side * int) Hashtbl.t;   (* map from order id to side and price *)
    out_buff    : Buffer.t                          (* Shared output buffer *)
}

let create target =
    let out_buff = Buffer.create 800_000 in
    {
        buy_grid    = BuyGrid.create target out_buff;
        sell_grid   = SellGrid.create target out_buff;
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
            BuyGrid.add_order order_book.buy_grid order
    | SellOrder order ->
            Hashtbl.replace order_book.oid_map order.oid (Sell, order.price);
            SellGrid.add_order order_book.sell_grid order
    | ReduceOrder order ->
            match Hashtbl.find order_book.oid_map order.oid with
            | Buy,price ->
                BuyGrid.reduce_order order_book.buy_grid {order with price = price}
            | Sell,price ->
                SellGrid.reduce_order order_book.sell_grid {order with price = price}

