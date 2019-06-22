# メモリーカードを改竄するか
$MODIFY_MEMCARD = false
# メモリーカードのバイナリの場所
MEMCARD = "C:/NO$PSX/MEMCARD/_01_2_A_.mcd"

module DQ7
  # from https://ja.wikipedia.org/wiki/%E5%B7%A1%E5%9B%9E%E5%86%97%E9%95%B7%E6%A4%9C%E6%9F%BB#CRC-32
  @@checksum_poly = 0x04c11db7
  @@checksum_table = []

  # チェックサムのテーブルの構築
  def self.init_checksum_table
    @@checksum_table = (0...256).map{|i|
      8.times.inject(i << 24){|c, _|
        ((c << 1) & 0xffffffff) ^ (c & 0x80000000 != 0 ? @@checksum_poly : 0)
      }
    }
  end

  # バイナリの先頭から124バイト目までのチェックサムを返す
  def self.checksum(bin, limit124 = true)
    bin2 = limit124 ? bin[0...124] : bin
    c = bin2.bytes.inject(0xffffffff){|c, b|
      ((c << 8) & 0xffffffff) ^ @@checksum_table[((c >> 24) ^ b) & 0xff]
    }
    ~c & 0xffffffff
  end

  # バイナリの先頭から124バイトに4バイトのチェックサムを追加する。元のバイナリの125バイト目以降は無視される。
  def self.append_checksum(bin, limit124 = true)
    bin2 = limit124 ? bin[0...124] : bin
    checksum = self.checksum(bin2)

    bin2 + [checksum].pack("l*")
  end

  self.init_checksum_table
end

AnimeMakerGap = 0x2300

def mods2AnimeMakers(mods)
  res = []
  mods.each{|region, hex|
    bin = hex2bin(hex)
    bin = DQ7.append_checksum(bin)
    bin.bytes.each_with_index{|b, i|
      next if b == 0
      y, x = (region.first + i - AnimeMakerGap).divmod(288)
      res << [x, y, b]
    }
  }
  res
end

def AnimeMakers2mods(ams)
  h = {}
  ams.each{|x, y, b|
    addr = first = x + 288 * y + AnimeMakerGap
    first = addr - addr % 128
    h[first] ||= "\x00" * 128
    h[first][addr % 128] = b.chr
  }
  h.map{|first, bin|
    [first..first+127, bin2hex(bin)]
  }.sort_by{|region, _| region.first }.to_h
end

def hex2bin(hex)
  [hex.tr("^0-9a-fA-F","")].pack("H*")
end

def bin2hex(bin)
  hex = bin.unpack("H*")[0]
  hex.scan(/.{,32}/).map{|s|
    s.scan(/../) * " "
  } * "\n"
end

MOD_DEFS = {
  0x4180..0x41ff => "
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
D0 07 08 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 24 07
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00
",
# こっち、THEENDから直接再開するとチェックサム計算されてない？
#   0x4e00...0x4e7f => "
# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
# 00 00 00 00 00 00 00 00 00 00 00 00
# ",
}
# チェックサムをちゃんとする
MOD_DEFS.transform_values!{|hex|
  bin = hex2bin(hex)
  bin = DQ7.append_checksum(bin)
  bin2hex(bin)
}

# メモリーカード改竄
def modify_memcard
  memcard = IO.binread(MEMCARD)
  MOD_DEFS.each{|region, hex|
    memcard[region] = hex2bin(hex)
  }
  IO.binwrite(MEMCARD, memcard)
end

def main
  # チェックサム
  puts"Checksum:"
  MOD_DEFS.each{|region, hex|
    bin = hex2bin(hex)
    checksum = DQ7.checksum(bin[0...124])
    puts "  %x..%x: %s"%[region.first, region.last, bin2hex([checksum].pack("l*"))]
  }
  # アニメティカの入力形式
  ams = mods2AnimeMakers(MOD_DEFS)
  puts "AnimeMaker:"
  ams.each{|x, y, b|
    puts"  %02X: (%3d,%3d): " % [b, x, y]
  }

  if $MODIFY_MEMCARD
    modify_memcard() 
  end
end

main()
