import std/strutils

proc currentSourceDir(): string {.compileTime.} =
  result = currentSourcePath().replace("\\", "/")
  result = result[0 ..< result.rfind("/")]

{.passc: "-I" & currentSourceDir() & "/libdeflate_gzip/private/libdeflate",
  passc: "-std=c99",
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

# TODO Create wrapper which automatically frees decompressor with `=destroy`.
type
  Decompressor = object
  DecompressorPtr* = ptr Decompressor

type
  Result* = enum
    Success = 0
    BadData = 1
    # This can't happen because `decompress` never specifies how long the output should be.
    # ShortOutput = 2
    InsufficientSpace = 3

proc allocDecompressor*(): DecompressorPtr {.importc: "libdeflate_alloc_decompressor".}

proc decompressC(
  decompressor: DecompressorPtr,
  input: pointer, inputSize: csize_t,
  output: pointer, outputSize: csize_t,
  read: var csize_t, written: var csize_t,
): Result {.importc: "libdeflate_gzip_decompress_ex".}

proc deallocDecompressor*(decompressor: DecompressorPtr) {.importc: "libdeflate_free_decompressor".}

# Using pointers is more flexible than using strings.
proc decompress*(
  decompressor: DecompressorPtr,
  input: pointer, inputSize: int64,
  output: pointer, outputSize: int64,
  read: var int64, written: var int64,
): Result =
  var readC, writtenC = 0.csize_t
  result = decompressC(
    decompressor,
    input, inputSize.csize_t,
    output, outputSize.csize_t,
    readC, writtenC,
  )
  read = readC.int64
  written = writtenC.int64
