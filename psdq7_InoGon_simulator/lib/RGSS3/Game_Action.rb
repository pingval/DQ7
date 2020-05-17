class Game_Action
  attr_reader   :subject                  # 行動主体
  attr_reader   :item                     # スキル / アイテム
  attr_accessor :target_index             # 対象インデックス
  attr_accessor :targets

  def initialize(subject)
    @subject = subject
    clear
  end

  def clear
    @item = nil
    @targets = nil
  end

  def set_targets(*trgs)
    if !trgs.empty?
      return @targets = trgs
    end
    
    @targets = case item
    when :Guard; [subject]
    when :Herb; [friends_unit.random_target]
    when :Leaf; [friends_unit.random_dead_target || friends_unit.random_target]
    when :Boomerang, :SandStorm; opponents_unit.alive_members
    else
      [opponents_unit.random_physical_target]
      # [opponents_unit.alive_members[0]]
    end
  end

  def targets_valid?
    return false if @targets.nil?
    return false if @targets.empty?
    # p [@subject, item, @targets]
    return false if item != :Leaf && @targets.any?{|a| a.dead? }
    true
  end

  def set(item, *trgs)
    set_item(item)
    set_targets(*trgs)
  end

  def targets
    set_targets if !targets_valid?
    @targets
  end

  def friends_unit
    subject.friends_unit
  end

  def opponents_unit
    subject.opponents_unit
  end

  def set_enemy_action(action)
    if action
      set_skill(action)
    else
      clear
    end
  end

  def set_attack
    set_skill(:Attack)
    self
  end

  def set_guard
    set_skill(:Guard)
    self
  end

  def set_skill(skill)
    @item = skill
    self
  end

  def set_item(item)
    set_skill(item)
  end

  def attack?
    item == :attack
  end

  def prepare
    
  end

  def valid?
    subject.usable?(item)
  end

  def speed
    case item
    when :Guard, :Ironize, :HolyAura; 10**9
    else 0
    end
  end

  def to_s
    tbl = {
      Attack: "攻撃",
      Guard: "防御",
      Watch: "様子を見る",
      Slash: "斬りつける",
      Tail: "爪できりさく",
      BrutalHit25: "痛恨の一撃(攻撃×2.5)",
      Claw: "尻尾",
      Fury: "武器を振り回す",
      SandStorm: "砂煙",
      Boomerang: "ブーメラン",
      Herb: "薬草",
      Leaf: "世界樹の葉",
    }
    t = tbl[item]
    if subject.actor? && item == :Herb && subject.has?(:Rock)
      t = "奇跡の石"
    end
    case item
    when :Guard, :Watch
      "%s: %s"%[subject.name, t]
    else
      trgs = targets.map{|target| target.name } * ", "
      "%s: %s to %s"%[subject.name, t, trgs]
    end
  end
end

