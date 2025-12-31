open! Core
open! Hardcaml

val num_bits : int

(*_ The module interface exports the same I/O records. Note that the widths don't need to
    be specified in the interface. *)
module I : sig
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; start : 'a
    ; data_in_magnitude : 'a
    ; data_in_direction : 'a
    ; data_in_valid : 'a
    }
  [@@deriving hardcaml]
end

module O : sig
  type 'a t =
    { next_ready : 'a
    ; result : 'a
    }
  [@@deriving hardcaml]
end

val part1_hierarchical : Scope.t -> Signal.t I.t -> Signal.t O.t
val part1_create : Scope.t -> Signal.t I.t -> Signal.t O.t
val part2_hierarchical : Scope.t -> Signal.t I.t -> Signal.t O.t
val part2_create : Scope.t -> Signal.t I.t -> Signal.t O.t
