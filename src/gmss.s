* $Id: gmss.s,v 1.1 1994/09/13 21:58:45 JACK Exp $


PATCHLEVEL:	.reg	'2'


* Include File -------------------------------- *

		.include	iocscall.mac
		.include	doscall.mac
		.include	gm_internal.mac


*-------------------------------------------------------------------------------
* 終了コードの定義

			.offset	0
EXIT_NO_ERROR:		.ds.b	1
EXIT_ERROR_OPTION:	.ds.b	1
EXIT_ERROR_SETBLOCK:	.ds.b	1
EXIT_ERROR_MALLOC:	.ds.b	1
EXIT_ERROR_MFREE:	.ds.b	1
EXIT_ERROR_GM_NOT_KEEP:	.ds.b	1
			.text

*-------------------------------------------------------------------------------
* マクロ定義

PUSH:		.macro	regs
		movem.l	regs,-(sp)
		.endm
POP:		.macro	regs
		movem.l	(sp)+,regs
		.endm

TAB:		.equ	$09
LF:		.equ	$0a
CR:		.equ	$0d
SPACE:		.equ	$20
		.ifdef	__CRLF__
CRLF:		.reg	CR,LF
		.else
CRLF:		.reg	LF
		.endif

* スーパーバイザーモードへ
_TO_SUPER:	.macro
		clr.l	-(sp)
		DOS	_SUPER
		move.l	d0,(sp)
		.endm

* ユーザーモードへ
_TO_USER:	.macro
		.local	to_user_skip
		tst.b	(sp)
		bmi	to_user_skip
		DOS	_SUPER
to_user_skip:	addq.l	#4,sp
		.endm

DEBUG_PRINT:	.macro	mes
		.ifdef	__DEBUG__
		move.l	d0,-(sp)
		pea	mes
		DOS	_PRINT
		addq.l	#4,sp
		move.l	(sp)+,d0
		.endif
		.endm

STACK_SIZE:	.equ	8192


* I/O Address --------------------------------- *

GVRAM:		.equ	$c00000

CRTC_R12:	.equ	$e80018
CRTC_R20:	.equ	$e80028
CRTC_R20H:	.equ	$e80028
CRTC_R21:	.equ	$e8002a
CRTC_ACT:	.equ	$e80480

G_PALET:	.equ	$e82000

VC_R0:		.equ	$e82400
VC_R0L:		.equ	$e82401
VC_R2:		.equ	$e82600
VC_R2L:		.equ	$e82601

MFP_GPIP:	.equ	$e88001


*-------------------------------------------------------------------------------

		.text
program_text_start:
		.data
program_data_start:
		.bss
program_bss_start:
		.stack
program_stack_start:
		.text


*-------------------------------------------------------------------------------
* タイトルメッセージ

		.data
message_title:
version_mes:	.dc.b	'GM Set Screen version 0.62 patchlevel ',PATCHLEVEL
version_mes_end:
		.dc.b	' programmed by JACK, Copyright (C) 2025 TcbnErik.'
		.dc.b	CRLF,0

*-------------------------------------------------------------------------------
* オプションスイッチの定義

		.offset	0
OPT_C:		.ds.b	1	* グラフィックのクリア
OPT_R:		.ds.b	1	* グラフィック・スクロール・レジスタの初期化
OPT_G:		.ds.b	1	* グラフィック表示のオンオフ
OPT_S:		.ds.b	1	* ６４Ｋ色グラフィックの縦圧縮
OPT_T:		.ds.b	1	* グラフィックのトーンダウン
OPT_M:		.ds.b	1	* 画面モードの初期化
OPT_V:		.ds.b	1	* バージョン表示、メッセージの表示
OPT_HLP:	.ds.b	1	* ヘルプ表示
		.fail	15<=$
OPT_ERR:	.equ	15	* スイッチ指定の間違いなど：常に最上位ビット
		.text

*-------------------------------------------------------------------------------
* ここからメインプログラム

		.text
		.even
program_start:
		lea	(16,a0),a0
		lea	(STACK_SIZE,a1),a1
		suba.l	a0,a1
		move.l	a1,-(sp)
		move.l	a0,-(sp)
		DOS	_SETBLOCK
		addq.l	#8,sp
		tst.l	d0
		bmi	program_error_setblock
		lea	(a0,a1.l),sp

		moveq	#0,d7			* d7.l = オプションスイッチ
		bsr	option_check
		cmpi	#1<<OPT_V,d7
		beq	print_version
		bra	exec_option

print_version:
		lea	(version_mes_end,pc),a0
		.ifdef	__CRLF__
		move.b	#CR,(a0)+
		.endif
		move.b	#LF,(a0)+
		clr.b	(a0)
		pea	(version_mes,pc)
		DOS	_PRINT
		DOS	_EXIT


*-------------------------------------------------------------------------------
* オプションスイッチの読み取り＆設定

		.text
option_check:
		pea	(1,a2)
		bsr	GetArgCharInit
		addq.l	#4,sp
