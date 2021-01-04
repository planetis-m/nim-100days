import macros, strutils, fusion/astdsl, std/enumerate

macro runCommand(cmdName: untyped,
    definitions: varargs[untyped]): untyped =
  let
    docarrayName = ident"docstrings" # injected
    enumName = genSym(nskType, "CmdKind")
    enumDef = buildAst(typeSection):
      typeDef:
        enumName
        empty()
        enumTy:
          empty()
          for n in definitions:
            if n.kind == nnkOfBranch:
              expectKind(n[0], nnkPar)
              enumFieldDef(genSym(nskEnumField, "ck"), n[0][0])
    docstrings = buildAst(constSection):
      constDef:
        docarrayName
        bracketExpr:
          bindSym"array"
          enumName
          bindSym"string"
        bracket:
          for i, n in enumerate(definitions):
            if n.kind == nnkOfBranch:
              expectLen(n[0], 2)
              exprColonExpr(enumDef[0][2][i+1][0], n[0][1])
    caseSwitch = buildAst(caseStmt(cmdName)):
      for i, n in enumerate(definitions):
        if n.kind == nnkOfBranch:
          ofBranch(enumDef[0][2][i+1][1]):
            n[1]
        else:
          expectKind(n, nnkElse)
          `else`(n[0])
  result = newStmtList(enumDef, docstrings, caseSwitch)
  when defined(debugRpn): echo result.repr

proc main =
  # First create a simple "stack" implementation
  var stack: seq[float]

  template push(stack, value) = stack.add(value)
  template execute(stack, operation) =
    # Convenience template to execute an operation over two operands from the stack
    let
      a {.inject.} = stack.pop
      b {.inject.} = stack.pop
    stack.add(operation)

  # Program main loop, read input from stdin, run our template to parse the
  # command and run the corresponding operation. if that fails try to push it as
  # a number. Print out our "stack" for every iteration of the loop
  while true:
    for command in stdin.readLine.split(" "):
      # Then define all our commands using our macro
      runCommand(command):
      of ("+", "Adds two numbers"):
        stack.execute(a + b)
      of ("-", "Subtract two numbers"):
        stack.execute(b - a)
      of ("*", "Multiplies two numbers"):
        stack.execute(a * b)
      of ("/", "Divides two numbers"):
        stack.execute(b / a)
      of ("pop", "Pops a number off the stack"):
        discard stack.pop
      of ("swap", "Swaps the two bottom elements on the stack"):
        swap(stack[^1], stack[^2])
      of ("rot", "Rotates the stack one level"):
        stack.insert(stack.pop, 0)
      of ("help", "Lists all the commands with documentation"):
        echo "Commands:"
        for c, doc in docstrings.pairs:
          echo "  ", c, "\t", doc
      of ("exit", "Exits the program"):
        quit(QuitSuccess)
      else:
        stack.push parseFloat(command)

main()
