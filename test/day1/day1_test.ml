open! Core
open! Hardcaml
open! Hardcaml_waveterm
module C_sim = Cyclesim.With_interface (Day1.I) (Day1.O)

let ( <--. ) = Bits.( <--. )
let lines = Parser.read_day ~n:1 ~short:false

let input_values =
  List.map
    ~f:(fun s ->
      let direction = int_of_char s.[0] = int_of_char 'L' in
      let magnitude = int_of_string (String.sub s ~pos:1 ~len:(String.length s - 1)) in
      direction, magnitude)
    lines
;;

let simple_testbench sim =
  let inputs : _ Day1.I.t = Cyclesim.inputs sim in
  let outputs : _ Day1.O.t = Cyclesim.outputs sim in
  let cycle ?n () = Cyclesim.cycle ?n sim in
  let peek_next_ready () = Bits.to_bool !(outputs.next_ready) in
  let feed_input ~dir ~num =
    inputs.data_in_magnitude <--. num;
    inputs.data_in_direction <--. if dir then 1 else 0;
    while not (peek_next_ready ()) do
      cycle ()
    done;
    inputs.data_in_valid := Bits.vdd;
    cycle ();
    inputs.data_in_valid := Bits.gnd;
    cycle ()
  in
  inputs.clear := Bits.vdd;
  cycle ();
  inputs.clear := Bits.gnd;
  cycle ();
  inputs.start := Bits.vdd;
  cycle ();
  inputs.start := Bits.gnd;
  List.iter input_values ~f:(fun (dir, num) -> feed_input ~dir ~num);
  while not (peek_next_ready ()) do
    cycle ()
  done;
  let result = Bits.to_signed_int !(outputs.result) in
  print_s [%message "Result" (result : int)];
  cycle ~n:2 ()
;;

let%expect_test "Day 1 Part 1:" =
  let scope =
    Scope.create () ~auto_label_hierarchical_ports:true ~trace_properties:true
  in
  let sim = C_sim.create (Day1.part1_create scope) in
  let waves, sim = Waveform.create sim in
  simple_testbench sim;
  let display_rules =
    [ Display_rule.port_name_matches
        ~wave_format:(Bit_or Int)
        (Re.Glob.glob "*" |> Re.compile)
    ]
  in
  Waveform.print ~display_rules ~signals_width:30 ~display_width:92 ~wave_width:1 waves;
  [%expect
    {|
    (Result (result 1100))
    ┌Signals─────────────────────┐┌Waves───────────────────────────────────────────────────────┐
    │clear                       ││────┐                                                       │
    │                            ││    └───────────────────────────────────────────────────────│
    │clock                       ││┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ │
    │                            ││  └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─│
    │data_in_direction           ││                                    ┌───────────────────────│
    │                            ││────────────────────────────────────┘                       │
    │                            ││────────────┬───────────┬───────────┬───────────┬───────────│
    │data_in_magnitude           ││ 0          │41         │17         │15         │2          │
    │                            ││────────────┴───────────┴───────────┴───────────┴───────────│
    │data_in_valid               ││                ┌───┐       ┌───┐       ┌───┐       ┌───┐   │
    │                            ││────────────────┘   └───────┘   └───────┘   └───────┘   └───│
    │start                       ││        ┌───┐                                               │
    │                            ││────────┘   └───────────────────────────────────────────────│
    │next_ready                  ││                ┌───┐       ┌───┐       ┌───┐       ┌───┐   │
    │                            ││────────────────┘   └───────┘   └───────┘   └───────┘   └───│
    │                            ││────────────────────────────────────────────────────────────│
    │result                      ││ 0                                                          │
    │                            ││────────────────────────────────────────────────────────────│
    └────────────────────────────┘└────────────────────────────────────────────────────────────┘
    |}]
;;