option_check_loop:
		bsr	GetArgChar
		tst.l	d0
		beq	option_check_loop
		bmi	option_check_end
		cmpi.b	#'-',d0
		bne	option_check_error

		bsr	GetArgChar
		cmpi.b	#'-',d0
		beq	long_option
		bra	@f
option_check_next:
		bsr	GetArgChar
option_check_next2:
		tst.l	d0
		beq	option_check_loop
		bmi	option_check_end
@@:
		cmpi.b	#'?',d0
		beq	opt_h

		andi.b	#$df,d0
		cmpi.b	#'V',d0
		beq	opt_v
		cmpi.b	#'C',d0
		beq	opt_c
		cmpi.b	#'R',d0
		beq	opt_r
		cmpi.b	#'G',d0
		beq	opt_g
		cmpi.b	#'S',d0
		beq	opt_s
		cmpi.b	#'T',d0
		beq	opt_t
		cmpi.b	#'M',d0
		beq	opt_m
		cmpi.b	#'H',d0
		beq	opt_h
option_check_error:
		bset	#OPT_ERR,d7
option_check_end:
		rts

opt_h:
		ori	#1<<OPT_HLP+1<<OPT_V,d7
		bra	option_check_loop

opt_c:		moveq	#OPT_C,d0
		bra	@f
opt_r:		moveq	#OPT_R,d0
		bra	@f
opt_m:		moveq	#OPT_M,d0
		bra	@f
opt_v:		moveq	#OPT_V,d0
		bra	@f
@@:		bset	d0,d7
		bra	option_check_loop

long_option:
		bsr	GetArgChar
		moveq	#OPT_HLP,d1
		lea	(str_help,pc),a1
		cmp.b	(a1)+,d0
		beq	long_option_loop
		moveq	#OPT_V,d1
		lea	(str_version,pc),a1
		bra	@f
long_option_loop:
		bsr	GetArgChar
@@:		cmp.b	(a1)+,d0
		bne	option_check_error
		tst.b	d0
		bne	long_option_loop
		bset	d1,d7
		bra	option_check_loop

		.data

str_help:	.dc.b	'help',0
str_version:	.dc.b	'version',0

		.even
opt_g_number:	.dc	1
opt_s_number:	.dc	0
opt_t_number:	.dc	50

		.text

opt_g:		moveq	#OPT_G,d0
		lea	(opt_g_number,pc),a1
		moveq	#3,d2
		bra	get_opt_num

opt_s:		moveq	#OPT_S,d0
		lea	(opt_s_number,pc),a1
		moveq	#1,d2
		bra	get_opt_num

opt_t:		moveq	#OPT_T,d0
		lea	(opt_t_number,pc),a1
		moveq	#100,d2
get_opt_num:
		bset	d0,d7
		bra	opt_number


*-------------------------------------------------------------------------------
* 数値を読み取ってワークにしまう
*
* entry:
*   d2.l = 最大数値
*   a1.l = 数値を保存するワークエリアのアドレス(１ワード)
* break:
*   d0.l/d1.l

	.text
opt_number:
		moveq	#0,d1
opt_number_loop:
		bsr	GetArgChar
		cmpi.b	#'0',d0
		bcs	option_check_next2
		cmpi.b	#'9',d0
		bhi	option_check_next2

		subi.b	#'0',d0
		mulu	#10,d1
		add	d0,d1
		move	d1,(a1)
		cmp.l	d1,d2
		bcc	opt_number_loop
		bra	option_check_error


*-------------------------------------------------------------------------------
* 引数収得

		.text
		.even

GetArgChar_p:	.dc.l	0
GetArgChar_c:	.dc.b	0
		.even

GetArgChar:
		movem.l	d1/a0-a1,-(sp)
		moveq	#0,d0
		lea	(GetArgChar_p,pc),a0
		movea.l	(a0)+,a1
		move.b	(a0),d0
		bmi	GetArgChar_noarg
GetArgChar_quate:
		move.b	d0,d1
GetArgChar_next:
		move.b	(a1)+,d0
		beq	GetArgChar_endarg
		tst.b	d1
		bne	GetArgChar_inquate
		cmpi.b	#' ',d0
		beq	GetArgChar_separate
		cmpi.b	#"'",d0
		beq	GetArgChar_quate
		cmpi.b	#'"',d0
		beq	GetArgChar_quate
GetArgChar_end:
		move.b	d1,(a0)
		move.l	a1,-(a0)
GetArgChar_abort:
		movem.l	(sp)+,d1/a0-a1
		rts
GetArgChar_endarg:
		st	(a0)
		bra	GetArgChar_abort
GetArgChar_noarg:
		moveq	#1,d0
		ror.l	#1,d0
		bra	GetArgChar_abort

GetArgChar_inquate:
		cmp.b	d0,d1
		bne	GetArgChar_end
		clr.b	d1
		bra	GetArgChar_next

