# -*- encoding: utf-8 -*-
# 2015/10/07
# ・公開
# ・http://web.archive.org/web/20070425160118/http://dqffstyle.nobody.jp/database/dq7-4damage.htm
# 　の計算式と少しの調査を元にして製作したため、あまり信頼できないかもしれない。計算順序とかわかんねー。

require "optparse"

# 引数ないならヘルプ表示
ARGV.push("--help") if ARGV.empty?

def eval_to_i(expr)
  begin
    [eval(expr).to_i, 0].max
  rescue
    0
  end
end

# 初期設定
option = {
  # atk, defは第1,2引数
  # atk: ARGV[0].to_i,            # 攻撃力
  # def: ARGV[1].to_i,            # 守備力
  atk: eval_to_i(ARGV[0]),      # 攻撃力
  df: eval_to_i(ARGV[1]),       # 守備力
  df_arr: [eval_to_i(ARGV[1])], # 守備力変化の様子
  spell_arr: [],                # 守備力変化呪文
  guard: 0,                     # 防御
  charge: 0,                    # 力ため
  twin: false,                  # バイキルト
  # element: false,               # 属性武器
  killer: false,                # 特攻武器
  order: 1,                     # 順番
  special: nil,                 # 特殊打撃
  number: 10000,                # 試行回数
  border: 0,                    # ボーダー
  quiet: false,                 # 分布を表示しない
}

spell_name_tbl = {
  upper: "スカラ",
  increase: "スクルト",
  sap: "ルカニ",
  defense: "ルカナン",
  pixy_sword: "妖精の剣",
}
spell_name_tbl.default = "×"

special_name_tbl = {
  crit:"会心",
  brut: "痛恨",
  brut25: "痛恨(攻×2.5)",
  danc: "剣の舞",
  quad: "爆裂拳",
  squall: "疾風突き",
  dragon: "ドラゴン斬り",
  metal: "メタル斬り",
  slash0: "火炎斬り(×)",
  slash1: "火炎斬り(△)",
  slash2: "火炎斬り(○)",
  slash3: "火炎斬り(◎)",
  f05: "弱打撃(×0.5)",
  f075: "弱打撃(×0.75)",
  f125: "強打撃(×1.25)",
  f15: "強打撃(×1.5)",
  moon: "ムーンサルト(順番を対象の数とみなす)",
  orbs: "念じボール",
  hand: "叩きつける",
}
special_name_tbl.default = "×"

# 守備力変化 守備力の配列を返すように変更
def apply_defspell(init_df, spl_a)
  spl_tbl = {
    upper: 0.5,                 # スカラ
    increase: 0.25,             # スクルト
    sap: -0.5,                  # ルカニ
    defense: -0.25,             # ルカナン
    pixy_sword: 0.5,            # 妖精の剣 ps2dq5とは異なりスカラとの違いはない
  }
  spl_a.map {|spl|
    mul = spl_tbl[spl]
    incr = (init_df * mul.abs).floor
    mul < 0 ? -incr : incr
  }.inject([init_df]) {|df_a, incr|
    # 常に 0 <= new_df <= init_df+200
    new_df = [0, [df_a.last + incr, init_df + 200].min].max
    df_a + [new_df]
  }
end

OptionParser.new {|opt|
  opt.banner = "Usage: #{File.basename(__FILE__, ".*")} atk def [options]"
  opt.version = "2015/10/07"
  
  # opt.on("-a", "--attack NUMBER", /\A\d+\Z/, "攻撃力") {|v| option[:atk] = v.to_i }
  # opt.on("-d", "--defense NUMBER", /\A\d+\Z/, "守備力") {|v| option[:df] = v.to_i }
  opt.on("-p", "--spell (1..4)+", /\A[1-4]+\Z/,
         "1\tスカラor妖精の剣", "2\tスクルト", "3\tルカニ", "4\tルカナン") {|v|
    spl_sym_tbl = [:upper, :increase, :sap, :defense, :pixy_sword]
    spl_a = v.split("").map{|c| spl_sym_tbl[c.to_i-1] }
    option[:spell_arr] = spl_a
    option[:df_arr] = apply_defspell(option[:df], spl_a)
    option[:df] = option[:df_arr].last
  }
  opt.on("-g", "--guard [1..3]", %w[1 2 3],
  "1or省略\t防御", "2\t防御(1/4タイプ)", "3\t大防御") {|v| option[:guard] = v.nil? ? 1 : v.to_i }
  opt.on("-c", "--charge [1..2]", %w[1 2], "1or省略\t力ため(強)", "2\t力ため(弱・敵専用)") {|v| option[:charge] = v.nil? ? 1 : v.to_i }
  opt.on("-t", "--twin", "バイキルト") {|v| option[:twin] = v }
  opt.on("-k", "--killer", "特攻武器((ドラゴン|ゾンビ)キラー)") {|v| option[:killer] = v }
  opt.on("-o", "--order NUMBER", /\A\d+\Z/, "順番(グループ/全体攻撃武器用)") {|v| option[:order] = v.to_i }
  opt.on("-s", "--special TYPE", /\A\w+\Z/,
  *special_name_tbl.map{|k, v| "#{k}\t#{v}"} ) {|v| option[:special] = v.intern }
  opt.on("-n", "--number NUMBER", /\A\d+\Z/, "試行回数") {|v| option[:number] = v.to_i }
  opt.on("-b", "--border NUMBER", /\A\d+\Z/, "ボーダー") {|v| option[:border] = v.to_i }
  opt.on("-q", "--quiet", "分布を表示しない") {|v| option[:quiet] = v }
  opt.on_tail(<<__TAIL__
e.g.
・イノップ(atk90)からのマリベル(def78)への痛恨(攻×2.5)：
    #{File.basename(__FILE__, ".*")} 90 78 -sbrut25
・アイラ(atk249)のオルゴ2-1(def200・ギラ耐性×)へのバイキルト気合火炎斬り：
    #{File.basename(__FILE__, ".*")} 249 200 -sslash0 -t -c
・アイラ(atk258)のメタルスライム(def512)への剣の舞、
　及び与ダメが4以上(確殺)になる確率：
    #{File.basename(__FILE__, ".*")} 258 512 -sdanc -b4
・メルビン(def612)にスクルトを入れた時の神さま(atk382)からの被ダメ：
    #{File.basename(__FILE__, ".*")} 382 612 -p2
__TAIL__
  )
  opt.permute!(ARGV)
}
# p ARGV
# p option


