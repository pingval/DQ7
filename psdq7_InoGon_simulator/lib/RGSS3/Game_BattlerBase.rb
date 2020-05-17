class Game_BattlerBase
  attr_accessor :hp, :mp
  attr_accessor :mhp, :mmp, :atk, :def, :agi, :eva, :int
  attr_reader :state_counts

  def initialize(**rest)
    @hp = @mp = 0
    clear_states
  end

  def dmg
    @mhp - @hp
  end

  def clear_states
    @state_counts = {}
  end

  def erase_state(state)
    @state_counts.delete state
  end

  def state?(state)
    # @state_counts[state] > 0
    @state_counts[state]
  end
 
  def state_rate(state)
    1
  end

  def guard?
    state?(:Guard)
  end

  def blind?
    state?(:Blind)
  end

  def recover_all(revive = true)
    clear_states
    if revive || @hp > 0
      @hp = mhp
      @mp = mmp
    end
  end

  def hp_rate
    @hp.to_f / mhp
  end

  def mp_rate
    mmp > 0 ? @mp.to_f / mmp : 0
  end

  def dead?
    @hp < 1
  end

  def alive?
    !dead?
  end

  def inputable?
    alive? && !state?(:confusion)
  end

  def actor?
    return false
  end

  def enemy?
    return false
  end

  def npc?
    return false
  end

  def usable?(item)
    true
  end
  
  def skil_cost_payable?(skill)
    true
    # mp >= skill.mp_cost
  end

  def pay_skill_cost(skill)
    # self.mp -= skill.mp_cost
  end
end