GetArgChar_separate:
		cmp.b	(a1)+,d0
		beq	GetArgChar_separate
		moveq	#0,d0
		tst.b	-(a1)
		beq	GetArgChar_endarg
		bra	GetArgChar_end

GetArgCharInit:
		movem.l	a0-a1,-(sp)
		movea.l	(12,sp),a1
GetArgCharInit_skip:
		cmpi.b	#' ',(a1)+
		beq	GetArgCharInit_skip
		tst.b	-(a1)
		lea	(GetArgChar_c,pc),a0
		seq	(a0)
		move.l	a1,-(a0)
		movem.l	(sp)+,a0-a1
		rts


*-------------------------------------------------------------------------------
* プログラムを実行しちゃうんです

		.data
		.even
exec_table:
		.dc	title-$
		.dc	error-$
		.dc	help-$
		.dc	gm_keep_check-$
		.dc	graphic_onoff-$
		.dc	shrink-$
		.dc	tone-$
		.dc	clear-$
		.dc	scroll-$
		.dc	main-$
		.dc	0

		.ifdef	__DEBUG__
message_exit:	.dc.b	'debug:ちゃんと終わりました。',CRLF,0
message_exit2:	.dc.b	'debug:エラーがでちゃったぁ。',CRLF,0
		.endif

		.text
exec_option:
		.ifdef	__DEBUG__
		bset	#OPT_V,d7
		.endif

		lea	(exec_table,pc),a1
exec_option_loop:
		move	(a1)+,d0
		beq	exec_option_end

		move.l	a1,-(sp)	;save
		jsr	(-2,a1,d0.w)
		movea.l	(sp)+,a1	;restore
		tst.l	d0
		beq	exec_option_loop
*exec_option_exit:
		DEBUG_PRINT	(message_exit2,pc)
		move	d0,-(sp)
		DOS	_EXIT2

exec_option_end:
		DEBUG_PRINT	(message_exit,pc)
		DOS	_EXIT


*-------------------------------------------------------------------------------
* 起動時のタイトル表示

	.text
title:
		move	#1<<OPT_ERR+1<<OPT_HLP+1<<OPT_V,d0
		and	d7,d0
		beq	title_end

		pea	(message_title,pc)
		DOS	_PRINT
		addq.l	#4,sp
title_end:
		moveq	#0,d0
		rts

*-------------------------------------------------------------------------------
* スイッチの指定が間違っていた時のエラーメッセージ表示

		.data
message_error:
		.dc.b	'スイッチの指定が間違ってます.',CRLF,0

		.text
error:
		moveq	#0,d0
		btst	#OPT_ERR,d7
		beq	error_end

		pea	(message_error,pc)
		DOS	_PRINT
		addq.l	#4,sp

		moveq	#EXIT_ERROR_OPTION,d0
error_end:
		rts

*-------------------------------------------------------------------------------
* ヘルプメッセージの表示

		.data
message_help:
	.dc.b	'usage: gmss [option]',CRLF
	.dc.b	'option:',CRLF
	.dc.b	'	-c	グラフィックのクリア',CRLF
	.dc.b	'	-r	グラフィック・スクロール・レジスタの初期化',CRLF
	.dc.b	'	-g[n]	グラフィックの表示 (0:オフ [1]:オン 2:16色 3:64K色)',CRLF
	.dc.b	'	-s[n]	６４Ｋ色グラフィックの縦圧縮 (n:[0]-1)',CRLF
	.dc.b	'	-t[n]	グラフィックのトーンダウン (n:0-[50]-100)',CRLF
	.dc.b	'	-m	画面モード初期化をする',CRLF
**	.dc.b	'	-v	バージョン表示、メッセージ表示',CRLF
**	.dc.b	'	-h	ヘルプメッセージ',CRLF
	.dc.b	0

		.text
help:
		btst	#OPT_HLP,d7
		beq	help_end

		pea	(message_help,pc)
		DOS	_PRINT
		addq.l	#4,sp

		DOS	_EXIT
help_end:
		moveq	#0,d0
		rts

*-------------------------------------------------------------------------------
* グラフィック画面のオンオフ

	.text
graphic_onoff:
	_TO_SUPER
	btst	#OPT_G,d7
	beq	graphic_onoff_end

	move	(opt_g_number,pc),d0
	bne	@f
;-g0
	andi	#$ffe0,(VC_R2)		;表示オフ
	bset	#3,(CRTC_R20H)
	bra	graphic_onoff_end
@@:
	subq	#2,d0
	bne	@f
;-g2
	moveq	#4,d0			;強制16色
	move.b	d0,(CRTC_R20H)
	move	d0,(VC_R0)
	bra	graphic_onoff_16
@@:
	subq	#1,d0
	bne	@f
;-g3
	moveq	#3,d0			;強制64K色
	move.b	d0,(CRTC_R20H)
	move	d0,(VC_R0)
	bra	graphic_onoff_64k
