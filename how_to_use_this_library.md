# How to Use `c_lib` (Odin-Inspired C99 Standard Library for Linux)

**License:** MIT Open Source License (`SPDX-License-Identifier: MIT` — see [LICENSE](LICENSE))

`c_lib` is a modular, zero-dependency (beyond Linux libc, libm, and pthreads), ISO C99 standard library for Linux engineered to bring the ergonomics, explicit memory architecture, and development-time safety of the **Odin** programming language into C99.

---

## 1. Quick Start & Building

### Directory Structure

```text
c_library/
├── LICENSE                         # MIT Open Source License
├── README.md                       # Project overview, quick start & 30-example index
├── Makefile                        # Top-level build, test, and example orchestrator
├── how_to_use_this_library.md      # This complete developer manual
├── c_lib/                          # Library headers (include/cl/*.h) and sources (src/*.c)
├── c_lib_unit_tests/               # Leak-checked unit test suite (36 tests, 7650+ checks)
├── c_lib_examples/                 # 30 documented examples (Beginner / Intermediate / Advanced)
└── c_lib_ref_html/                 # Zero-dependency Odin-style offline HTML API reference
```

### Build & Verify Commands

```bash
# Build library, tests, and all 30 examples (default: debug with CL_BOUNDS_CHECK=1)
make

# Run unit tests in debug mode (includes automatic per-test leak checking & bounds traps)
make test

# Run full verification matrix:
#   1. GCC Debug (-std=c99 -Wall -Wextra -Wpedantic -Werror -g -DCL_BOUNDS_CHECK=1)
#   2. GCC Sanitize (-fsanitize=address,undefined,bounds-strict + ASan arena poisoning)
#   3. GCC Release (-O2 -DNDEBUG -DCL_BOUNDS_CHECK=0)
#   4. Clang Debug (clang -std=c99 -Wall -Wextra -Wpedantic -Werror -DCL_BOUNDS_CHECK=1)
#   5. All 30 examples in both Debug and ASan+UBSan modes
make verify
```

### Linking `c_lib` into Your Own C99 Linux Project

```bash
# 1. Build the static archive (choose PROFILE=debug, release, sanitize, or clang)
make -C /path/to/c_lib PROFILE=debug

# 2. Compile and link your program
gcc -std=c99 -Wall -Wextra -Wpedantic -g -DCL_BOUNDS_CHECK=1 \
    -I/path/to/c_lib/include \
    my_app.c /path/to/c_lib/build/debug/libc_lib.a -lm -lpthread -o my_app
```

In your C file:

```c
/* Option A: Prefixed API (zero namespace collisions with third-party headers) */
#include <cl/cl.h>

/* Option B: Opt-in Odin-style short names (u8, i64, complex64, complex128, Str, Arena...) */
#define CL_SHORT_NAMES
#include <cl/cl.h>
```

---

## 2. Odin-to-`c_lib` Rosetta Stone

| Odin Concept | `c_lib` Equivalent | Header |
|---|---|---|
| `i8..i64`, `u8..u64`, `int`, `uint`, `f32`, `f64`, `rune` | `cl_i8..cl_i64`, `cl_u8..cl_u64`, `cl_isize`, `cl_usize`, `cl_f32`, `cl_f64`, `cl_rune` (short names in `cl_short.h`) | `cl_types.h` |
| `complex64`, `complex128` | `cl_c64` (`float _Complex`), `cl_c128` (`double _Complex`) | `cl_types.h`, `cl_complex.h` |
| `quaternion128`, `quaternion256` | `Cl_Quat128`, `Cl_Quat256` | `cl_types.h`, `cl_complex.h` |
| `context` (`allocator`, `temp_allocator`, `logger`) | `Cl_Context`, `cl_ctx_push/pop`, `cl_ctx_allocator()`, `cl_ctx_temp_allocator()` | `cl_context.h` |
| `mem.Allocator` | `Cl_Allocator` (`cl_alloc`, `cl_new`, `cl_make_array`, `cl_resize`, `cl_free`, `cl_free_all`) | `cl_alloc.h` |
| `mem.Arena` + `temp_arena_memory` | `Cl_Arena` + `cl_arena_temp_begin/end` | `cl_arena.h` |
| `core:mem/virtual` Arena | `Cl_Virtual_Arena` (`mmap` reserve + `mprotect` commit on demand) | `cl_virtual_arena.h` |
| `mem.Pool` | `Cl_Pool` (O(1) fixed-size block allocator) | `cl_pool.h` |
| `mem.Tracking_Allocator` | `Cl_Tracking_Allocator` (leaks + double free + bad pointer + 16-byte redzones + poison) | `cl_tracking_alloc.h` |
| `defer` | `CL_DEFER_*` (Tier 1 cleanup attr), `CL_DEFER_LOOP` (Tier 2), `Cl_Defer_Stack` (Tier 3) | `cl_defer.h` |
| `(T, bool)` / `(T, Err)` + `or_return` / `or_else` | `CL_OPT_DEFINE`, `CL_RES_DEFINE`, `CL_OR_RETURN`, `CL_OR_ELSE`, `CL_OPT_OR_BREAK` | `cl_result.h` |
| `[]T` + `s[lo:hi]` + `#no_bounds_check` | `CL_SLICE_DEFINE`, `CL_SLICE_AT`, `CL_SLICE_SUB`, `-DCL_BOUNDS_CHECK=1/0` | `cl_slice.h` |
| `[dynamic]T` | `CL_DA_DEFINE` (`CL_DA_PUSH`, `POP`, `ORDERED_REMOVE`, `UNORDERED_REMOVE`, `SHRINK`) | `cl_array.h` |
| `Small_Array`, `Queue`, `Bit_Array` | `CL_SMALL_ARRAY_DEFINE`, `CL_QUEUE_DEFINE`, `Cl_Bit_Set` | `cl_array.h` |
| `map[K]V` | `CL_MAP_DEFINE` (Swiss H2 control bytes + dense arrays) | `cl_map.h` |
| `string` & `cstring` | `Cl_Str` + `cl_str_to_cstr`, `cl_str_to_cstr_temp`, `cl_str_to_cstr_buf` | `cl_string.h` |
| `strings.Builder` | `Cl_String_Builder` (dynamic & fixed modes) + `cl_aprintf` / `cl_tprintf` | `cl_string_builder.h` |
| Mutable fixed `char[N]` editing | `Cl_Str_Buf` (zero-heap, always-NUL-terminated in-place editing) | `cl_strbuf.h` |
| `core:unicode/utf8` | `cl_utf8_decode_rune`, `cl_utf8_encode_rune`, `cl_utf8_valid`, `cl_utf8_next` | `cl_utf8.h` |
| `core:log` | `Cl_Logger` (console, file, multi, nil) + `CL_LOG_DEBUG..FATAL` | `cl_log.h` |
| `core:os` & `core:time` | `cl_os_read_entire_file`, `cl_os_write_entire_file`, `Cl_Stopwatch` | `cl_os.h` |

