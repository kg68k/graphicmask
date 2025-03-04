* $Id: gmss.s,v 1.1 1994/09/13 21:58:45 JACK Exp $

	.include	iocscall.mac
	.include	doscall.mac
	.include	gm_internal.mac

*
	.text
program_text_start:
	.data
program_data_start:
	.bss
program_bss_start:
	.stack
program_stack_start:
	.text
*

*-------------------------------------------------------------------------------
* 終了コードの定義

	.offset	0
EXIT_NO_ERROR		.ds.b	1
EXIT_HELP		.ds.b	1
EXIT_ERROR_OPTION	.ds.b	1
EXIT_ERROR_SETBLOCK	.ds.b	1
EXIT_ERROR_MALLOC	.ds.b	1
EXIT_ERROR_MFREE	.ds.b	1
EXIT_ERROR_GM_NOT_KEEP	.ds.b	1
	.text

*-------------------------------------------------------------------------------
* タイトルメッセージ

	.data
message_title:
	.dc.b	'GM Set Screen version 0.62 programmed by JACK',13,10
	.dc.b	0

*-------------------------------------------------------------------------------
* マクロ定義

_TO_SUPER	.macro
* スーパーバイザーモードへ
	clr.l	-(sp)
	DOS	__SUPER
	addq.l	#4,sp
	move.l	d0,-(sp)
	.endm

_TO_USER	.macro
		.local	super_end
* ユーザーモードへ
	move.l	(sp)+,d0
	bmi	super_end
	move.l	d0,-(sp)
	DOS	__SUPER
	addq.l	#4,sp
super_end:
	.endm

*-------------------------------------------------------------------------------
* ここからメインプログラム

	.bss
	.even
parameter_a0:
	.ds.l	1
parameter_a1:
	.ds.l	1
parameter_a2:
	.ds.l	1
parameter_a3:
	.ds.l	1
parameter_a4:
	.ds.l	1
program_top_address:
	.ds.l	1
program_size:
	.ds.l	1

	.stack
	.ds.l	1024
user_stack:

	.text
program_start:
	lea	user_stack,sp
	movem.l	a0-a4,parameter_a0
	lea	$10(a0),a0
	sub.l	a0,a1
	move.l	a1,-(sp)
	move.l	a0,-(sp)
	DOS	__SETBLOCK
	addq.l	#8,sp
	tst.l	d0
	bmi	program_error_setblock
	bsr	program_ver_check

	move.l	parameter_a0,a0
	move.l	parameter_a1,a1
	lea	$100(a0),a0
	move.l	a0,program_top_address
	sub.l	a0,a1			* a1.l = プログラムサイズ
	move.l	a1,program_size

	move.l	parameter_a2,a0
switch_check:
	clr.l	d7			* d7.l = オプションスイッチ
	tst.b	(a0)+
switch_check_loop:
	bsr	get_character
	beq	switch_check_end
	cmp.b	#'-',d0
	beq	switch_check_option

	.ifdef	__SLASH__
	cmp.b	#'/',d0
	beq	switch_check_option
	.endif

	bra	switch_check_error
switch_check_option:
	bsr	option_check
	bra	switch_check_loop
switch_check_error:
	bset.l	#OPT_ERR,d7

switch_check_end:
	tst.l	d7
	bne	exec_option
	bra	exec_option		* スイッチがなくても起動する

*-------------------------------------------------------------------------------
* オプションスイッチの定義

	.offset	0
OPT_C	.ds.b	1	* グラフィックのクリア
OPT_R	.ds.b	1	* グラフィック・スクロール・レジスタの初期化
OPT_G	.ds.b	1	* グラフィック表示のオンオフ
OPT_S	.ds.b	1	* ６４Ｋ色グラフィックの縦圧縮
OPT_T	.ds.b	1	* グラフィックのトーンダウン
OPT_M	.ds.b	1	* 画面モードの初期化
OPT_V	.ds.b	1	* バージョン表示、メッセージの表示
OPT_HLP	.ds.b	1	* ヘルプ表示
OPT_ERR	equ	31	* スイッチ指定の間違いなど：常に最上位ビット
	.text

*-------------------------------------------------------------------------------
* オプションスイッチの読み取り＆設定

	.text
option_check:
	tst.b	(a0)
	bne	option_check_loop
	bset.l	#OPT_ERR,d7
	bra	option_check_end
option_check_loop:
	move.b	(a0),d0
	beq	option_check_end
	tst.b	(a0)+
	bsr	toupper
	cmp.b	#' ',d0
	beq	option_check_end
	cmp.b	#$09,d0
	beq	option_check_end
	cmp.b	#'V',d0
	beq	opt_v
	cmp.b	#'C',d0
	beq	opt_c
	cmp.b	#'R',d0
	beq	opt_r
	cmp.b	#'G',d0
	beq	opt_g
	cmp.b	#'S',d0
	beq	opt_s
	cmp.b	#'T',d0
	beq	opt_t
	cmp.b	#'M',d0
	beq	opt_m
	cmp.b	#'H',d0
	beq	opt_h
	bra	opt_err

opt_c:
	bset.l	#OPT_C,d7
	bra	option_check_loop

opt_r:
	bset.l	#OPT_R,d7
	bra	option_check_loop

	.bss
	.even
opt_g_number:
	.ds.l	1
	.text
opt_g:
	bset.l	#OPT_G,d7
	lea	opt_g_number,a1
	move.l	#1,(a1)			* デフォルトは１らしい
	moveq.l	#3,d0			* 読み取り数値の最大値
	bsr	opt_number
	bmi	opt_err			* 最大値超えたか数値の読み取りでエラーがでた
	bra	option_check_loop

	.bss
	.even
opt_s_number:
	.ds.l	1
	.text
opt_s:
	bset.l	#OPT_S,d7
	lea	opt_s_number,a1
	clr.l	(a1)			* デフォルトは０らしい
	moveq.l	#1,d0			* 読み取り数値の最大値
	bsr	opt_number
	bmi	opt_err			* 最大値超えたか数値の読み取りでエラーがでた
	bra	option_check_loop

	.bss
	.even
opt_t_number:
	.ds.l	1
	.text
opt_t:
	bset.l	#OPT_T,d7
	lea	opt_t_number,a1
	move.l	#50,(a1)		* デフォルトは５０らしい
	moveq.l	#100,d0			* 読み取り数値の最大値
	bsr	opt_number
	bmi	opt_err			* 最大値超えたか数値の読み取りでエラーがでた
	bra	option_check_loop

opt_m:
	bset.l	#OPT_M,d7
	bra	option_check_loop

opt_v:
	bset.l	#OPT_V,d7
	bra	option_check_loop

opt_h:
	bset.l	#OPT_HLP,d7
	bset.l	#OPT_V,d7
	bra	option_check_loop

