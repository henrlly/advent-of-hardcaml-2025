let read_file filename =
  let ch = open_in filename in
  let rec loop acc =
    try loop (input_line ch :: acc) with
    | End_of_file ->
      close_in ch;
      List.rev acc
  in
  loop []
;;

(* Returns a list of strings, one for each line of the input. *)
(* ~short is for the sample input given as example in the problem statement. *)
let read_day ~n ~short =
  let path = Printf.sprintf "inputs/day%d_%s.in" n (if short then "short" else "full") in
  read_file path
;;