@@:
;-g1
	bclr	#3,(CRTC_R20H)
	btst	#1,(CRTC_R20H)
	beq	graphic_onoff_16	;16/256色

	moveq	#3,d0
	or.b	d0,(CRTC_R20H)
	move	d0,(VC_R0)
graphic_onoff_64k:
	lea	(CRTC_R12),a0		* ６４Ｋなら位置補正＋トーンダウン
	move.l	#($ff80<<16)+0,d0
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+

	moveq	#0,d1
	move.b	(VC_R2L),d1

	bsr	gpalette_check
	tst.l	d0
	bne	@f
	move.l	(gpalette_sum,pc),d0
	cmpi.l	#$007f8000,d0
	bne	@@f			* FLAME.Xで変更中
@@:
	ori	#$1900,d1
@@:
	move	d1,(VC_R2)

	moveq	#.low._GM_AUTO_STATE,d1
	bsr	_gm_internal_tgusemd
	cmp.l	#-1,d0
	beq	@f
	cmpi	#_GM_INTERNAL_MODE,d0
	bne	@f
	swap	d0
	lsr	#1,d0
	bcs	@f			* マスク禁止
	lsr	#1,d0
	bcc	@f			* マスク許可しない

	moveq	#.low._GM_MASK_SET,d1
	bsr	_gm_internal_tgusemd
@@:
graphic_onoff_16:
	ori	#$003f,(VC_R2)		* オン

graphic_onoff_end:
	_TO_USER
	moveq	#0,d0
	rts

*-------------------------------------------------------------------------------
* トーン

		.text
tone:
	btst	#OPT_T,d7
	beq	tone_end

	bsr	mode_check
	tst	d0
	beq	@f

	bsr	tone_change_64k
	bra	tone_end
@@:
	bsr	tone_change
tone_end:
	moveq	#0,d0
	rts

*-------------------------------------------------------------------------------
* クリア

		.text
clear:
	btst	#OPT_C,d7
	beq	clear_end

	bsr	mode_check
	tst	d0
	beq	@f

	bsr	clear_64k		* スクロールリセットを含む
	bra	clear_end
@@:
	bsr	clear_16
clear_end:
	moveq	#0,d0
	rts

*-------------------------------------------------------------------------------
* スクロール

	.text
scroll:
	btst	#OPT_R,d7
	beq	scroll_end

	bsr	mode_check
	tst	d0
	bne	scroll_end		;64K色なら初期化しない

	bsr	scroll_reset
scroll_end:
	moveq	#0,d0
	rts

*-------------------------------------------------------------------------------
* モードチェック

	.text
mode_check:
	PUSH	d1-d2
	moveq	#.low._GM_GRAPHIC_MODE_STATE,d1
	bsr	_gm_internal_tgusemd
	cmp.l	#-1,d0
	beq	@f
	swap	d0
@@:
	POP	d1-d2
	rts

*-------------------------------------------------------------------------------
* 常駐チェック

		.data
message_gm_not_keep:
		.dc.b	'gm が常駐していません.',CRLF,0

		.text
gm_keep_check:
	moveq	#.low._GM_VERSION_NUMBER,d1
	bsr	_gm_internal_tgusemd
	cmpi.l	#-1,d0
	beq	gm_not_keep		* gm がないよぉ
	cmpi	#_GM_INTERNAL_MODE,d0
	bne	gm_not_keep		* gm 以外だよぉ

gm_keep_check_end:
	moveq	#0,d0
	rts

gm_not_keep:
	pea	(message_gm_not_keep,pc)
	DOS	_PRINT
	addq.l	#4,sp
	moveq	#EXIT_ERROR_GM_NOT_KEEP,d0
	rts

*-------------------------------------------------------------------------------
* スクエア６４Ｋのチェック

	.text
square_64k_check:
	move.l	d1,-(sp)
	_TO_SUPER
	move	(CRTC_R20),d0
	andi	#%111_0001_1111,d0	;COL/HF/VD/HD
	moveq	#0,d1
	cmpi	#$316,d0
	beq	@f			;768x512,64Kc
	moveq	#1,d1
	btst	#1,(CRTC_R20H)
	bne	@f			;256c
	btst	#1,(VC_R0L)
	bne	@f			;64Kc
	moveq	#-1,d1
@@:
	_TO_USER
	move.l	d1,d0
	move.l	(sp)+,d1
	rts

*-------------------------------------------------------------------------------
* デフォルト処理

	.text
main:
	btst.l	#OPT_M,d7
	bne	@f

	bsr	square_64k_check
	tst.l	d0
	bgt	@f
	tst.l	d7
	bne	main_end
@@:
	move.l	#16<<16+0,-(sp)		* ７６８×５１２にする
	DOS	_CONCTRL
	move.l	#10<<16+2,(sp)		* 画面クリア
	DOS	_CONCTRL
	addq.l	#4,sp
main_end:
	moveq	#0,d0
	rts

*-------------------------------------------------------------------------------
* 内部モードで TGUSEMD をコールする

	.text