let%expect_test "Day 1 Part 2:" =
  let scope = Scope.create () in
  let sim = C_sim.create (Day1.part2_create scope) in
  let waves, sim = Waveform.create sim in
  simple_testbench sim;
  let display_rules =
    [ Display_rule.port_name_matches
        ~wave_format:(Bit_or Int)
        (Re.Glob.glob "*" |> Re.compile)
    ]
  in
  Waveform.print ~display_rules ~signals_width:30 ~display_width:92 ~wave_width:1 waves;
  [%expect
    {|
    (Result (result 6358))
    ┌Signals─────────────────────┐┌Waves───────────────────────────────────────────────────────┐
    │clear                       ││────┐                                                       │
    │                            ││    └───────────────────────────────────────────────────────│
    │clock                       ││┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ │
    │                            ││  └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─│
    │data_in_direction           ││                                    ┌───────────────────────│
    │                            ││────────────────────────────────────┘                       │
    │                            ││────────────┬───────────┬───────────┬───────────┬───────────│
    │data_in_magnitude           ││ 0          │41         │17         │15         │2          │
    │                            ││────────────┴───────────┴───────────┴───────────┴───────────│
    │data_in_valid               ││                ┌───┐       ┌───┐       ┌───┐       ┌───┐   │
    │                            ││────────────────┘   └───────┘   └───────┘   └───────┘   └───│
    │start                       ││        ┌───┐                                               │
    │                            ││────────┘   └───────────────────────────────────────────────│
    │next_ready                  ││                ┌───┐       ┌───┐       ┌───┐       ┌───┐   │
    │                            ││────────────────┘   └───────┘   └───────┘   └───────┘   └───│
    │                            ││────────────────────────────────────────┬───────┬───────────│
    │result                      ││ 0                                      │1      │2          │
    │                            ││────────────────────────────────────────┴───────┴───────────│
    └────────────────────────────┘└────────────────────────────────────────────────────────────┘
    |}]
;;

(* Debug – With all Variables printed *)

(* open! Hardcaml_test_harness
module Harness = Cyclesim_harness.Make (Day1.I) (Day1.O)

let%expect_test "Debug waveform:" =
  (* For simple tests, we can print the waveforms directly in an expect-test (and use the
     command [dune promote] to update it after the tests run). This is useful for quickly
     visualizing or documenting a simple circuit, but limits the amount of data that can
     be shown. *)
  let display_rules =
    [ Display_rule.port_name_matches
        ~wave_format:(Bit_or Int)
        (Re.Glob.glob "day1_p2*" |> Re.compile)
    ]
  in
  Harness.run_advanced
    ~create:Day1.part2_hierarchical
    ~trace:`All_named
    ~print_waves_after_test:(fun waves ->
      Waveform.print
        ~display_rules
          (* [display_rules] is optional, if not specified, it will print all named
             signals in the design. *)
        ~signals_width:30
        ~display_width:92
        ~wave_width:1
        (* [wave_width] configures how many chars wide each clock cycle is *)
        waves)
    simple_testbench;
  [%expect
    {|
    (Result (result 6))
    ┌Signals─────────────────────┐┌Waves───────────────────────────────────────────────────────┐
    │                            ││────────────┬───────┬───────────┬───────┬───────────┬───────│
    │day1_p2$cur                 ││ 0          │50     │-18        │82     │52         │152    │
    │                            ││────────────┴───────┴───────────┴───────┴───────────┴───────│
    │day1_p2$i$clear             ││────┐                                                       │
    │                            ││    └───────────────────────────────────────────────────────│
    │day1_p2$i$clock             ││┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ │
    │                            ││  └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─│
    │day1_p2$i$data_in_direction ││            ┌───────────────────────────────┐               │
    │                            ││────────────┘                               └───────────────│
    │                            ││────────────┬───────────┬───────────────────┬───────────────│
    │day1_p2$i$data_in_magnitude ││ 0          │68         │30                 │48             │
    │                            ││────────────┴───────────┴───────────────────┴───────────────│
    │day1_p2$i$data_in_valid     ││                ┌───┐               ┌───┐               ┌───│
    │                            ││────────────────┘   └───────────────┘   └───────────────┘   │
    │day1_p2$i$start             ││        ┌───┐                                               │
    │                            ││────────┘   └───────────────────────────────────────────────│
    │day1_p2$o$next_ready        ││                ┌───┐               ┌───┐               ┌───│
    │                            ││────────────────┘   └───────────────┘   └───────────────┘   │
    │                            ││────────────────────────┬───────────────────────────────────│
    │day1_p2$o$result            ││ 0                      │1                                  │
    │                            ││────────────────────────┴───────────────────────────────────│
    │                            ││────────────┬───────────────────────┬───────────────────┬───│
    │day1_p2$prev                ││ 0          │50                     │82                 │52 │
    │                            ││────────────┴───────────────────────┴───────────────────┴───│
    │                            ││────────────────────────────────────────────────────────────│
    │day1_p2$temp                ││ 0                                                          │
    │                            ││────────────────────────────────────────────────────────────│
    └────────────────────────────┘└────────────────────────────────────────────────────────────┘
    |}]
;; *)