opt_err:
	bset.l	#OPT_ERR,d7
	bsr	skip_character		* 後のコマンドラインは評価しても無駄なので切る
	bra	option_check_loop

option_check_end:
	rts

*-------------------------------------------------------------------------------
* 数値を読み取ってワークにしまう
*
* entry:
*   d0.l = 最大数値
*   a0.l = 文字列ポインタ
*   a1.l = 数値を保存するワークエリアのアドレス
* return:
*   ccr:n = 0 読み取れた
*   ccr:n = 1 エラーだな
* broken:
*   d0.l, d1.l

	.text
opt_number:
	bsr	skip_space		* スイッチの後にスペースがあってもいい
	cmp.b	#'-',(a0)
	beq	opt_number_next		* 次のスイッチらしい
	bsr	option_get_number
	tst.l	d1
	beq	opt_number_end		* デフォルトだな
	bmi	opt_number_end		* 最大値を超えたか数値の読み取りでエラーがでた
	move.l	d0,(a1)
opt_number_end:
	tst.l	d1
	rts

opt_number_next:
	subq.l	#1,a0			* 行き過ぎだから戻る
	cmp.b	#' ',(a0)
	beq	@f
	cmp.b	#$09,(a0)
	beq	@f
	addq.l	#1,a0			* スペース、タブ以外は無視する
@@:
	moveq.l	#0,d1
	bra	opt_number_end

*-------------------------------------------------------------------------------
* 数値の読み取り（１０進数）
*
* entry:
*   d0.l = 最大数値
*   a0.l = 文字列ポインタ
* return:
*   d0.l = 数値（エラー時や数値が続いてない時は不定）
*   d1.l = 0 数値が続いていなかった
*   d1.l > 0 数値が得られた
*   d1.l < 0 異常な文字があったか最大数値を超えた

option_get_number_register	reg	d2-d4

option_get_number:
	movem.l	option_get_number_register,-(sp)
	move.l	d0,d4
	clr.l	d0
	clr.l	d1
	clr.l	d3
option_get_number_loop:
	move.b	(a0),d1
	beq	option_get_number_check
	cmp.b	#' ',d1
	beq	option_get_number_check
	cmp.b	#$09,d1
	beq	option_get_number_check
	sub.b	#'0',d1
	bmi	option_get_number_error	* 0 ～ 9の範囲でなければ当然エラーです。
	cmp.b	#9+1,d1
	bcc	option_get_number_error
	moveq.l	#1,d3			* 読み取りフラグオン
	add.l	d0,d0
	move.l	d0,d2
	add.l	d0,d0
	add.l	d0,d0
	add.l	d2,d0
	add.l	d1,d0			* d0.l=d0.l*10 + d1.l
	tst.b	(a0)+			* 文字列ポインタを１つ進める
	bra	option_get_number_loop

option_get_number_check:
	tst.l	d3
	beq	option_get_number_end
	cmp.l	d4,d0			* 最大値を超えてるかな？
	bls	option_get_number_end
option_get_number_error:
	moveq.l	#-1,d3			* エラー
option_get_number_end:
	move.l	d3,d1
	movem.l	(sp)+,option_get_number_register
	rts

*-------------------------------------------------------------------------------
* プログラムを実行しちゃうんです

	.data
	.even
exec_table:
	.dc.l	title
	.dc.l	error
	.dc.l	help
	.dc.l	gm_keep_check
	.dc.l	graphic_onoff
	.dc.l	shrink
	.dc.l	tone
	.dc.l	clear
	.dc.l	scroll
	.dc.l	main
	.dc.l	0

	.ifdef	__DEBUG__
message_exit:
	.dc.b	'debug:ちゃんと終わりました。',13,10
	.dc.b	0
message_exit2:
	.dc.b	'debug:エラーがでちゃったぁ。',13,10
	.dc.b	0
message_keeppr:
	.dc.b	'debug:メモリに常駐しちゃいます。',13,10
	.dc.b	0
	.endif

exec_register	reg	d7/a1

	.text
exec_option:
	.ifdef	__DEBUG__
	bset.l	#OPT_V,d7
	.endif

	lea	exec_table,a1
exec_option_loop:
	move.l	(a1)+,d0
	beq	exec_option_end
	move.l	d0,a0
	jsr	(a0)
	tst.l	d0
	bne	exec_option_exit
	bra	exec_option_loop
exec_option_end:

	.ifdef	__DEBUG__
	pea	message_exit
	DOS	__PRINT
	addq.l	#4,sp
	.endif

	DOS	__EXIT
exec_option_exit:
	tst.l	d0
	bmi	exec_option_keeppr
	move.w	d0,-(sp)

	.ifdef	__DEBUG__
	pea	message_exit2
	DOS	__PRINT
	addq.l	#4,sp
	.endif

	DOS	__EXIT2
exec_option_keeppr:
	move.w	d0,-(sp)
	move.l	d1,-(sp)

	.ifdef	__DEBUG__
	pea	message_keeppr
	DOS	__PRINT
	addq.l	#4,sp
	.endif

	DOS	__KEEPPR

*-------------------------------------------------------------------------------
* 空白文字以外の一文字を得る
*
* return:
*   ccr:z  = 0 文字が得られた
*   ccr:z  = 1 文字はありません
*     d0.b = (文字コード)

	.text
get_character:
	move.b	(a0)+,d0
	beq	get_character_end
	cmp.b	#' ',d0
	beq	get_character
	cmp.b	#$09,d0
	beq	get_character
get_character_end:
	rts

*-------------------------------------------------------------------------------
* ヌル文字までポインタを進める

	.text
skip_character:
	tst.b	(a0)
	beq	skip_character_end
	tst.b	(a0)+
	bra	skip_character
skip_character_end:
	rts

*-------------------------------------------------------------------------------
* スペース、タブを読み飛ばす

	.text
skip_space:
	tst.b	(a0)+
	beq	skip_space_end
	cmp.b	#' ',-1(a0)
	beq	skip_space
	cmp.b	#$09,-1(a0)
	beq	skip_space
skip_space_end:
	subq.l	#1,a0
	rts

*-------------------------------------------------------------------------------
* アルファベット小文字を大文字に変換

	.text
toupper:
	cmp.b	#'a',d0
	bcs	toupper_end
	cmp.b	#'z'+1,d0
	bcc	toupper_end
	sub.b	#'a'-'A',d0
toupper_end:
	rts

*-------------------------------------------------------------------------------
* '-v' が設定されている時メッセージを表示する
*
* entry:
*   $04(sp) = 文字列のアドレス

	.text
_vprint:
	btst.l	#OPT_V,d7
	beq	_vprint_end
	move.l	$04(sp),-(sp)
	DOS	__PRINT
	addq.l	#4,sp
_vprint_end:
	rts

