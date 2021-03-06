# https://medium.com/adamedelwiess/operating-system-6-thread-part-2-reader-writer-problem-spurious-wakeups-and-deadlocks-6e28ab161002
import std/locks

type
  RwMonitor* = object
    readPhase: Cond
    writePhase: Cond
    L: Lock
    counter: int

proc initRwMonitor*(rw: var RwMonitor) =
  initCond rw.readPhase
  initCond rw.writePhase
  initLock rw.L
  rw.counter = 0

proc destroyRwMonitor*(rw: var RwMonitor) {.inline.} =
  deinitCond(rw.readPhase)
  deinitCond(rw.writePhase)
  deinitLock(rw.L)

proc beginRead*(rw: var RwMonitor) =
  acquire(rw.L)
  while rw.counter == -1:
    wait(rw.readPhase, rw.L)
  inc rw.counter
  release(rw.L)

proc beginWrite*(rw: var RwMonitor) =
  acquire(rw.L)
  while rw.counter != 0:
    wait(rw.writePhase, rw.L)
  rw.counter = -1
  release(rw.L)

proc endRead*(rw: var RwMonitor) =
  acquire(rw.L)
  dec rw.counter
  if rw.counter == 0:
    rw.writePhase.signal()
  release(rw.L)

proc endWrite*(rw: var RwMonitor) =
  acquire(rw.L)
  rw.counter = 0
  rw.readPhase.broadcast()
  rw.writePhase.signal()
  release(rw.L)

template readWith*(a: RwMonitor, body: untyped) =
  mixin beginRead, endRead
  beginRead(a)
  try:
    body
  finally:
    endRead(a)

template writeWith*(a: RwMonitor, body: untyped) =
  mixin beginWrite, endWrite
  beginWrite(a)
  try:
    body
  finally:
    endWrite(a)
