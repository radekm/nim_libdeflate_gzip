when not defined(gcArc) and not defined(gcOrc):
  {.error: "Using --mm:arc or --mm:orc is required by libdeflate_gzip".}

import std/strutils

proc currentSourceDir(): string {.compileTime.} =
  result = currentSourcePath().replace("\\", "/")
  result = result[0 ..< result.rfind("/")]

{.passc: "-I" & currentSourceDir() & "/libdeflate_gzip/private/libdeflate",
  passc: "-std=c11",
  passc: "-Wall"
.}

when defined(arm) or defined(arm64):
  {.compile: "libdeflate_gzip/private/libdeflate/lib/arm/cpu_features.c".}
else:
  {.compile: "libdeflate_gzip/private/libdeflate/lib/x86/cpu_features.c".}

{.compile: "libdeflate_gzip/private/libdeflate/lib/deflate_compress.c",
  compile: "libdeflate_gzip/private/libdeflate/lib/deflate_decompress.c",
  compile: "libdeflate_gzip/private/libdeflate/lib/utils.c",
  compile: "libdeflate_gzip/private/libdeflate/lib/crc32.c",
  compile: "libdeflate_gzip/private/libdeflate/lib/gzip_compress.c",
  compile: "libdeflate_gzip/private/libdeflate/lib/gzip_decompress.c",
.}

type
  CompressorC = ptr object

proc allocCompressorC(
  compressionLevel: cint
): CompressorC {.importc: "libdeflate_alloc_compressor".}

# Returns 0 on failure.
# `output` buffer must be slightly bigger than actual compressed output.
proc compressC(
  compressor: CompressorC,
  input: pointer, inputSize: csize_t,
  output: pointer, outputSize: csize_t,
): csize_t {.importc: "libdeflate_gzip_compress".}

proc deallocCompressorC(compressor: CompressorC) {.importc: "libdeflate_free_compressor".}

type
  Compressor* = object
    raw: CompressorC

proc `=destroy`*(compressor: Compressor) =
  if compressor.raw != nil:
    deallocCompressorC(compressor.raw)

proc `=copy`*(dest: var Compressor, src: Compressor) {.error: "Copying not allowed".}

proc newCompressor*(compressionLevel: int32): Compressor =
  result.raw = allocCompressorC(compressionLevel)
  if result.raw == nil:
    raise newException(CatchableError, "Not enough memory to create compressor")

# Using pointers is more flexible than using strings.
proc compress*(
  compressor: Compressor,
  input: pointer, inputSize: int,
  output: pointer, outputSize: int,
): int =
  result = compressC(
    compressor.raw,
    input, inputSize.csize_t,
    output, outputSize.csize_t,
  ).int

type
  DecompressorC = ptr object

type
  Result* {.size: sizeof(cint).} = enum
    Success = 0
    BadData = 1
    # This can't happen because `decompress` never specifies how long the output should be.
    # ShortOutput = 2
    InsufficientSpace = 3

proc allocDecompressorC(): DecompressorC {.importc: "libdeflate_alloc_decompressor".}

proc decompressC(
  decompressor: DecompressorC,
  input: pointer, inputSize: csize_t,
  output: pointer, outputSize: csize_t,
  read: var csize_t, written: var csize_t,
): Result {.importc: "libdeflate_gzip_decompress_ex".}

proc deallocDecompressorC(decompressor: DecompressorC) {.importc: "libdeflate_free_decompressor".}

type
  Decompressor* = object
    raw: DecompressorC

proc `=destroy`*(decompressor: Decompressor) =
  if decompressor.raw != nil:
    deallocDecompressorC(decompressor.raw)

proc `=copy`*(dest: var Decompressor, src: Decompressor) {.error: "Copying not allowed".}

proc newDecompressor*(): Decompressor =
  result.raw = allocDecompressorC()
  if result.raw == nil:
    raise newException(CatchableError, "Not enough memory to create decompressor")

# Using pointers is more flexible than using strings.
proc decompress*(
  decompressor: Decompressor,
  input: pointer, inputSize: int,
  output: pointer, outputSize: int,
  read: var int, written: var int,
): Result =
  var readC, writtenC = 0.csize_t
  result = decompressC(
    decompressor.raw,
    input, inputSize.csize_t,
    output, outputSize.csize_t,
    readC, writtenC,
  )
  read = readC.int
  written = writtenC.int
