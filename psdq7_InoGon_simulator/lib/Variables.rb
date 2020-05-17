class Array
  def weighted_sample(n = 1)
    sum = self.sum
    return [] if sum < 1
    res = n.times.map{
      r = rand(sum)
      self.each_with_index{|weight, index|
        break index if r < weight
        r -= weight
      }
    }
    n == 1 ? res[0] : res
  end
end

class Hash
  def weighted_sample(n = 1)
    sum = self.values.sum
    return [] if sum < 1
    res = n.times.map{
      r = rand(sum)
      self.each{|key, weight|
        break key if r < weight
        r -= weight
      }
    }
    n == 1 ? res[0] : res
  end
end

Actor_Status = {
  Hero_lv10: { mhp: 74, mmp: 29, atk: 28, def: 11, agi: 18, eva: 1r/64, },
  Mari_lv10: { mhp: 50, mmp: 35, atk: 13, def: 10, agi: 30, eva: 1r/64, },
  Mari_lv11: { mhp: 60, mmp: 41, atk: 14, def: 11, agi: 33, eva: 1r/64, },
  Gabo_lv5: { mhp: 59, mmp: 0, atk: 26, def: 13, agi: 38, eva: 1r/64, },
}

def enemy_Inopp
  Game_Enemy.new(
    index: 0,
    name: "イノ",
    status: { mhp: 440, mmp: 0, atk: 90, def: 38, agi: 73, int: 0, eva: 0, },
    action: {
      list: %i[Attack Fury Attack BrutalHit25 SandStorm Attack],
      times: 1,
      pattern: :prob2,
    }
  )
end

def enemy_Gonz
  Game_Enemy.new(
    index: 1,
    name: "ゴン",
    status: { mhp: 400, mmp: 0, atk: 79, def: 35, agi: 64, int: 0, eva: 1r/64, },
    action: {
      list: %i[Attack Tail Attack BrutalHit25 Claw Tail],
      times: 1,
      pattern: :prob2,
    }
  )
end

def troop_InoGon
  Game_Troop.new(enemy_Inopp, enemy_Gonz)
end

def npc_Kasim
  Game_NPC.new(
    index: 3,
    name: "カシム",
    status: { mhp: 65000, mmp: 0, atk: 73, def: 40, agi: 55, int: 2, eva: 0, },
    action: {
      list: %i[Attack Watch Slash Attack Slash Watch],
      times: 1,
      pattern: :rot1,
    }
  )
end