# それぞれの式に対応する守備力の範囲 [式1, 式2, 式3]　泥臭い・・・
def def_ranges(atk)
  # 式の種類を返す
  atk = atk.floor
  def formula(atk, df)
    base_d = ((atk - (df/2).floor)/2).floor
    if base_d <= 0
      3
    elsif base_d <= (atk/16).floor # 式1と2の境界はここのはず
      2
    else
      1
    end
  end
  
  r = [nil] * 3
  (0..1024).each {|df|
    case formula(atk, df)
    when 1
      r[0] = 0..df              # 式1
    when 2
      r[1] = (r[0].last+1)..df  # 式2
    when 3
      r[2] = df..1.0/0          # 式3
      break
    end
  }
  r
end

# 打撃ダメージ計算
def calc_damage(atk:0, df:0, guard:0, charge:0, twin:false, killer:false, order:1, special:nil, **kwrest)
  guard_mul = [256, 128, 64, 25][guard] # 防御倍率

  # defに依存しない会心と痛恨は先に済ませる
  if [:crit, :brut].include?(special)
    case special
    when :crit # 会心
      r = (atk * rand(243..268)/256).floor
    when :brut # 痛恨
      r = (atk * rand(217..243)/256).floor
    end
    r = (r * guard_mul/256).floor
    return r
  end
  
  # 基本値
  base_d = ((atk - (df/2).floor)/2).floor
  
  if base_d <= 0
    # 式3
    r = rand(0..1)
  elsif base_d <= (atk/16).floor
    # 式2
    r = rand(0..(atk/16).floor)
  else
    # 式1
    rnd_min = base_d - (base_d/16).floor - 1
    rnd_max = base_d + (base_d/16).floor + 1
    r = rand(rnd_min..rnd_max)
  end

  # バイキルト
  r = (r * 512/256).floor if twin && order == 1
  
  # 力ため
  if order == 1
    case charge
    when 1
      # r = (r * rand(512..640)/256).floor
      r = rand((r * 512/256).floor..(r * 640/256).floor)
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
    # r = (r * rand(153..204)/256).floor
    r = rand((r * 153/256).floor..(r * 204/256).floor)
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

# 適用される式にあたる守備力範囲を強調
def_range_a = def_ranges(option[:atk]).map {|range|
  if range.is_a?(Range) && range.include?(option[:df])
    [range]
  else
    range
  end
}

print <<__HEADER__
攻撃力\t#{option[:atk]}
守備力\t#{option[:df_arr].join("→")}
守呪文\t[#{option[:spell_arr].map{|k| spell_name_tbl[k]}.join(", ")}]
守範囲\t#{def_range_a}
基本d\t#{((option[:atk]-(option[:df]/2).floor)/2).floor}
防御\t#{%w[× 通常 1/4タイプ 大防御][option[:guard]]}
力ため\t#{%w[× 強 弱][option[:charge]]}
バイキ\t#{option[:twin] ? "○" : "×"}
特攻\t#{option[:killer] ? "○" : "×"}
順番\t#{option[:order]}
特殊\t#{special_name_tbl[option[:special]]}
試行\t#{option[:number]}回

__HEADER__

arr = Array.new
option[:number].times {
  dmg = calc_damage(option)
  arr[dmg] ||= 0
  arr[dmg] += 1
}

sum = 0
above_border_count = 0
min, max = nil, nil
arr.each_with_index {|cnt, dmg|
  next if cnt.nil?
  puts "%d\t%.2f%%" % [dmg, cnt.to_f/option[:number]*100] if !option[:quiet]
  sum += dmg * cnt
  min ||= dmg
  max = dmg
  above_border_count += cnt if dmg >= option[:border]
}
ave = sum.to_f / option[:number]
puts "平均\t#{ave}"
if [:danc, :quad].include?(option[:special])
  puts "×4\t#{ave*4}"
  if option[:charge] == 0 && !option[:twin]
    puts "バイキ\t#{ave*5}"     # 力ためでもバイキルトでもなければ表示
  end
end
puts "範囲\t#{min..max}"
puts "%d以上\t%.2f%%" % [option[:border], above_border_count.to_f / option[:number] * 100] if option[:border] > 0

# 舞＆爆裂拳専用
sum_a = [0]*5
if option[:border] > 0 && [:danc, :quad].include?(option[:special])
  opt = option.dup
  opt[:charge] = 0
  opt[:twin] = false
  
  option[:number].times {
    dmg_a = Array.new(4){calc_damage(opt)}.inject([0]){|r, dmg|
      r + [r.last + dmg]
    }.each_with_index{|dmg, i|
      sum_a[i] += 1 if dmg >= option[:border]
    }
  }
  
  5.times {|i|
    next if i == 0
    puts "%d回：%d以上\t%.2f%%" % [i, option[:border], sum_a[i].to_f / option[:number] * 100]
  }
end
