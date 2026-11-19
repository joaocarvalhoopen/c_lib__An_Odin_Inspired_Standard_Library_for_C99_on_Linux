# c_lib — An Odin-Inspired Standard Library for C99 on Linux
An interesting library.


## Description
`c_lib` is a clean, modular, zero-third-party-dependency **ISO C99** standard library for Linux designed to bring the ergonomics, explicit memory architecture, data-oriented containers, and development-time safety of the **Odin** programming language to C99.

It compiles cleanly with **zero warnings** under `-std=c99 -Wall -Wextra -Wpedantic -Werror` on both **GCC** and **Clang**, while leveraging safely guarded Linux/GCC/Clang primitives (`__builtin_expect`, `__builtin_trap`, `__attribute__((cleanup))`, `mmap`/`mprotect`, and AddressSanitizer manual memory poisoning) to deliver rapid bug detection during development and bare-metal speed in release builds.

**License:** MIT Open Source License (`SPDX-License-Identifier: MIT` — see [LICENSE](LICENSE))

---

## Key Features

- **Explicit, Uniform Allocators (`Cl_Allocator`)**:
  - `cl_heap_allocator()` (aligned `malloc`/`calloc`/`realloc`/`free`, zero-initialized by default)
  - `Cl_Arena` (fixed-buffer O(1) linear bump arena with O(1) in-place top-allocation resize and `Cl_Arena_Temp` checkpoints)
  - `Cl_Virtual_Arena` (Linux `mmap`/`mprotect` reserve-on-init, commit-on-demand growing arena with 100% pointer stability and `MADV_DONTNEED` physical page reclamation)
  - `Cl_Pool` (O(1) fixed-size block allocator with intrusive free list and zero fragmentation)
  - `cl_panic_allocator()` (traps immediately if a real-time hot path attempts any allocation)
  - `Cl_Context` (thread-local context stack carrying `allocator`, `temp_allocator`, `logger`, `assert_proc`, and conflict-free dual scratch arenas via `cl_scratch_begin`)
- **Memory Leak, Bad-Pointer & Bounds Bug Finding**:
  - `Cl_Tracking_Allocator` wraps any allocator to catch memory leaks (`file:line:func`), double frees (original alloc + first free site), unknown/stack/interior bad-pointer frees, 16-byte front & back `0xFD` redzone overflows/underflows, uninit/freed poisoning (`0xCD`/`0xDD`), and live pointer validation (`cl_tracking_validate_ptr`).
  - Manual AddressSanitizer poisoning (`ASAN_POISON_MEMORY_REGION`) inside `Cl_Arena`, `Cl_Virtual_Arena`, and `Cl_Pool` catches arena use-after-rewind and pool use-after-free bugs under `-fsanitize=address`.
  - Toggleable bounds checking (`-DCL_BOUNDS_CHECK=1` in debug, `-DCL_BOUNDS_CHECK=0` in release) backed by `__builtin_expect`, `__builtin_trap`, and Linux glibc `backtrace()`.
- **Odin-Style Ergonomics in C99**:
  - **Slices (`Cl_Slice_*`)**: `{ T *data; cl_isize len; }` with bounds-checked indexing (`CL_SLICE_AT`), zero-copy sub-slicing (`CL_SLICE_SUB`), sorting, binary search, and reversing.
  - **Three-Tier `defer`**: Tier 1 (`CL_DEFER_*` via `__attribute__((cleanup))` — works on GCC & Clang, LIFO, early-return safe, zero executable stack), Tier 2 (pure ISO C99 `CL_DEFER_LOOP` / `CL_WITH_TEMP`), and Tier 3 (pure ISO C99 `Cl_Defer_Stack`).
  - **Multiple Return Values & Propagation**: `CL_OPT_DEFINE`, `CL_RES_DEFINE`, `CL_PAIR_DEFINE`, `CL_TUPLE3_DEFINE`, `CL_OR_RETURN`, `CL_OPT_OR_RETURN`, `CL_OR_ELSE`, `CL_OPT_OR_BREAK`, and `CL_NODISCARD`.
  - **First-Class `complex64`, `complex128` & Quaternions**: Built on ISO C99 native `float _Complex` (`cl_c64`) and `double _Complex` (`cl_c128`) with infix `+ - * /`, exact `float[2]`/`double[2]` binary layout, polar/transcendental math, parsing, formatting, plus `Cl_Quat128` / `Cl_Quat256`.
