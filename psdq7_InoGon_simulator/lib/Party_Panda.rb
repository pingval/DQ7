class Game_Party_Panda < Game_Party
  def set_actions
    a, b, c = actors

    case [a.alive?, b.alive?, c.alive?]
    when [true,  true,  true]
      # 3番目
      damaged_actor = alive_actors.min_by{|actor| -actor.dmg }
      if damaged_actor.dmg > 10
        c.set(:Herb, damaged_actor)
      # elsif !c.has?(:Leaf)
      #   c.set(:Herb, b)
      else
        c.set(:Herb, a)
      end
      # 2番目
      if b.dmg > 35
        b.set(:Guard)
      else
        _damaged_actor_hp = damaged_actor.hp
        begin
          # 一時的に回復して2人目の回復対象を選択
          damaged_actor.hp = (damaged_actor.hp + 35).clamp(0, damaged_actor.mhp)
          damaged_actor2 = alive_actors.min_by{|actor| -actor.dmg }
          if damaged_actor2.dmg > 20 && b.has?(:Herb)
            b.set(:Herb, damaged_actor2)
          else
            b.set(:Boomerang)
          end
        ensure
          damaged_actor.hp = _damaged_actor_hp
        end
      end
      # 1番目
      if a.dying?
        a.has?(:Herb) ? a.set(:Herb, a) : a.set(:Attack, a.opponents_unit.lowest_hp_member)
      else
        a.set(:Guard)
      end
      if b.dying?
        b.has?(:Herb) ? b.set(:Herb, b) : b.set(:Boomerang)
      end
      c.set(:Herb, c) if c.dying?
      # なるべく自分自身を回復するように
      if b.current_action.item == :Herb && c.current_action.item == :Herb
        if b.current_action.targets[0] == c || c.current_action.targets[0] == b
          b.current_action.targets[0], c.current_action.targets[0] = c.current_action.targets[0], b.current_action.targets[0]
        end
      end

    when [false, true,  true]
      if b.has?(:Leaf) && !b.danger?
        b.set(:Leaf, a)
        c.set(:Herb, b)
      elsif c.has?(:Leaf)
        b.set(:Guard)
        c.set(:Leaf, a)
      else
        damaged_actor = alive_actors.min_by{|actor| -actor.dmg }
        if damaged_actor.dmg > 30
          c.set(:Herb, damaged_actor)
        else
          c.set(:Herb, b)
        end

        if b.dmg > 35
          b.set(:Guard)
        else
          _damaged_actor_hp = damaged_actor.hp
          begin
            # 一時的に回復して2人目の回復対象を選択
            damaged_actor.hp = (damaged_actor.hp + 35).clamp(0, damaged_actor.mhp)
            damaged_actor2 = alive_actors.min_by{|actor| -actor.dmg }
            if damaged_actor2.dmg > 20 && b.has?(:Herb)
              b.set(:Herb, damaged_actor2)
            elsif damaged_actor2.safe?
              b.set(:Boomerang)
            else
              b.set(:Guard)
            end
          ensure
            damaged_actor.hp = _damaged_actor_hp
          end
        end
        if b.dying?
          b.has?(:Herb) ? b.set(:Herb, b) : b.set(:Boomerang)
        end
        c.set(:Herb, c) if c.dying?

        if b.current_action.item == :Herb && c.current_action.item == :Herb
          if b.current_action.targets[0] == c || c.current_action.targets[0] == b
            b.current_action.targets[0], c.current_action.targets[0] = c.current_action.targets[0], b.current_action.targets[0]
          end
        end
      end

    when [true,  false, true]
      if c.has?(:Leaf)
        c.set(:Leaf, b)
      elsif a.dmg > c.dmg
        c.set(:Herb, a)
      else
        c.set(:Herb, c)
      end
      if a.dying?
        a.has?(:Herb) ? a.set(:Herb, a) : a.set(:Attack, a.opponents_unit.lowest_hp_member)
      else
        a.set(:Guard)
      end
      a.set(:Herb, c) if c.dying? && a.has?(:Herb)

    when [true,  true,  false]
      if b.has?(:Leaf)
        b.set(:Leaf, c)
      elsif a.dmg < 10 && b.safe?
        b.set(:Boomerang)
      else
        b.set(:Guard)
      end
      if a.dying?
        a.has?(:Herb) ? a.set(:Herb, a) : a.set(:Attack, a.opponents_unit.lowest_hp_member)
      else
        a.set(:Guard)
      end
      if b.dying?
        b.has?(:Herb) ? b.set(:Herb, b) : b.set(:Boomerang)
      end

    when [false, false, true]
      c.set(:Guard)
      c.set(:Herb, c) if c.dying?

    when [false, true,  false]
      b.set(:Guard)
      if b.dying?
        b.has?(:Herb) ? b.set(:Herb, b) : b.set(:Boomerang)
      end

    when [true,  false, false]
      if a.dying?
        a.has?(:Herb) ? a.set(:Herb, a) : a.set(:Attack, a.opponents_unit.lowest_hp_member)
      else
        a.set(:Guard)
      end
    end
  end
end

def hero_Panda(seed_type: :rand)
  Game_Actor.new(
    name: "主",
    status: Actor_Status[:Hero_lv10],
    seed_type: seed_type,

    equipments: {
      atk: 26 + 1,
      def: 28 + 13 + 8,
      agi: 0,
      eva: 0,
    },
    seeds: { mhp: 2, mmp: 0, atk: 6, def: 2, agi: 0, },
    inventory: { Herb: 7, Leaf: 1 },
  )
end

def mari_Panda(seed_type: :rand, mari_lv11: false)
  Game_Actor.new(
    name: "マ",
    status: Actor_Status[mari_lv11 ? :Mari_lv11 : :Mari_lv10],
    seed_type: seed_type,

    equipments: {
      atk: 23,
      def: 28 + 15 + 15 + 5,
      agi: 0,
      eva: 1r/6,
    },
    seeds: { mhp: 2, mmp: 1, atk: 0, def: 3, agi: 0, },
    inventory: { Herb: 1.0/0, Leaf: 1 },
  )
end

def gabo_Panda(seed_type: :rand)
  Game_Actor.new(
    name: "ガ",
    status: Actor_Status[:Gabo_lv5],
    seed_type: seed_type,

    equipments: {
      atk: 21,
      def: 18 + 9 + 5,
      agi: 0,
      eva: 0,
    },
    seeds: { mhp: 0, mmp: 2, atk: 0, def: 0, agi: 4, },
    inventory: { Herb: 3, Leaf: 0 },
  )
end

Party_Panda = ->seed_type: :rand, mari_lv11: false{
  hero = hero_Panda(seed_type: seed_type)
  mari = mari_Panda(seed_type: seed_type, mari_lv11: mari_lv11)
  gabo = gabo_Panda(seed_type: seed_type)

  Game_Party_Panda.new(gabo, hero, mari, npc_Kasim)
}