*-------------------------------------------------------------------------------
* エラー時のメッセージ表示
*
* entry:
*   $04(sp) = 文字列のアドレス

	.text
_error_print:
	move.l	$04(sp),-(sp)		* 見た目の問題・・・
	DOS	__PRINT
	addq.l	#4,sp
_error_print_end:
	rts

*-------------------------------------------------------------------------------
* 起動時のタイトル表示

	.text
title:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_V,d7
	bne	title_print
	btst.l	#OPT_ERR,d7
	bne	title_print
	btst.l	#OPT_HLP,d7
	bne	title_print
	bra	title_end

title_print:
	pea	message_title
	DOS	__PRINT
	addq.l	#4,sp
	clr.l	d0
title_end:
	movem.l	(sp)+,exec_register
	rts

*-------------------------------------------------------------------------------
* スイッチの指定が間違っていた時のエラーメッセージ表示

	.data
message_error:
	.dc.b	'スイッチの指定が間違ってます。',13,10
	.dc.b	'(-h でヘルプが表示されます。)',13,10
	.dc.b	0

	.text
error:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_ERR,d7
	beq	error_end

	pea	message_error
	bsr	_error_print
	addq.l	#4,sp

	moveq.l	#EXIT_ERROR_OPTION,d0
error_end:
	movem.l	(sp)+,exec_register
	rts

*-------------------------------------------------------------------------------
* ヘルプメッセージの表示

	.data
message_help:
	.dc.b	'使用法: gmss <スイッチ>',13,10
	.dc.b	'スイッチ:',13,10
	.dc.b	'	-c	グラフィックのクリア',13,10
	.dc.b	'	-r	グラフィック・スクロール・レジスタの初期化',13,10
	.dc.b	'	-g[n]	グラフィックの表示 (0:オフ [1]:オン 2:16色 3:64K色)',13,10
	.dc.b	'	-s[n]	６４Ｋ色グラフィックの縦圧縮 (n:[0]-1)',13,10
	.dc.b	'	-t[n]	グラフィックのトーンダウン (n:0-[50]-100)',13,10
	.dc.b	'	-m	画面モード初期化をする',13,10
	.dc.b	'	-v	バージョン表示、メッセージ表示',13,10
	.dc.b	'	-h	ヘルプメッセージ',13,10
	.dc.b	13,10
	.dc.b	'スイッチは大文字／小文字を区別しません。',13,10
	.dc.b	13,10
	.dc.b	0

	.text
help:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_HLP,d7
	beq	help_end

	pea	message_help
	bsr	_vprint
	addq.l	#4,sp

	moveq.l	#EXIT_HELP,d0
	movem.l	(sp)+,exec_register
	clr.l	d7			* その他のスイッチは無効です
	movem.l	exec_register,-(sp)
help_end:
	movem.l	(sp)+,exec_register
	rts

*-------------------------------------------------------------------------------
* グラフィック画面のオンオフ

	.text
graphic_onoff:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_G,d7
	beq	graphic_onoff_end

	move.l	opt_g_number,d0
	bne	@f

	_TO_SUPER
	and.b	#$60,$e82601		* オフ
	bset.b	#3,$e80028
	_TO_USER
	clr.l	d0
	bra	graphic_onoff_end

@@:
	subq.l	#2,d0
	bne	@f
	_TO_SUPER
	move.b	#$04,$e80028		* 強制16色
	move.w	#$0004,$e82400
	bra	graphic_onoff_16

@@:
	subq.l	#1,d0
	bne	@f
	_TO_SUPER
	move.b	#$03,$e80028		* 強制64K色
	move.w	#$0003,$e82400
	bra	1f

@@:
	_TO_SUPER
	bclr.b	#3,$e80028
	btst.b	#1,$e80028
	beq	graphic_onoff_16

	or.b	#3,$e80028		* 256色は対応しない
	move.w	#3,$e82400
1:
	lea	$e80018,a0		* ６４Ｋなら位置補正＋トーンダウン
	move.w	#$ff80,d0
	move.w	d0,(a0)+
	clr.w	(a0)+
	move.w	d0,(a0)+
	clr.w	(a0)+
	move.w	d0,(a0)+
	clr.w	(a0)+
	move.w	d0,(a0)+
	clr.w	(a0)+

	move.w	$e82600,d1
	and.w	#$00ff,d1

	bsr	gpalette_check
	tst.l	d0
	bne	@f
	cmp.l	#$007f8000,gpalette_sum
	bne	@@f			* FLAME.Xで変更中
@@:
	or.w	#$1900,d1
@@:
	move.w	d1,$e82600

	move.w	#_GM_AUTO_STATE,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	cmp.l	#-1,d0
	beq	@f
	cmp.w	#_GM_INTERNAL_MODE,d0
	bne	@f
	swap.w	d0
	btst.l	#0,d0
	bne	@f			* マスク禁止
	btst.l	#1,d0
	beq	@f			* マスク許可しない

	move.w	#_GM_MASK_SET,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
@@:
graphic_onoff_16:
	or.w	#$003f,$e82600		* オン
	_TO_USER
	clr.l	d0

graphic_onoff_end:
	movem.l	(sp)+,exec_register
	rts

*-------------------------------------------------------------------------------
* トーン

	.text
tone:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_T,d7
	beq	tone_end

	bsr	mode_check
	cmp.l	#-1,d0
	beq	tone_end
	tst.w	d0
	beq	@f

	bsr	tone_change_64k
	clr.l	d0
	bra	tone_end
@@:
	bsr	tone_change
	clr.l	d0
tone_end:
	movem.l	(sp)+,exec_register
	rts

*-------------------------------------------------------------------------------
* クリア

	.text
clear:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_C,d7
	beq	clear_end

	bsr	mode_check
	cmp.l	#-1,d0
	beq	clear_end
	tst.w	d0
	beq	@f

	bsr	clear_64k		* スクロールリセットを含む
	clr.l	d0
	bra	clear_end
@@:
	bsr	clear_16
	clr.l	d0
clear_end:
	movem.l	(sp)+,exec_register
	rts

*-------------------------------------------------------------------------------
* スクロール

	.text
scroll:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_R,d7
	beq	scroll_end

	bsr	mode_check
	cmp.l	#-1,d0
	beq	scroll_end
	tst.w	d0
	beq	@f

	clr.l	d0
	bra	scroll_end
@@:
	bsr	scroll_reset
	clr.l	d0
scroll_end:
	movem.l	(sp)+,exec_register
	rts

*-------------------------------------------------------------------------------
* モードチェック

	.text
mode_check:
	movem.l	d1-d2,-(sp)
	move.w	#_GM_GRAPHIC_MODE_STATE,d1
	moveq.l	#-1,d2			* ダミーデータ
	bsr	_gm_internal_tgusemd
	cmp.l	#-1,d0
	beq	@f
	swap.w	d0