---

## 3. Compile-Time Configuration & Toggleable Bounds Checking

All feature flags live in `cl_config.h` and can be overridden on the compiler command line:

| Macro | Default (Debug) | Default (Release / `NDEBUG`) | Effect |
|---|---|---|---|
| `CL_BOUNDS_CHECK` | `1` | `0` | Enables/disables bounds checking on slices, dynamic arrays, strings, queues, bitsets, and buffers. |
| `CL_BOUNDS_CHECK_TRAP` | `1` | `0` | Executes `__builtin_trap()` on GCC/Clang so GDB halts on the exact offending frame. |
| `CL_LOG_MIN_LEVEL` | `0` (DEBUG) | `1` (INFO) | Strips lower log levels at compile time (0=DEBUG, 1=INFO, 2=WARN, 3=ERROR, 4=FATAL, 5=NONE). |
| `CL_ENABLE_BACKTRACE` | `1` (glibc Linux) | `1` (glibc Linux) | Prints glibc `backtrace()` stack traces on panic/assertion failures. |
| `CL_ENABLE_THREAD_SAFETY` | `1` | `1` | Guards logging and tracking allocator with `pthread_mutex_t`. |

### How Bounds Checking Works Under the Hood

When `CL_BOUNDS_CHECK == 1`:
- Every `CL_SLICE_AT(s, i)`, `CL_SLICE_SUB(s, lo, hi)`, `CL_DA_AT(&da, i)`, `CL_DA_POP(&da)`, `cl_str_at(s, i)`, `cl_str_slice(s, lo, hi)`, `CL_QUEUE_AT(&q, i)`, and `cl_bitset_test(&bs, i)` checks `0 <= idx < len` (or `0 <= lo <= hi <= len`).
- The check uses GCC/Clang's `__builtin_expect(!!(cond), 0)` (`CL_UNLIKELY`) so the valid path remains straight-line branch-predicted code.
- On failure, `c_lib` prints the exact file, line, function, offending index vs actual length, a Linux stack backtrace, and traps with `__builtin_trap()`.

When `CL_BOUNDS_CHECK == 0`:
- `CL_BOUNDS_CHECK_INDEX(idx, len)` expands to `((cl_isize)(idx))` and `CL_BOUNDS_CHECK_RANGE(...)` expands to `((void)0)` -- literally zero instructions!

For maximum safety during development, compile with `PROFILE=sanitize`:

```bash
gcc -std=c99 -Wall -Wextra -Wpedantic -g -O1 -fno-omit-frame-pointer \
    -DCL_BOUNDS_CHECK=1 -fsanitize=address,undefined,bounds-strict ...
```

This adds hardware-speed AddressSanitizer (including custom manual poisoning inside `Cl_Arena`, `Cl_Virtual_Arena`, and `Cl_Pool`!), UndefinedBehaviorSanitizer, and GCC's native array `-fsanitize=bounds-strict`.

---

## 4. Primitive Types, `complex64`, `complex128` & Quaternions

### Signed Sizes (`cl_isize`)

Following Odin's `int` convention, `c_lib` uses signed `cl_isize` (`ptrdiff_t`) for all lengths, capacities, and indices. Signed lengths eliminate classic C unsigned underflow bugs (such as `for (size_t i = len - 1; i >= 0; i--)` looping forever when `len == 0`).

### First-Class `complex64` (`cl_c64`) and `complex128` (`cl_c128`)

`cl_c64` (`float _Complex`, 8 bytes) and `cl_c128` (`double _Complex`, 16 bytes) use ISO C99 native `_Complex` types without pulling `<complex.h>`'s single-letter `I` macro into user headers:

- Native operators `+`, `-`, `*`, `/`, and unary `-` work directly.
- Binary layout is guaranteed by ISO C99 Section 6.2.5p13 to match `float[2]` / `double[2]` (`{ real, imag }`), giving zero-copy compatibility with Odin `complex64`/`complex128`, FFTW, BLAS, and interleaved IQ DSP streams.

Plain-text math formulas supported by `cl_complex.h`:

```text
z        = a + b*i           (constructed via cl_c64_make(a, b) / cl_c128_make(a, b))
conj(z)  = a - b*i           (cl_c64_conj / cl_c128_conj)
|z|      = sqrt(a^2 + b^2)   (cl_c64_abs / cl_c128_abs)
|z|^2    = a^2 + b^2         (cl_c64_abs2 / cl_c128_abs2 - avoids sqrt)
arg(z)   = atan2(b, a)       (cl_c64_arg / cl_c128_arg, in [-pi, pi])
polar    = r * e^(i * theta) (cl_c64_from_polar / cl_c128_from_polar)
```

