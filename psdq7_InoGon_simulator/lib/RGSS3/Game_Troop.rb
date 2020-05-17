class Game_Troop < Game_Unit
  attr_reader   :turn_count               # ターン数
  attr_reader   :troop

  def initialize(*enemies)
    super
    clear
    @enemies = enemies
  end

  def members
    @enemies
  end

  def clear
    @enemies = []
    @turn_count = 0
  end

  def increase_turn
    @turn_count += 1
  end
end