@@:
	movem.l	(sp)+,d1-d2
	rts

*-------------------------------------------------------------------------------
* 常駐チェック

	.data
message_gm_not_keep:
	.dc.b	'gm が常駐していません。',13,10
	.dc.b	0

	.text
gm_keep_check:
	movem.l	exec_register,-(sp)
	move.w	#_GM_VERSION_NUMBER,d1
	moveq.l	#-1,d2			* ダミーデータ
	bsr	_gm_internal_tgusemd
	cmp.l	#-1,d0
	beq	gm_not_keep		* gm がないよぉ
	cmp.w	#_GM_INTERNAL_MODE,d0
	bne	gm_not_keep		* gm 以外だよぉ

gm_keep_check_end:
	clr.l	d0
	movem.l	(sp)+,exec_register
	rts

gm_not_keep:
	pea	message_gm_not_keep
	bsr	_error_print
	addq.l	#4,sp
	moveq.l	#EXIT_ERROR_GM_NOT_KEEP,d0
	bra	main_end

*-------------------------------------------------------------------------------
* スクエア６４Ｋのチェック

	.text
square_64k_check:
	move.l	d1,-(sp)
	_TO_SUPER
	move.w	$e80028,d0
	and.w	#%111_00011111,d0
	moveq.l	#0,d1
	cmp.w	#$316,d0
	beq	@f
	moveq.l	#1,d1
	btst.b	#1,$e80028
	bne	@f
	btst.b	#1,$e82401
	bne	@f
	moveq.l	#-1,d1
@@:
	_TO_USER
	move.l	d1,d0
	move.l	(sp)+,d1
	rts

*-------------------------------------------------------------------------------
* デフォルト処理

	.text
main:
	movem.l	exec_register,-(sp)
	btst.l	#OPT_M,d7
	bne	main_mode

	bsr	square_64k_check
	tst.l	d0
	beq	@f
	bpl	main_mode

@@:
	clr.l	d0
	tst.l	d7
	bne	main_end

main_mode:
	move.w	#0,-(sp)		* ７６８×５１２にする
	move.w	#16,-(sp)
	DOS	__CONCTRL
	addq.l	#4,sp

	move.w	#2,-(sp)		* 画面クリア
	move.w	#10,-(sp)
	DOS	__CONCTRL
	addq.l	#4,sp

	clr.l	d0
main_end:
	movem.l	(sp)+,exec_register
	rts

*-------------------------------------------------------------------------------
* 内部モードで TGUSEMD をコールする

	.text
_gm_internal_tgusemd:
	swap.w	d1
	move.w	#_GM_INTERNAL_MODE,d1
	swap.w	d1
	IOCS	__TGUSEMD
	rts

*-------------------------------------------------------------------------------
* マクロ定義

_HSYNC_WAIT2	.macro
		.local	_HSYNC_WAIT2_loop
_HSYNC_WAIT2_loop:
	tst.b	$e88001
	bpl	_HSYNC_WAIT2_loop
	.endm

_HSYNC_WAIT	.macro
		.local	_HSYNC_WAIT_loop
_HSYNC_WAIT_loop:
	tst.b	$e88001
	bmi	_HSYNC_WAIT_loop
	_HSYNC_WAIT2
	.endm

*-------------------------------------------------------------------------------
* V-DISPをみて垂直表示期間は待つ

	.text
vdisp_wait:
	btst.b	#4,$e88001
	beq	vdisp_wait
vdisp_wait2:
	btst.b	#4,$e88001
	bne	vdisp_wait2
	rts

*-------------------------------------------------------------------------------
* CRTC 高速クリア実行
*
* entry:
*   d0.w = クリアページ指定
* broken:
*   d0.l, a0.l

	.text
crtc_gclr:
	lea	$e80480,a0
	move.w	d0,$e8002a
	moveq.l	#%0010,d0
	bclr.b	#3,$e80028
	move.w	d0,(a0)			* CRTC 高速クリア実行
@@:	move.w	(a0),d0
	btst.l	#1,d0
	beq	@b
	rts

*-------------------------------------------------------------------------------
* CRTC 高速クリア終了まで待つ
*
* broken:
*   d0.w, a0.l

	.text
crtc_gclr_wait:
	lea	$e80480,a0
@@:	move.w	(a0),d0
	btst.l	#1,d0
	bne	@b
	rts

*-------------------------------------------------------------------------------
* グラフィックのクリア（６４Ｋ色）
*
* return:
*   d0.l  = 0 なにもしてない。
*   d0.l != 0 処理完了

clear_64k_register	reg	d1-d2

	.text
clear_64k:
	movem.l	clear_64k_register,-(sp)
	_TO_SUPER
	move.l	$e80028,d1
	moveq.l	#$0f,d0
	bsr	vdisp_wait
	bsr	crtc_gclr
	bsr	crtc_gclr_wait
	move.l	d1,$e80028
	_TO_USER

	move.w	#_GM_MASK_CLEAR,d1	* グラフィックがなく、マスクは不要だから消去。
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	bsr	scroll_reset		* -r と併用時にスクロールリセット！
clear_64k_end:
	movem.l	(sp)+,clear_64k_register
	rts

*-------------------------------------------------------------------------------
* グラフィックのクリア（１６色）
* 
* return:
*   d0.l  = 0 なにもしてない。
*   d0.l != 0 処理完了

clear_16_register	reg	d1

	.text
clear_16:
	movem.l	clear_16_register,-(sp)
	_TO_SUPER
	move.l	$e80028,d1
	moveq.l	#$0f,d0			* ダミー
	bsr	vdisp_wait
	bsr	graphic_scroll_register_clear
	bsr	crtc_gclr		* 上半分クリア
	bsr	crtc_gclr_wait
	lea	$e80018,a0
	move.l	#512,d0
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	bsr	crtc_gclr		* 下半分クリア
	bsr	crtc_gclr_wait
	bsr	graphic_scroll_register_clear
	move.l	d1,$e80028
	_TO_USER
clear_16_end:
	movem.l	(sp)+,clear_16_register
	rts

*-------------------------------------------------------------------------------
* グラフィック・スクロール・レジスタの初期化

	.text
scroll_reset:
	_TO_SUPER
	bsr	graphic_scroll_register_clear
	_TO_USER
scroll_reset_end:
	rts

*-------------------------------------------------------------------------------
* グラフィック・スクロール・レジスタをクリアする

	.text
graphic_scroll_register_clear:
	lea	$e80018,a0
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	rts

*-------------------------------------------------------------------------------
* グラフィックパレットを６４Ｋ用に設定します

gpalette_set_register	reg	d0-d2/a0

	.text
