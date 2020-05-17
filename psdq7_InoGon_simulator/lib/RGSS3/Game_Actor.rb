class Game_Actor < Game_Battler
  attr_reader   :inventory
  attr_reader   :first_inventory

  def seed_value(stat, n, seed_type = :rand)
    range = case stat
    when :mhp; 3..4
    when :mmp; 3..5
    when :int; 1..3
    else 1..2
    end
    
    res = case seed_type
    when :min; range.min * n
    when :max; range.max * n
    when :ave, :med; (range.min * n + range.max * n) / 2
    else n.times.map{ rand(range) }.sum
    end
  end

  def initialize(name: "", status: {}, equipments: {}, seeds: {}, inventory: {}, seed_type: :rand)
    super
    @name = name
    keys = %i[mhp mmp atk def agi]
    instance_variables = %i[@mhp @mmp @atk @def @agi]
    keys.zip(instance_variables).each{|key, ins|
      stat_val = status[key] || 0
      equipment_val = equipments[key] || 0
      seed_val = seed_value(key, (seeds[key] || 0), seed_type)
      val = stat_val + equipment_val + seed_val
      
      instance_variable_set(ins, val)
    }
    # みかわし率はデフォルトで1/64
    @eva = [status[:eva], equipments[:eva]].inject(1r/64){|r, eva|
      1 - (1 - r) * (1 - (eva || 0))
    }
    @inventory = inventory.dup || {}
    @inventory.default = 0
    @first_inventory = @inventory.dup

    @memo_damage = {}

    recover_all
  end

  def state_rate(state)
    case state
    when :Blind; 128r/256
    else 1
    end
  end

  def actor?
    return true
  end

  def friends_unit
    $game_party
  end

  def opponents_unit
    $game_troop
  end

  def index
    $game_party.members.index(self)
  end

  def has?(item)
    case item
    when :Rock; inventory[:Herb] > 100
    else inventory[item] > 0
    end
  end

  def memo(subject, skill, rand_type)
    atk = case subject
    when :Inopp; 90
    when :Gonz; 79
    end
    special = case skill
    when :Attack; nil
    when :Fury; :f125
    when :BrutalHit25; :brut25
    end
    @memo_damage[[subject, skill, rand_type]] ||= calc_damage(atk: atk, df: @def, special: special, rand_type: rand_type)
  end
  
  def ino_attack_max
    memo(:Inopp, :Attack, :max)
  end
  
  def ino_attack_min
    memo(:Inopp, :Attack, :min)
  end
  
  def ino_attack_med
    memo(:Inopp, :Attack, :med)
  end
  
  def ino_fury_max
    memo(:Inopp, :Fury, :max)
  end
  
  def ino_fury_min
    memo(:Inopp, :Fury, :min)
  end
  
  def ino_fury_med
    memo(:Inopp, :Fury, :med)
  end
  
  def ino_brut_max
    memo(:Inopp, :BrutalHit25, :max)
  end
  
  def ino_brut_min
    memo(:Inopp, :BrutalHit25, :min)
  end
  
  def ino_brut_med
    memo(:Inopp, :BrutalHit25, :med)
  end

  def gon_attack_max
    memo(:Gonz, :Attack, :max)
  end
  
  def gon_attack_min
    memo(:Gonz, :Attack, :min)
  end
  
  def gon_attack_med
    memo(:Gonz, :Attack, :med)
  end
  
  def gon_fury_max
    memo(:Gonz, :Fury, :max)
  end
  
  def gon_fury_min
    memo(:Gonz, :Fury, :min)
  end
  
  def gon_fury_med
    memo(:Gonz, :Fury, :med)
  end
  
  def gon_brut_max
    memo(:Gonz, :BrutalHit25, :max)
  end
  
  def gon_brut_min
    memo(:Gonz, :BrutalHit25, :min)
  end
  
  def gon_brut_med
    memo(:Gonz, :BrutalHit25, :med)
  end

  def current_attack_max
    opponents_unit.members[0].alive? ? ino_attack_max : gon_attack_max
  end
  
  def current_attack_min
    opponents_unit.members[0].alive? ? ino_attack_min : gon_attack_min
  end
  
  def current_attack_med
    opponents_unit.members[0].alive? ? ino_attack_med : gon_attack_med
  end
  
  def current_fury_max
    opponents_unit.members[0].alive? ? ino_fury_max : gon_fury_max
  end
  
  def current_fury_min
    opponents_unit.members[0].alive? ? ino_fury_min : gon_fury_min
  end
  
  def current_fury_med
    opponents_unit.members[0].alive? ? ino_fury_med : gon_fury_med
  end
  
  def current_brut_max
    opponents_unit.members[0].alive? ? ino_brut_max : gon_brut_max
  end
  
  def current_brut_min
    opponents_unit.members[0].alive? ? ino_brut_min : gon_brut_min
  end
  
  def current_brut_med
    opponents_unit.members[0].alive? ? ino_brut_med : gon_brut_med
  end

  # ゴンズの攻撃の最低乱数ではなく、イノップの攻撃(≒ゴンズの強打撃)の最低乱数にする？？
  # 攻撃されたら防御しても死ぬ
  def dying?
    # hp <= gon_attack_min / 2
    # hp <= ino_attack_min / 2
    hp <= current_attack_min / 2
  end

  # 攻撃されたら防御しないと死ぬ
  def danger?
    # hp <= gon_attack_min / 2
    # hp <= ino_attack_min
    hp <= current_attack_min
  end

  # HPまんたん
  def safe?
    hp == mhp
  end
end
