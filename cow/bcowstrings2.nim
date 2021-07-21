import cowstrings, sync/spsc_queue

const
  numIters = 200

var
  pong: Thread[void]
  q1: SpscQueue[String]
  q2: SpscQueue[String]

template pushLoop(tx, data: typed, body: untyped): untyped =
  while not tx.tryPush(data):
    body

template popLoop(rx, data: typed, body: untyped): untyped =
  while not rx.tryPop(data):
    body

proc pongFn {.thread.} =
  while true:
    var n: String
    popLoop(q1, n): cpuRelax()
    pushLoop(q2, n): cpuRelax()
    #sleep 20
    if n == toStr("0"): break
    assert n == toStr("1")

proc pingPong =
  q1 = newSpscQueue[String](50)
  q2 = newSpscQueue[String](50)
  createThread(pong, pongFn)
  for i in 1..numIters:
    pushLoop(q1, toStr("1")): cpuRelax()
    var n: String
    #sleep 10
    popLoop(q2, n): cpuRelax()
    assert n == toStr("1")
  pushLoop(q1, toStr("0")): cpuRelax()
  var n: String
  popLoop(q2, n): cpuRelax()
  assert n == toStr("0")
  pong.joinThread()

pingPong()