Transcendental functions (`exp`, `log`, `sqrt`, `pow`, `sin`, `cos`), approximate equality (`approx_eq`), parsing (`cl_str_parse_c64`, `cl_str_parse_c128`), formatting (`cl_sb_write_c64`, `cl_sb_write_c128`), slices (`Cl_Slice_C64`, `Cl_Slice_C128`), dynamic arrays (`Cl_DA_C64`, `Cl_DA_C128`), and maps (`Cl_Map_Str_C128`) are all built in.

```c
cl_c128 z1 = cl_c128_make(3.0, 4.0);
cl_c128 z2 = cl_c128_from_polar(2.0, CL_PI_F64 / 4.0);
cl_c128 prod = z1 * z2;
cl_f64  mag  = cl_c128_abs(prod);
```

### `printf` Formatting & Cast Reference Table (All `c_lib` Types)

`<inttypes.h>` is automatically included by `cl_types.h`, and `c_lib` defines two concise cast macros for `%lld` / `%llu`:

```c
#define CL_LL  long long
#define CL_ULL unsigned long long
```

All format specifiers below compile with **zero warnings** under `-std=c99 -Wall -Wextra -Wpedantic -Werror`:

| Data Type | `printf` Format String | Required Cast / Argument |
|---|---|---|
| `cl_i8` / `i8` (`int8_t`) | `"%d"` or `"%" PRId8` | **None** (promoted to `int`) |
| `cl_i16` / `i16` (`int16_t`) | `"%d"` or `"%" PRId16` | **None** (promoted to `int`) |
| `cl_i32` / `i32` (`int32_t`) | `"%d"` or `"%" PRId32` | **None** |
| `cl_i64` / `i64` (`int64_t`) | `"%" PRId64` *(portable)* / `"%ld"` *(Linux 64-bit only)* / `"%lld"` | **None** with `PRId64` or `%ld` / **`(CL_LL)x`** with `%lld` |
| `cl_u8` / `u8` / `cl_byte` / `byte` (`uint8_t`) | `"%u"`, `"%02X"` or `"%" PRIu8` | **None** (promoted to `int`) |
| `cl_u16` / `u16` (`uint16_t`) | `"%u"`, `"%X"` or `"%" PRIu16` | **None** (promoted to `int`) |
| `cl_u32` / `u32` (`uint32_t`) | `"%u"`, `"%x"`, `"%X"` or `"%" PRIu32` | **None** |
| `cl_u64` / `u64` (`uint64_t`) | `"%" PRIu64`, `"0x%" PRIx64` *(portable)* / `"%lu"` *(Linux 64-bit only)* / `"%llu"` | **None** with `PRIu64` or `%lu` / **`(CL_ULL)x`** with `%llu` |
| `cl_isize` / `isize` (`ptrdiff_t`) | `"%td"` *(native C99)* / `"%lld"` | **None** with `%td` / **`(CL_LL)x`** with `%lld` |
| `cl_usize` / `usize` (`size_t`) | `"%zu"`, `"%zx"` *(native C99)* | **None** |
| `cl_uintptr` / `uintptr` (`uintptr_t`) | `"%" PRIuPTR`, `"0x%" PRIxPTR` | **None** |
| `cl_f32` / `f32` (`float`) | `"%f"`, `"%.3f"`, `"%g"`, `"%e"` | **None** in standard C99 *(promoted to `double`; use `(double)x` only if `-Wdouble-promotion` is enabled)* |
| `cl_f64` / `f64` (`double`) | `"%f"`, `"%.6f"`, `"%g"`, `"%e"` | **None** |
| `bool` (`_Bool`) | `"%s"` *(text)* or `"%d"` *(0/1)* | `x ? "true" : "false"` with `%s` / **None** with `%d` |
| `cl_b8` / `b8` (`uint8_t`) | `"%s"` or `"%u"` | `x ? "true" : "false"` with `%s` / **None** with `%u` |
| `cl_b32` / `b32` (`uint32_t`) | `"%s"` or `"%u"` | `x ? "true" : "false"` with `%s` / **None** with `%u` |
| `cl_rune` / `rune` (`int32_t`) | `"U+%04X"` *(code point)* / `"%d"` | **`(unsigned)r`** with `%X` *(since `rune` is signed)* / **None** with `%d` |
| `cl_rawptr` / `rawptr` (`void *`) | `"%p"` | **None** |
| Typed pointer (`T *`) | `"%p"` | **`(void *)ptr`** *(required by `-Wpedantic`)* |
| `cl_c64` / `c64` / `complex64` (`float _Complex`) | `"%.3f %+.3fi"` *(C99 has no native `_Complex` specifier)* | `cl_c64_real(z), cl_c64_imag(z)` *(no cast; `(double)` only with `-Wdouble-promotion`)* |
| `cl_c128` / `c128` / `complex128` (`double _Complex`) | `"%.3f %+.3fi"` | `cl_c128_real(z), cl_c128_imag(z)` *(no cast)* |
| `Cl_Quat128` / `Quat128` | `"(%g, %g, %g, %g)"` | `q.x, q.y, q.z, q.w` *(no cast)* |
| `Cl_Quat256` / `Quat256` | `"(%g, %g, %g, %g)"` | `q.x, q.y, q.z, q.w` *(no cast)* |
| `Cl_Str` / `Str` | `CL_STR_FMT` (`"%.*s"`) | `CL_STR_ARG(s)` *(macro handles `(int)s.len, (const char *)s.data` internally)* |
| `const char *` (C-string) | `"%s"` | **None** |

#### Practical Summary (Golden Rules for Concise / Zero-Cast `printf`)

- **`isize`**: use **`%td`** (zero cast), or **`%lld`** with **`(CL_LL)x`**.
- **`usize`**: use **`%zu`** (zero cast).
- **`i64` / `u64`**: use **`"%" PRId64`** / **`"%" PRIu64`** (zero cast, portable across 32-bit and 64-bit), **`%ld` / `%lu`** (zero cast on 64-bit Linux LP64), or **`%lld` / `%llu`** with **`(CL_LL)x`** / **`(CL_ULL)x`**.
- **All smaller integers (`i8`, `i16`, `i32`, `u8`, `u16`, `u32`) and floats (`f32`, `f64`)**: **zero casts required**.
- **Only two cases genuinely require an explicit cast in pedantic ISO C99**: **`(void *)ptr`** when printing a typed pointer `T *` with `%p`, and **`(unsigned)r`** when printing a signed `rune` in hexadecimal `%X`.

