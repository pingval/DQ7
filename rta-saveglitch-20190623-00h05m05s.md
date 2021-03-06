# [PS版DQ7 セーブデータ改竄RTA in 5:05](https://www.youtube.com/watch?v=oN6G7JVtApU)

**RPGツクール3内蔵のお絵かきソフトであるアニメティカをバイナリエディタ代わりに使ってセーブデータを改竄する、ぶっ壊れ系RTAです。詳しくは[こっち](#参考)。**

- プレイ日時: 2019年06月23日
- 計測区間: 本体の電源投入からTHE ENDの羽ペン消滅まで
- 使用ソフト:
  - RPGツクール3
  - PS版DQ7 アルティメットヒッツ版(いわゆる廉価版)
- 使用本体: PS2(SCPH-90000)
- 使用コントローラ: HORI アナログ振動パッド2 TURBO レッド、連射機能非使用
- 改ざん用のセーブデータ作成を計測区間に含める（事前に作成したセーブデータの利用は禁止！）
- アニメティカでの8ブロックセーブ中のメモリーカードの抜き差しは禁止（事前に作成したセーブデータを利用できる怖れがあるため）

----

## [とどトド氏の8:17.07](https://www.nicovideo.jp/watch/sm35229544)からの変更点など

- DQ7のセーブデータのチェックサムを解析したことにより、セーブデータを好きに改竄できるようになった。チェックサムのアルゴリズムは生成多項式0x4c11db7のCRC32をビット反転したもの。
- ロード後のゲームの再開ポイントを「キーファの手紙」から「THE END画面」へ変更したことにより約55sの短縮。タイトルBGMをバックにTHE END画面が表示される。
- 再開ポイントを「THE END画面」に変更すると`0x4e00~0x4e7f`(アニメティカにおける(64,38)~(191,38))の範囲の改竄が不要になっため、アニメティカによるバイナリ編集をほぼ半減できた。また、必要最低限(たぶん)の改竄を施したデータのチェックサムが偶然にも`ed e1 ee ea`という非常に入力しやすい値となった。

----

## タイムいろいろ

|区間名|通過|区間|戦闘|備考|
|:---:|:---:|:---:|:---:|:---:|
|電源投入|00:00:00|||
|アニメティカ終了|00:02:47|00:02:47|||
|エンディング終了|00:05:05|00:02:18|||

- 計測地点:
  - アニメティカ終了: アニメティカ起動中にリセットした瞬間

----

## 実際のプレイ

- 1時間近く試行を繰り返していたが、DQ7でセーブ中にメモリーカードを抜くのに最後の最後しか成功しなかった。
- 記録の出たプレイでは、失敗続きの原因はアニメティカの最後のセーブ中のリセット(約2sの短縮)かもしれないと考え、ちゃんとセーブ終了後にリセットした。
- アニメティカの色塗りの最後のほうが遅い。DQ7に移って3回目のセーブで成功。リセットは2回行った。

----

## おわりに

- というわけで3分台は可能。
- のちほど調べたところ、アニメティカの最後のセーブ中のリセットは実機でも問題なかった。
- DQ7のセーブ中にメモリーカードを抜く猶予時間をPSエミュレータNO$PSXのフレームアドバンス機能を使って調べたところ、2f (60fps)つまり約0.03sだった。実機ではないので確かなことは言えないが、もし実機でも猶予時間が同じなら、今日のプレイで無限に失敗してたのは仕方ないんじゃないかな！
- [調査のために書いたスクリプト](./psdq7_checksum_animemaker.rb)(要[Ruby](https://www.ruby-lang.org/ja/))。`MOD_DEFS`の定義を元にして、アニメティカで塗る座標の出力とかエミュレータで使うメモリーカードの改竄とかできます。
- このRTA、非オフライン環境では、引き抜いたメモリーカードを事前に用意したものと交換するだけで簡単に不正できるのがまずい。手元を映すくらいしか対策なくない？
- もしSRCで登録するなら、カテゴリ名は Any% AnimeMaker Saveglitch JP とかになるのかな？

### 色塗り

並び順は実際に塗った順ではなく単純に座標の昇順です。

#### [とどトド氏の8:17.07](https://www.nicovideo.jp/watch/sm35229544)
```
AnimeMaker:
  01: ( 32, 27)
  02: ( 35, 27)
  D0: ( 48, 27)
  07: ( 49, 27)
  08: ( 50, 27)
  0B: ( 52, 27)
  03: ( 56, 27)
  31: ( 58, 27)
  17: ( 76, 27)
  15: ( 78, 27)
  07: ( 79, 27)
  5B: (156, 27)
  93: (157, 27)
  E0: (158, 27)
  71: (159, 27)
  21: (142, 38)
  06: (188, 38)
  D2: (189, 38)
  4E: (190, 38)
  E4: (191, 38)
Visual:
y\x| 32       35                                     48 49 50    52          56    58                                                    76    78 79 ~ 142                                       156157158159                                                                                    188189190191
---+------------------------------------------------------------------------------------------------------------------------------------------------ ~ ------------------------------------------------------------------------------------------------------------------------------------------------------
 27| 01       02                                     D0 07 08    0B          03    31                                                    17    15 07 ~                                            5B 93 E0 71                                                                                                
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 38|                                                                                                                                                 ~  21                                                                                                                                        06 D2 4E E4
```

#### 本プレイ
```
  D0: ( 48, 27)
  07: ( 49, 27)
  08: ( 50, 27)
  24: ( 78, 27)
  07: ( 79, 27)
  ED: (156, 27)
  E1: (157, 27)
  EE: (158, 27)
  EA: (159, 27)
Visual:
y\x| 48 49 50                                                                                  78 79 ~ 156157158159
---+------------------------------------------------------------------------------------------------ ~ ------------
 27| D0 07 08                                                                                  24 07 ~  ED E1 EE EA
```

#### Dragon Warrior VII

DQ7の北米版であるDW7で同じことをする場合、再開マップを`24 07`から`25 07`に変更する必要があり、それに伴いチェックサムも変更される。  
なお、DW7を動かすのに必要な北米版のPS2では日本語版のRPGツクール3は動かないので、PS2を日本語版と北米版の2台用意するか、北米版のRPGツクール3(RPG Maker)を用意する必要がある。

```
AnimeMaker:
  D0: ( 48, 27)
  07: ( 49, 27)
  08: ( 50, 27)
  25: ( 78, 27)
  07: ( 79, 27)
  EB: (156, 27)
  0E: (157, 27)
  1B: (158, 27)
  5B: (159, 27)
Visual:
y\x| 48 49 50                                                                                  78 79 ~ 156157158159
---+------------------------------------------------------------------------------------------------ ~ ------------
 27| D0 07 08                                                                                  25 07 ~  EB 0E 1B 5B
```

↑はチェックサムがめんどくさいので簡単に調べたところ、(144, 27)に`01`を塗ると入力がそこそこ楽になるようだ。
```
AnimeMaker:
  D0: ( 48, 27)
  07: ( 49, 27)
  08: ( 50, 27)
  25: ( 78, 27)
  07: ( 79, 27)
  01: (144, 27)
  ED: (156, 27)
  ED: (157, 27)
  ED: (158, 27)
  5C: (159, 27)
Visual:
y\x| 48 49 50                                                                                  78 79 ~ 144                                 156157158159
---+------------------------------------------------------------------------------------------------ ~ ------------------------------------------------
 27| D0 07 08                                                                                  25 07 ~  01                                  ED ED ED 5C
```

----

## 参考

- [RPGツクール3を使ったPS1セーブデータの改ざん方法 | RTAPlay!](https://rta-play.info/tool/save-glitch/)
- [【ゆっくり実況】ドラゴンクエスト7 セーブデータ改ざんRTA　0:14:04](https://www.nicovideo.jp/watch/sm35205981)
- [巡回冗長検査 - Wikipedia](https://ja.wikipedia.org/wiki/%E5%B7%A1%E5%9B%9E%E5%86%97%E9%95%B7%E6%A4%9C%E6%9F%BB)