gpalette_set:
	movem.l	gpalette_set_register,-(sp)
	lea	$e82000,a0
	move.l	#$00010001,d0
	move.l	#$02020202,d1
	moveq.l	#128-1,d2
	_HSYNC_WAIT
gpalette_set_loop:
	_HSYNC_WAIT2
	move.l	d0,(a0)+
	add.l	d1,d0
	dbra	d2,gpalette_set_loop
	movem.l	(sp)+,gpalette_set_register
	rts

*-------------------------------------------------------------------------------
* グラフィックパレットが６４Ｋ用のものか調べる
*
* return
*  d0.l  = 0 ６４Ｋのパレットです
*       != 0 設定値が違います

gpalette_check_register	reg	d1-d4/a0

	.text
gpalette_sum:
	.dc.l	0
gpalette_check:
	movem.l	gpalette_check_register,-(sp)
	lea	$e82000,a0
	move.w	#256-1,d2
	clr.l	d3
	clr.w	d4
	clr.w	d0
	_HSYNC_WAIT
gpalette_check_loop:
	_HSYNC_WAIT2
	move.w	(a0)+,d0
	add.l	d0,d3
	eor.w	d0,d4
	dbra	d2,gpalette_check_loop

	move.l	d3,gpalette_sum
	move.w	d4,d0
	ext.l	d0
gpalette_check_end:
	movem.l	(sp)+,gpalette_check_register
	rts

*-------------------------------------------------------------------------------
* ６４Ｋ色時のトーンダウン

	.text
tone_change_64k:
	move.l	opt_t_number,d0
	bne	@f
	bsr	tone_change_64k_sub_0
	bra	tone_change_64k_end
@@:
	cmp.b	#50,d0
	bne	@f
	bsr	tone_change_64k_sub_50
	bra	tone_change_64k_end
@@:
	cmp.b	#100,d0
	bne	@f
	bsr	tone_change_64k_sub_100
	bra	tone_change_64k_end
@@:
	bsr	tone_change_64k_sub
tone_change_64k_end:
	rts

*-------------------------------------------------------------------------------
* トーンダウン６４Ｋ

tone_change_64k_sub_register	reg	d1-d7/a1

	.bss
	.even
tone_64k_init:
	.ds.w	256
tone_64k_work:
	.ds.w	256

	.text
tone_change_64k_sub:
	movem.l	tone_change_64k_sub_register,-(sp)
	move.l	d0,d6			* ％
	_TO_SUPER
	lea	tone_64k_init,a0	* まず初期パレットを作る
	move.l	a0,a1
	move.l	#$00010001,d0
	move.l	#$02020202,d1
	moveq.l	#128-1,d2
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	move.l	d0,(a1)+
	add.l	d1,d0
	dbra	d2,@b

	lea	tone_64k_work,a1
	moveq.l	#%11111,d5
	moveq.l	#100,d4
	moveq.l	#%11,d3
	moveq.l	#128-1,d7
tone_change_64k_sub_loop:
	move.w	(a0)+,d0
	moveq.l	#%1,d2			* 奇数の I は常に 1

	ror.w	#1,d0			* Blue
	ror.w	#1,d2
	move.w	d0,d1
	and.w	d5,d1
	mulu.w	d6,d1
	divu.w	d4,d1
	or.w	d1,d2

	ror.w	#5,d0			* Red low
	ror.w	#5,d2
	move.w	d0,d1
	and.w	d3,d1
	mulu.w	d6,d1
	divu.w	d4,d1
	or.w	d1,d2

	ror.w	#3,d0			* Blue
	ror.w	#3,d2
	move.w	d0,d1
	and.w	d5,d1
	mulu.w	d6,d1
	divu.w	d4,d1
	or.w	d1,d2

	ror.w	#5,d0			* Red low
	ror.w	#5,d2
	move.w	d0,d1
	and.w	d3,d1
	mulu.w	d6,d1
	divu.w	d4,d1
	or.w	d1,d2

	ror.w	#2,d2
	move.w	d2,(a1)+

	move.w	(a0)+,d0

	move.w	d0,d1			* Red high
	and.w	#%111,d1
	mulu.w	d6,d1
	divu.w	d4,d1
	move.w	d1,d2

	ror.w	#3,d0			* Green
	ror.w	#3,d2
	move.w	d0,d1
	and.w	d5,d1
	mulu.w	d6,d1
	divu.w	d4,d1
	or.w	d1,d2

	ror.w	#5,d0			* Red high
	ror.w	#5,d2
	move.w	d0,d1
	and.w	#%111,d1
	mulu.w	d6,d1
	divu.w	d4,d1
	or.w	d1,d2

	ror.w	#3,d0			* Green
	ror.w	#3,d2
	move.w	d0,d1
	and.w	d5,d1
	mulu.w	d6,d1
	divu.w	d4,d1
	or.w	d1,d2

	ror.w	#5,d2
	move.w	d2,(a1)+
	dbra	d7,tone_change_64k_sub_loop

	move.w	#$003f,$e82600		* １００％
	lea	tone_64k_work,a1
	lea	$e82000,a0		* グラフィックパレットアドレス先頭
	move.l	#128-1,d0
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	move.l	(a1)+,(a0)+
	dbra	d0,@b

	_TO_USER
	movem.l	(sp)+,tone_change_64k_sub_register
	rts

*-------------------------------------------------------------------------------
* １００％の時はパレット初期化
*

	.text
tone_change_64k_sub_100:
	_TO_SUPER
	move.w	#$003f,$e82600		* １００％
	bsr	gpalette_set
	_TO_USER
	rts

*-------------------------------------------------------------------------------
* ５０％の時はパレット初期化＋擬似トーンダウン
*

	.text
tone_change_64k_sub_50:
	_TO_SUPER
	move.w	#$193f,$e82600		* ５０％
	bsr	gpalette_set
	_TO_USER
	rts

*-------------------------------------------------------------------------------
* ０％ならクリアする

	.text
tone_change_64k_sub_0:
	_TO_SUPER
	lea	$e82000,a0		* グラフィックパレットアドレス先頭
	move.w	#256-1,d0
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	clr.w	(a0)+
	dbra	d0,@b
	_TO_USER
	rts

*-------------------------------------------------------------------------------
* １６色時の処理（トーンダウン）

	.text
tone_change:
	move.w	#_GM_KEEP_PALETTE_GET,d1
	moveq.l	#-1,d2			* ダミーデータ(一応gmがない時のため)
	bsr	_gm_internal_tgusemd
	cmp.l	#-1,d0
	beq	tone_change_end		* gmが対応してない(versionが0.69以前)
	cmp.w	#_GM_INTERNAL_MODE,d0
	bne	tone_change_end
	swap.w	d0
	tst.w	d0
	beq	tone_change_end		* 常駐パレットは無効
					* （まだグラフィックがロードされてない）
					* 有効なら a1.l にアドレスが入っている

	move.l	opt_t_number,d0
	bne	@f
	bsr	tone_change_sub_0
	bra	tone_change_end
