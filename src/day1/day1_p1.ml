(* We generally open Core and Hardcaml in any source file in a hardware project. For
   design source files specifically, we also open Signal. *)
open! Core
open! Hardcaml
open! Signal
open! Always

let num_bits = 64

(* We will multiply variables in the DSL by these constants. *)
let div_100_magic_number = of_int_trunc ~width:num_bits 1374389535
let one_hundred = of_int_trunc ~width:num_bits 100

(* Related: https://xania.org/202512/07-division-again *)
(* Applied compiler optimizations: https://godbolt.org/z/GMq19E3eE *)
(* Same behavior as OCaml: *)
(* 110 mod 100 = 10; -10 mod 100 = -10; -110 mod 100 = -10 *)
let mod_100 ~(num : Variable.t) ~(result : Variable.t) =
  if_
    (num.value >=+. 0)
    [ result
      <-- num.value
          -: sel_bottom
               ~width:num_bits
               (sra
                  ~by:37
                  (sel_bottom ~width:num_bits (num.value *: div_100_magic_number))
                *: one_hundred)
    ]
    [ result
      <-- num.value
          -: sel_bottom
               ~width:num_bits
               (sra
                  ~by:37
                  (sel_bottom ~width:num_bits (num.value *: div_100_magic_number))
                *: one_hundred)
          -: one_hundred
    ]
;;

(* Every hardcaml module should have an I and an O record, which define the module
   interface. *)
module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; start : 'a
    ; data_in_magnitude : 'a [@bits num_bits]
    ; data_in_direction : 'a
    ; data_in_valid : 'a
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    {
      next_ready : 'a
    ; result : 'a [@bits num_bits]
    }
  [@@deriving hardcaml]
end

module States = struct
  type t =
    | Idle
    | Accepting_inputs
    | Stage_1
    | Stage_2
  [@@deriving sexp_of, compare ~localize, enumerate]
end

let part1_create
  scope
  ({ clock; clear; start; data_in_magnitude; data_in_direction; data_in_valid } : _ I.t)
  : _ O.t
  =
  let spec = Reg_spec.create ~clock ~clear () in
  let sm = State_machine.create (module States) spec in
  let%hw_var cur = Variable.reg spec ~width:num_bits in
  let next_ready = Variable.reg spec ~width:1 in
  let result = Variable.reg spec ~width:num_bits in
  compile
    [ sm.switch
        [ ( Idle
          , [ when_
                start
                [ cur <-- of_int_trunc ~width:num_bits 50
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
                    [ cur <-- cur.value -: data_in_magnitude ]
                    [ cur <-- cur.value +: data_in_magnitude ]
                ; sm.set_next Stage_1
                ]
                [ next_ready <-- vdd; sm.set_next Accepting_inputs ]
            ] )
        ; Stage_1, [ mod_100 ~num:cur ~result:cur; sm.set_next Stage_2 ]
        ; ( Stage_2
          , [ when_ (cur.value ==:. 0) [ result <-- result.value +:. 1 ]
            ; next_ready <-- vdd
            ; sm.set_next Accepting_inputs
            ] )
        ]
    ];
  { result = result.value; next_ready = next_ready.value }
;;

let part1_hierarchical scope =
  let module Scoped = Hierarchy.In_scope (I) (O) in
  Scoped.hierarchical ~scope ~name:"day1_p1" part1_create
;;
