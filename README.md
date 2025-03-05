# Graphic Mask

Graphic Maskの改造版です。  
無保証につき各自の責任で使用して下さい。

gm.xとgmss.xの実行ファイル形式をX形式からR形式に変更し、gm.rとgmss.rとしました。


## gm.rの追加機能

gm.rにオプション-gが追加されています。

このオプションを指定すると、IOCS _G_CLR_ONが呼ばれた時にグラフィック画面が使用中か調べ、
使用中であればエラー(白帯)を表示します。


## 技術資料: gm.rがフックするベクタ

* IOCSコール
  * IOCS _B_KEYSNS ($01) ... 電卓処理後のマスク検査。
  * IOCS _TGUSEMD ($0e) ... 内部コール用。オートマスク処理。
  * IOCS _CRTMOD ($10) ... 64K色GNC。オートマスク処理。
  * IOCS _TPALET ($13) ... パレットイルミネーション対応など。
  * IOCS _TPALET2 ($14) ... パレットイルミネーション対応など。
  * IOCS _DENSNS  ($7e) ... 電卓処理後のマスク検査。
  * IOCS _G_CLR_ON ($90) ... 64K色表示座標初期化、マスク消去など。
* DOSコール
  * DOS _EXIT ($ff00) ... VRAM検査、(必要なら)常駐パレットへの転送。GVRAM占有フラグのクリア。
  * DOS _EXIT2 ($ff4c) ... VRAM検査、(必要なら)常駐パレットへの転送。GVRAM占有フラグのクリア。
  * DOS _KEEPPR ($ff31) ... VRAM検査、(必要なら)常駐パレットへの転送。GVRAM占有フラグのクリア。


## Build

PCやネット上での取り扱いを用意にするために、src/内のファイルはUTF-8で記述されています。
X68000上でビルドする際には、UTF-8からShift_JISへの変換が必要です。

### u8tosjを使用する方法

あらかじめ、[u8tosj](https://github.com/kg68k/u8tosj)をインストールしておいてください。

トップディレクトリで`make`を実行してください。以下の処理が行われます。
1. `build/`ディレクトリの作成。
3. `src/`内のファイルをShift_JISに変換して`build/`へ保存。

次に、カレントディレクトリを`build/`に変更し、`make`を実行してください。
実行ファイルが作成されます。

### u8tosjを使用しない方法

`src/`内のファイルを適当なツールで適宜Shift_JISに変換してから`make`を実行してください。
UTF-8のままでは正しくビルドできませんので注意してください。


## License
改造元のGraphic Maskの著作権はJACK氏にあります。  
改造部分の著作権は改造者(TcbnErik)にあります。

配布規定については改造元のGraphic Maskに準じます。

詳しくはGM087.TGZ内のgm.docを参照してください。


## Author

TcbnErik / https://github.com/kg68k/graphicmask
