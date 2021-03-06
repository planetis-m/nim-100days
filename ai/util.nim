# https://www.youtube.com/watch?v=M0Sx_M61ILU
import random, strformat

const
  maxHealingPotions = 3

type
  Player = object
    health: float32
    healingPotions: int

  Action = enum
    Attack, Heal, RunAway

proc initPlayer(): Player =
  result = Player(health: 1, healingPotions: maxHealingPotions)

# Considerations
proc healthWeight(p: Player): float32 =
  result = p.health

proc healingPotionsWeight(p: Player): float32 =
  result = p.healingPotions / maxHealingPotions

# Curve
proc boundedLinear(value: float32): float32 =
  result = max(1 - value, 0.5'f32)

proc inverse(value, factor, offset: float32): float32 =
  result = 1 / (value * factor + offset)

proc aboveZero(value: float32): float32 =
  result = if value > 0: 1 else: 0

proc equalsZero(value: float32): float32 =
  result = if value == 0: 1 else: 0

# Reasoner
proc attackWeight(enemy: Player): float32 =
  result = boundedLinear(enemy.healthWeight())
  echo &"Attack weight {result:.3}"

proc healWeight(p: Player): float32 =
  let healthWeight = inverse(p.healthWeight(), 10, 1)
  let healingPotionsWeight = aboveZero(p.healingPotionsWeight())
  result = healthWeight * healingPotionsWeight
  echo &"Health weight {healthWeight:.3} Healing Potions weight {healingPotionsWeight:.3} Heal weight {result:.3}"

proc runAwayWeight(p: Player): float32 =
  let healthWeight = inverse(p.healthWeight(), 10, 1)
  let healingPotionsWeight = equalsZero(p.healingPotionsWeight())
  result = healthWeight * healingPotionsWeight
  echo &"Health weight {healthWeight:.3} Healing Potions weight {healingPotionsWeight:.3} Run Away weight {result:.3}"

proc chooseAction(p, enemy: Player): Action =
  let actions = [
    (Attack, attackWeight(enemy)),
    (Heal, healWeight(p)),
    (RunAway, runAwayWeight(p))
  ]
  result = actions[0][0]
  var maxScore = actions[0][1]
  for i in 1 ..< actions.len:
    template a: untyped = actions[i]
    if a[1] > maxScore:
      result = a[0]
      maxScore = a[1]

proc main =
  randomize()
  var players = @[initPlayer(), initPlayer()]
  while true:
    echo &"Player 1: health: {players[0].health:.3} potions {players[0].healingPotions}"
    let action1 = chooseAction(players[0], players[1])
    echo "Player 1 action: ", action1
    case action1
    of Attack:
      players[1].health -= rand(0.2'f32..0.3'f32)
      if players[1].health <= 0:
        echo "Player 1 wins!"
        break
    of Heal:
      players[0].healingPotions.dec
      players[0].health += rand(0.2'f32..0.3'f32)
    of RunAway:
      echo "Player 1 ran away."
      break
    # Player 2
    echo &"Player 2: health: {players[1].health:.3} potions {players[1].healingPotions}"
    let action2 = chooseAction(players[1], players[0])
    echo "Player 2 action: ", action2
    case action2
    of Attack:
      players[0].health -= rand(0.2'f32..0.3'f32)
      if players[0].health <= 0:
        echo "Player 2 wins!"
        break
    of Heal:
      players[1].healingPotions.dec
      players[1].health += rand(0.2'f32..0.3'f32)
    of RunAway:
      echo "Player 2 ran away."
      break

main()
