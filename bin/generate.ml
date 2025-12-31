open! Core
open! Hardcaml

module type Design = sig
  module I : Interface.S
  module O : Interface.S

  val hierarchical : Scope.t -> Signal.t I.t -> Signal.t O.t
  val name : string
end

let generate_range_finder_rtl (module D : Design) =
  let module C = Circuit.With_interface (D.I) (D.O) in
  let scope = Scope.create ~auto_label_hierarchical_ports:true () in
  let circuit = C.create_exn ~name:(D.name ^ "_top") (D.hierarchical scope) in
  let rtl_circuits =
    Rtl.create ~database:(Scope.circuit_database scope) Verilog [ circuit ]
  in
  let rtl = Rtl.full_hierarchy rtl_circuits |> Rope.to_string in
  print_endline rtl
;;

let make_rtl_command (module D : Design) =
  Command.basic
    ~summary:""
    [%map_open.Command
      let () = return () in
      fun () -> generate_range_finder_rtl (module D)]
;;

let () =
  Command_unix.run
    (Command.group
       ~summary:""
       [ ( "day1-p1"
         , make_rtl_command
             (module struct
               module I = Day1.I
               module O = Day1.O

               let hierarchical = Day1.part1_hierarchical
               let name = "day1_p1"
             end) )
       ; ( "day1-p2"
         , make_rtl_command
             (module struct
               module I = Day1.I
               module O = Day1.O

               let hierarchical = Day1.part2_hierarchical
               let name = "day1_p2"
             end) )
       ])
;;