---

## 5. Memory Architecture & Choosing the Right Allocator

Every allocator exposes the same 16-byte `Cl_Allocator` value handle (`{ proc, data }`). All allocations are **zero-initialized by default** (`cl_alloc`, `cl_new`, `cl_make_array`, `cl_resize`), with explicit `_non_zeroed` variants when you immediately overwrite the buffer.

### Allocator Decision Matrix

| Allocator | Allocation Speed | Individual `free()` | Bulk `free_all()` | Pointer Stability | Best Circumstances | Trade-offs |
|---|---|---|---|---|---|---|
| `cl_heap_allocator()` | O(log n) / libc | Yes | No | Moves on `resize` | Arbitrary lifetimes, unknown sizes, general fallback | Can fragment; must free every allocation individually. |
| `Cl_Arena` | O(1) bump | No (no-op) | O(1) + temp rewind | Stable (except non-top `resize`) | Per-frame, per-request, stack-backed scratch (`4 KiB..64 KiB`) | Fixed capacity; returns `NULL` when full. |
| `Cl_Virtual_Arena` | O(1) bump | No (no-op) | O(1) + optional page decommit | **100% stable** across growth | Long-lived growing data (ASTs, scenes, graphs, DSP buffers) | Linux `mmap` page granularity; cannot free individual objects. |
| `Cl_Pool` | O(1) pop | **Yes (O(1))** | O(n) rebuild | 100% stable | Entities, nodes, network packets of uniform max size | Fixed max chunk size and fixed slot count. |
| `cl_ctx_temp_allocator()` / `Cl_Scratch` | O(1) bump | No | O(1) `cl_ctx_temp_reset()` | Stable until reset | C-string interop (`cl_str_to_cstr_temp`), `cl_tprintf`, temp arrays | Lifetime ends at next `cl_ctx_temp_reset()` or `cl_scratch_end()`. |
| `Cl_Tracking_Allocator` | Wraps any allocator | Delegates + checks | Delegates + checks | Same as wrapped | Development builds, unit tests, leak & bad-pointer hunting | Adds 32+ bytes redzone + hash-table overhead; disable in release. |
| `cl_panic_allocator()` | Traps! | No-op on NULL | Traps! | N/A | Audio callbacks, real-time hot paths that forbid allocation | Intentionally crashes on any allocation attempt. |

### Conflict-Free Dual Scratch Arenas

When writing a reusable function that allocates its return value into a caller-supplied `dst_alloc` AND needs internal temporary space, always pass `&dst_alloc` to `cl_scratch_begin`:

```c
Cl_Str build_result(Cl_Str input, Cl_Allocator dst_alloc) {
    /* Guaranteed NEVER to alias dst_alloc, even if caller passed temp_allocator! */
    Cl_Scratch scratch = cl_scratch_begin(&dst_alloc, 1);
    CL_DEFER_SCRATCH(scratch);

    /* Do temporary work in scratch.allocator ... */
    /* Allocate final return value in dst_alloc ... */
}
```

### Thread-Local `Cl_Context`

`Cl_Context` holds the active `allocator`, `temp_allocator`, `logger`, `assert_proc`, `user_ptr`, and `user_index` on a per-thread stack (up to 32 levels deep). Any zeroed field in a pushed `Cl_Context` automatically inherits from the previous level:

```c
Cl_Context sub = {0};
sub.allocator = cl_arena_allocator(&my_arena);
sub.logger    = cl_nil_logger();
CL_DEFER_CTX_PUSH(sub); /* Automatically pops at scope exit! */
```

---

## 6. Finding Memory Leaks & Bad Pointer Manipulation

`c_lib` gives you **three layers** of memory safety:

### Layer 1: `Cl_Tracking_Allocator` (Works Anywhere, Zero External Tools)

Wrap any underlying allocator (typically `cl_heap_allocator()`):

```c
Cl_Tracking_Allocator tracker;
cl_tracking_init(&tracker, cl_heap_allocator());
CL_DEFER_TRACKING(tracker);
tracker.panic_on_error = true; /* Optional: trap immediately on first error */
Cl_Allocator alloc = cl_tracking_allocator(&tracker);
```

What it catches automatically:
1. **Memory Leaks**: exact `file:line (func)`, byte size, and monotonic allocation ID.
2. **Double Frees**: ring history of recently freed blocks reports original alloc site, first free site, AND second free site without corrupting the heap.
3. **Bad / Unknown / Interior Pointer Frees**: freeing a stack variable, wild pointer, or offset interior pointer (`ptr + 8`) is caught cleanly without crashing `free()`.
4. **Buffer Underflows & Overflows**: 16-byte front and back `0xFD` guard redzones checked on `resize`, `free`, and `cl_tracking_check_integrity(&tracker, CL_HERE)`.
5. **Uninitialized & Use-After-Free Patterns**: non-zeroed allocations are filled with `0xCD` and freed blocks are scrubbed with `0xDD`.
6. **Live Pointer Validation**: `cl_tracking_validate_ptr(&tracker, ptr, access_size)` returns `CL_PTR_VALID`, `CL_PTR_NULL`, `CL_PTR_OUT_OF_BOUNDS`, `CL_PTR_FREED`, or `CL_PTR_UNKNOWN`.

Call `cl_tracking_print_report(&tracker, stderr)` or assert `cl_tracking_is_clean(&tracker)` at shutdown (the `c_lib_unit_tests` harness does this automatically for every single test).

### Layer 2: Manual ASan Poisoning Inside Custom Arenas & Pools

