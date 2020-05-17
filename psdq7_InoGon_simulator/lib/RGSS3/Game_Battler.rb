def calc_damage(atk:0, df:0, guard:0, charge:0, twin:false, killer:false, order:1, special:nil, rand_type: :rand, **kwrest)
  rnd = ->range {
    case rand_type
    when :min; range.min
    when :max; range.max
    when :ave, :med; (range.min + range.max) / 2.0
    else rand(range)
    end
  }
  
  guard_mul = [256, 128, 64, 25][guard] # 防御倍率

  # defに依存しない会心と痛恨は先に済ませる
  if [:crit, :brut].include?(special)
    case special
    when :crit # 会心
      r = (atk * rnd[243..268]/256).floor
    when :brut # 痛恨
      r = (atk * rnd[217..243]/256).floor
    end
    r = (r * guard_mul/256).floor
    return r
  end
  
  # 基本値
  base_d = ((atk - (df/2).floor)/2).floor
  
  if base_d <= 0
    # 式3
    r = rnd[0..1]
  elsif base_d <= (atk/16).floor
    # 式2
    r = rnd[0..(atk/16).floor]
  else
    # 式1
    rnd_min = base_d - (base_d/16).floor - 1
    rnd_max = base_d + (base_d/16).floor + 1
    r = rnd[rnd_min..rnd_max]
  end

  # バイキルト
  r = (r * 512/256).floor if twin && order == 1
  
  # 力ため
  if order == 1
    case charge
    when 1
      # r = (r * rnd(512..640)/256).floor
      r = rnd[(r * 512/256).floor..(r * 640/256).floor]
    when 2
      r = (r * 384/256).floor
    else
      # 0ならなにもしない
    end
  end

  # いろいろ
  case special
  when :brut25                  # 痛恨(攻×2.5)
    r = (r * 640/256).floor
  when :danc                    # 剣の舞
    # r = (r * rnd(153..204)/256).floor
    r = rnd[(r * 153/256).floor..(r * 204/256).floor]
  when :quad                    # 爆裂拳
    r = (r * 128/256).floor
  when :squall                  # 疾風突き
    r = (r * 204/256).floor
  when :dragon                  # ドラゴン斬り
    r = (r * 384/256).floor
  when :metal                   # メタル斬り
    r = (r * 384/256).floor + 1
  when :slash0                  # 火炎斬り(×)
    r = (r * 332/256).floor
  when :slash1                  # 火炎斬り(△)
    r = (r * 294/256).floor
  when :slash2                  # 火炎斬り(○)
    r = (r * 192/256).floor
  when :slash3                  # 火炎斬り(◎)
    r = (r * 76/256).floor
  when :f05                     # 弱打撃(×0.5)
    r = (r * 128/256).floor
  when :f075                    # 弱打撃(×0.75)
    r = (r * 192/256).floor
  when :f125                    # 強打撃(×1.25)
    r = (r * 320/256).floor
  when :f15                     # 強打撃(×1.5)
    r = (r * 384/256).floor
  when :moon                    # ムーンサルト(順番を対象の数とみなす)
    r = (r * 3 / (order + 1)).floor
  when :orbs, :hand             # 念じボール、叩きつける
    r = (r * 128/256).floor     # 固定ダメージはあとで
  else
    # グループ/全体攻撃
    order_tbl = [256, 204, 179, 128, 76, 51]
    idx = [order, order_tbl.size].min - 1
    r = (r * order_tbl[idx]/256).floor
  end

  # 特攻武器
  r = (r * 384/256).floor if killer
  
  # 防御
  r = (r * guard_mul/256).floor
  
  # 防御無視ダメージ
  case special
  when :orbs                    # 念じボール
    r += 67
  when :hand                    # 叩きつける
    r += 150
  end

  r
end

