# 必要なもの:
# - crc - CRC calcurator for ruby (https://github.com/dearblue/ruby-crc)
#   - インストールは gem install crc でよい
# - 同じフォルダに
#   - https://github.com/pingval/Speedrun/blob/master/AnimeMaker/pssaves.rb
#   - https://github.com/pingval/Speedrun/blob/master/AnimeMaker/animemaker.rb
#   - crchackのバイナリ(https://github.com/resilar/crchack)
#     - 自分の改造版(https://github.com/pingval/crchack)もあるがこれは要らない

require "open3"
require "tempfile"
require "./pssaves"
include PlayStation

$>.sync = true

# crchackの場所
CRCHACK = "./crchack"
# crchackに渡すコマンドラインオプション(CRCアルゴリズム)
ALGO_OPT = "-w32 -p04c11db7 -iffffffff -xffffffff"
# 指定するCRC値
TARGET_CRC = 0

# 再開地点
# TheEnd: 0x724
# 船の遠景から: 0x721
# 船の近景から: 0x722
# ペラッペラ: 0x715
# 超美麗ムービー1: 0x062e
# 超美麗ムービー2: 0x0633
# オルゴ戦前: 0x06de
# (オルゴ戦前'?: 0x06df)
# オルゴ戦後: 0x06e0
# 神さま戦: 0x06f8
MapID = 0x06de # オルゴ戦前
# ブロックの有効フラグ
BLOCK_FLAGS_HEX = "20 00 00 02 00 00" # オルゴ即戦フラグ・オルゴ撃破
# BLOCK_FLAGS_HEX = "00 00 00 00 00 00" # ED
# BLOCK_FLAGS_HEX = "04 00 00 00 00 00" # 超美麗ムービー
IS_ED = [0x715..0x724].include?(MapID)
# 出力する使用色の条件
# UNIQ_CNT_BORDER = IS_ED ? 7 : 9
UNIQ_CNT_BORDER = 12


ORGO_FLAGS = ["07", "06", "de"]
MIMIC_2S = ["06", "de", "02"]
CHARS = ["a1", "01"]
STAUTUSES = ["00 a1 00 00 00 a1", "a1 00 00 00 00 a1", "20 00 00 00 00 20", "de 00 00 00 00 de", ]

# # 元のバイナリ
# BIN = "#{BLOCK_FLAGS_HEX} 00 00 00 00 00 00 00 06 00 00
# d0 07 08 00 00 00 00 00 00 00 00 00 00 00 00 00
# 00 00 00 00 00 00 00 00 00 00 00 00 03 06 #{MapID.bin(2).b2h}
# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 a1 00
# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 a1 00
# 00 00 00 a1 00 00 00 00 00 00 00 00 00 00 00 00
# 00 00 00 00 00 00 00 00 00 00 00 00".h2b
# 書き換えを禁止するアドレス
# アイテム欄は空に！(ミミックの石2byte目を除く)
NG_ADDRs = [
  *0x00..0x06, # 20 00 00 02 00 00
  *0x10..0x13, # d0 07 08 00
  # 0x0d, # オルゴ即戦闘フラグ
  0x2c, # ミミックの石1byte目
  # 0x2d, # ミミックの石2byte目
  *0x2e..0x2f, # 再開マップ
  *0x30..0x43, # アイテム欄 3~12
  0x4e, # キャラ
  # *0x5e..0x5f, # 現在hP
  # *0x62..0x63, # 素早さ
]
# 書き換えを許可するアドレス
OK_ADDRs = [*0x00..0x6f] - NG_ADDRs
# OK_ADDRs = [*0x00..0x37] - NG_ADDRs
# 組み合わせの要素数
# COMB_N = 4
COMB_N = 3
# 発見済みのバイナリ
$found = {}

def valid?(o)
  # オルゴ即戦闘フラグ
  return false if !(o[0x0d].ord & 0x04 != 0)
  # ミミックの石
  return false if !(o[0x2c].ord == 0x03)
  tmp = o[0x2d].ord
  return false if !(tmp & 0x02 != 0 && tmp & 0x01 == 0)
  # 名前の1文字目。2文字目はいいや…
  name1_1 = o[0x44].ord
  name1_2 = o[0x45].ord
  return false if name1_1.between?(0x01, 0xef) && name1_2 == 0x00
  # キャラ
  return false if !(o[0x4e].ord & 0x1f == 0x01)
  # 現在HP
  hp = (o[0x5e].ord >> 4) | ((o[0x5f].ord & 0x3f) << 4)
  return false if hp < 1
  # 素早さ
  agi = (o[0x62].ord >> 4) | ((o[0x63].ord & 0x3f) << 4)
  return false if agi < 270
  true
end

count = 0
VALUES_COMBINATION = ORGO_FLAGS.product(MIMIC_2S, CHARS, STAUTUSES)
total = OK_ADDRs.combination(COMB_N).size * VALUES_COMBINATION.size

VALUES_COMBINATION.each{|orgo_flag, mimic_2, char, status|
  puts "===="
  bin = "#{BLOCK_FLAGS_HEX} 00 00 00 00 00 00 00 #{orgo_flag} 00 00
d0 07 08 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 03 #{mimic_2} #{MapID.bin(2).b2h}
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 #{char} 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00
#{status} 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00".h2b
  puts bin.b2h
  puts "===="
  Tempfile.create{|tf|
    tf.binmode.write(bin)
    tf.close
    OK_ADDRs.combination(COMB_N){|comb|
      count += 1
      # crchackに渡すコマンドラインオプション(書き換えアドレス)
      mod_opt = comb.map{|i| "-b %d:+1" % i } * " "
      cmd = "#{CRCHACK} #{ALGO_OPT} #{mod_opt} #{tf.path} #{TARGET_CRC}"
      o, e, s = Open3.capture3(cmd)
      ob = o.b
      if !o.empty? && valid?(ob)
        cnt, uniq_cnt = ob.counts
        # 使う色がN未満なら出力
        if uniq_cnt < UNIQ_CNT_BORDER
        # if 1
          # 既出なら飛ばす
          next if $found[o]
          $found[o] = 1
          # 塗るマスの数
          puts "Count:"
          puts "%4d"%cnt
          # 使う色の数
          puts "Unique Count:"
          puts "%4d"%uniq_cnt
          # バイナリ
          puts "Hex:"
          puts o.b2h
          # アニメティカでの塗り方
          am = AM.new("\0" * 0x180 + ob, pos:2)
          puts am.to_s(true) # アドレス順
          # 可視化
          puts "Visual:"
          puts am.inspect
          # 境界線と進捗
          puts "----" + " #{count}/#{total}"
        end
      end
    }
  }
}