_gm_internal_tgusemd:
		moveq	#-1,d2		* ダミーデータ(一応gmがない時のため)
		swap	d1
		move	#_GM_INTERNAL_MODE,d1
		swap	d1
		IOCS	_TGUSEMD
		rts

*-------------------------------------------------------------------------------
* マクロ定義

_HSYNC_WAIT2:	.macro
		.local	_HSYNC_WAIT2_loop
_HSYNC_WAIT2_loop:
		tst.b	(MFP_GPIP)
		bpl	_HSYNC_WAIT2_loop
		.endm

_HSYNC_WAIT:	.macro
		.local	_HSYNC_WAIT_loop
_HSYNC_WAIT_loop:
		tst.b	(MFP_GPIP)
		bmi	_HSYNC_WAIT_loop
		_HSYNC_WAIT2
		.endm

*-------------------------------------------------------------------------------
* V-DISPをみて垂直表示期間は待つ

	.text
vdisp_wait:
	btst	#4,(MFP_GPIP)
	beq	vdisp_wait
vdisp_wait2:
	btst	#4,(MFP_GPIP)
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
	move	d0,(CRTC_R21)
	lea	(CRTC_ACT),a0
	moveq	#%0010,d0
	bclr	#3,(CRTC_R20H)
	move	d0,(a0)			* CRTC 高速クリア実行
@@:	move	(a0),d0
	btst	#1,d0
	beq	@b
	rts

*-------------------------------------------------------------------------------
* CRTC 高速クリア終了まで待つ
*
* broken:
*   d0.w, a0.l

	.text
crtc_gclr_wait:
	lea	(CRTC_ACT),a0
@@:	move	(a0),d0
	btst	#1,d0
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
	PUSH	clear_64k_register
	_TO_SUPER
	move.l	(CRTC_R20),-(sp)	;r20/r21
	bsr	vdisp_wait
	moveq	#$0f,d0
	bsr	crtc_gclr
	bsr	crtc_gclr_wait
	move.l	(sp)+,(CRTC_R20)
	_TO_USER

	moveq	#.low._GM_MASK_CLEAR,d1	* グラフィックがなく、マスクは不要だから消去。
	bsr	_gm_internal_tgusemd
	bsr	scroll_reset		* -r と併用時にスクロールリセット！
clear_64k_end:
	POP	clear_64k_register
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
	PUSH	clear_16_register
	_TO_SUPER
	move.l	(CRTC_R20),-(sp)	;r20/r21
	bsr	vdisp_wait
	bsr	graphic_scroll_register_clear
	moveq	#$0f,d0
	bsr	crtc_gclr		* 上半分クリア
	bsr	crtc_gclr_wait
	lea	(CRTC_R12),a0
	move.l	#0<<16+512,d0
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	bsr	crtc_gclr		* 下半分クリア
	bsr	crtc_gclr_wait
	bsr	graphic_scroll_register_clear
	move.l	(sp)+,(CRTC_R20)
	_TO_USER
clear_16_end:
	POP	clear_16_register
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
	lea	(CRTC_R12),a0
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
	PUSH	gpalette_set_register
	lea	(G_PALET),a0
	move.l	#$0001_0001,d0
	move.l	#$0202_0202,d1
	moveq	#256/2-1,d2
	_HSYNC_WAIT
gpalette_set_loop:
	_HSYNC_WAIT2
	move.l	d0,(a0)+
	add.l	d1,d0
	dbra	d2,gpalette_set_loop
	POP	gpalette_set_register
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
	PUSH	gpalette_check_register
	lea	(G_PALET),a0
	moveq	#0,d0
	move	#256-1,d2
	moveq	#0,d3
	moveq	#0,d4
	_HSYNC_WAIT
gpalette_check_loop:
	_HSYNC_WAIT2
	move	(a0)+,d0
	add.l	d0,d3
	eor	d0,d4
	dbra	d2,gpalette_check_loop

	lea	(gpalette_sum,pc),a0
	move.l	d3,(a0)
	move	d4,d0
	ext.l	d0
gpalette_check_end:
	POP	gpalette_check_register
	rts

*-------------------------------------------------------------------------------
* ６４Ｋ色時のトーンダウン

	.text
tone_change_64k:
	move	(opt_t_number,pc),d0
	bne	@f
	bsr	tone_change_64k_sub_0
	bra	tone_change_64k_end
@@:
	cmpi	#50,d0
	bne	@f
	bsr	tone_change_64k_sub_50
	bra	tone_change_64k_end
@@:
	cmpi	#100,d0
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

		.text
tone_change_64k_sub:
	PUSH	tone_change_64k_sub_register
	move	d0,d6			* ％
	_TO_SUPER

	lea	(-256*2,sp),sp

	lea	(sp),a0			;まず初期パレットを作る
	move.l	#$0001_0001,d0
	move.l	#$0202_0202,d1
	moveq	#256/2-1,d2
