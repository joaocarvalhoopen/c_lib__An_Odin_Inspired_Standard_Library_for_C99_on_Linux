# ============================================================================
# Top-level Makefile for c_lib, c_lib_unit_tests, and c_lib_examples
# License: MIT Open Source License (see LICENSE file)
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Joao Carvalho
#
# Common Commands:
#   make               -> Build c_lib, unit tests, and examples (debug)
#   make test          -> Run unit test suite (debug)
#   make test-all      -> Run unit tests across debug, sanitize, release, clang
#   make examples      -> Build and run all 30 examples (debug)
#   make examples-asan -> Build and run all 30 examples under ASan + UBSan
#   make docs          -> Generate Odin-style HTML API reference in c_lib_ref_html/
#   make verify        -> Full CI check (test-all + examples + examples-asan + docs)
#   make clean         -> Clean all build directories
# ============================================================================

PROFILE ?= debug

.PHONY: all lib test test-all examples examples-asan docs verify clean

all: lib
	$(MAKE) -C c_lib_unit_tests PROFILE=$(PROFILE)
	$(MAKE) -C c_lib_examples PROFILE=$(PROFILE)

lib:
	$(MAKE) -C c_lib PROFILE=$(PROFILE)

test:
	$(MAKE) -C c_lib_unit_tests PROFILE=$(PROFILE) test

test-all:
	$(MAKE) -C c_lib_unit_tests test-all

examples:
	$(MAKE) -C c_lib_examples PROFILE=$(PROFILE) run

examples-asan:
	$(MAKE) -C c_lib_examples run-sanitize

docs:
	python3 c_lib_ref_html/generate_docs.py

verify: test-all examples examples-asan docs

clean:
	$(MAKE) -C c_lib clean
	$(MAKE) -C c_lib_unit_tests clean
	$(MAKE) -C c_lib_examples clean
