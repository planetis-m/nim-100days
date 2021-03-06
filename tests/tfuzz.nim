# https://llvm.org/docs/LibFuzzer.html

# --panics:on --gc:arc -d:useMalloc --cc:clang -t:"-fsanitize=fuzzer,address,undefined"
# -l:"-fsanitize=fuzzer,address,undefined" -d:nosignalhandler --nomain:on -d:danger -g

proc initialize(): cint {.exportc: "LLVMFuzzerInitialize".} =
  {.emit: "N_CDECL(void, NimMain)(void); NimMain();".}

proc fuzzMe(data: openarray[byte]): bool =
  result = data.len >= 3 and
    data[0].char == 'F' and
    data[1].char == 'U' and
    data[2].char == 'Z' and
    data[3].char == 'Z' # :‑<

proc testOneInput(data: openarray[byte]): cint {.exportc: "LLVMFuzzerTestOneInput".} =
  result = 0
  discard fuzzMe(data)
