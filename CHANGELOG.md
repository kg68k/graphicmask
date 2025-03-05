# 変更履歴

## Release 1.0.0  (2025-03-05)

* リポジトリ作成。ビルド環境の近代化。

### gm 0.87 patchlevel 4

* 改行コードをCRLFに戻した。

### gmss 0.62 patchlevel 2

* 改行コードをCRLFに戻した。


## gm087p3.zip  (1997-09-19)

### gm 0.87 patchlevel 3

* R形式実行ファイルに変更。
* HUPAIRに対応。
* オプション追加。--version、-vでバージョン、--help、-hで使用法を表示する。
* Human68kのバージョンチェックを外した。
* 使用するdoscall.mac、iocscall.macをXC形式(シンボル名の先頭が`__`ではなく`_`)に変更。
* DOS _KEEPPRのフックを追加。
* IOCS _B_WPOKEのフックを削除。
* IOCS _TXXLINE、_TXYLINE、_TXBOXのフックを削除。
* 使用法の表示から-fオプションを削除(機能自体は存続)。
* マスク禁止状態でもマスクしてしまう不具合を修正。
* オプション-gを追加。

### gmss 0.62 patchlevel 1

* R形式実行ファイルに変更。
* HUPAIRに対応。
* オプション追加。--version、-vでバージョン、--help、-hで使用法を表示する。
* Human68kのバージョンチェックを外した。
* 使用するdoscall.mac、iocscall.macをXC形式(シンボル名の先頭が`__`ではなく`_`)に変更。
* -t0実行時に表示色が乱れないようした。
