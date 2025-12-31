open! Core
open! Hardcaml
open! Signal
open! Always
open! Day1_p1

let div_100 ~(num : Variable.t) ~(result : Variable.t) =
  if_
    (num.value >=+. 0)
    [ result
      <-- sra ~by:37 (sel_bottom ~width:num_bits (num.value *: div_100_magic_number))
    ]
    [ result
      <-- sra ~by:37 (sel_bottom ~width:num_bits (num.value *: div_100_magic_number))
          +:. 1
    ]
;;

let abs_add ~(num : Variable.t) ~(result : Variable.t) =
  if_
    (num.value <+. 0)
    [ result
      <-- result.value
          +: sel_bottom ~width:num_bits (num.value *: of_int_trunc ~width:num_bits (-1))
    ]
    [ result <-- result.value +: num.value ]
;;

let part2_create
  scope
  ({ clock; clear; start; data_in_magnitude; data_in_direction; data_in_valid } : _ I.t)
  : _ O.t
  =
  let spec = Reg_spec.create ~clock ~clear () in
  let sm = State_machine.create (module States) spec in
  let%hw_var cur = Variable.reg spec ~width:num_bits in
  let%hw_var prev = Variable.reg spec ~width:num_bits in
  (* Stores cur / 100, and its absolute values will be added to the result. *)
  let%hw_var temp = Variable.reg spec ~width:num_bits in
  let next_ready = Variable.reg spec ~width:1 in
  let result = Variable.reg spec ~width:num_bits in
  compile
    [ sm.switch
        [ ( Idle
          , [ when_
                start
                [ cur <-- of_int_trunc ~width:num_bits 50
                ; prev <-- of_int_trunc ~width:num_bits 50
                ; result <-- zero num_bits
                ; next_ready <-- gnd
                ; sm.set_next Accepting_inputs
                ]
            ] )
        ; ( Accepting_inputs
          , [ if_
                data_in_valid
                [ next_ready <-- gnd
                ; if_
                    data_in_direction
                    [ cur <-- prev.value -: data_in_magnitude ]
                    [ cur <-- prev.value +: data_in_magnitude ]
                ; sm.set_next Stage_1
                ]
                [ next_ready <-- vdd; sm.set_next Accepting_inputs ]
            ] )
        ; ( Stage_1
          , [ when_
                (prev.value >+. 0)
                [ when_ (cur.value <=+. 0) [ result <-- result.value +:. 1 ] ]
            ; div_100 ~num:cur ~result:temp
            ; mod_100 ~num:cur ~result:cur
            ; sm.set_next Stage_2
            ] )
        ; ( Stage_2
          , [ abs_add ~num:temp ~result
            ; if_ (cur.value <+. 0) [ prev <-- cur.value +:. 100 ] [ prev <-- cur.value ]
            ; next_ready <-- vdd
            ; sm.set_next Accepting_inputs
            ] )
        ]
    ];
  { result = result.value; next_ready = next_ready.value }
;;

let part2_hierarchical scope =
  let module Scoped = Hierarchy.In_scope (I) (O) in
  Scoped.hierarchical ~scope ~name:"day1_p2" part2_create
;;
