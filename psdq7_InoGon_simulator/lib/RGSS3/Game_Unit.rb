class Game_Unit
  def initialize(*args)
  end

  def members
    return []
  end

  def alive_members
    members.select {|member| member.alive? }
  end

  def dead_members
    members.select {|member| member.dead? }
  end

  def movable_members
    members.select {|member| member.movable? }
  end

  def clear_actions
    members.each {|member| member.clear_actions }
  end

  def all_targets
    alive_members
  end

  def random_target
    alive_members.sample
  end

  def random_physical_target
    alive_members.sample
  end

  def random_dead_target
    dead_members.empty? ? nil : dead_members[rand(dead_members.size)]
  end

  def clear_results
    members.select {|member| member.result.clear }
  end

  def on_battle_start
    members.each {|member| member.on_battle_start }
  end

  def on_battle_end
    @in_battle = false
    members.each {|member| member.on_battle_end }
  end

  def make_actions
    members.each {|member| member.make_actions }
  end

  def all_dead?
    alive_members.empty?
  end

  def lowest_hp_member
    alive_members.min_by{|member| member.hp }
  end

  def to_s
    members.map(&:to_s) * " | "
  end
end
