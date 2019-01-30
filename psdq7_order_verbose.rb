# -*- encoding: utf-8 -*-
# 2016/01/22
# ・公開

if ARGV.size < 1
  puts "Usage: #{File.basename(__FILE__, ".*")} target_agi [number=100000]"
  exit
end

$option = {
  target_agi: ARGV.size > 0 ? ARGV[0].to_i : 100,
  number: ARGV.size > 1 ? ARGV[1].to_i : 10000,
}

# $psdq7rnd_state = 0
$psdq7rnd_state = rand(0..0xffffffff) # 乱数の状態

# PS版DQ7の乱数生成 rand(0..32767)
def psdq7rnd()
  $psdq7rnd_state = ($psdq7rnd_state * 0x41c64e6d + 0x3039) & 0xffffffff
  return ($psdq7rnd_state >> 16) & 0x7fff
end

# 0..max-1の乱数を返す rand(max)
def psdq7rnd_max(max)
  return (((psdq7rnd() * max) & 0xffffffff) >> 15) & 0xffff
end

# 範囲内の乱数を返す rand(range)
def psdq7rnd_range(range)
  return range.min + psdq7rnd_max(range.max - range.min + 1)
end

# 行動順値のとりうる範囲を返す
def make_speed_range(agi)
  [1, agi].max*32 .. [1, agi].max*64
end
$option[:speed_range] = make_speed_range($option[:target_agi])

# 行動順値を求める
def make_speed(agi)
  psdq7rnd_range(make_speed_range(agi))
end

# 試行回数で先攻率を求める
def calc_preemptive_rate(a, b, number=10000)
  number.times.count { make_speed(a) >= make_speed(b) }.to_f / number
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

def main
  agi_arr = (0..500).map {|i|
    ($option[:target_agi] * i.to_f / 100).to_i
  }.uniq                        # 対象agiの0~5倍で重複を避ける
  
  puts "素早さ\t倍率\t先攻率\t近似式\t行動順値の範囲"
  agi_arr.each {|agi|
    rate = calc_preemptive_rate(agi, $option[:target_agi], $option[:number])
    rate_by_formula = calc_preemptive_rate_by_formula(agi, $option[:target_agi])
    
    # next if rate == 0.0
    puts "%d\t%.2f\t%.6f\t%.6f\t%s" % [agi, agi.to_f/$option[:target_agi], rate, rate_by_formula, make_speed_range(agi)]
    break if rate == 1.0        # 確定先攻で終了
  }
end

puts $option
main()
