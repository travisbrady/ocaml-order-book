(*
 * Brief test of order parsing
 *)
open Order

let test_adds =
    let add1 = "28800538 A b S 44.26 100" in
    let add1_o = SellOrder {ts="28800538"; oid="b"; price=4426; size=100}  in
    assert (order_of_string add1 = add1_o);

    let add2 = "55797135 A zvthb B 44.49 100" in
    let add2_o = BuyOrder {ts="55797135"; oid="zvthb"; price=4449; size=100} in

    assert (order_of_string add2 = add2_o)

