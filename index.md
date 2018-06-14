---
layout: main
title: Cyclone Scheme
id: index
ghproj: "http://github.com/justinethier/cyclone/tree/master/"
---

Cyclone is a brand-new Scheme-to-C compiler that allows practical development of applications using R<sup>7</sup>RS Scheme. [Cheney on the MTA](http://www.pipeline.com/~hbaker1/CheneyMTA.html) is used by the runtime to implement full tail recursion, continuations, and generational garbage collection. In addition, the Cheney on the MTA concept has been extended to allow execution of multiple native threads. An on-the-fly garbage collector is used to manage the second-generation heap and perform major collections without "stopping the world".

Cyclone is the first compiler written entirely in the latest R<sup>7</sup>RS Scheme language standard, and the intent is to support as much of that language as possible.

Features
--------

- Support for the majority of the Scheme language as specified by the latest [R<sup>7</sup>RS standard](docs/Scheme-Language-Compliance.md). 
- New features from R<sup>7</sup>RS including libraries, exceptions, and record types.
- Built-in support for Unicode strings and characters.
- Hygienic macros based on `syntax-rules`
- Low-level explicit renaming macros
- Guaranteed tail call optimizations
- Native multithreading support
- A foreign function interface that allows easy integration with C
- A concurrent, generational garbage collector based on Cheney on the MTA
- Includes an optimizing Scheme-to-C compiler,
- ... as well as an interpreter for debugging
- Support for [many popular SRFI's](docs/API.md#srfi-libraries)
- Online user manual and API documentation

Getting Started
---------------

1. To install Cyclone on your machine for the first time use [**cyclone-bootstrap**](https://github.com/justinethier/cyclone-bootstrap) to build a set of binaries. Instructions are provided for Linux, Mac, and Windows (via MSYS).

2. After installing you can run the `cyclone` command to compile a single Scheme file:

        $ cyclone examples/fac.scm
        $ examples/fac
        3628800
    
    And the `icyc` command to start an interactive interpreter:
    
        $ icyc
        
                      :@
                    @@@
                  @@@@:
                `@@@@@+
               .@@@+@@@      Cyclone
               @@     @@     An experimental Scheme compiler
              ,@             https://github.com/justinethier/cyclone
              '@
              .@
               @@     #@     (c) 2014 Justin Ethier
               `@@@#@@@.     Version 0.0.1 (Pre-release)
                #@@@@@
                +@@@+
                @@#
              `@.
        
        cyclone> (write 'hello-world)
        hello-world

   You can use [`rlwrap`](http://linux.die.net/man/1/rlwrap) to make the interpreter more friendly, EG: `rlwrap icyc`.

3. Read the documentation below for more information on how to use Cyclone.

Documentation
-------------

- The [User Manual](docs/User-Manual) covers in detail how to use Cyclone and provides information on the Scheme language features implemented by Cyclone.

- An [API Reference](docs/API) is available for all libraries provided by Cyclone, including a complete alphabetical listing.

- If you need a resource to start learning the Scheme language you may want to try a classic textbook such as [Structure and Interpretation of Computer Programs](https://mitpress.mit.edu/sicp/full-text/book/book.html).

- Finally, this [benchmarks](http://ecraven.github.io/r7rs-benchmarks/benchmark.html) page by [ecraven](https://github.com/ecraven) compares the performance of Cyclone with other Schemes.

Example Programs
----------------

Cyclone provides several example programs, including:

- [Tail Call Optimization]({{ page.ghproj }}examples/tail-call-optimization.scm) - A simple example of Scheme tail call optimization; this program runs forever, calling into two mutually recursive functions.

- [Threading]({{ page.ghproj }}examples/threading) - Various examples of multi-threaded programs.

- [Game of Life]({{ page.ghproj }}examples/game-of-life) - The [Conway's game of life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) example program and libraries from R<sup>7</sup>RS.

- [Game of Life PNG Image Generator]({{ page.ghproj }}examples/game-of-life-png) - A modified version of game of life that uses libpng to create an image of each iteration instead of writing it to console. This example also demonstrates basic usage of the C Foreign Function Interface (FFI).

- Finally, the largest program is the compiler itself. Most of the code is contained in a series of libraries which are used by [`cyclone.scm`]({{ page.ghproj }}cyclone.scm) and [`icyc.scm`]({{ page.ghproj }}icyc.scm) to create executables for Cyclone's compiler and interpreter.

Compiler Internals
------------------

- [Writing the Cyclone Scheme Compiler](docs/Writing-the-Cyclone-Scheme-Compiler-Revised-2017) provides high-level details on how the compiler was written and how it works.

- There is a [Development Guide](docs/Development) with instructions for common tasks when hacking on the compiler itself.

- Cyclone's [Garbage Collector](docs/Garbage-Collector) is documented at a high-level. This document includes details on extending Cheney on the MTA to support multiple stacks and fusing that approach with a tri-color marking collector.