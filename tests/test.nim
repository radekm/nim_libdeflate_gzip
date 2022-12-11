import std/os
import std/strutils

import unittest

import libdeflate_gzip

proc currentSourceDir(): string {.compileTime.} =
  result = currentSourcePath().replace("\\", "/")
  result = result[0 ..< result.rfind("/")]

const
  dataDir = currentSourceDir() & "/data"
  bufferSize = 1000

test "gzip and ungzip string":
  let c = newCompressor(12)
  let d = newDecompressor()
  let str = "Zero Waste Life"
  let compressed = newString(256)
  let compressedLen = c.compress(str.cstring, str.len, compressed.cstring, compressed.len)
  check compressedLen > 0

  let decompressed = newString(256)
  var read, written: int
  let result = d.decompress(
    compressed.cstring, compressedLen,
    decompressed.cstring, decompressed.len,
    read, written
  )
  check result == Success
  check read == compressedLen
  check written == str.len
  check decompressed.startsWith(str)

test "ungzip both members":
  let compressed = readFile(dataDir & "/ab.gz")
  let d = newDecompressor()
  var read, written: int

  var member1 = newString(bufferSize)
  let result1 = d.decompress(
    compressed.cstring, compressed.len,
    member1.cstring, member1.len,
    read, written,
  )
  check result1 == Success
  check cast[BiggestInt](read) == getFileSize(dataDir & "/a.gz")
  check cast[BiggestInt](written) == getFileSize(dataDir & "/a.txt")
  member1.setLen(cast[Natural](written))
  check member1 == readFile(dataDir & "/a.txt")

  var member2 = newString(bufferSize)
  let result2 = d.decompress(
    unsafeAddr compressed[read], compressed.len,
    member2.cstring, member2.len,
    read, written,
  )
  check result2 == Success
  check cast[BiggestInt](read) == getFileSize(dataDir & "/b.gz")
  check cast[BiggestInt](written) == getFileSize(dataDir & "/b.txt")
  member2.setLen(cast[Natural](written))
  check member2 == readFile(dataDir & "/b.txt")

test "input buffer doesn't hold whole member":
  var compressed = readFile(dataDir & "/b.gz")
  compressed.setLen(compressed.len * 2 div 3)

  var decompressed = newString(bufferSize)
  let d = newDecompressor()
  var read, written: int
  let result = d.decompress(
    compressed.cstring, compressed.len,
    decompressed.cstring, decompressed.len,
    read, written,
  )

  check result == BadData

test "output buffer is not big enough":
  let compressed = readFile(dataDir & "/b.gz")

  var decompressed = newString(getFileSize(dataDir & "/b.txt") - 5)
  let d = newDecompressor()
  var read, written: int
  let result = d.decompress(
    compressed.cstring, compressed.len,
    decompressed.cstring, decompressed.len,
    read, written,
  )

  check result == InsufficientSpace

# TODO Test invalid gzip.

import std/streams
import std/strformat

iterator decompressGzipMembers(
  compressed: Stream,
  maxCompressedMemberLen: int = 2 * 1024 * 1024,
  maxDecompressedMemberLen: int = 8 * 1024 * 1024,
): tuple[decompressed: string, decompressedLen: int, posInCompressed: Slice[int]] =
  if maxCompressedMemberLen < 1 or maxDecompressedMemberLen < 1:
    raise newException(CatchableError, "Invalid max buffer len")

  var inBuffer = newString(min(2 * 1024 * 1024, maxCompressedMemberLen))
  var outBuffer = newString(min(8 * 1024 * 1024, maxDecompressedMemberLen))
  var eof = false
  var bytesInInBuffer = 0
  var pos = compressed.getPosition

  let decompressor = newDecompressor()

  while not eof or bytesInInBuffer > 0:
    # Fill input buffer.
    while not eof and bytesInInBuffer < inBuffer.len:
      let n = compressed.readDataStr(inBuffer, bytesInInBuffer .. inBuffer.len - 1)
      if n == 0:
        eof = true
      else:
        bytesInInBuffer += n

    # Empty buffer is not valid gzip member.
    if bytesInInBuffer > 0:
      var read, written: int
      let status = decompressor.decompress(
        inBuffer.cstring, bytesInInBuffer,
        outBuffer.cstring, outBuffer.len,
        read, written,
      )
      case status:
        of Success:
          yield (
            decompressed: outBuffer,
            decompressedLen: written.int,
            posInCompressed: pos .. pos + read.int - 1,
          )

          bytesInInBuffer -= read.int
          pos += read.int

          # Move unused input bytes to the beginning of input buffer.
          moveMem(
            inBuffer.cstring,
            cast[pointer](cast[int](inBuffer.cstring) + read),
            bytesInInBuffer
          )

        of InsufficientSpace:
          let n = min(2 * outBuffer.len, maxDecompressedMemberLen)
          if n > outBuffer.len:
            echo fmt"Increasing output buffer to {n} bytes"
            outBuffer.setLen(n)
          else:
            raise newException(CatchableError, fmt"Output buffer len {outBuffer.len} is too small")

        of BadData:
          # If we're not at the end of file it may help to enlarge
          # input buffer and load more compressed data.
          #
          # Note: When last call `readDataStr` reads remaining data from `compressed`
          # and fills `inBuffer` then `eof` is false even though we're at the end of file.
          # In this case member is corrupted but we don't detect it yet.
          # Instead we either enlarge `inBuffer` and detect corrupted member later,
          # or if enlarging fails we will raise exception stating two possible reasons
          # instead of saying that member is corrupted.
          if not eof:
            let n = min(2 * inBuffer.len, maxCompressedMemberLen)
            if n > inBuffer.len:
              echo fmt"Increasing input buffer to {n} bytes"
              inBuffer.setLen(n)
            else:
              raise newException(
                CatchableError,
                fmt"Input buffer len {inBuffer.len} is too small or member at {pos} is corrupted"
              )
          else:
            raise newException(CatchableError, fmt"Member at {pos} is corrupted")

import std/sequtils

test "iterate through all members":
  let stream = openFileStream(dataDir & "/ab.gz", fmRead)
  let positions = decompressGzipMembers(stream).toSeq().mapIt(it.posInCompressed)
  check positions == @[0..32, 33..79]

# This check helps to ensure that `Result` enum in Nim which has size `cint`
# has the same size as the original enum `libdeflate_result`.
{.emit: """
#include "libdeflate.h"
_Static_assert(sizeof(int) == sizeof(enum libdeflate_result));
""".}