@@:
	cmp.b	#50,d0
	bne	@f
	bsr	tone_change_sub_50
	bra	tone_change_end
@@:
	cmp.b	#100,d0
	bne	@f
	bsr	tone_change_sub_100
	bra	tone_change_end
@@:
	bsr	tone_change_sub
tone_change_end:
	rts

*-------------------------------------------------------------------------------
* トーンダウンしましょ！
*
* entry:
*   d0.l = 常駐パレットに対する％（０～１００まで）
*   a1.l = 常駐パレットの先頭アドレス（内容を変更したらおしおき・・・）

tone_change_sub_register	reg	d1-d7

	.text
tone_change_sub:
	movem.l	tone_change_sub_register,-(sp)
	move.l	d0,d6			* ％
	_TO_SUPER
	moveq.l	#%11111,d5
	moveq.l	#100,d4
	lea	$e82000,a0		* グラフィックパレットアドレス先頭
	moveq.l	#16-1,d7
	_HSYNC_WAIT
tone_change_sub_loop:
	_HSYNC_WAIT2
	move.w	(a1)+,d0
	ror.w	#1,d0
	move.w	d0,d1
	and.l	d5,d1
	ror.w	#5,d0
	move.w	d0,d2
	and.l	d5,d2
	ror.w	#5,d0
	move.w	d0,d3
	and.l	d5,d3

	mulu.w	d6,d1
	divu.w	d4,d1
	mulu.w	d6,d2
	divu.w	d4,d2
	mulu.w	d6,d3
	divu.w	d4,d3

	lsl.w	#5,d3
	or.w	d2,d3
	lsl.w	#5,d3
	or.w	d1,d3
	add.w	d3,d3
	_HSYNC_WAIT2
	move.w	d3,(a0)+
	dbra	d7,tone_change_sub_loop
	_TO_USER
	movem.l	(sp)+,tone_change_sub_register
	rts

*-------------------------------------------------------------------------------
* １００％の時は常駐パレットそのまま
*
* entry:
*   a1.l = 常駐パレットの先頭アドレス（内容を変更したらおしおき・・・）

	.text
tone_change_sub_100:
	_TO_SUPER
	lea	$e82000,a0		* グラフィックパレットアドレス先頭
	moveq.l	#16-1,d0
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	move.w	(a1)+,(a0)+
	dbra	d0,@b
	_TO_USER
	rts

*-------------------------------------------------------------------------------
* ５０％の時は高速処理（デフォルト）
*
* entry:
*   a1.l = 常駐パレットの先頭アドレス（内容を変更したらおしおき・・・）

	.text
tone_change_sub_50:
	_TO_SUPER
	lea	$e82000,a0		* グラフィックパレットアドレス先頭
	move.w	#%01111_01111_01111_0,d1
	moveq.l	#16-1,d0
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	move.w	(a1)+,d2
	lsr.w	#1,d2
	and.w	d1,d2
	_HSYNC_WAIT2
	move.w	d2,(a0)+
	dbra	d0,@b
	_TO_USER
	rts

*-------------------------------------------------------------------------------
* ０％ならクリアする

	.text
tone_change_sub_0:
	_TO_SUPER
	lea	$e82000,a0		* グラフィックパレットアドレス先頭
	moveq.l	#16-1,d0
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	clr.w	(a0)+
	dbra	d0,@b
	_TO_USER
	rts

*-------------------------------------------------------------------------------
* ６４Ｋ色時の処理

	.text
shrink:
	movem.l	exec_register,-(sp)
	bsr	mode_check
	tst.w	d0
	beq	shrink_16		* １６色なら実行しない

	clr.l	d0
	btst.l	#OPT_S,d7
	beq	shrink_end

	move.l	#513*1024,-(sp)		* ３ライン毎だから５１３
	DOS	__MALLOC
	addq.l	#4,sp
	tst.l	d0
	bmi	program_error_malloc	* 致命的エラー
	move.l	d0,-(sp)
	move.l	d0,a0

	bsr	shrink_sub

	move.l	(sp)+,d0
	move.l	d0,-(sp)
	DOS	__MFREE
	addq.l	#4,sp
	tst.l	d0
	bmi	program_error_mfree	* 致命的エラー
shrink_end:
	movem.l	(sp)+,exec_register
	rts

shrink_16:
	clr.l	d0
	bra	shrink_end

*-------------------------------------------------------------------------------
* グラフィックの画像を縮める
*
* entry:
*   a0.l = buffer top address

	.text
shrink_sub:
	_TO_SUPER
	move.l	opt_s_number,d0
	tst.l	d0
	beq	shrink_sub_0
	subq.l	#1,d0
	beq	shrink_sub_1
	bra	shrink_sub_complete	* こんなはずはないが・・・

shrink_sub_0:
	bsr	gram_to_buffer
	bsr	buffer_shrink_to_gram
	bra	shrink_sub_complete

shrink_sub_1:
	bsr	gram_to_buffer_not_clear
	bsr	buffer_shrink_to_gram
	bsr	gram_clear

shrink_sub_complete:
	_TO_USER
	rts

*-------------------------------------------------------------------------------
* マクロ定義
*
*   グラフィック１ライン消去×２（上下）

GLINE_CLEAR	.macro
		.local	gline_clear_loop
	moveq.l	#0,d2
	move.l	d2,d3
	move.l	d2,d4
	move.l	d2,d5
	move.l	d2,d6
	move.l	d2,d7
	move.l	d2,a5
	move.l	d2,a6
	moveq.l	#32-1,d1
gline_clear_loop:
	movem.l	d2-d7/a5-a6,-(a3)
	movem.l	d2-d7/a5-a6,-(a4)
	dbra	d1,gline_clear_loop
	.endm

*-------------------------------------------------------------------------------
* ＧＲＡＭの内容をバッファに取り込む（クリアしない版）
*
* entry:
*   a0.l = buffer top address

gram_to_buffer_not_clear_register	reg	d0-d7/a0-a6

	.text
gram_to_buffer_not_clear:
	movem.l	gram_to_buffer_not_clear_register,-(sp)

	move.l	a0,a1
	move.l	a0,a2			* 最終ラインは２重取り込み
	move.w	#32,a0
	add.l	#$0007fc00,a2
	lea	$c00000,a3
	lea	$c7fc00,a4
	moveq.l	#(32-1)-1,d1
gram_to_buffer_not_clear_start_loop:
	movem.l	(a4)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a2)
	movem.l	d2-d7/a5-a6,$400(a2)
	add.w	a0,a2
	dbra	d1,gram_to_buffer_not_clear_start_loop

	movem.l	(a4)+,d2-d7/a5
	move.l	(a4)+,a6
	movem.l	d2-d7/a5-a6,(a2)
	movem.l	d2-d7/a5-a6,$400(a2)
	add.w	a0,a2

	move.w	#(512-1)-1,d0		* 残りのラインを取り込む
