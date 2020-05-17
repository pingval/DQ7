class Game_ActionResult
  attr_accessor :used                     # 使用フラグ
  attr_accessor :missed                   # 命中失敗フラグ
  attr_accessor :evaded                   # 回避成功フラグ
  attr_accessor :critical                 # クリティカルフラグ
  attr_accessor :success                  # 成功フラグ
  attr_accessor :hp_damage                # HP ダメージ
  attr_accessor :mp_damage                # MP ダメージ
  attr_accessor :added_states             # 付加されたステート
  attr_accessor :removed_states           # 解除されたステート
  attr_accessor :added_buffs              # 付加された能力強化
  attr_accessor :added_debuffs            # 付加された能力弱体
  attr_accessor :removed_buffs            # 解除された強化／弱体

  def initialize(battler)
    @battler = battler
    clear
  end

  def clear
    clear_hit_flags
    clear_damage_values
    clear_status_effects
  end

  def clear_hit_flags
    @used = false
    @missed = false
    @evaded = false
    @critical = false
    @success = false
  end

  def clear_damage_values
    @hp_damage = 0
    @mp_damage = 0
  end

  def make_damage(value, item)
    @hp_damage = value
    @success = true if value != 0
  end

  def clear_status_effects
    @added_states = []
    @removed_states = []
    @added_buffs = []
    @added_debuffs = []
    @removed_buffs = []
  end

  def status_affected?
    !(@added_states.empty? && @removed_states.empty? &&
      @added_buffs.empty? && @added_debuffs.empty? && @removed_buffs.empty?)
  end

  def hit?
    @used && !@missed && !@evaded
  end

  def to_s
    if used
      if missed
        "missed to %s"%[@battler.name]
      elsif evaded
        "%s: evaded"%[@battler.name]
      elsif hp_damage != 0
        crit = @critical ? "(会心)" : ""
        "%s%s: HP%+d (%3d/%3d)" % [@battler.name, crit, -@hp_damage, @battler.hp, @battler.mhp]
      elsif status_affected? && added_states.include?(:Blind)
        tbl = {
          Blind: "暗"
        }
        st = added_states.map{|state|
          "[%s%d]"%[tbl[state], @battler.state_counts[state]]
        }*""
        "%s: +%s" % [@battler.name, st]
      end
    end
  end
end