@@:
	move.l	d0,(a0)+
	add.l	d1,d0
	dbra	d2,@b

	lea	(sp),a0
	moveq	#%11111,d5
	moveq	#100,d4
	moveq	#%11,d3
	moveq	#256/2-1,d7
tone_change_64k_sub_loop:
	move	(a0),d0
	moveq	#%1,d2			* 奇数の I は常に 1

	ror	#1,d0			* Blue
	ror	#1,d2
	move	d0,d1
	and	d5,d1
	mulu	d6,d1
	divu	d4,d1
	or	d1,d2

	ror	#5,d0			* Red low
	ror	#5,d2
	move	d0,d1
	and	d3,d1
	mulu	d6,d1
	divu	d4,d1
	or	d1,d2

	ror	#3,d0			* Blue
	ror	#3,d2
	move	d0,d1
	and	d5,d1
	mulu	d6,d1
	divu	d4,d1
	or	d1,d2

	ror	#5,d0			* Red low
	ror	#5,d2
	move	d0,d1
	and	d3,d1
	mulu	d6,d1
	divu	d4,d1
	or	d1,d2

	ror	#2,d2
	move	d2,(a0)+

	move	(a0),d0

	move	d0,d1			* Red high
	and	#%111,d1
	mulu	d6,d1
	divu	d4,d1
	move	d1,d2

	ror	#3,d0			* Green
	ror	#3,d2
	move	d0,d1
	and	d5,d1
	mulu	d6,d1
	divu	d4,d1
	or	d1,d2

	ror	#5,d0			* Red high
	ror	#5,d2
	move	d0,d1
	and	#%111,d1
	mulu	d6,d1
	divu	d4,d1
	or	d1,d2

	ror	#3,d0			* Green
	ror	#3,d2
	move	d0,d1
	and	d5,d1
	mulu	d6,d1
	divu	d4,d1
	or	d1,d2

	ror	#5,d2
	move	d2,(a0)+
	dbra	d7,tone_change_64k_sub_loop

	move	#$003f,(VC_R2)		* １００％
	lea	(G_PALET),a0
	moveq	#256/2-1,d0
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	move.l	(sp)+,(a0)+
	dbra	d0,@b

	_TO_USER
	POP	tone_change_64k_sub_register
	rts

*-------------------------------------------------------------------------------
* １００％の時はパレット初期化
*

	.text
tone_change_64k_sub_100:
	_TO_SUPER
	move	#$003f,(VC_R2)		* １００％
	bsr	gpalette_set
	_TO_USER
	rts

*-------------------------------------------------------------------------------
* ５０％の時はパレット初期化＋擬似トーンダウン
*

	.text
tone_change_64k_sub_50:
	_TO_SUPER
	move	#$193f,(VC_R2)		* ５０％
	bsr	gpalette_set
	_TO_USER
	rts

*-------------------------------------------------------------------------------
* ０％ならクリアする

	.text
tone_change_64k_sub_0:
	PUSH	d0-d1/a0-a1
	_TO_SUPER
	lea	(G_PALET),a0
	moveq	#256/2-1,d0
	moveq	#0,d1

	lea	(VC_R2),a1
	bsr	vdisp_wait
	move	(a1),-(sp)
	andi	#$ffe0,(a1)

	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	move.l	d1,(a0)+
	dbra	d0,@b

	move	(sp)+,(a1)
	_TO_USER
	POP	d0-d1/a0-a1
	rts

*-------------------------------------------------------------------------------
* １６色時の処理（トーンダウン）

	.text
tone_change:
	moveq	#.low._GM_KEEP_PALETTE_GET,d1
	bsr	_gm_internal_tgusemd
	cmpi.l	#-1,d0
	beq	tone_change_end		* gmが対応してない(versionが0.69以前)
	subi	#_GM_INTERNAL_MODE,d0
	bne	tone_change_end
	swap	d0
	beq	tone_change_end		* 常駐パレットは無効
					* （まだグラフィックがロードされてない）
					* 有効なら a1.l にアドレスが入っている
	move	(opt_t_number,pc),d0
	bne	@f
	bsr	tone_change_sub_0
	bra	tone_change_end
@@:
	cmpi	#50,d0
	bne	@f
	bsr	tone_change_sub_50
	bra	tone_change_end
@@:
	cmpi	#100,d0
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
	PUSH	tone_change_sub_register
	move	d0,d6			* ％
	_TO_SUPER
	moveq	#%11111,d5
	moveq	#100,d4
	lea	(G_PALET),a0
	moveq	#16-1,d7
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
	POP	tone_change_sub_register
	rts

*-------------------------------------------------------------------------------
* １００％の時は常駐パレットそのまま
*
* entry:
*   a1.l = 常駐パレットの先頭アドレス（内容を変更したらおしおき・・・）

	.text