gram_to_buffer_not_clear_loop:
	moveq.l	#32-1,d1		* １ライン転送
gram_to_buffer_not_clear_loop1:
	movem.l	(a3)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a1)
	add.w	a0,a1
	dbra	d1,gram_to_buffer_not_clear_loop1
	dbra	d0,gram_to_buffer_not_clear_loop

	movem.l	(sp)+,gram_to_buffer_not_clear_register
	rts

*-------------------------------------------------------------------------------
* 隙間のみグラフィック消去

gram_clear_register	reg	d0-d7/a0-a6

	.text
gram_clear:
	movem.l	gram_clear_register,-(sp)
	lea	$c00000,a3
	move.l	a3,a4
	add.l	#(255-171+1)*1024,a3	* GRAMの位置（上）
	add.l	#(256+171+1)*1024,a4	* GRAMの位置（下）
	move.w	#32,a0
	moveq.l	#0,d2
	move.l	d2,d3
	move.l	d2,d4
	move.l	d2,d5
	move.l	d2,d6
	move.l	d2,d7
	move.l	d2,a5
	move.l	d2,a6

	move.w	#255-171,d0		* 隙間を埋める
gram_clear_loop:
	move.w	#(1024/32)-1,d1		* １ライン消去
gram_clear_loop1:
	movem.l	d2-d7/a5-a6,-(a3)
	movem.l	d2-d7/a5-a6,-(a4)
	dbra	d1,gram_clear_loop1
	lea	$800(a4),a4
	dbra	d0,gram_clear_loop
gram_clear_end:
	movem.l	(sp)+,gram_clear_register
	rts

*-------------------------------------------------------------------------------
* ＧＲＡＭの内容をバッファに取り込む
*
* entry:
*   a0.l = buffer top address

gram_to_buffer_register	reg	d0-d7/a0-a6

	.text
gram_to_buffer:
	movem.l	gram_to_buffer_register,-(sp)

	move.l	a0,a1			* 最初の１ラインを取り出す
	move.l	a0,a2			* 最終ラインは２重取り込み
	move.w	#32,a0
	add.l	#$0007fc00,a2
	lea	$c00000,a3
	lea	$c7fc00,a4
	moveq.l	#(32-1)-1,d1
gram_to_buffer_start_loop:
	movem.l	(a3)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a1)
	movem.l	(a4)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a2)
	movem.l	d2-d7/a5-a6,$400(a2)
	add.w	a0,a1
	add.w	a0,a2
	dbra	d1,gram_to_buffer_start_loop

	movem.l	(a3)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a1)
	movem.l	(a4)+,d2-d7/a5
	move.l	(a4)+,a6
	movem.l	d2-d7/a5-a6,(a2)
	movem.l	d2-d7/a5-a6,$400(a2)
	add.w	a0,a1
	add.w	a0,a2

	GLINE_CLEAR

	lea	$400(a3),a3
	lea	$fffffc00(a4),a4
	lea	$fffff800(a2),a2

	move.w	#(256-1)-1,d0		* 残りのラインを取り込む
gram_to_buffer_loop:
	moveq.l	#32-1,d1		* １ライン転送
gram_to_buffer_loop1:
	movem.l	(a3)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a1)
	movem.l	(a4)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a2)
	add.w	a0,a1
	add.w	a0,a2
	dbra	d1,gram_to_buffer_loop1

	GLINE_CLEAR

	lea	$400(a3),a3
	lea	$fffffc00(a4),a4
	lea	$fffff800(a2),a2
	dbra	d0,gram_to_buffer_loop

	movem.l	(sp)+,gram_to_buffer_register
	rts

*-------------------------------------------------------------------------------
* バッファの内容を縦圧縮してＧＲＡＭに書き込む
*
* entry:
*   a0.l = buffer top address

buffer_shrink_to_gram_register	reg	d0-d7/a0-a6

	.text
buffer_shrink_to_gram:
	movem.l	buffer_shrink_to_gram_register,-(sp)

	move.l	a0,a1
	move.l	a0,a2
	add.l	#255*1024,a1		* 初期バッファ位置（上）
	add.l	#257*1024,a2		* 初期バッファ位置（下）
	lea	$c3fc00,a3		* GRAMの位置（上）
	lea	$c40000,a4		* GRAMの位置（下）

	lea	shrink_div3_table_g,a0	* 割り算テーブル
	lea	shrink_div3_table_r,a5
	lea	shrink_div3_table_b,a6

	move.w	#%1111100000111110,d4	* パレットマスク
	move.w	#%0000011111000000,d5
	clr.w	d6			* Ｇ、Ｂを同時に計算するのでその時使うワークレジスタ
					* d6.w の上位バイトは常に０にする

	bsr	shrink_put_down		* ちょうど真ん中
	move.w	#((513/3)/2)-1,d7	* ループ数
buffer_shrink_to_gram_loop:
	bsr	shrink_put_up
	bsr	shrink_put_down
	dbra	d7,buffer_shrink_to_gram_loop

	movem.l	(sp)+,buffer_shrink_to_gram_register
	rts

*-------------------------------------------------------------------------------
* 画面半分より上に表示するやつを上のラインと混ぜる

	.text
shrink_put_up:
	exg.l	a1,a2
	exg.l	a3,a4
	bsr	shrink_put_sub
	exg.l	a1,a2
	exg.l	a3,a4
	lea	$fffff400(a1),a1
	lea	$00000400(a2),a2
	lea	$fffff800(a3),a3
	rts

*-------------------------------------------------------------------------------
* 画面半分より上に表示するやつを下のラインと混ぜる

	.text
shrink_put_down:
	bsr	shrink_put_sub
	lea	$fffff800(a1),a1
	lea	$fffff800(a3),a3
	rts

*-------------------------------------------------------------------------------
* ２：１の割合で上または下のラインと混ぜる
*
* entry:
*   a1.l = バッファアドレス（下と混ぜる）
*   a2.l = バッファアドレス（上と混ぜる）
*   a3.l = ＧＲＡＭアドレス（下と混ぜる）
*   a4.l = ＧＲＡＭアドレス（上と混ぜる）
*
*   ☆このルーチンが速度をだいぶ落としている

	.data
	.even
					* ここのテーブルが高速化のポイント
	.ifndef	__SHRINK_HIGH_SPEED__
shrink_div3_table_g:
_DIV3_COUNT	set	0
	.rept	32
	.dc.w	(_DIV3_COUNT<<11),(_DIV3_COUNT<<11),(_DIV3_COUNT<<11)
