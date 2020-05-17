module BattleManager
  def self.setup
    init_members
  end

  def self.init_members
    @phase = :init              # 戦闘進行フェーズ
    @action_battlers = []       # 行動順序リスト
  end

  def self.in_turn?
    @phase == :turn
  end

  def self.turn_end?
    @phase == :turn_end
  end

  def self.battle_start
    $game_party.on_battle_start
    $game_troop.on_battle_start
  end

  def self.judge_win_loss
    if @phase
      # NPCが生きてても死ぬ
      return process_defeat  if $game_party.all_dead?
      return process_victory if $game_troop.all_dead?
    end
    return false
  end

  def self.process_victory
    battle_end(:victory)
  end

  def self.process_defeat
    battle_end(:defeat)
  end

  def self.battle_end(result)
    @phase = nil
    $game_party.on_battle_end
    $game_troop.on_battle_end
    log("%-7s"%result + $game_troop.to_s + " | " + $game_party.to_s, :battle)
    result
  end

  def self.input_start
    if @phase != :input
      @phase = :input
      $game_party.make_actions
      $game_troop.make_actions
    end
  end

  def self.turn_start
    @phase = :turn
    $game_troop.increase_turn
    log("%2dT: "%$game_troop.turn_count + $game_troop.to_s + " | " + $game_party.to_s, :turn)
    make_action_orders
  end

  def self.turn_end
    @phase = :turn_end
  end

  def self.make_action_orders
    @action_battlers = []
    @action_battlers += $game_party.members
    @action_battlers += $game_troop.members
    @action_battlers.each {|battler| battler.make_speed }
    # 順序を保存
    @action_battlers.sort_by!.with_index{|a, i| [-a.speed, i] }
  end

  def self.next_subject
    loop do
      battler = @action_battlers.shift
      return nil unless battler
      next unless battler.index && battler.alive?
      return battler
    end
  end
end