class Game_Battler < Game_BattlerBase
  attr_reader   :name
  attr_reader   :action_times             # 行動回数
  attr_reader   :actions                  # 戦闘行動（行動側）
  attr_reader   :speed                    # 行動速度
  attr_reader   :result                   # 行動結果（対象側）
  attr_reader   :action_count             # 行動した回数

  def initialize(**rest)
    @name = ""
    @actions = []
    @speed = 0
    @action_count = 0
    @result = Game_ActionResult.new(self)
    super
  end

  def clear_actions
    @actions.clear
  end

  def add_state(state)
    if state_addable?(state)
      add_new_state(state)
      @result.added_states.push(state).uniq!
    end
  end

  def state_addable?(state)
    return false if dead?
    # 砂煙は延長されないがマヌーサは延長される　がまあいいや
    case state
    when :TwinHits, :Blind; !@state_counts[state]
    else true
    end
  end

  def add_new_state(state)
    weighted_table = case state
    when :Blind
      # マヌーサ
      { 5 => 192, 6 => 200, 7 => 105, 8 => 15, }
    when :Sap
      # 守備力変化
      { 6 => 320, 7 => 144, 8 => 42, 9 => 6, }
    else
      { 1 => 512, }
    end
    count = weighted_table.weighted_sample
    @state_counts[state] = count
  end

  def remove_state(state)
    erase_state(state)
  end

  def die
    @hp = 0
    clear_states
  end
  
  def revive(full = true)
    @hp = full ? mhp : mhp / 2
  end

  def update_state_counts
    @state_counts.transform_values!{|count| count - 1 }
  end
  
  def remove_states_auto(timing)
    # 防御、アストロン、ノアの方舟
    on_turn_end_states = [:Guard, :Ironize, :HolyAura]
    case timing
    when :action
      @state_counts.reject!{|state, count| !on_turn_end_states.include?(state) && count < 1 }
    when :turn
      @state_counts.reject!{|state, count| on_turn_end_states.include?(state) }
    end
  end

  def remove_states_by_attack
  end

  def make_action_times
    1
  end

  def make_actions
    clear_actions
    return if dead?
    @actions = Array.new(make_action_times){ Game_Action.new(self) }
  end

  # こんな感じ？
  def make_speed
    base_speed_range = [1, agi].max * 32 .. [1, agi].max * 64
    @speed = rand(base_speed_range) + (@actions.map{|action| action.speed }.min || 0)
  end

  def current_action
    @actions[0]
  end

  def remove_current_action
    @actions.shift
    # ここで行動した回数に加算とか
    @action_count += 1
    update_state_counts
    remove_states_auto(:action)
  end

  def make_damage_value(user, item, index)
    value = case item
    when :Herb; dead? ? 0 : -rand(30..40)
    when :Leaf; dead? ? -@mhp : 0
    when :Attack; calc_damage(atk: user.atk, df: @def)
    when :Boomerang; calc_damage(atk: user.atk, df: @def, order: index + 1)
    when :BrutalHit25; calc_damage(atk: user.atk, df: @def, special: :brut25)
    when :Fury, :Tail, :Claw, :Slash; calc_damage(atk: user.atk, df: @def, special: :f125)
    else 0
    end
    value = calc_damage(atk: user.atk, df: @def, special: :crit) if @result.critical
    value = apply_guard(value)
    @result.make_damage(value.to_i, item)
  end

  def item_effect_apply(user, item)
    case item
    when :SandStorm
      add_state(:Blind) if rand < state_rate(:Blind)
    when :Guard, :Ironize, :HolyAura
      add_state(:Guard)
    end
  end

  # 大防御とか1/4はいいや
  def apply_guard(damage)
    damage / (damage > 0 && guard? ? 2 : 1)
  end

  def execute_damage(user)
    self.hp -= @result.hp_damage
    self.mp -= @result.mp_damage

    @hp = @hp.clamp(0, @mhp)
    @mp = @mp.clamp(0, @mmp)

    if dead?
      clear_states
    end
  end

  def use_item(item)
    pay_skill_cost(item)
  end
  
  def consume_item(user, item)
    if user.actor? && (item == :Leaf || item == :Herb)
      user.inventory[item] -= 1
    end
  end

  def item_hit(user, item)
    rate = 1
    case item
    when :Guard, :Leaf, :Herb, :Watch, :SandStorm;
    else
      rate *= 3r/8 if user.blind?
    end
    rate
  end
  
  def item_test(user, item)
    # アイテムを持っているか
    # if item == :Leaf
    #   p [user.name, user.inventory[item]]
    # end
    return false if user.actor? && (item == :Leaf || item == :Herb) && user.inventory[item] < 1

    return false if item == :Leaf && alive?
    return false if item != :Leaf && dead?
    return false if item == :Herb && @mhp == @hp
    true
  end
  
  # 砂煙はphysicalなことに注意
  def item_eva(user, item)
    case item
    when :Guard, :Leaf, :Herb, :Watch; 0
    else eva
    end
  end

  # ブーメランは0 カシムの「斬りつける」には会心判定なし
  def item_cri(user, item)
    if !user.enemy? && item == :Attack
      1r/64
    else
      0
    end
  end

  def item_apply(user, item, index)
    @result.clear
    @result.used = item_test(user, item)
    @result.missed = rand >= item_hit(user, item) 
    @result.evaded = !@result.missed && rand < item_eva(user, item)
    if @result.hit?
      @result.critical = (rand < item_cri(user, item))
      make_damage_value(user, item, index)
      execute_damage(user)
      item_effect_apply(user, item)
      consume_item(user, item)
    end
  end

  def opposite?(battler)
    enemy? != battler.enemy?
  end

  def on_battle_start
    @result.clear
    clear_actions
  end

  def on_battle_end
    @result.clear
  end

  def on_action_end
    @result.clear
  end

  def on_turn_end
    @result.clear
    remove_states_auto(:turn)
  end

  def to_s
    st = blind? ? "[暗#{@state_counts[:Blind]}]" : dead? ? "[死 ]" : "     "
    "%s%s%3d/%3d"%[st, @name, hp, mhp]
  end

  def set(*args)
    current_action.set(*args)
  end
end
