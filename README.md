# Advent of FPGA 2025

Advent of Code 2025 in [Hardcaml](https://github.com/janestreet/hardcaml)!

As part of [Advent of FPGA](https://blog.janestreet.com/advent-of-fpga-challenge-2025/).

This repo is adapted from Jane Street's [Hardcaml Template Project](https://github.com/janestreet/hardcaml_template_project/tree/with-extensions).

## Day 1

We parse each line (e.g. `L50`) into its:

1. Direction: `1` for `L`, `0` for `R`
2. Magnitude: e.g. (`50`)

### Part 1

For part 1 we have to count the number of time the dial is at 0 after each rotation.

There is 1 register, `cur`, that stores the current position of the dial.

There are 3 stages:

1. Update `cur` by adding or subtracting magnitude based on the direction
2. Apply mod 100 to `cur`
3. Increment `result` if `cur` is 0

Mod 100 is applied using `num - (num/100) * 100`, using `(num * magic_number) << bits` for division, following a [compiler trick](https://xania.org/202512/07-division-again). [GCC does this too](https://godbolt.org/z/GMq19E3eE).

### Part 2

For part 2 we have to count the number of times the dial touches 0 after each rotation, assuming the dial rotates 1 click at a time each rotation.

We can store the _position_ of the current dial as a non-negative integer between 0 and 99 (inclusive). \
We can let the _change_ of each rotation as `+magnitude` or `-magnitude` based on the direction of rotation.

After each rotation, the result increases by at least as much as `abs(position + change) / 100`. This is because: \
The result increases by at least as much as `abs(change) / 100`, the number of complete revolutions that rotation. \
Since `abs(position) = 0` because `0 <= position <= 99`, in the case where `abs(change) / 100 = 0` and
`abs(position + change) / 100 = 1`, the position decreases in magnitude and the dial touches zero 1 additional time.

We then add 1 to the result for the case where `position > 0` and `position + change <= 0`. This is because: \
The dial rotates left and passes though zero. For example when `position = 20` and `change = -40`, 
`abs(position + change) / 100 = 0`, but the dial touches zero once.

We reuse the mod 100 function in part 1, and there are 3 registers:
1. `cur` to store the current position of the dial
2. `prev` to store the previous position of the dial (to check for the additional case)
3. `temp` to store the intermediate result of `abs(position + change) / 100` to be added to the result

There are 3 stages:
1. Set `cur` to the sum of `prev` and the change
2. Add 1 to result if `prev > 0` and `cur <= 0`; Divide `cur` by 100 and store it in `temp`; Apply mod 100 to `cur`
3. Add the absolute value of `temp` to result; Set `prev` to `cur` or `cur + 100` depending on whether `cur >= 0`

## Installing Hardcaml

Hardcaml can be installed with opam. We highly recommend using Hardcaml with OxCaml (a
bleeding-edge OCaml compiler), which includes some Jane Street compiler extensions and
maintains the latest version of Hardcaml; while still maintaining direct compatibility
with existing OCaml code and libraries. Note that when looking at Hardcaml GitHub
repositories, the OxCaml version is in a branch named `with-extensions`.

Install [opam, the OxCaml compiler, and some basic developer
tools](https://oxcaml.org/get-oxcaml/) to get started.

For additional information on setting up the OCaml toolchain and editor support, see [Real
World OCaml](https://dev.realworldocaml.org/install.html).

Once it's set up, make sure you have the current switch selected in your shell:

```bash
opam switch create 5.2.0+ox --repos ox=git+https://github.com/oxcaml/opam-repository.git,default
opam switch 5.2.0+ox

eval $(opam env)
```

Then, install the core Hardcaml libraries and some other libraries used in Hardcaml projects:

```bash
opam install -y hardcaml hardcaml_test_harness hardcaml_waveterm ppx_hardcaml
opam install -y core core_unix ppx_jane rope re dune ocaml-lsp-server ocamlformat
```

## Building the Project

To build the project, clone this repository and then run the following command, which will
build the generator binary (note the exe prefix is standard for OCaml, even on Unix
systems), as well as building and running all of the tests.

```bash
dune build bin/generate.exe @runtest

# To build (all days, same binary)
dune build bin/generate.exe

# To run tests for one day (both parts)
dune runtest tests/dayX # E.g. tests/day1
```

To validate that the tests are running, try changing one of the input values in
`test_range_finder.ml` and re-running the tests, to see if the printed values change. Once
`dune` shows a diff in the tests, it can be accepted using the following command (this
will modify the file in-place, so you may need to close and re-open it):

```bash
dune promote
```

For more on how expect-tests work, see [this blog post](https://blog.janestreet.com/the-joy-of-expect-tests/)

## Generating RTL

To generate RTL, run the compiled `generate.exe` binary, which will print the Verilog source:

```bash
# To generate RTL for one part of one day
bin/generate.exe dayX-pX # E.g. day1-p1
```

Note that dune should automatically copy the compiled binary into your source directory,
but if it does not, all build products can be found in `_build/default/`.

### Viewing Waveforms

Hardcaml has two main ways to view waveforms:

- Exporting to a `.hardcamlwaveform` file, which, can be viewed using the Hardcaml
  terminal waveform viewer.
  - To try this, uncomment the `waves_config` definition that sets the format to
    `Hardcamlwaveform`, then run the tests again. The file should save into `/tmp/` by
    default.
  - To run the viewer, `hardcaml-waveform-viewer show file.hardcamlwaveform` (if the
    command isn't available, make sure you've activated the opam switch in the same shell
    you're trying to run in, see above)
  - Some more details on using the viewer are available [here](https://www.janestreet.com/web-app/hardcaml-docs/simulating-circuits/waveterm_interactive_viewer)

- Exporting to a `.vcd` file, which can be viewed using standard tools like
  [GTKWave](https://gtkwave.sourceforge.net/) and [Surfer](https://surfer-project.org/)
  - To try this, uncomment the `waves_config` definition that sets the format to
    `Vcd`, then run the tests again. The file should save into `/tmp/` by default.

For small tests, waveforms can also be printed inline (as shown in
`test_range_finder.ml`), which is useful for documenting and visualizing design behavior,
albeit not as useful for interactive debugging.

### Resources

- If you would like to run dune continuously to re-run tests every time a file is edited:

```bash
dune build --watch --terminal-persistence=clear-on-rebuild-and-flush-history bin/generate.exe @runtest
```

- Hardcaml documentation and further tutorials [can be found
  here](https://www.janestreet.com/web-app/hardcaml-docs/introduction/why/)

- Real World OCaml is a [free online book](https://dev.realworldocaml.org/toc.html) for learning OCaml

- The OCaml LSP and autoformatter can be used with VSCode, Emacs, and Vim, [see
  instructions here](https://dev.realworldocaml.org/install.html#editor-setup)