tone_change_sub_100:
	_TO_SUPER
	lea	(G_PALET),a0
	moveq	#16/2-1,d0
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	move.l	(a1)+,(a0)+
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
	lea	(G_PALET),a0		* グラフィックパレットアドレス先頭
	move	#%01111_01111_01111_0,d1
	moveq	#16-1,d0
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	move	(a1)+,d2
	lsr	#1,d2
	and	d1,d2
	_HSYNC_WAIT2
	move	d2,(a0)+
	dbra	d0,@b
	_TO_USER
	rts

*-------------------------------------------------------------------------------
* ０％ならクリアする

	.text
tone_change_sub_0:
	_TO_SUPER
	lea	(G_PALET),a0
	moveq	#16/2-1,d0
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	clr.l	(a0)+
	dbra	d0,@b
	_TO_USER
	rts

*-------------------------------------------------------------------------------
* ６４Ｋ色時の処理

	.text
shrink:
	btst	#OPT_S,d7
	beq	shrink_end

	bsr	mode_check
	tst	d0
	beq	shrink_end		* １６色なら実行しない

	move.l	#513*1024,-(sp)		* ３ライン毎だから５１３
	DOS	_MALLOC
	move.l	d0,(sp)+
	bmi	program_error_malloc	* 致命的エラー
	move.l	d0,-(sp)

	movea.l	d0,a0
	bsr	shrink_sub

	DOS	_MFREE
	move.l	d0,(sp)+
	bmi	program_error_mfree	* 致命的エラー
shrink_end:
	moveq	#0,d0
	rts

*-------------------------------------------------------------------------------
* グラフィックの画像を縮める
*
* entry:
*   a0.l = buffer top address

	.text
shrink_sub:
	_TO_SUPER
	move	(opt_s_number,pc),d0
	bne	shrink_sub_1
;-s0
	bsr	gram_to_buffer
	bsr	buffer_shrink_to_gram
	bra	@f
shrink_sub_1:
;-s1
	bsr	gram_to_buffer_not_clear
	bsr	buffer_shrink_to_gram
	bsr	gram_clear
@@:
	_TO_USER
	rts

*-------------------------------------------------------------------------------
* マクロ定義
*
*   グラフィック１ライン消去×２（上下）

GLINE_CLEAR	.macro
		.local	gline_clear_loop
	moveq	#0,d2
	move.l	d2,d3
	move.l	d2,d4
	move.l	d2,d5
	move.l	d2,d6
	move.l	d2,d7
	move.l	d2,a5
	move.l	d2,a6
	moveq	#32-1,d1
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
	PUSH	gram_to_buffer_not_clear_register

	move.l	a0,a1
	move.l	a0,a2			* 最終ラインは２重取り込み
	adda.l	#511*1024,a2
	lea	(GVRAM+511*1024),a4
	moveq	#(32-1)-1,d1
gram_to_buffer_not_clear_start_loop:
	movem.l	(a4)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a2)
	movem.l	d2-d7/a5-a6,(1024,a2)
	lea	(32,a2),a2
	dbra	d1,gram_to_buffer_not_clear_start_loop

	movem.l	(a4)+,d2-d7/a5
	move.l	(a4)+,a6
	movem.l	d2-d7/a5-a6,(a2)
	movem.l	d2-d7/a5-a6,(1024,a2)
	lea	(32,a2),a2

	lea	(GVRAM),a3
	move	#(512-1)-1,d0		* 残りのラインを取り込む
gram_to_buffer_not_clear_loop:
	moveq	#32-1,d1		* １ライン転送
gram_to_buffer_not_clear_loop1:
	movem.l	(a3)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a1)
	lea	(32,a1),a1
	dbra	d1,gram_to_buffer_not_clear_loop1
	dbra	d0,gram_to_buffer_not_clear_loop

	POP	gram_to_buffer_not_clear_register
	rts

*-------------------------------------------------------------------------------
* 隙間のみグラフィック消去

gram_clear_register	reg	d0-d7/a0-a6

	.text
gram_clear:
	PUSH	gram_clear_register
	lea	(GVRAM+(255-171+1)*1024),a3	* GRAMの位置(上)
	lea	(GVRAM+(256+171+1)*1024),a4	* GRAMの位置(下)
	movea	#32,a0
	moveq	#0,d2
	move.l	d2,d3
	move.l	d2,d4
	move.l	d2,d5
	move.l	d2,d6
	move.l	d2,d7
	move.l	d2,a5
	move.l	d2,a6

	move	#255-171,d0		* 隙間を埋める
gram_clear_loop:
	move	#(1024/32)-1,d1		* １ライン消去
gram_clear_loop1:
	movem.l	d2-d7/a5-a6,-(a3)
	movem.l	d2-d7/a5-a6,-(a4)
	dbra	d1,gram_clear_loop1
	lea	(1024*2,a4),a4
	dbra	d0,gram_clear_loop
gram_clear_end:
	POP	gram_clear_register
	rts

*-------------------------------------------------------------------------------
* ＧＲＡＭの内容をバッファに取り込む
*
* entry:
*   a0.l = buffer top address

gram_to_buffer_register	reg	d0-d7/a0-a6

	.text
