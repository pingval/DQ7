# -*- encoding: utf-8 -*-
#
# 2019/01/24
# ・公開
# ・参考: https://ch.nicovideo.jp/kettamachine/blomaga/ar1512875

# メルビン: Lv26・船乗り・奇跡の剣・水の羽衣・ホワイトシールド・鉄兜・大地のアミュレット
# HP264, MP97, ATK176, DEF162, SPD64
# ※事前にスカラ1回掛けてある前提の計算

$option = {
  N: 100000,                    # 試行回数
  HP: 264,                      # メルビン初期HP
  orgo2_1_action: :fubuki,      # メルビンさざなみの剣使用ターンのオルゴ2-1の行動
  houi?: true,                  # かまいたちターンにメルビン法衣装備？
  shukufuku_on_kamaitachi_turn?: true, # かまいたちターンに祝福の杖使用あり？
}

# メルビンさざなみの剣使用ターンのオルゴ2-1の行動
def orgo2_1_action
  case $option[:orgo2_1_action]
  when :fubuki
    # 吹雪
    rand(120..140)
  when :shakunetsu
    # 灼熱
    rand(150..170) - 30 - 10
  when :attack
    # 打撃(スカラ1)
    # psdq7_atk.rb 330 162 -p1
    rand(97..111)
  else
    # 強打撃(スカラ1)
    # psdq7_atk.rb 330 162 -sf125 -p1
    rand(121..138)
  end
end

# 祝福の杖
def shukufuku
  rand(75..95)
end

# オルゴ2-1メルビン奇跡の剣回復
def kiseki
  # psdq7_atk.rb 176 200
  rand(35..41) / 4
end

# オルゴ2-2打撃(スカラ1)
def orgo2_2_attack
  # psdq7_atk.rb 330 162 -p1
  rand(97..111)
end

# オルゴ2-2かまいたち
def orgo2_2_kamaitachi
  # メルビンのバギ系耐性込み
  (160 * rand(217..294) / 256 - ($option[:houi?] ? 25 : 0)) * 179 / 256
end

# おてうさんの近似式(http://oteu.net/blog/archives/2169)で先攻率を求める
def calc_preemptive_rate_by_formula(a, b)
  a = [1, a].max
  b = [1, b].max
  if a > b * 2
    1.0
  elsif b > a * 2
    0.0
  elsif a >= b
    1.0 - ((2 * b - a) ** 2).to_f / (2 * a * b)
  else
    ((2 * a - b) ** 2).to_f / (2 * b * a)
  end
end

# オルゴ2-2ガボ先攻判定(Lv24・船乗り・早種11)
def gabo_initiative?
  rand > calc_preemptive_rate_by_formula(171, 135)
end

puts "試行回数: %d" % $option[:N]
puts "メルビン初期HP: %d(スカラ1)" % $option[:HP]
s = case $option[:orgo2_1_action]
  when :fubuki; "吹雪"
  when :shakunetsu; "灼熱"
  when :attack; "打撃"
  else "強打撃"
end
puts "メルビンさざなみの剣使用ターンのオルゴ2-1の行動: %s" % s
puts "オルゴ2-2かまいたちターンにメルビン法衣装備: %s" % [$option[:houi?] ? "Yes" : "No"]
puts "オルゴ2-2かまいたちターンに祝福の杖使用: %s" % [$option[:shukufuku_on_kamaitachi_turn?] ? "Yes" : "No"]

rate = $option[:N].times.count{
  hp = $option[:HP]
  # オルゴ2-1の行動
  (0 < hp -= orgo2_1_action) &&
  # 奇跡の剣回復
  (0 < hp += kiseki) &&
  # 祝福の杖＆オルゴ2-2打撃
  (gabo_initiative? ? (0 < hp += shukufuku) && (0 < hp -= orgo2_2_attack) : (0 < hp -= orgo2_2_attack) && (0 < hp += shukufuku)) &&
  # 祝福の杖＆オルゴ2-2かまいたち
  if $option[:shukufuku_on_kamaitachi_turn?]
    (gabo_initiative? ? (0 < hp += shukufuku) && (0 < hp -= orgo2_2_kamaitachi) : (0 < hp -= orgo2_2_kamaitachi))
  else
    (0 < hp -= orgo2_2_kamaitachi)
  end
}.fdiv($option[:N])
puts "オルゴ2-2かまいたちターン生存率: %.2f%%" % [rate * 100]