Normally AddressSanitizer cannot see overflows or use-after-reset inside a custom arena because ASan only hooks `malloc`/`free`. `Cl_Arena`, `Cl_Virtual_Arena`, and `Cl_Pool` explicitly call `ASAN_POISON_MEMORY_REGION` / `ASAN_UNPOISON_MEMORY_REGION` when compiled with `-fsanitize=address`. Reading a pointer after `cl_arena_temp_end()`, `cl_arena_reset()`, or `cl_pool_free()` triggers an immediate `AddressSanitizer: use-after-poison` crash!

### Layer 3: GCC/Clang Sanitizers (`PROFILE=sanitize`)

Compile with `-fsanitize=address,undefined,bounds-strict -fno-omit-frame-pointer` to catch every out-of-bounds access, signed integer overflow, null dereference, misaligned load, and memory leak across your entire codebase.

---

## 7. `defer` in C99 (Three Complementary Tiers)

Because C99 has no native `defer` keyword (and GCC nested-function tricks break Clang and can create executable stacks), `c_lib` offers three honest, warning-free tiers:

### Tier 1 (Recommended Default on Linux — Works on BOTH GCC and Clang)

Backed by `__attribute__((cleanup(fn)))`. Executes in strict **LIFO** order on normal exit, early `return`, `break`, `continue`, or `goto`, with zero runtime overhead and NO executable stack:

```c
Cl_Arena arena;
cl_arena_init_alloc(&arena, CL_KB(64), alloc);
CL_DEFER_ARENA(arena);

Cl_DA_I64 items = {0};
CL_DA_INIT(&items, alloc);
CL_DEFER_DA(items);

FILE *fp = fopen("data.txt", "r");
CL_DEFER_FILE(fp);

CL_DEFER_FN(my_cleanup_callback, &my_state);
```

Built-in Tier 1 macros: `CL_DEFER_FREE`, `CL_DEFER_FREE_SLOT`, `CL_DEFER_ARENA`, `CL_DEFER_TEMP`, `CL_DEFER_VARENA`, `CL_DEFER_VTEMP`, `CL_DEFER_SCRATCH`, `CL_DEFER_POOL`, `CL_DEFER_TRACKING`, `CL_DEFER_CTX_PUSH`, `CL_DEFER_FILE`, `CL_DEFER_FD`, `CL_DEFER_DA`, `CL_DEFER_MAP`, `CL_DEFER_SB`, `CL_DEFER_FN`, `CL_DEFER_VAR`.

### Tier 2 (100% Pure ISO C99 — Structured Block Scopes)

Uses a single-iteration `for` loop with zero compiler extensions:

```c
CL_WITH_TEMP(&arena) {
    /* Temporary allocations automatically rewind at the closing brace */
}
```

**Important C99 Caveat**: Never `return`, `break`, or `goto` out of a Tier 2 block because doing so skips the `for`-loop post-expression. Use `continue` to exit a Tier 2 block early while still running cleanup, or prefer Tier 1 when early `return` is needed.

### Tier 3 (100% Pure ISO C99 — Early-Return-Safe Defer Stack)

For strict non-GNU C99 compilers:

```c
Cl_Defer_Stack ds;
cl_defer_stack_init(&ds);
cl_defer_stack_push(&ds, close_resource, &res);
if (failed) {
    CL_DEFER_STACK_RETURN(&ds, CL_ERR_IO_READ);
}
cl_defer_stack_run(&ds);
```

---

## 8. Multiple Return Values & Error Propagation

On Linux x86_64 SysV ABI, structs up to 16 bytes (such as `{ cl_i64 value; bool ok; }`) are returned directly in CPU registers (`RAX` + `RDX`) with zero stack spill.

```c
/* Define custom optional, result, pair, or triple return types */
CL_OPT_DEFINE(Opt_Port, cl_u16);
CL_RES_DEFINE(Res_Config, My_Config, Cl_Error);
CL_PAIR_DEFINE(Div_Mod, cl_i64, cl_i64);

/* Return and propagate errors cleanly */
static CL_NODISCARD Cl_Res_I64 load_and_double(Cl_Str path, Cl_Allocator alloc) {
    Cl_Str text;
    CL_OR_RETURN(text, cl_os_read_entire_file_str(path, alloc), Cl_Res_I64);
    void *slot = (void *)(cl_uintptr)text.data;
    CL_DEFER_FREE_SLOT(alloc, slot, text.len);

    Cl_Opt_I64 n = cl_str_parse_i64(text, 10);
    if (!n.ok) {
        return CL_ERR(Cl_Res_I64, CL_ERR_PARSE_FAILED);
    }
    return CL_OK(Cl_Res_I64, n.value * 2);
}
```

Propagation macros:
- `CL_OR_RETURN(out, res_expr, RetResType)` — unpack `value` or return `CL_ERR(RetResType, err)`.
- `CL_OR_RETURN_ERR(out, res_expr)` — unpack `value` or return `err` directly (when function returns `Cl_Error`).
- `CL_OPT_OR_RETURN(out, opt_expr, RetOptType)` — unpack `value` or return `CL_NONE(RetOptType)`.
- `CL_OR_ELSE(opt_expr, fallback)` / `CL_RES_OR_ELSE(res_expr, fallback)` — inline fallback value.
- `CL_OPT_OR_BREAK(out, opt_expr)` / `CL_OPT_OR_CONTINUE(out, opt_expr)` — loop-friendly unpacking.
- `CL_OPT_OR_PANIC(opt_expr)` / `CL_RES_OR_PANIC(res_expr)` — assert-unwrap.

---

## 9. Containers: Slices, Dynamic Arrays, Small Arrays, Queues, BitSets & HashMaps

### Typed Slices (`cl_slice.h`)

