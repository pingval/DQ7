# -*- encoding: utf-8 -*-
# 2016/01/23
# ・公開

# agi1, agi2が指定されてない場合
if ARGV.size < 2
  puts "Usage: #{File.basename(__FILE__, ".*")} agi1 agi2 [number=100000]"
  exit
end

$option = {
  agi1: ARGV[0].to_i,
  agi2: ARGV[1].to_i,
  number: ARGV.size > 2 ? ARGV[2].to_i : 100000,
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
# $option[:speed_range] = make_speed_range($option[:target_agi])

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
  rate_by_formula = calc_preemptive_rate_by_formula($option[:agi1], $option[:agi2])
  rate = calc_preemptive_rate($option[:agi1], $option[:agi2], $option[:number])
  
  puts "近似式\t%.2f%%" % [rate_by_formula * 100]
  puts "%d回試行\t%.2f%%" % [$option[:number], rate * 100]
end

# puts $option
main()