- **Containers**:
  - **Dynamic Arrays (`Cl_DA_*`)**: `{ T *data; cl_isize len; cl_isize cap; Cl_Allocator allocator; }` with `{0}` zero-init, `PUSH`, `POP`, `INJECT_AT`, `ORDERED_REMOVE`, O(1) `UNORDERED_REMOVE`, `RESIZE`, `SHRINK`, and zero-copy `CL_DA_AS_SLICE`.
  - **HashMap (`Cl_Map_*`)**: Swiss-inspired 8-bit H2 control bytes + dense contiguous `keys[]`/`values[]` arrays for O(1) lookup/swap-delete and cache-friendly sequential iteration (`CL_MAP_FOR_EACH`).
  - **Additional Containers**: stack-allocated `CL_SMALL_ARRAY_DEFINE`, O(1) circular ring `CL_QUEUE_DEFINE`, and `Cl_Bit_Set`.
- **Strings, UTF-8, Builders & Mutable Buffers**:
  - `Cl_Str` (`{ const cl_u8 *data; cl_isize len; }`) with O(1) literals, embedded-NUL safety, 3 C-string conversion paths (`cl_str_to_cstr`, `cl_str_to_cstr_temp`, `cl_str_to_cstr_buf`), zero-alloc `cut`/`trim`/`split_iter`/`split_lines_iter`/`fields_iter`, allocating `split`/`join`/`replace`/`to_upper`/`to_lower`/`pad`, strict RFC 3629 UTF-8 runes, and strict numeric/complex parsers.
  - `Cl_String_Builder` (dynamic growing & fixed-buffer modes, `cl_aprintf`, `cl_tprintf`, `cl_bprintf`).
  - `Cl_Str_Buf` (zero-heap, always-NUL-terminated in-place editing: `insert`, `erase`, `replace_in_place`, `trim`, `case`, `reverse`, `pad`).
- **Structured Logging & Whole-File Linux Filesystem I/O**:
  - `Cl_Logger` (auto-TTY ANSI console, file, multi-sink fan-out, silent nil, compile-time `CL_LOG_MIN_LEVEL` stripping, thread-safe).
  - Minimal whole-file filesystem API (`cl_os_read_entire_file`, `_str`, `_cstr`, `cl_os_write_entire_file`, `_str`, `_cstr`, `cl_os_write_entire_file_atomic`, supporting regular files and Linux `/proc` files) plus monotonic `Cl_Stopwatch`.
- **Optional Short Aliases**: `#define CL_SHORT_NAMES` before `#include <cl/cl.h>` exposes Odin-style names (`u8..u64`, `i8..i64`, `isize`, `f32`, `f64`, `complex64`, `complex128`, `Str`, `Arena`, `Allocator`, etc.).

---

## Repository Layout

```text
c_library/
├── LICENSE                         # MIT Open Source License
├── README.md                       # Project overview, quick start & example catalog
├── how_to_use_this_library.md      # Complete developer manual & API reference
├── Makefile                        # Top-level build, test, and verification orchestrator
├── c_lib/                          # Core library (25 headers, 19 C99 source modules)
│   ├── include/cl/*.h
│   ├── src/*.c
│   └── Makefile
├── c_lib_unit_tests/               # 10 test suites (36 leak-checked tests, 7650+ assertions)
│   ├── cl_test.h
│   ├── test_*.c
│   └── Makefile
├── c_lib_examples/                 # 30 progressive documented examples (10 per level)
│   ├── level_1_beginner/           # 01 .. 10
│   ├── level_2_intermediate/       # 11 .. 20
│   ├── level_3_advanced/           # 21 .. 30
│   └── Makefile
└── c_lib_ref_html/                 # Zero-dependency Odin-style HTML reference docs
    ├── generate_docs.py            # Python 3 stdlib doc & syntax-highlighted source generator
    ├── index.html                  # Offline reference with API search, Examples search & Dark/Light mode
    ├── src/*.html                  # Dark-mode syntax-highlighted C99 source viewers (#L...)
    └── examples/*.html             # Dark-mode syntax-highlighted viewers for all 30 examples
```