gram_to_buffer:
	PUSH	gram_to_buffer_register

	move.l	a0,a1			* 最初の１ラインを取り出す
	move.l	a0,a2			* 最終ラインは２重取り込み
	movea	#32,a0
	adda.l	#511*1024,a2
	lea	(GVRAM),a3
	lea	(GVRAM+511*1024),a4
	moveq	#(32-1)-1,d1
gram_to_buffer_start_loop:
	movem.l	(a3)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a1)
	movem.l	(a4)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a2)
	movem.l	d2-d7/a5-a6,(1024,a2)
	adda	a0,a1
	adda	a0,a2
	dbra	d1,gram_to_buffer_start_loop

	movem.l	(a3)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a1)
	movem.l	(a4)+,d2-d7/a5
	move.l	(a4)+,a6
	movem.l	d2-d7/a5-a6,(a2)
	movem.l	d2-d7/a5-a6,(1024,a2)
	adda	a0,a1
	adda	a0,a2

	GLINE_CLEAR

	lea	(1024,a3),a3
	lea	(-1024,a4),a4
	lea	(-2048,a2),a2

	move	#(256-1)-1,d0		* 残りのラインを取り込む
gram_to_buffer_loop:
	moveq	#32-1,d1		* １ライン転送
gram_to_buffer_loop1:
	movem.l	(a3)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a1)
	movem.l	(a4)+,d2-d7/a5-a6
	movem.l	d2-d7/a5-a6,(a2)
	adda	a0,a1
	adda	a0,a2
	dbra	d1,gram_to_buffer_loop1

	GLINE_CLEAR

	lea	(1024,a3),a3
	lea	(-1024,a4),a4
	lea	(-2048,a2),a2
	dbra	d0,gram_to_buffer_loop

	POP	gram_to_buffer_register
	rts

*-------------------------------------------------------------------------------
* バッファの内容を縦圧縮してＧＲＡＭに書き込む
*
* entry:
*   a0.l = buffer top address

buffer_shrink_to_gram_register	reg	d0-d7/a0-a6

	.text
buffer_shrink_to_gram:
	PUSH	buffer_shrink_to_gram_register

	move.l	a0,a1
	move.l	a0,a2
	adda.l	#255*1024,a1		* 初期バッファ位置（上）
	adda.l	#257*1024,a2		* 初期バッファ位置（下）
	lea	(GVRAM+255*1024),a3	* GRAMの位置（上）
	lea	(GVRAM+256*1024),a4	* GRAMの位置（下）

	lea	(shrink_div3_table_g,pc),a0	* 割り算テーブル
	lea	(shrink_div3_table_r,pc),a5
	lea	(shrink_div3_table_b,pc),a6

	move	#%1111100000111110,d4	* パレットマスク
	move	#%0000011111000000,d5
	clr	d6			* Ｇ、Ｂを同時に計算するのでその時使うワークレジスタ
					* d6.w の上位バイトは常に０にする

	bsr	shrink_put_down		* ちょうど真ん中
	move	#((513/3)/2)-1,d7	* ループ数
buffer_shrink_to_gram_loop:
	bsr	shrink_put_up
	bsr	shrink_put_down
	dbra	d7,buffer_shrink_to_gram_loop

	POP	buffer_shrink_to_gram_register
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
	lea	(-3072,a1),a1
	lea	(1024,a2),a2
	lea	(-2048,a3),a3
	rts

*-------------------------------------------------------------------------------
* 画面半分より上に表示するやつを下のラインと混ぜる

	.text
shrink_put_down:
	bsr	shrink_put_sub
	lea	(-2048,a1),a1
	lea	(-2048,a3),a3
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
	move.w	(1024,a1),d2		* ２分の１で混ぜ合わせるカラー
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

	move.w	(-1024,a2),d2		* ２分の１で混ぜ合わせるカラー
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
* エラー処理

	.data
mes_progerr:
	.dc.b	'強制終了します.',CRLF,0
mes_progerr_setblock:
	.dc.b	'メモリブロックの変更ができません.',CRLF,0
mes_progerr_malloc:
	.dc.b	'メモリブロックが確保できません.',CRLF,0
mes_progerr_mfree:
	.dc.b	'メモリブロックが解放できません.',CRLF,0

	.text
program_error_setblock:
	lea	(mes_progerr_setblock,pc),a0
	move	#EXIT_ERROR_SETBLOCK,d0
	bra	program_error

program_error_malloc:
	lea	(mes_progerr_malloc,pc),a0
	move	#EXIT_ERROR_MALLOC,d0
	bra	program_error

program_error_mfree:
	lea	(mes_progerr_mfree,pc),a0
	move	#EXIT_ERROR_MFREE,d0
	bra	program_error

program_error:
	move	d0,-(sp)
	move.l	a0,-(sp)
	DOS	_PRINT
	pea	(mes_progerr,pc)
	DOS	_PRINT
	addq.l	#8,sp
	DOS	_EXIT2


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