_DIV3_COUNT	set	_DIV3_COUNT+1
	.endm

shrink_div3_table_r:
_DIV3_COUNT	set	0
	.rept	32
	.dc.w	(_DIV3_COUNT<<6),(_DIV3_COUNT<<6),(_DIV3_COUNT<<6)
_DIV3_COUNT	set	_DIV3_COUNT+1
	.endm

	.else

shrink_div3_table_g:
shrink_div3_table_r	equ	*+2
_DIV3_COUNT	set	0
	.rept	32
	.dc.w	(_DIV3_COUNT<<11)
	.dc.w	(_DIV3_COUNT<<6)
		.rept	32-2
		.dc.w	0
		.endm
	.dc.w	(_DIV3_COUNT<<11)
	.dc.w	(_DIV3_COUNT<<6)
		.rept	32-2
		.dc.w	0
		.endm
	.dc.w	(_DIV3_COUNT<<11)
	.dc.w	(_DIV3_COUNT<<6)
		.rept	32-2
		.dc.w	0
		.endm
_DIV3_COUNT	set	_DIV3_COUNT+1
	.endm
	.endif		* for __SHRINK_HIGH_SPEED__

shrink_div3_table_b:
_DIV3_COUNT	set	0
	.rept	32
	.dc.w	(_DIV3_COUNT<<1),(_DIV3_COUNT<<1),(_DIV3_COUNT<<1)
_DIV3_COUNT	set	_DIV3_COUNT+1
	.endm

	.text
shrink_put_sub:
	move.w	#512-1,d1
shrink_put_sub_loop:
	move.w	$400(a1),d2		* ２分の１で混ぜ合わせるカラー
	move.w	(a1),d0			* ベースカラー

	move.w	d2,d3
	and.w	d4,d0
	and.w	d4,d3
	ror.w	#1,d3
	add.w	d3,d0

	move.b	d0,d6			* 順番注意 Ｘフラグにデータ取ってるので
	sf.b	d0			* add.w d6,d6 が先だと画像が変になる
	.ifndef	__SHRINK_HIGH_SPEED__
	roxl.w	#8,d0
	.else
	roxr.w	#4,d0
	.endif
	move.w	(a0,d0.w),d0
	add.w	d6,d6
	or.w	(a6,d6.w),d0

	move.w	(a1)+,d3
	and.w	d5,d3
	and.w	d5,d2
	add.w	d3,d3
	add.w	d2,d3

	.ifndef	__SHRINK_HIGH_SPEED__
	ror.w	#5,d3
	.endif

	or.w	(a5,d3.w),d0
	move.w	d0,(a3)+

	move.w	$fffffc00(a2),d2	* ２分の１で混ぜ合わせるカラー
	move.w	(a2),d0			* ベースカラー

	move.w	d2,d3
	and.w	d4,d0
	and.w	d4,d3
	ror.w	#1,d3
	add.w	d3,d0

	move.b	d0,d6			* 順番注意 Ｘフラグにデータ取ってるので
	sf.b	d0			* add.w d6,d6 が先だと画像が変になる
	.ifndef	__SHRINK_HIGH_SPEED__
	roxl.w	#8,d0
	.else
	roxr.w	#4,d0
	.endif
	move.w	(a0,d0.w),d0
	add.w	d6,d6
	or.w	(a6,d6.w),d0

	move.w	(a2)+,d3
	and.w	d5,d3
	and.w	d5,d2
	add.w	d3,d3
	add.w	d2,d3

	.ifndef	__SHRINK_HIGH_SPEED__
	ror.w	#5,d3
	.endif

	or.w	(a5,d3.w),d0
	move.w	d0,(a4)+

	dbra	d1,shrink_put_sub_loop
	rts

*-------------------------------------------------------------------------------

	.ifndef	__OS_VERCHK__
*-------------------------------------------------------------------------------
* デフォルト・・・

	.text
program_ver_check:
	rts

*-------------------------------------------------------------------------------
	.else
	.ifndef	__HUMAN_V2__
*-------------------------------------------------------------------------------
* ＯＳのバージョンチェック

	.data
message_ver_error:
	.dc.b	'ＯＳのバージョンが古すぎるぅ',13,10
	.dc.b	'Human68k version 3.00以降を使ってね。',13,10,0

	.text
program_ver_check:
	DOS	__VERNUM
	cmp.w	#$0300,d0
	bcs	program_ver_check_error
	rts
program_ver_check_error:
	pea	message_ver_error
	DOS	__PRINT
	addq.l	#4,sp
	move.w	#EXIT_ERROR_OS_VERSION,-(sp)
	DOS	__EXIT2

	.else
*-------------------------------------------------------------------------------

	.data
message_ver_error:
	.dc.b	'ＯＳのバージョンが新しすぎるぅ',13,10
	.dc.b	'Human68k version 3.00以前を使ってね。',13,10,0

	.text
program_ver_check:
	DOS	__VERNUM
	cmp.w	#$0300,d0
	bcc	program_ver_check_error
	rts
program_ver_check_error:
	pea	message_ver_error
	DOS	__PRINT
	addq.l	#4,sp
	move.w	#EXIT_ERROR_OS_VERSION,-(sp)
	DOS	__EXIT2

*-------------------------------------------------------------------------------
	.endif		* for __HUMAN_V2__
	.endif		* for __OS_VERCHK__


*-------------------------------------------------------------------------------
* エラー処理

	.data
message_program_error:
	.dc.b	'強制終了します。',13,10
	.dc.b	0

	.text
program_error:
	move.w	d0,-(sp)
	move.l	a0,-(sp)
	DOS	__PRINT
	addq.l	#4,sp
	pea	message_program_error
	DOS	__PRINT
	addq.l	#4,sp
	DOS	__EXIT2

	.data
message_program_error_setblock:
	.dc.b	'メモリブロックの変更ができません。',13,10
	.dc.b	0
message_program_error_malloc:
	.dc.b	'メモリブロックが確保できません。',13,10
	.dc.b	0
message_program_error_mfree:
	.dc.b	'メモリブロックが解放できません。',13,10
	.dc.b	0

	.text
program_error_setblock:
	lea	message_program_error_setblock,a0
	move.w	#EXIT_ERROR_SETBLOCK,d0
	bra	program_error

program_error_malloc:
	lea	message_program_error_malloc,a0
	move.w	#EXIT_ERROR_MALLOC,d0
	bra	program_error

program_error_mfree:
	lea	message_program_error_mfree,a0
	move.w	#EXIT_ERROR_MFREE,d0
	bra	program_error

*-------------------------------------------------------------------------------


*
	.text
	.even
program_text_end:
	.data
	.even
program_data_end:
	.bss
	.even
program_bss_end:
	.stack
	.even
program_stack_end:
	.text
*

	.end	program_start
