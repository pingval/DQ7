Lib_Dir = "./lib"
RGSS3_Dir = "./lib/RGSS3"
RGSS3_Require_Order = %w[
  Game_Action
  Game_ActionResult
  Game_BattlerBase
  Game_Battler
  Game_Actor
  Game_Enemy
  Game_NPC
  Game_Unit
  Game_Party
  Game_Troop
  BattlerManager
  Scene_Battle
]

RGSS3_Require_Order.each{|basename|
  rb = File.join(RGSS3_Dir, basename)
  require rb
}
Dir.glob(File.join(Lib_Dir, "*.rb")){|rb|
  require rb
}

# ログ
def log(str, timing)
  tbl = %i[none battle turn action result]
  idx = tbl.index(timing)
  return if tbl.index($option[:log_timing]) < idx
  pre = idx < 1 ? "" : "  " * (idx - 1)
  puts pre + str
end

# 結果
$result = {
  both: {},
  win: {},
  lose: {},
}

# 結果を集計
def tally_result(*keys)
  keys.each{|key|
    h = $result[key]
    h[:turn_count] ||= 0
    h[:turn_count] += $game_troop.turn_count
    party_leaf_count = 0
    h[:leaf_distribution] ||= {}
    $game_party.actors.each_with_index{|actor, i|
      h[:party] ||= {}
      h[:party][i] ||= Hash.new 0
      h[:party][i][:dead] += actor.dead? ? 1 : 0
      h[:party][i][:hp] += actor.hp
      h[:party][i][:herb_count] += actor.first_inventory[:Herb] - actor.inventory[:Herb]
      leaf_count = actor.first_inventory[:Leaf] - actor.inventory[:Leaf]
      party_leaf_count += leaf_count
      h[:party][i][:leaf_count] += leaf_count
    }
    h[:leaf_distribution][party_leaf_count] ||= 0
    h[:leaf_distribution][party_leaf_count] += 1
    $game_troop.members.each_with_index{|enemy, i|
      h[:troop] ||= {}
      h[:troop][i] ||= Hash.new 0
      h[:troop][i][:dead] += enemy.dead? ? 1 : 0
      h[:troop][i][:hp] += enemy.hp
    }
  }
end

# 結果を出力
def puts_result(key, total)
  label_width = 30
  def h(depth, s)
    puts ("  " * depth) + s
  end

  h = $result[key]
  h(0, "* " + key.to_s.capitalize)
  h(1, "Ave. turn count: %.2f" % [h[:turn_count].fdiv(total)])
  h(1, "Party:")
  h(2, (" " * label_width) + h[:party].keys.map{|i|
    "No.#{i + 1}".rjust(10)
  } * "")
  tbl = {
    dead: "Death rate on battle end",
    hp: "Ave. HP on battle end",
    herb_count: "Ave. Herb count",
    leaf_count: "Ave. Leaf count",
  }
  tbl.each{|key, label|
    h(2, label.ljust(label_width) + h[:party].size.times.map{|i|
      if key == :dead
        "%9.2f%%"%[h[:party][i][key].fdiv(total) * 100]
      else
        "%10.2f"%h[:party][i][key].fdiv(total)
      end
    } * "")
  }

  h(1, "Distribution of Leaf count:")
  leaf_distribution_sum = 0
  h[:leaf_distribution].sort.each{|leaf_count, n|
    h(2, "%5d%9.2f%%"%[leaf_count, n.fdiv(total) * 100])
    leaf_distribution_sum += leaf_count * n
  }
  h(2, "Ave. %10.2f"%[leaf_distribution_sum.fdiv(total)])

  h(1, "Troop:")
  h(2, (" " * label_width) + h[:troop].keys.map{|i|
    "No.#{i + 1}".rjust(10)
  } * "")
  tbl = {
    dead: "Death rate on battle end",
    hp: "Ave. HP on battle end",
  }
  tbl.each{|key, label|
    h(2, label.ljust(label_width) + h[:troop].size.times.map{|i|
      if key == :dead
        "%9.2f%%"%[h[:troop][i][key].fdiv(total) * 100]
      else
        "%10.2f"%h[:troop][i][key].fdiv(total)
      end
    } * "")
  }
end

def main
  win = 0
  # ログを出力するなら勝手にN=1に変更
  if $option[:log_timing] != :none
    $option[:N] = 1
  end
  $option[:N].times{
    $game_troop = troop_InoGon
    $game_party = $option[:party][seed_type: $option[:seed_type], mari_lv11: $option[:mari_lv11]]

    scene = Scene_Battle.new
    case scene.test
    when :victory
      tally_result(:win)
      win += 1
    when :defeat
      tally_result(:lose)
    end
    tally_result(:both)
  }

  # 結果
  return if $option[:N] == 1
  puts "N = #{$option[:N]}"
  puts "Maribel's Level = #{$option[:mari_lv11] ? 11 : 10}"
  puts
  puts "Win rate:\t%.2f%%" % [win.fdiv($option[:N]) * 100]
  puts_result(:win, win)
  puts
  puts_result(:lose, $option[:N] - win)
  puts
  puts_result(:both, $option[:N])
end

# if ARGV.size < 1
#   puts "Usage: #{File.basename(__FILE__, ".*")} party [N=100000]"
# end

# log_timing: none, battle, turn, action, result
$option = {
  N: 1000,
  log_timing: :turn,
  party: Party_Panda,
  mari_lv11: false,
  seed_type: :rand,
}

main()