---

## Quick Start

### Requirements
- Linux (x86_64 or arm64)
- GCC or Clang with C99 support (`-lm`, `-lpthread`)
- GNU Make

### Build, Test & Verify Everything

```bash
# Build library, unit tests, and all 30 examples (debug profile, CL_BOUNDS_CHECK=1)
make

# Run unit tests in debug mode (per-test tracking allocator + fork() trap checks)
make test

# Run unit tests across all 4 profiles: debug, sanitize (ASan+UBSan), release, clang
make test-all

# Build and run all 30 examples (debug or ASan+UBSan)
make examples
make examples-asan

# Full verification suite (test-all + all 30 examples in Debug and ASan+UBSan + HTML docs)
make verify

# Regenerate Odin-style offline HTML API reference in c_lib_ref_html/index.html
make docs
```

### Integrating `c_lib` into Your Project

```bash
make -C c_lib PROFILE=debug   # or PROFILE=release / PROFILE=sanitize / PROFILE=clang

gcc -std=c99 -Wall -Wextra -Wpedantic -g -DCL_BOUNDS_CHECK=1 \
    -Ic_lib/include my_program.c c_lib/build/debug/libc_lib.a -lm -lpthread -o my_program
```

---

## A Taste of `c_lib`

```c
#define CL_SHORT_NAMES
#include <cl/cl.h>
#include <stdio.h>

int main(void) {
    /* Wrap heap with Tracking Allocator to prove zero leaks */
    Tracking_Allocator tracker;
    cl_tracking_init(&tracker, cl_heap_allocator());
    CL_DEFER_TRACKING(tracker);
    Allocator alloc = cl_tracking_allocator(&tracker);

    /* Phase-scoped arena cleaned up automatically on scope exit */
    Arena arena;
    CL_ENSURE(cl_arena_init_alloc(&arena, KB(16), alloc));
    CL_DEFER_ARENA(arena);
    Allocator aa = cl_arena_allocator(&arena);

    /* Whole-file write & read with multiple-return error handling */
    Str path = STR("/tmp/c_lib_quickstart.txt");
    CL_ENSURE(cl_os_write_entire_file_str(path, STR("3+4i\n1-2i\n")) == CL_ERR_NONE);
    Cl_Res_Str file = cl_os_read_entire_file_str(path, aa);
    CL_ENSURE(file.err == CL_ERR_NONE);

    /* Zero-copy line iteration + native C99 complex128 arithmetic */
    complex128 product = cl_c128_make(1.0, 0.0);
    Str cur = file.value;
    for (;;) {
        Str line;
        CL_OPT_OR_BREAK(line, cl_str_split_lines_iter(&cur));
        Cl_Opt_C128 z = cl_str_parse_c128(line);
        if (z.ok) {
            product = product * z.value;
        }
    }

    printf("Product = %.2f %+.2fi (|z| = %.4f)\n",
           cl_c128_real(product), cl_c128_imag(product), cl_c128_abs(product));

    (void)cl_os_remove_file(path);
    cl_ctx_thread_shutdown();
    return 0;
}
```

---

## Complete 30-Example Curriculum (`c_lib_examples/`)

Every example is self-contained and thoroughly documented in English, explaining **what** feature is used, **why** it is chosen, **when** to use it, **advantages**, and **disadvantages**.

### Level 1 — Beginner (Core Ergonomics & Types)

