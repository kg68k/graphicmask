
☆ 配布ファイル一覧

	doc/			ドキュメント, バージョンアップ履歴
	  gm.doc
	  gm.his
	  gm_hook.doc		GMが利用するベクタの一覧
	  gmss.doc
	  gmss.his
	  gsvexe.doc
	  gsvexe.his

	src/			全ソースファイル
	  Makefile
	  gm.s
	  gm_call_i.h		GCC & libc 用GM制御インライン関数
	  gm_internal.mac	内部(GM制御)コール用の定数定義
	  gmss.s
	  gsvexe.s

	bin/
	  gm.x			GM本体
	  gmss.x		gm.x のサポートツール
	  gsvexe.x		謎のグラフィック復帰です


☆ インストール

	gm.x, gmss.x, gsvexe.x をパスの通った所にコピーしてください.

	必要ならば gm_call_i.h, gm_internal.mac を $include にコピー

	してください.

	そして, autoexec.bat 等に

		gm -vpnk

	の１行を付け加えればとりあえず使えるようになります.

	オプションスイッチの意味等は gm.doc を参照してください.


☆ 付属ソースについて

	このアーカイブに含まれるヘッダやソースは自由に使って構いません.

	また, gm付属ソース及びヘッダを含むソースを公開する場合でも私への

	連絡は一切不用です.


				JACK