```c
CL_SLICE_DEFINE(Slice_Vec2, Vec2);

cl_i32 arr[5] = { 5, 3, 1, 4, 2 };
Cl_Slice_I32 s = CL_SLICE_FROM_ARRAY(Cl_Slice_I32, arr);
Cl_Slice_I32 mid = CL_SLICE_SUB(s, 1, 4); /* { 3, 1, 4 }, zero-copy, bounds-checked */
CL_SLICE_SORT(s, cl_cmp_i32);
cl_isize pos = CL_SLICE_BSEARCH(s, &(cl_i32){4}, cl_cmp_i32);
```

### Dynamic Arrays (`cl_array.h`)

Zero-initialization `{0}` is valid and binds `cl_ctx_allocator()` automatically on first push:

```c
Cl_DA_F64 vals = {0};
CL_DEFER_DA(vals);
CL_DA_PUSH(&vals, 3.14);
CL_DA_INJECT_AT(&vals, 0, 1.41);
CL_DA_ORDERED_REMOVE(&vals, 0);   /* O(n), preserves order */
CL_DA_UNORDERED_REMOVE(&vals, 0); /* O(1), swap-with-last */
Cl_Slice_F64 view = CL_DA_AS_SLICE(Cl_Slice_F64, &vals);
```

Also in `cl_array.h`:
- `CL_SMALL_ARRAY_DEFINE(Name, T, CAP)` — stack-allocated fixed-capacity dynamic-length array (zero heap allocs).
- `CL_QUEUE_DEFINE(Name, T)` — O(1) circular ring buffer (`PUSH_BACK`, `PUSH_FRONT`, `POP_FRONT_SAFE`, `POP_BACK_SAFE`).
- `Cl_Bit_Set` — compact 64-bit word bitset (`set`, `clear`, `toggle`, `test`, `count_ones`, `union_in_place`, `intersect_in_place`).

### HashMap (`cl_map.h`)

Uses 8-bit Swiss-style control bytes (`0xFF`=EMPTY, `0xFE`=TOMBSTONE, `0x00..0x7F`=7-bit H2 fingerprint) indexing into dense contiguous `keys[]` and `values[]` arrays:

```c
Cl_Map_Str_I64 counts = {0};
CL_MAP_INIT_STR(&counts, alloc); /* Hashes string BYTES, not pointer addresses! */
CL_DEFER_MAP(counts);

CL_MAP_PUT(&counts, CL_STR("apples"), 5);
cl_i64 *p = CL_MAP_GET(&counts, CL_STR("apples"));
if (p != NULL) { *p += 1; }

/* Dense sequential iteration: zero empty buckets skipped! */
CL_MAP_FOR_EACH(i, &counts) {
    printf(CL_STR_FMT " => %lld\n", CL_STR_ARG(counts.keys[i]), (CL_LL)counts.values[i]);
}
```

Use `CL_MAP_INIT_STR`, `CL_MAP_INIT_CSTR`, `CL_MAP_INIT_I64`, `CL_MAP_INIT_U64`, `CL_MAP_INIT_I32`, `CL_MAP_INIT_POD`, or `CL_MAP_INIT(m, alloc, custom_hash, custom_eq)`.

### Using Custom `struct` Types with Slices, Dynamic Arrays, and HashMaps

All generic containers in `c_lib` (`CL_SLICE_DEFINE`, `CL_DA_DEFINE`, `CL_MAP_DEFINE`, `CL_SMALL_ARRAY_DEFINE`, `CL_QUEUE_DEFINE`, `CL_OPT_DEFINE`, `CL_RES_DEFINE`) follow the same one-line type-generator pattern for user-defined structs.

#### 1. Passing a Slice of Structs as a Function Parameter

```c
typedef struct My_Struct {
    cl_i32 id;
    cl_f64 value;
    Cl_Str name;
} My_Struct;

/* Generate the typed slice (and optionally a matching dynamic array) in 1 line */
CL_SLICE_DEFINE(Cl_Slice_My_Struct, My_Struct);
CL_DA_DEFINE(Cl_DA_My_Struct, My_Struct);

/* Optional: read-only slice preventing callers from mutating struct fields */
CL_SLICE_DEFINE(Cl_Slice_Const_My_Struct, const My_Struct);

/* Pass slices BY VALUE (only 16 bytes: { data, len }) */
static void print_my_struct_slice(const char *label, Cl_Slice_My_Struct s1) {
    printf("  %-18s [len=%lld]:\n", label, (CL_LL)s1.len);
    CL_SLICE_FOR_EACH(i, s1) {
        /* Take the address of CL_SLICE_AT to avoid copying large structs */
        const My_Struct *item = &CL_SLICE_AT(s1, i);
        printf("    [%lld] id=%d, value=%.2f, name=" CL_STR_FMT "\n",
               (CL_LL)i, item->id, item->value, CL_STR_ARG(item->name));
    }
}
```

Creating and passing `Cl_Slice_My_Struct` from any backing storage:

```c
/* From a stack / static C array */
My_Struct raw[] = {
    { 1, 10.5, CL_STR("alpha") },
    { 2, 20.0, CL_STR("beta")  },
    { 3, 30.5, CL_STR("gamma") },
};
Cl_Slice_My_Struct s1 = CL_SLICE_FROM_ARRAY(Cl_Slice_My_Struct, raw);
print_my_struct_slice("Array", s1);

/* Zero-copy sub-slice s1[1:3] */
print_my_struct_slice("Sub [1:3]", CL_SLICE_SUB(s1, 1, 3));

/* Zero-copy O(1) view from a Dynamic Array */
Cl_DA_My_Struct da = {0};
CL_DEFER_DA(da);
CL_DA_PUSH(&da, ((My_Struct){ 4, 40.0, CL_STR("delta") }));
print_my_struct_slice("From DA", CL_DA_AS_SLICE(Cl_Slice_My_Struct, &da));

/* Allocated directly from any Cl_Allocator (heap, arena, virtual arena) */
Cl_Slice_My_Struct dyn = CL_SLICE_MAKE(Cl_Slice_My_Struct, alloc, 5);
CL_SLICE_AT(dyn, 0).id = 99; /* Mutable bounds-checked lvalue */
CL_SLICE_FREE(alloc, dyn);
```