| # | File | Topics Covered |
|---|---|---|
| 01 | `level_1_beginner/01_primitive_types_and_short_names.c` | Fixed-width types, signed `isize`, `CL_SHORT_NAMES`, `CL_STATIC_ASSERT`, single-eval `CL_MIN`/`MAX`/`CLAMP`/`SWAP` |
| 02 | `level_1_beginner/02_strings_basics_and_cstr_interop.c` | `Cl_Str`, `CL_STR()`, `CL_STR_FMT`, embedded NULs, stack/temp/owned C-string conversions |
| 03 | `level_1_beginner/03_slices_and_bounds_checking.c` | `Cl_Slice_*`, `CL_SLICE_AT`, zero-copy `CL_SLICE_SUB`, sort/bsearch/reverse, `CL_BOUNDS_CHECK` |
| 04 | `level_1_beginner/04_defer_three_tiers.c` | Tier 1 (`CL_DEFER_*` LIFO cleanup), Tier 2 (`CL_DEFER_LOOP`), Tier 3 (pure ISO C99 `Cl_Defer_Stack`) |
| 05 | `level_1_beginner/05_multiple_return_values_and_errors.c` | `CL_OPT_DEFINE`, `CL_RES_DEFINE`, `CL_TUPLE3_DEFINE`, `CL_OR_RETURN`, `CL_OR_ELSE`, `CL_NODISCARD` |
| 06 | `level_1_beginner/06_structured_logging.c` | `Cl_Logger`, console TTY auto-color, file sink, `Cl_Multi_Logger`, `cl_nil_logger()`, `CL_LOG_MIN_LEVEL` |
| 07 | `level_1_beginner/07_complex64_and_complex128_basics.c` | Native `complex64`/`complex128`, polar form, Euler identity `e^(i*pi) + 1 = 0`, AC RLC circuit phasors |
| 08 | `level_1_beginner/08_string_manipulation_and_iterators.c` | Zero-alloc `cl_str_cut`, trimming, `split_iter`, `fields_iter`, allocating `split`/`join`/`replace`/`pad` |
| 09 | `level_1_beginner/09_parsing_and_utf8_runes.c` | Strict `parse_i64`/`f64`/`bool`/`c64`/`c128`, Odin `_` separators, RFC 3629 UTF-8 runes & safe reverse |
| 10 | `level_1_beginner/10_whole_file_read_write_and_time.c` | Whole-file read/write, crash-safe atomic write (`fsync`+`rename`), `/proc/version`, `Cl_Stopwatch` |

### Level 2 — Intermediate (Memory Strategies, Containers & Diagnostics)

| # | File | Topics Covered |
|---|---|---|
| 11 | `level_2_intermediate/11_linear_arena_and_temp_checkpoints.c` | Stack `Cl_Arena`, O(1) bump alloc, O(1) in-place top resize, nested `Cl_Arena_Temp` checkpoints |
| 12 | `level_2_intermediate/12_context_and_dual_scratch_arenas.c` | Thread-local `Cl_Context` stack, `cl_tprintf()`, conflict-free dual `cl_scratch_begin(&dst, 1)` |
| 13 | `level_2_intermediate/13_dynamic_arrays_in_depth.c` | Custom `CL_DA_DEFINE`, `APPEND_SLICE`, `INJECT_AT`, `ORDERED_REMOVE` vs O(1) `UNORDERED_REMOVE`, `SHRINK` |
| 14 | `level_2_intermediate/14_hashmaps_word_frequency.c` | `Cl_Map_Str_I64`, byte-content hashing, dense `CL_MAP_FOR_EACH`, delete, and arena-owned keys |
| 15 | `level_2_intermediate/15_custom_hashmap_struct_keys.c` | POD struct keys (`CL_MAP_INIT_POD`) and custom case-insensitive HTTP header hash/equality callbacks |
| 16 | `level_2_intermediate/16_string_builder_dynamic_and_fixed.c` | `Cl_String_Builder` in dynamic JSON generation and zero-heap fixed-buffer mode + `cl_bprintf`/`cl_tprintf` |
| 17 | `level_2_intermediate/17_strbuf_inplace_buffer_editing.c` | `Cl_Str_Buf` zero-heap in-place `insert`, `erase`, `replace_in_place`, `trim`, `case`, `reverse`, `pad` |
| 18 | `level_2_intermediate/18_small_array_queue_and_bitset.c` | Stack `CL_SMALL_ARRAY_DEFINE`, O(1) ring `CL_QUEUE_DEFINE` (graph BFS), and `Cl_Bit_Set` set algebra |
| 19 | `level_2_intermediate/19_tracking_allocator_bug_hunter.c` | Live `Cl_Tracking_Allocator` demo catching leaks, double frees, bad/interior pointers, and redzone breaches |
| 20 | `level_2_intermediate/20_endianness_and_binary_file_packets.c` | Portable big-endian packet encode/decode (`cl_write/read_u16/32/64_be`) + whole-file binary I/O |

