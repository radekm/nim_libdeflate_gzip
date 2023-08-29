# About

Nim wrapper for libdeflate's gzip functionality.
Since this library relies on destructors only `--mm:arc` and `--mm:orc` are supported.
No external dependencies are needed because libdeflate is embedded.

The main difference from Zippy is that libdeflate supports
gzips with multiple members (ie. multiple gzips concatenated together).
In our benchmark libdeflate always achieved better compression ratio than Zippy.
Speed varied sometimes libdeflate was faster and sometimes Zippy was faster.

# Usage

Examples are in `tests/test.nim`. If you want to iterate through all members
use iterator `decompressGzipMembers`.

# Performance

After putting compression corpus into `benchmark/corpus` benchmarking can be performed by running

```
nim c -d:release -r benchmark/bench.nim benchmark/corpus
```

We stored files of Canterbury Corpus into `benchmark/corpus`
and ran the benchmark with the following results:

```
libdeflate_gzip [best compression]
   min time    avg time  std dv   runs name
1195.580 ms 1209.007 ms ±16.449     x5 E.coli
   5.268 ms    5.526 ms  ±0.175   x899 alice29.txt
   3.717 ms    3.892 ms  ±0.119  x1000 asyoulik.txt
 184.394 ms  188.128 ms  ±2.130    x27 bible.txt
   0.449 ms    0.470 ms  ±0.029  x1000 cp.html
   0.210 ms    0.215 ms  ±0.007  x1000 fields.c
   0.081 ms    0.084 ms  ±0.007  x1000 grammar.lsp
  92.985 ms   95.265 ms  ±1.788    x53 kennedy.xls
  12.821 ms   13.287 ms  ±0.288   x375 lcet10.txt
  18.539 ms   19.162 ms  ±0.432   x261 plrabn12.txt
   8.931 ms    9.312 ms  ±0.241   x534 ptt5
   1.047 ms    1.100 ms  ±0.045  x1000 sum
  68.342 ms   70.074 ms  ±1.347    x72 world192.txt
   0.082 ms    0.085 ms  ±0.007  x1000 xargs.1
libdeflate_gzip [extreme compression]
 935.087 ms  940.593 ms  ±7.056     x6 E.coli
  34.777 ms   35.947 ms  ±0.729   x139 alice29.txt
  20.796 ms   21.622 ms  ±0.498   x231 asyoulik.txt
 853.568 ms  871.239 ms ±14.762     x6 bible.txt
   4.260 ms    4.471 ms  ±0.205  x1000 cp.html
   1.425 ms    1.571 ms  ±0.174  x1000 fields.c
   0.485 ms    0.504 ms  ±0.019  x1000 grammar.lsp
  92.977 ms   95.004 ms  ±1.288    x53 kennedy.xls
  70.173 ms   72.436 ms  ±1.458    x69 lcet10.txt
 104.050 ms  106.002 ms  ±1.471    x48 plrabn12.txt
 186.481 ms  190.618 ms  ±2.271    x27 ptt5
   4.604 ms    4.797 ms  ±0.127  x1000 sum
 405.040 ms  412.119 ms  ±7.127    x13 world192.txt
   0.479 ms    0.509 ms  ±0.029  x1000 xargs.1
zippy [best compression]
 426.592 ms  430.734 ms  ±4.946    x12 E.coli
   4.227 ms    4.398 ms  ±0.114  x1000 alice29.txt
   2.878 ms    3.010 ms  ±0.088  x1000 asyoulik.txt
 165.265 ms  168.568 ms  ±2.401    x30 bible.txt
   0.418 ms    0.432 ms  ±0.013  x1000 cp.html
   0.222 ms    0.242 ms  ±0.024  x1000 fields.c
   0.103 ms    0.108 ms  ±0.008  x1000 grammar.lsp
  97.076 ms   99.796 ms  ±2.385    x50 kennedy.xls
  12.464 ms   12.956 ms  ±0.315   x384 lcet10.txt
  14.304 ms   14.798 ms  ±0.289   x338 plrabn12.txt
 142.542 ms  145.645 ms  ±2.679    x35 ptt5
   1.433 ms    1.491 ms  ±0.064  x1000 sum
  95.373 ms   97.099 ms  ±1.430    x52 world192.txt
   0.106 ms    0.110 ms  ±0.011  x1000 xargs.1

Sizes

                file   uncompressed      ld [best]   ld [extreme]   zippy [best]
              E.coli        4638690        1235915        1223548        1303378
         alice29.txt         152089          53564          51680          55149
        asyoulik.txt         125179          47989          46487          49473
           bible.txt        4047392        1161166        1107396        1193722
             cp.html          24603           7934           7741           8105
            fields.c          11150           3120           3042           3240
         grammar.lsp           3721           1222           1204           1258
         kennedy.xls        1029744         181469         179067         242329
          lcet10.txt         426754         142045         137939         146959
        plrabn12.txt         481861         191694         184389         196190
                ptt5         513216          52204          49212          55052
                 sum          38240          12592          11983          13910
        world192.txt        2473400         714212         695270         737593
             xargs.1           4227           1735           1708           1816
```

Benchmark was run on Intel Mac with
libdeflate_gzip 0.5.0, Zippy 0.10.10, benchy 0.0.1, Nim 2.0.0.

## Benchmark summary

In our benchmark libdeflate had always better compression ratio than Zippy.
Libdeflate with compression level 9 had similar speed to Zippy with compression level 9.
The exception is file `E.coli` where libdeflate was 3 times slower than Zippy
and `ptt5` where Zippy was 14 times slower than Libdeflate.
Libdeflate with compression level 12 was usually the slowest.

# Updating libdeflate

Libdeflate can be updated by running

```shell
git subtree pull --prefix src/libdeflate_gzip/private/libdeflate https://github.com/ebiggers/libdeflate.git master --squash
```