*(See [13_dynamic_arrays_in_depth.c](c_lib_examples/level_2_intermediate/13_dynamic_arrays_in_depth.c) for a complete runnable example.)*

#### 2. Using a Struct as a HashMap Value or Key

**Struct as Value (`Cl_Str -> My_Struct`):**

```c
CL_MAP_DEFINE(Cl_Map_Str_My_Struct, Cl_Str, My_Struct);

/* Pass HashMaps BY POINTER (const for read-only, non-const for mutation) */
static void print_my_map(const Cl_Map_Str_My_Struct *m) {
    CL_MAP_FOR_EACH(i, m) {
        const My_Struct *v = &m->values[i];
        printf("  " CL_STR_FMT " => { id=%d, value=%.2f }\n",
               CL_STR_ARG(m->keys[i]), v->id, v->value);
    }
}

Cl_Map_Str_My_Struct m = {0};
CL_MAP_INIT_STR(&m, alloc);
CL_DEFER_MAP(m);

CL_MAP_PUT(&m, CL_STR("player1"), ((My_Struct){ 1, 99.5, CL_STR("Alice") }));

/* Modify the stored struct directly in place */
My_Struct *entry = CL_MAP_GET(&m, CL_STR("player1"));
if (entry != NULL) {
    entry->value += 10.0;
}
print_my_map(&m);
```

**Struct as Key (`My_Key -> My_Struct`):**

```c
typedef struct My_Key {
    cl_i32 x;
    cl_i32 y;
} My_Key;

CL_STATIC_ASSERT(sizeof(My_Key) == 8, my_key_has_no_padding);
CL_MAP_DEFINE(Cl_Map_Key_My_Struct, My_Key, My_Struct);
```

Choose the right initializer for struct keys:
- **Zero-padding POD structs** (like `My_Key` above): use `CL_MAP_INIT_POD(&m, alloc);` (hashes and compares raw bytes; verify zero padding with `CL_STATIC_ASSERT`).
- **Structs containing padding bytes, pointers, `Cl_Str`, or floats**: provide explicit field-by-field hash and equality callbacks via `CL_MAP_INIT(&m, alloc, my_key_hash, my_key_eq);` so uninitialized padding bytes or distinct pointer addresses never cause false lookup misses.

*(See [15_custom_hashmap_struct_keys.c](c_lib_examples/level_2_intermediate/15_custom_hashmap_struct_keys.c) and [29_log_file_analyzer_pipeline.c](c_lib_examples/level_3_advanced/29_log_file_analyzer_pipeline.c) for full runnable examples.)*

#### 3. Parameter-Passing Rule of Thumb (By Value vs By Pointer)

| Type Category | How to Pass to Functions | Why |
|---|---|---|
| **Views**: `Cl_Slice_*`, `Cl_Str`, `Cl_Bytes`, `Cl_Allocator` | **By value** (`Cl_Slice_My_Struct s`) | Lightweight 16-byte non-owning descriptors (`{ data, len }` or `{ proc, data }`). |
| **Owning Containers**: `Cl_Map_*`, `Cl_DA_*`, `Cl_Queue_*`, `Cl_Small_Array`, `Cl_String_Builder`, `Cl_Str_Buf`, `Cl_Bit_Set` | **By pointer** (`const Type *` read-only, `Type *` mutable) | They manage internal heap/arena buffers and capacities; all container macros (`CL_MAP_*`, `CL_DA_*`, etc.) operate on pointers. |

---

## 10. Strings, UTF-8, `Cl_String_Builder` & `Cl_Str_Buf`

### `Cl_Str` & C-String Interop (`cl_string.h`, `cl_utf8.h`)

- `CL_STR("hello")` computes length at compile time in O(1).
- Print safely with `CL_STR_FMT` and `CL_STR_ARG(s)` (`printf(CL_STR_FMT "\n", CL_STR_ARG(s))`).
- Convert to NUL-terminated C string:
  - `cl_str_to_cstr_temp(s)` — best for quick POSIX/libc calls (freed on `cl_ctx_temp_reset()`).
  - `cl_str_to_cstr_buf(s, stack_buf, cap)` — zero allocation when max length is bounded.
  - `cl_str_to_cstr(s, alloc)` — caller-owned, freed with `cl_cstr_free(cs, s.len, alloc)`.
- Zero-allocation operations: `cl_str_slice`, `cl_str_cut`, `cl_str_trim_*`, `cl_str_eq`, `cl_str_eq_fold`, `cl_str_cmp`, `cl_str_has_prefix/suffix`, `cl_str_contains`, `cl_str_index`, `cl_str_count`, `cl_str_split_iter`, `cl_str_split_lines_iter`, `cl_str_fields_iter`.
- Allocating operations: `cl_str_clone`, `cl_str_split`, `cl_str_join`, `cl_str_concat`, `cl_str_repeat`, `cl_str_replace_all`, `cl_str_replace_n`, `cl_str_to_lower/upper`, `cl_str_reverse_utf8`, `cl_str_pad_left/right`.
- Strict parsers (`CL_NODISCARD`): `cl_str_parse_i64`, `cl_str_parse_u64` (supports `0x`/`0b`/`0o` and Odin underscores like `1_000_000`), `cl_str_parse_f64`, `cl_str_parse_bool`, `cl_str_parse_c64`, `cl_str_parse_c128`.
- Strict RFC 3629 UTF-8: `cl_utf8_decode_rune`, `cl_utf8_encode_rune`, `cl_utf8_valid`, `cl_utf8_rune_count`, `cl_utf8_next`.

### Choosing Between `Cl_String_Builder` and `Cl_Str_Buf`