### Level 3 — Advanced (Systems Architecture & Mini-Applications)

| # | File | Topics Covered |
|---|---|---|
| 21 | `level_3_advanced/21_virtual_arena_large_graph.c` | Linux `Cl_Virtual_Arena` (`mmap`/`mprotect`) pointer-stable graph across commit chunks + page decommit |
| 22 | `level_3_advanced/22_pool_allocator_and_ecs_simulation.c` | Multi-allocator ECS simulation (`Cl_Virtual_Arena` + `Cl_Pool` + `Cl_Bit_Set` + per-tick `temp_allocator`) |
| 23 | `level_3_advanced/23_panic_allocator_realtime_audio_dsp.c` | Hard real-time zero-alloc DSP callback guarded by `cl_panic_allocator()` + `complex64` IQ filter + `Cl_Str_Buf` |
| 24 | `level_3_advanced/24_complex_dft_spectrum_analyzer.c` | `complex64`/`complex128` Discrete Fourier Transform, Parseval energy check, ASCII spectrum rendering |
| 25 | `level_3_advanced/25_complex_mandelbrot_ascii_renderer.c` | `complex128` Mandelbrot fractal (`z = z*z + c`, `cl_c128_abs2`), `Cl_String_Builder`, whole-file export |
| 26 | `level_3_advanced/26_quaternions_3d_orientation_tracker.c` | `Cl_Quat256` 3D rotation composition (`v' = q * v * conj(q)`) and smooth SLERP trajectory tracking |
| 27 | `level_3_advanced/27_ini_config_file_parser.c` | Zero-copy `.ini` config file parser backed by a single `Cl_Arena` + `Cl_Map_Str_Str` + typed getters |
| 28 | `level_3_advanced/28_csv_table_query_engine.c` | In-memory CSV dataset loader, `GROUP BY` HashMap aggregation, sorting, and Markdown table export |
| 29 | `level_3_advanced/29_log_file_analyzer_pipeline.c` | Production CLI log analyzer uniting whole-file I/O, `Cl_Map`, `Cl_DA`, `Cl_Multi_Logger`, and leak checks |
| 30 | `level_3_advanced/30_multi_stage_compiler_lexer_and_eval.c` | Capstone complex-number expression lexer + recursive-descent evaluator with `Cl_Arena` & `Cl_Map_Str_C128` |

---

## Documentation

- **Developer Manual & API Guide**: See **[how_to_use_this_library.md](how_to_use_this_library.md)** for the full architectural deep-dive, Odin-to-`c_lib` rosetta table, allocator selection matrix, memory safety layers, build profile flags, and module-by-module guide.
- **Offline Interactive HTML Reference**: Open **[c_lib_ref_html/index.html](c_lib_ref_html/index.html)** in your browser for Odin-style searchable API reference docs, dark-mode syntax-highlighted source viewers, and a dedicated searchable catalog of all 30 examples.

---

## License

`c_lib` — including all library headers and source files, unit tests, examples, build scripts, and documentation — is released under the **MIT Open Source License** (`SPDX-License-Identifier: MIT`).

See the [LICENSE](LICENSE) file for the full license text.
