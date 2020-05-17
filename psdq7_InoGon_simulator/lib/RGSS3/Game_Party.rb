class Game_Party < Game_Unit
  def initialize(*members)
    super
    @members = members
  end

  def exists
    !@actors.empty?
  end

  def members
    @members
  end

  def all_members
    members
  end

  def actors
    members.select{|member| member.actor? }
  end

  def npcs
    members.select{|member| member.npc? }
  end

  def alive_actors
    actors.select {|member| member.alive? }
  end

  def alive_npcs
    npcs.select {|member| member.alive? }
  end

  def dead_actors
    actors.select {|member| member.dead? }
  end

  def dead_npcs
    npcs.select {|member| member.dead? }
  end

  def movable_actors
    actors.select {|member| member.movable? }
  end

  def movable_npcs
    npcs.select {|member| member.movable? }
  end

  def all_members
    members
  end

  def battle_members
    all_members
  end

  def max_battle_members
    return 5
  end

  def leader
    battle_members[0]
  end

  def highest_level
    lv = members.collect {|actor| actor.level }.max
  end

  def add_actor(actor)
    @members.push(actor) unless @members.include?(actor)
    actors, npcs = @members.partition{|member| member.actor? }
    @members = actors + npcs
  end

  def remove_actor(actor)
    @members.delete(actor)
  end

  def add_npc(npc)
    add_actor(npc)
  end

  def remove_npc(npc)
    remove_actor(npc)
  end

  def usable?(item)
    members.any? {|actor| actor.usable?(item) }
  end

  def inputable?
    members.any? {|actor| actor.inputable? }
  end

  # NPCが生きててもだめ
  def all_dead?
    actors.none?{|member| member.alive? }
  end

  def swap_order(index1, index2)
    @members[index1], @members[index2] = @members[index2], @members[index1]
  end

  def random_physical_target
    # 先頭 > NPC > 残り の優先順位
    mems = alive_members.sort_by.with_index{|member, i|
      if i == 0
        0
      elsif member.npc?
        i
      else
        1000 + i
      end
    }
    # p mems

    weighted_table = case mems.size
    when 1; [10]
    when 2; [6, 4]
    when 3; [5, 3, 2]
    when 4; [4, 3, 2, 1]
    when 5; [3, 3, 2, 2, 1]
    end
    idx = weighted_table.weighted_sample
    mems[idx]
  end

  def random_group_targets
    r = [alive_actors.size, alive_npcs.size].weighted_sample
    r == 0 ? alive_actors : alive_npcs
  end

  def set_actions
    raise
  end

  def make_actions
    super

    set_actions

    alive_actors.each{|actor|
      item = actor.current_action.item
      if (item == :Herb || item == :Leaf) && actor.inventory[item] < 1
        raise "%s doesn't have %s." % [actor.name, item]
      end
    }
  end

    def to_s
    members.map(&:to_s) * " | "
  end
end