| Criterion | `Cl_String_Builder` (`cl_string_builder.h`) | `Cl_Str_Buf` (`cl_strbuf.h`) |
|---|---|---|
| Primary use case | Building arbitrarily long strings incrementally (JSON, reports, SQL, logs) | In-place editing of fixed `char buf[N]` (paths, protocol headers, real-time loops) |
| Heap allocations | Grows via `Cl_Allocator` (or optional fixed mode) | **Never allocates** (always caller buffer) |
| NUL termination | On-demand via `cl_sb_to_cstr(&sb)` | **Guaranteed at every step** (`data[len] == '\0'`) |
| In-place edit ops | Append, pop byte, truncate, reset | Set, append, **insert, erase, replace_in_place, trim, upper/lower, reverse, pad** |
| Formatter helpers | `cl_sb_write_fmt`, `cl_sb_write_c64/c128`, `cl_aprintf`, `cl_tprintf` | `cl_strbuf_append_fmt`, `cl_bprintf` |

---

## 11. Structured Logging & Linux OS / Time

### Logging (`cl_log.h`)

```c
Cl_Multi_Logger ml;
cl_multi_logger_init(&ml);
cl_multi_logger_add(&ml, cl_console_logger(CL_LOG_LEVEL_INFO, CL_LOG_DEFAULT_OPTIONS));
cl_multi_logger_add(&ml, cl_file_logger(log_fp, CL_LOG_LEVEL_WARN, CL_LOG_OPT_LEVEL | CL_LOG_OPT_TIME));

Cl_Context ctx = cl_ctx_default();
ctx.logger = cl_multi_logger(&ml, CL_LOG_LEVEL_DEBUG);
CL_DEFER_CTX_PUSH(ctx);

CL_LOG_INFO("Server listening on port %d", 8080);
CL_LOG_WARN("High latency: %.2f ms", 142.5);
```

### Whole-File Linux Filesystem I/O & Stopwatch (`cl_os.h`)

The filesystem surface in `cl_os.h` is intentionally minimal and focuses strictly on **reading and writing whole files at once** (no streaming reader classes, directory walkers, or symlink/permission trees):

- `cl_os_read_entire_file(Cl_Str path, Cl_Allocator alloc)` -> `Cl_Res_Bytes` (single exact allocation on regular files + automatic chunked fallback on Linux `/proc` virtual files whose `st_size == 0`).
- `cl_os_read_entire_file_str(Cl_Str path, Cl_Allocator alloc)` -> `Cl_Res_Str`.
- `cl_os_read_entire_file_cstr(const char *path, Cl_Allocator alloc)` -> `Cl_Res_Bytes`.
- `cl_os_write_entire_file(Cl_Str path, Cl_Bytes data)` -> `Cl_Error`.
- `cl_os_write_entire_file_str(Cl_Str path, Cl_Str text)` -> `Cl_Error`.
- `cl_os_write_entire_file_cstr(const char *path, Cl_Bytes data)` -> `Cl_Error`.
- `cl_os_write_entire_file_atomic(Cl_Str path, Cl_Bytes data)` -> `Cl_Error` (writes sibling temp file, calls `fsync()`, and atomically replaces target via `rename()`).

```c
Cl_Res_Str content = cl_os_read_entire_file_str(CL_STR("config.ini"), alloc);
if (content.err == CL_ERR_NONE) {
    /* Use content.value ... */
    cl_str_free(content.value, alloc);
}

/* Crash-safe whole-file replacement */
Cl_Bytes payload = { (cl_u8 *)"ok\n", 3 };
Cl_Error err = cl_os_write_entire_file_atomic(CL_STR("state.dat"), payload);

Cl_Stopwatch sw = {0};
cl_stopwatch_start(&sw);
/* ... work ... */
cl_stopwatch_stop(&sw);
printf("Elapsed: %.3f ms\n", cl_stopwatch_elapsed_ms(&sw));
```

---

## 12. Honest Trade-Offs: C99 vs Native Odin

`c_lib` gets remarkably close to Odin's feel while keeping 100% C99 speed and ecosystem interoperability, with a few inherent C99 realities to keep in mind:

1. **Macro-generated generics**: C99 has no parametric polymorphism, so custom slice/array/map/result types require a 1-line typedef macro (`CL_DA_DEFINE`, `CL_MAP_DEFINE`, `CL_SLICE_DEFINE`, `CL_RES_DEFINE`). To prevent code bloat, all heavy logic (resizing, probing, rehashing, sorting) lives in single shared `.c` runtime engines.
2. **Manual lifetime ownership**: Unlike Rust's borrow checker (and just like Odin), views (`Cl_Str`, `Cl_Slice_*`) do not track lifetime at compile time. Using Arenas + `CL_DEFER_*` + `Cl_Tracking_Allocator` + ASan arena poisoning makes lifetimes simple, structured, and verifiable.
3. **No language-level implicit parameter**: Odin threads `context` implicitly as a hidden function argument; `c_lib` uses fast thread-local storage (`__thread` on GCC/Clang) with a scoped stack (`CL_DEFER_CTX_PUSH`), giving nearly identical ergonomics at near-zero cost.
4. **Tier 1 `defer` portability**: `CL_DEFER_*` uses `__attribute__((cleanup))`, which works identically on GCC and Clang on Linux (no executable stack). If you ever port to MSVC or an exotic non-GNU C99 compiler, Tier 2 (`CL_DEFER_LOOP`) and Tier 3 (`Cl_Defer_Stack`) provide pure ISO C99 fallbacks.
5. **Recommended Workflow**: Develop and run tests with `PROFILE=sanitize` (`CL_BOUNDS_CHECK=1` + ASan + UBSan + `Cl_Tracking_Allocator`), then ship with `PROFILE=release` (`-O2 -DNDEBUG -DCL_BOUNDS_CHECK=0`) for full bare-metal C performance.

---

## 13. License

`c_lib` (all library modules, unit tests, examples, build files, and documentation tools) is open-source software licensed under the **MIT Open Source License** (`SPDX-License-Identifier: MIT`).

You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the software subject to the terms in the root [LICENSE](LICENSE) file.
