import std/strutils

proc currentSourceDir(): string {.compileTime.} =
  result = currentSourcePath().replace("\\", "/")
  result = result[0 ..< result.rfind("/")]

{.passc: "-I" & currentSourceDir() & "/libdeflate_gzip/private/libdeflate",
  passc: "-std=c11",
  passc: "-Wall",
  passc: "-D_ANSI_SOURCE"
.}

when defined(arm) or defined(arm64):
  {.compile: "libdeflate_gzip/private/libdeflate/lib/arm/cpu_features.c".}
else:
  {.compile: "libdeflate_gzip/private/libdeflate/lib/x86/cpu_features.c".}

{.compile: "libdeflate_gzip/private/libdeflate/lib/deflate_decompress.c",
  compile: "libdeflate_gzip/private/libdeflate/lib/utils.c",
  compile: "libdeflate_gzip/private/libdeflate/lib/crc32.c",
  compile: "libdeflate_gzip/private/libdeflate/lib/gzip_decompress.c"
.}

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

proc `=destroy`*(decompressor: var Decompressor) =
  if decompressor.raw != nil:
    deallocDecompressorC(decompressor.raw)

proc `=copy`*(dest: var Decompressor, src: Decompressor) {.error: "Copying not allowed".}

proc newDecompressor*(): Decompressor =
  result.raw = allocDecompressorC()

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
