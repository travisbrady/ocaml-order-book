open Order

let max_dollar = 10_000

type side = Buy | Sell

module type SideType = sig
    val side : side
end

exception Terminate_fold of int * int * int

module OrderMap(S : SideType) =
    struct
        module MapMod = Map.Make(
            struct 
                type t = int 
                let compare = if S.side = Sell then compare else (fun x y -> compare y x)
            end
        )
        type order_box = {
            target                      : int;
            mutable current_size        : int;
            mutable last_price_taken    : int;
            mutable total_price         : int;
            mutable price_to_size       : int MapMod.t;
            out_buff                    : Buffer.t
        }
        let default_price = if S.side = Sell then max_dollar * 100 + 1 else -1
        let create target out_buff = {
            target              = target;
            current_size        = 0;
            last_price_taken    = default_price;
            total_price         = 0;
            price_to_size       = MapMod.empty;
            out_buff            = out_buff
        }

        let txn_side = if S.side = Buy then " S " else " B "
        let better = if S.side = Buy then (>) else (<)
        let better_eq = if S.side = Buy then (>=) else (<=)

        let fmt_txn om ts price size = 
            let buf = om.out_buff in
            Buffer.add_string buf ts;
            Buffer.add_string buf txn_side;
            if size >= om.target then
                let dollars_str = string_of_int(price/100) in
                let cents = price mod 100 in

                Buffer.add_string buf dollars_str;
                Buffer.add_char buf '.';
                if cents < 10 then Buffer.add_char buf '0';
                Buffer.add_string buf (string_of_int cents);
                Buffer.add_char buf '\n';
                Buffer.output_buffer stdout buf;
                Buffer.reset buf
            else
                Buffer.add_string buf "NA\n";
                Buffer.output_buffer stdout buf;
                Buffer.reset buf

        (* Compose an output string and write to stdout *)
        let fmt_txn om ts price size = 
            (* Using Buffer here is verbose, but performs best *)
            let buf = om.out_buff in
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
        let fmt_na om ts =
            Buffer.add_string om.out_buff ts;
            Buffer.add_string om.out_buff txn_side;
            Buffer.add_string om.out_buff "NA\n";
            Buffer.output_buffer stdout om.out_buff;
            Buffer.reset om.out_buff

        let compute_txn om =
            (* fold takes fn, map, start *)
            let f this_price this_num_shares (last_price, total_price, shares_needed) =
                let shares_to_take = min shares_needed this_num_shares in
                let this_total = this_price * shares_to_take in
                if shares_to_take = shares_needed then (
                    raise (Terminate_fold (this_price, total_price + this_total, shares_needed))
                )
                else (
                    (this_price, total_price + this_total, shares_needed - shares_to_take)
                )
            in 
            try
                MapMod.fold f om.price_to_size (0, 0, om.target)
            with Terminate_fold (last_price, total_price, shares_needed)->
                (last_price, total_price, shares_needed)

        let add_order om order =
            (* Bump size *)
            om.current_size <- om.current_size + order.size;
            let curr_size = 
                try MapMod.find order.price om.price_to_size
                with Not_found -> 0
            in

            om.price_to_size <- MapMod.add order.price (curr_size + order.size) om.price_to_size;

            (* Recompute? *)
            if (om.current_size >= om.target) && (better order.price om.last_price_taken) then (
                let (last_price_taken, total_price, _) = compute_txn om in

                if total_price <> om.total_price then (
                    fmt_txn om order.ts total_price om.current_size;
                    om.total_price <- total_price;
                    om.last_price_taken <- last_price_taken;
                )
            )
            
        let reduce_order om order =
            let old_size = om.current_size in
            om.current_size <- old_size - order.size;
            let curr_size = 
                try MapMod.find order.price om.price_to_size
                with Not_found -> 0
            in
            let new_size = curr_size - order.size in

            let pts = if (new_size = 0) then
                MapMod.remove order.price om.price_to_size
            else
                MapMod.add order.price new_size om.price_to_size
            in
            om.price_to_size <- pts;

            if om.current_size >= om.target && better_eq order.price om.last_price_taken then
                begin
                    (* Case when a transaction is possible *)
                    let (last_price_taken, total_price, _) = compute_txn om in
                    om.last_price_taken <- last_price_taken;
                    if om.total_price != total_price then (
                        om.total_price <- total_price;
                        fmt_txn om order.ts total_price om.current_size;
                    )
                end
            else if old_size >= om.target && om.current_size < om.target then
                begin
                    (* NA *)
                    om.last_price_taken <- default_price;
                    om.total_price <- default_price;
                    fmt_na om order.ts
                    (*fmt_txn om order.ts om.total_price om.current_size;*)
                end
        
end

module BuyMap = OrderMap(struct let side = Buy end)
module SellMap = OrderMap(struct let side = Sell end)
