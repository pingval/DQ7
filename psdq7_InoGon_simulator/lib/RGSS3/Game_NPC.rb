class Game_NPC < Game_Enemy
  def initialize(**rest)
    super
    # NPCはみかわし判定1/64あり
    @eva = 1 - (1 - @eva) * (1 - 1r/64)
  end

  def state_rate(state)
    case state
    when :Blind; 217r/256
    else 1
    end
  end

  def enemy?
    return false
  end

  def npc?
    return true
  end

  def friends_unit
    $game_party
  end

  def opponents_unit
    $game_troop
  end
end
