class Game_Enemy < Game_Battler
  attr_reader   :index                    # 敵グループ内インデックス

  def initialize(index: 0, name: "", status: {}, action: {})
    super
    @index = index
    @name = name
    keys = %i[mhp mmp atk def agi int eva]
    instance_variables = %i[@mhp @mmp @atk @def @agi @int @eva]
    keys.zip(instance_variables).each{|key, ins|
      stat_val = status[key] || 0
      
      instance_variable_set(ins, stat_val)
    }
    @action_list = action[:list]
    @action_times = action[:times]
    @action_pattern = action[:pattern]

    @hp = mhp
    @mp = mmp
  end

  def enemy?
    return true
  end

  def state_rate(state)
    0
  end

  def friends_unit
    $game_troop
  end

  def opponents_unit
    $game_party
  end

  def action_valid?(action)
    true
  end

  def select_enemy_action
    count = @action_count
    idx = case @action_pattern
    when :prob1, :prob2, :prob3, :prob4
      tbl = {
        prob1: [5526, 5397, 5526, 5525, 5397, 5397],
        prob2: [8739, 7453, 6168, 4883, 3469, 2056],
        prob3: [25701, 5140, 1028, 514, 385, 0],
        prob4: [8960, 8960, 8960, 2048, 2048, 1792],
      }
      tbl[@action_pattern].weighted_sample
    when :rot1, :rot4
      count % 6
    when :rot2
      count % 3 * 2 + rand(0..1)
    when :rot3
      count.even? ? 0 : rand(1..5)
    end

    action = @action_list[idx]
    if action_valid?(action)
      action
    else
      select_enemy_action
    end
  end

  def make_action_times
    case @action_times
    when 1; 1
    when 1.5; rand(1..2)
    when 2; 2
    end
  end

  def make_actions
    super
    return if @actions.empty?
    @actions.each do |action|
      action.set_enemy_action(select_enemy_action)
    end
  end
end
