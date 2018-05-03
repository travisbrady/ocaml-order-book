(*
 * ordergrid.ml
 * This is the workhorse.  This module implements the add_order and reduce_order
 * logic
 *)
open Order

let max_dollar = 5_000

type side = Buy | Sell
module type SideType = sig
    val side : side
end

module OrderGrid(S : SideType) =
    struct
        type order_box = {
            target                      : int;
            mutable current_size        : int;          (* shares currently this side *)
            mutable last_price_taken    : int;          (* worst price from last transaction *)
            mutable best_price          : int;          (* best price this side *)
            mutable total_price         : int;
            price_to_size               : int array;    (* map price points (array indexes) to sizes available at that price point *)
            out_buff                    : Buffer.t
        }

        (* one cent worse than the theoretical worst possible price *)
        let default_price = if S.side = Sell then max_dollar * 100 + 1 else -1

        let create target out_buff = {
            target              = target;
            current_size        = 0;
            last_price_taken    = default_price;
            best_price          = default_price;
            total_price         = 0;
            price_to_size       = (Array.make (max_dollar * 100) 0);
            out_buff            = out_buff
        }

        (* output transaction side *)
        let txn_side = if S.side = Buy then " S " else " B "

        (* bid is higher or ask is lower *)
        let better = if S.side = Buy then (>) else (<)
        let better_eq = if S.side = Buy then (>=) else (<=)
        let next_price = if S.side = Buy then pred else succ

        (* Compose an output string and write to stdout *)
        let fmt_txn og ts price size =
            (* Using Buffer here is verbose, but performs best *)
            let buf = og.out_buff in
            let cents = price mod 100 in
            let dollars_str = string_of_int(price/100) in

            Buffer.add_string buf ts;
            Buffer.add_string buf txn_side;
            Buffer.add_string buf dollars_str;
            Buffer.add_char buf '.';
            if cents < 10 then Buffer.add_char buf '0';
            Buffer.add_string buf (string_of_int cents);
            Buffer.add_char buf '\n';
            Buffer.output_buffer stdout buf;
            Buffer.reset buf

        (* Print an NA to stdout when fewer than target size shares are available*)
        let fmt_na og ts =
            Buffer.add_string og.out_buff ts;
            Buffer.add_string og.out_buff txn_side;
            Buffer.add_string og.out_buff "NA\n";
            Buffer.output_buffer stdout og.out_buff;
            Buffer.reset og.out_buff

        let compute_txn og =
            (* Do we need to find the best current price in the loop? *)
            let find_best = ref (og.price_to_size.(og.best_price) = 0) in

            (* loop over array of price points *)
            let rec aux price shares_needed total_price =
                let size_this_price = og.price_to_size.(price) in
                if !find_best && (size_this_price > 0) then
                    begin
                        (* Reset best price so we know where to start looping
                         * next time *)
                        og.best_price <- price;
                        find_best := false
                    end
                else ();
                (* Grab this many shares from current price point *)
                let shares_to_take = min shares_needed og.price_to_size.(price) in
                let this_total = price * shares_to_take in
                if shares_to_take = shares_needed then
                    (* Done looping, return total transaction amount and last price taken *)
                    (total_price + this_total, price)
                else
                    (* Keep looping *)
                    aux (next_price price) (shares_needed - shares_to_take) (this_total + total_price)
            in
            aux og.best_price og.target 0

        let add_order og order =
            og.current_size <- og.current_size + order.size;
            og.price_to_size.(order.price) <- og.price_to_size.(order.price) + order.size;
            if better order.price og.best_price then og.best_price <- order.price;

            (* Recompute best bundle? *)
            if (og.current_size >= og.target) && (better order.price og.last_price_taken) then (
                (* if we have enough shares on this side and the latest price is
                 * better than the worst price we took last time *)
                let (total_price, last_price_taken) = compute_txn og in

                if total_price <> og.total_price then (
                    (* If there's a change in the overall price we print to stdout *)
                    fmt_txn og order.ts total_price og.current_size;
                    og.total_price <- total_price;
                )
            )

        let reduce_order og order =
            let old_size = og.current_size in
            og.current_size <- old_size - order.size;
            og.price_to_size.(order.price) <- og.price_to_size.(order.price) - order.size;

            (* Recompute best bundle? *)
            if og.current_size >= og.target && better_eq order.price og.last_price_taken then
                begin
                    (* Case when a transaction is possible *)
                    let total_price,last_price_taken = compute_txn og in
                    og.last_price_taken <- last_price_taken;
                    if og.total_price != total_price then (
                        og.total_price <- total_price;
                        fmt_txn og order.ts total_price og.current_size;
                    )
                end
            else if old_size >= og.target && og.current_size < og.target then
                begin
                    (* Fewer than target shares available, so NA *)
                    og.last_price_taken <- default_price;
                    og.total_price <- default_price;
                    fmt_na og order.ts
                end

    end

module BuyGrid = OrderGrid(struct let side = Buy end)
module SellGrid = OrderGrid(struct let side = Sell end)

