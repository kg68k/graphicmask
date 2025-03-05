* $Id: gm.s,v 1.2 1994/09/15 22:18:58 JACK Exp $


* ＧＭのバージョン
GM_VERSION:	.equ	$0087

PATCHLEVEL:	.reg	'4'


* Include File -------------------------------- *

		.include	iocscall.mac
		.include	doscall.mac
		.include	gm_internal.mac


*-------------------------------------------------------------------------------
* 終了コードの定義

			.offset	0
EXIT_NO_ERROR:		.ds.b	1
EXIT_ERROR_OS_VERSION:	.ds.b	1
EXIT_ERROR_OPTION:	.ds.b	1
EXIT_ERROR_GNCMODE:	.ds.b	1
EXIT_ERROR_DEN_MASK:	.ds.b	1
EXIT_ERROR_GSTOP:	.ds.b	1
EXIT_ERROR_SETBLOCK:	.ds.b	1
EXIT_ERROR_KEEP:	.ds.b	1
EXIT_ERROR_RELEASE:	.ds.b	1
EXIT_ERROR_NOT_KEEP:	.ds.b	1
EXIT_ERROR_NOT_SUPPORT:	.ds.b	1
EXIT_ERROR_TRAM_USED:	.ds.b	1
			.text


*-------------------------------------------------------------------------------
* マクロの定義

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

STACK_SIZE:	.equ	8*1024


*-------------------------------------------------------------------------------
* Ｉ／Ｏアドレス

G_VRAM:		.equ	$c00000

CRTC_R00:	.equ	$e80000
CRTC_R12:	.equ	$e80018
CRTC_R20:	.equ	$e80028
CRTC_R20h:	.equ	$e80028
CRTC_R20l:	.equ	$e80029
CRTC_R21:	.equ	$e8002a

GRAPHIC_PAL:	.equ	$e82000

VC_R0:		.equ	$e82400
VC_R0h:		.equ	$e82400
VC_R0l:		.equ	$e82401
VC_R2:		.equ	$e82600
VC_R2h:		.equ	$e82600
VC_R2l:		.equ	$e82601

MFP_GPIP:	.equ	$e88001

BGSR_BG0:	.equ	$eb0800

SRAM_TPAL0:	.equ	$ed002e
SRAM_TPAL8:	.equ	$ed0038

TVRAM_P3:	.equ	$e60000
TPALET:		.equ	$e82200


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
* プログラム識別文字列

		.text
program_start_0:
		bra.s	skip_id
		.dc.b	'#HUPAIR',0
program_id_name:
		.dc.b	'Graphic Mask'
		.dc.b	0
program_id_version:
		.dc.b	'0.87 patchlevel ',PATCHLEVEL
		.dc.b	0
		.even
skip_id:
		bra	program_start


*-------------------------------------------------------------------------------
* タイトルメッセージ

	.data
message_title:
version_mes:
	.dc.b	'Graphic Mask version 0.87 patchlevel ',PATCHLEVEL
version_mes_end:
	.dc.b	' programmed by JACK, Copyright (C) 2025 TcbnErik.'
	.dc.b	CRLF,0


*-------------------------------------------------------------------------------
* ベクタ保存領域

HOOK:		.macro	adr,vec
		.dc	(adr-$),(vec.or.$100)	* DOS:$ffxx IOCS:$01xx (割り込み指定不可)
		.endm

		.text
		.quad

vector_table_top:

vector_TPALET:		HOOK	NEW_TPALET	,_TPALET
vector_TPALET2:		HOOK	NEW_TPALET2	,_TPALET2
vector_CRTMOD:		HOOK	NEW_CRTMOD	,_CRTMOD
vector_TGUSEMD:		HOOK	NEW_TGUSEMD	,_TGUSEMD
vector_G_CLR_ON:	HOOK	NEW_G_CLR_ON	,_G_CLR_ON
vector_B_KEYSNS:	HOOK	NEW_B_KEYSNS	,_B_KEYSNS
vector_DENSNS:		HOOK	NEW_DENSNS	,_DENSNS
		.if	0
vector_TXXLINE:		HOOK	NEW_TXXLINE	,_TXXLINE
vector_TXYLINE:		HOOK	NEW_TXYLINE	,_TXYLINE
vector_TXBOX:		HOOK	NEW_TXBOX	,_TXBOX
vector_B_WPOKE:		HOOK	NEW_B_WPOKE	,_B_WPOKE
		.endif
vector_EXIT:		HOOK	NEW_EXIT	,_EXIT
vector_EXIT2:		HOOK	NEW_EXIT2	,_EXIT2
vector_KEEPPR:		HOOK	NEW_KEEPPR	,_KEEPPR

			.dc	0	* end of table


*-------------------------------------------------------------------------------
* フラグ領域

	.text
	.even

active_flag:
	.dc.b	$ff			* ＧＭ主要機能の動作フラグ 0:停止 0以外:動作
force_flag:
	.dc.b	0			* 強制フラグ 0:IOCSに従う 0以外:強制使用する
gnc_flag:
	.dc.b	0			* GNCフラグ 0:無効 0以外:有効
den_mask_flag:
	.dc.b	0			* 電卓消去時のマスクフラグ 0:無効 0以外:有効

	.if	0
wpoke_flag:
	.dc.b	0			* うっしっし（μEmacs用）
	.endif

check_force_flag:
	.dc.b	0			* 不都合解消
save_force_flag:
	.dc.b	0			* 不都合解消
gstop_flag:
	.dc.b	0			* グラフィック使用モード監視 0:無効 0以外:有効

mask_set_flag:
	.dc.b	0			* マスクフラグ 0:マスクなし 0以外:マスクあり
mask_halt_flag:
	.dc.b	0
mask_disable_flag:
	.dc.b	0
mask_enable_flag:
	.dc.b	$ff
mask_request_flag:
	.dc.b	0

graphic_palette_16_flag:
	.dc.b	0
graphic_data_16_flag:
	.dc.b	0

g_use_flag:
	.dc.b	0			* 0以外:現プロセスがGVRAMを占有した

	.even

*-------------------------------------------------------------------------------
* グラフィック画面の最大色－１

	.text
_graphic_color_max:
	PUSH	d0-d1
	moveq	#16-1,d0
	move.b	($93c),d1		* _CRTMODの画面モード
	cmp.b	d0,d1			* cmpi.b #16,d1
	bhi	@f			* bcc @f
	ror.b	#4,d1
	bcc	@f
	st	d0			* move	#256-1,d0
	rol.b	#2,d1
	bcc	@f
	moveq	#$ff,d0			* 65536-1
@@:
	move	d0,($964)
	POP	d0-d1
	rts

*-------------------------------------------------------------------------------
* ＧＶＲＡＭ１ラインのサイズ

	.text
_graphic_line_length:
	move.l	d0,-(sp)
	moveq	#$40,d0			* move.l #$400,d0
	lsl	#4,d0			*
	btst	#2,(CRTC_R20h)
	beq	@f
	add	d0,d0
@@:
	move.l	d0,($960)
	move.l	(sp)+,d0
	rts

*-------------------------------------------------------------------------------
* グラフィッククリッピングエリア

	.text
_graphic_window:
	clr.l	($968)
	btst	#2,(CRTC_R20h)
	bne	@f

	move.l	#(512-1)<<16+(512-1),($96c)
	rts
@@:
	move.l	#(768-1)<<16+(512-1),($96c)
	rts

*-------------------------------------------------------------------------------
* CRTCが１６色用になっているか調べる
*
* return:
*   ccr:z  = 0 違うなぁ
*   ccr:z  = 1 １６色です

	.text
crtc_check_16:
	move.l	a0,-(sp)
	lea	(CRTC_R20),a0

	cmpi	#$0c15,(a0)
	bhi	crtc_check_16_goff
	beq	crtc_check_16_end
	cmpi	#$0415,(a0)
	beq	crtc_check_16_end
	cmpi	#$0416,(a0)
	beq	crtc_check_16_end
	cmpi	#$041a,(a0)
crtc_check_16_end:
	movea.l	(sp)+,a0
	rts

crtc_check_16_goff:
	cmpi	#$0c16,(a0)
	beq	crtc_check_16_end
	cmpi	#$0c1a,(a0)
	bra	crtc_check_16_end

*-------------------------------------------------------------------------------
* _EXITの処理

	.text
NEW_EXIT:
	move.l	(vector_EXIT,pc),-(sp)
	bra	NEW_EXIT_check

*-------------------------------------------------------------------------------
* _EXIT2の処理

	.text
NEW_EXIT2:
	move.l	(vector_EXIT2,pc),-(sp)
NEW_EXIT_check:
**	move.l	a0,-(sp)
	lea	(g_use_flag,pc),a0
	clr.b	(a0)
**	movea.l	(sp)+,a0

	bsr	exit_mask_check
	bsr	crtc_check_16
	beq	graphic_data_16_check		* ちぇっく、ちぇ～っく(^^;
*NEW_EXIT_end:
	rts

*-------------------------------------------------------------------------------
* _KEEPPRの処理

	.text
NEW_KEEPPR:
	move.l	(vector_KEEPPR,pc),-(sp)
	bra	NEW_EXIT_check

*-------------------------------------------------------------------------------
* 不都合を取る

	.text
exit_mask_check:
	move.b	(mask_set_flag,pc),-(sp)
	addq.l	#2,sp
	beq	exit_mask_check_end

	tst	(TVRAM_P3)
	beq	mask_sub
exit_mask_check_end:
	rts

	.if	0

*-------------------------------------------------------------------------------
* _TXXLINE, _TXYLINE用のオフセット表

	.offset	0
vram_page:	.ds.w	1		* テキストプレーン番号
line_x:		.ds.w	1		* 始点Ｘ座標
line_y:		.ds.w	1		* 始点Ｙ座標
line_length:	.ds.w	1		* 終点までの長さ
line_style:	.ds.w	1		* ラインスタイル
txline_work_size:
	.text

*-------------------------------------------------------------------------------
* _TXXLINEの処理

	.text
NEW_TXXLINE:
	move.b	(active_flag,pc),d0
	and.b	(mask_set_flag,pc),d0
	beq	NEW_TXXLINE_end

	cmpi	#2,vram_page(a1)	* テキストプレーン２かな？
	bne	NEW_TXXLINE_end
	tst	line_length(a1)
	beq	NEW_TXXLINE_end		* 長さ０？

	cmpi	#512,line_y(a1)
	bcc	NEW_TXXLINE_end		* Ｙ座標 512 以上はマスクがない

	tst	line_style(a1)		* クリア？
	seq	d0
	ext	d0

txxline_mask_register	reg	a1-a4
	PUSH	txxline_mask_register
	lea	-txline_work_size(sp),sp	* ワークエリアを得る
	lea	(sp),a2
	exg.l	a1,a2

	lea	(CRTC_R21),a3
	move	(a3),-(sp)
	clr.b	(a3)
	movea.l	(vector_TXXLINE,pc),a4
	move	#3,(a1)				* vram_page
	move	line_y(a2),line_y(a1)
	move	d0,line_style(a1)

	move	line_x(a2),d0
	cmpi	#128,d0
	bcc	NEW_TXXLINE_clear_right

NEW_TXXLINE_clear_left:
	move	d0,line_x(a1)
	add	line_length(a2),d0
	cmpi	#128,d0
	bcs	@f
	moveq	#127,d0
@@:
	sub	line_x(a1),d0
	addq	#1,d0
	move	d0,line_length(a1)
	jsr	(a4)

NEW_TXXLINE_clear_right:
	move	line_x(a2),d0
	add	line_length(a2),d0
	cmpi	#640,d0
	bcs	NEW_TXXLINE_clear_end

	move	#640,line_x(a1)
	sub	#640-1,d0
	move	d0,line_length(a1)
	jsr	(a4)

NEW_TXXLINE_clear_end:
	move	(sp)+,(a3)

	lea	txline_work_size(sp),sp		* ワークエリアを戻す
	POP	txxline_mask_register
NEW_TXXLINE_end:
	move.l	(vector_TXXLINE,pc),-(sp)
	rts

*-------------------------------------------------------------------------------
* _TXYLINEの処理

	.text
NEW_TXYLINE:
	move.b	(active_flag,pc),d0
	and.b	(mask_set_flag,pc),d0
	beq	NEW_TXYLINE_end

	cmpi	#2,(a1)			* テキストプレーン２かな？
	bne	NEW_TXYLINE_end
	tst	line_length(a1)
	beq	NEW_TXYLINE_end		* 長さ０？

	moveq	#0,d0
	cmpi	#512,line_y(a1)
	bcc	NEW_TXYLINE_end		* Ｙ座標 512 以上はマスクがない
	move	line_x(a1),d0
	cmpi	#768,d0
	bcc	NEW_TXYLINE_end		* Ｘ座標 768 以上は論外
	cmpi	#640,d0
	bcc	NEW_TXYLINE_mask
	cmpi	#128,d0
	bcc	NEW_TXYLINE_end		* Ｘ座標 128 ～ 639 はマスクがない
NEW_TXYLINE_mask:
txyline_mask_register	reg	d1-d5/a1

	PUSH	txyline_mask_register
	moveq	#%111,d1
	and.b	d0,d1
	lsr.l	#3,d0			* Ｘ座標 -> アドレス
	lea	(TVRAM_P3),a0
	adda.l	d0,a0
	move	line_y(a1),d0
	lsl.l	#7,d0			* Ｙ座標 -> アドレス
	adda.l	d0,a0

	neg.b	d1
	addq.b	#7,d1			* ビット列を反転させる
	st	d2
	bclr	d1,d2			* d2.b = マスクパターン
	move.b	d2,d5
	tst	line_style(a1)		* クリア？
	bne	NEW_TXYLINE_mask_clear
NEW_TXYLINE_mask_set:
	bset	d1,d2
NEW_TXYLINE_mask_clear:
	move	line_length(a1),d0
	subq	#1,d0
	lea	(CRTC_R21),a1
	move	(a1),-(sp)
	clr.b	(a1)
	move	#$0080,d1
	move.l	#-$20000,d3
NEW_TXYLINE_mask_loop:
	move.b	(a0,d3.l),d4
	and.b	d5,d4
	not.b	d4
	and.b	d2,d4
	move.b	d4,(a0)
	adda	d1,a0
	dbra	d0,NEW_TXYLINE_mask_loop
	move	(sp)+,(a1)
	POP	txyline_mask_register
NEW_TXYLINE_end:
	move.l	(vector_TXYLINE,pc),-(sp)
	rts

*-------------------------------------------------------------------------------
* _TXBOXの処理

	.text
NEW_TXBOX:
	move.b	(active_flag,pc),d0
	and.b	(mask_set_flag,pc),d0
	beq	NEW_TXBOX_end

	cmpi	#2,(a1)			* テキストプレーン２かな？
	bne	NEW_TXBOX_end

	tst	line_style(a1)		* クリア？
	seq	d0
	ext	d0

txbox_mask_register	reg	a1-a3
	PUSH	txbox_mask_register
	lea	-2*6(sp),sp			* ワークエリアを得る
	lea	(sp),a2
	exg.l	a1,a2

	lea	(CRTC_R21),a3
	move	(a3),-(sp)
	clr.b	(a3)
	move	#3,(a1)+
	addq.l	#2,a2
	move.l	(a2)+,(a1)+
	move.l	(a2)+,(a1)+
	move	d0,(a1)+
	lea	(sp),a1
	movea.l	(vector_TXBOX,pc),a0
	jsr	(a0)
	move	(sp)+,(a3)

	lea	2*6(sp),sp			* ワークエリアを戻す
	POP	txbox_mask_register
NEW_TXBOX_end:
	move.l	(vector_TXBOX,pc),-(sp)
	rts

	.endif

*-------------------------------------------------------------------------------
* _B_KEYSNSの処理

	.text
NEW_B_KEYSNS:
	move.b	(active_flag,pc),d0
	beq	NEW_B_KEYSNS_end

	move.b	(mask_set_flag,pc),d0
	beq	NEW_B_KEYSNS_no_mask

	tst.b	(MFP_GPIP)
	bpl	NEW_B_KEYSNS_no_mask
	tst	(TVRAM_P3)
	bne	NEW_B_KEYSNS_no_mask
	bsr	mask_sub
NEW_B_KEYSNS_no_mask:
	movea.l	(vector_B_KEYSNS,pc),a0
	bra	dentaku_mask		* 電卓マスクに対応したルーチン

NEW_B_KEYSNS_end:
	move.l	(vector_B_KEYSNS,pc),-(sp)
	rts

*-------------------------------------------------------------------------------
* _DENSNSの処理

	.text
NEW_DENSNS:
	move.b	(active_flag,pc),-(sp)
	addq.l	#2,sp
	beq	NEW_DENSNS_end

	movea.l	(vector_DENSNS,pc),a0
	bra	dentaku_mask

NEW_DENSNS_end:
	move.l	(vector_DENSNS,pc),-(sp)
	rts

*-------------------------------------------------------------------------------
* 電卓の表示によって空いたマスクを埋める
*
* entry:
*   a0.l = コールするアドレス

* この表はＸＶＩで調べたものです
DEN_XSIZE	equ	23		* 電卓の横幅（文字単位）
DEN_XPOS	equ	$0bfc		* 電卓のＸ座標
DEN_YPOS	equ	$0bfe		* 電卓のＹ座標
DEN_PRINT	equ	$0bc6		* 電卓の表示フラグ	0:なし  1:あり
DEN_MODE	equ	$0bc7		* 電卓のモード		0:DEC   1:HEX

dentaku_mask_register	reg	d0-d5/a0-a1

	.text
dentaku_mask_off:
	jmp	(a0)			* 表示なし、または使用しない

dentaku_mask:
	move.b	(den_mask_flag,pc),-(sp)
	addq.l	#2,sp
	beq	dentaku_mask_off

	tst.b	(DEN_PRINT)
	beq	dentaku_mask_off
	jsr	(a0)
	tst.b	(DEN_PRINT)
	bne	dentaku_mask_end	* 電卓表示中

	move.b	(mask_set_flag,pc),-(sp)
	addq.l	#2,sp
	beq	dentaku_mask_end	* マスクされていない

	cmpi	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,(TPALET+2*8)
	bne	dentaku_mask_end	* 表示カラーが違う

	cmpi	#512,(DEN_YPOS)
	bcc	dentaku_mask_end	* Ｙ座標 512 以上はマスクがない
	cmpi	#768,(DEN_XPOS)
	bcc	dentaku_mask_end	* Ｘ座標 768 以上はマスクがない
	cmpi	#640-(DEN_XSIZE*8)+1,(DEN_XPOS)
	bcc	dentaku_mask_right	* Ｘ座標 640 からマスクがある
	cmpi	#128,(DEN_XPOS)
	bcc	dentaku_mask_end	* Ｘ座標 128 ～ 639 はマスクがない

dentaku_mask_left:
	PUSH	dentaku_mask_register
	moveq	#0,d0
	move	(DEN_YPOS),d0
	lsl.l	#7,d0			* Ｙ座標 -> アドレス
	lea	(TVRAM_P3),a0
	adda.l	d0,a0
	bra	dentaku_mask_paint

dentaku_mask_right:
	PUSH	dentaku_mask_register
	moveq	#0,d0
	move	(DEN_YPOS),d0
	lsl.l	#7,d0			* Ｙ座標 -> アドレス
	lea	(TVRAM_P3),a0
	lea	(80,a0,d0.l),a0		* Ｘ座標 640 から

dentaku_mask_paint:
	moveq	#-1,d1
	move.l	d1,d2
	move.l	d1,d3
	move.l	d1,d4
	move	#$80,d5
	move	#16-1,d0

	lea	(CRTC_R21),a1
	move	(a1),-(sp)
	clr.b	(a1)
dentaku_mask_paint_loop:
	movem.l	d1-d4,(a0)		* テキストプレーン塗りつぶし
	adda	d5,a0
	dbra	d0,dentaku_mask_paint_loop
	move	(sp)+,(a1)
	POP	dentaku_mask_register
dentaku_mask_end:
	rts

	.if	0

*-------------------------------------------------------------------------------
* _B_WPOKEの処理

	.text
NEW_B_WPOKE:
	move.b	(active_flag,pc),d0
	and.b	(mask_set_flag,pc),d0
	beq	NEW_B_WPOKE_end

	cmpa.l	#TPALET,a1
	bne	NEW_B_WPOKE_end

	lea	(wpoke_flag,pc),a0
	st	(a0)
	movea.l	(vector_B_WPOKE,pc),a0
	lea	2*8(a1),a1
	move.l	d1,-(sp)
	bne	@f
	move.l	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,d1
@@:
	jsr	(a0)			* a1.l += 2
	move.l	(sp)+,d1
	lea	-2*9(a1),a1
NEW_B_WPOKE_end:
	move.l	(vector_B_WPOKE,pc),-(sp)
	rts

	.endif

*-------------------------------------------------------------------------------
* _TPALET2の処理

tpalet2_register	reg	d1-d2/a1

	.text
NEW_TPALET2:
	move.b	(active_flag,pc),d0
	and.b	(mask_set_flag,pc),d0
	beq	NEW_TPALET2_end

	.if	0
	move.b	(wpoke_flag,pc),d0
	bne	NEW_TPALET2_wpoke
	.endif

	tst.l	d2
	bmi	NEW_TPALET2_end

*NEW_TPALET2_set:
*	cmpi.b	#16,d1
*	bcc	NEW_TPALET2_end
	cmpi.b	#12,d1
	bcc	NEW_TPALET2_end
	cmpi.b	#9,d1
	bcc	NEW_TPALET2_set_9
	cmpi.b	#8,d1
	beq	NEW_TPALET2_set_0
	cmpi.b	#4,d1
	bcc	NEW_TPALET2_end
	tst.b	d1
	beq	NEW_TPALET2_set_0

	PUSH	tpalet2_register
NEW_TPALET2_set_9_sub:
	movea.l	(vector_TPALET2,pc),a1
	jsr	(a1)
	bset	#3,d1
NEW_TPALET2_set_0_sub:
	jsr	(a1)
	POP	tpalet2_register
	rts

NEW_TPALET2_set_9:
	PUSH	tpalet2_register
	bclr	#3,d1
	moveq	#-1,d2
	bra	NEW_TPALET2_set_9_sub

NEW_TPALET2_set_0:
	PUSH	tpalet2_register
	movea.l	(vector_TPALET2,pc),a1
	btst	#3,d1
	bne	@f
	jsr	(a1)
	bset	#3,d1
@@:
	move.l	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,d2
	bra	NEW_TPALET2_set_0_sub

	.if	0
NEW_TPALET2_wpoke:
	lea	(wpoke_flag,pc),a0
	clr.b	(a0)
	tst.l	d1
	bne	NEW_TPALET2_end
	tst.l	d2
	bmi	NEW_TPALET2_end

	movea.l	(vector_TPALET2,pc),a0
	moveq	#8,d1
	move.l	d2,-(sp)
	move.l	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,d2
	jsr	(a0)
	move.l	(sp)+,d2
	moveq	#0,d1
	.endif

NEW_TPALET2_end:
	move.l	(vector_TPALET2,pc),-(sp)
	rts

*-------------------------------------------------------------------------------
* _TPALETの処理

tpalet_register	reg	d1-d2/a1

	.text

NEW_TPALET:
	move.b	(active_flag,pc),d0
	and.b	(mask_set_flag,pc),d0
	beq	NEW_TPALET_end

	moveq	#-2,d0
	cmp.l	d0,d2
	beq	NEW_TPALET_initialize	* -2:初期化
	bcs	NEW_TPALET_set
	bra	NEW_TPALET_get		* -1:収得

NEW_TPALET_get:
	cmpi.b	#16,d1
	bcc	NEW_TPALET_end
	cmpi.b	#8,d1
	bcs	NEW_TPALET_end		* パレット８～１５以外はもとのルーチンに行く

	PUSH	tpalet_register
	movea.l	(vector_TPALET2,pc),a1	* IOCS _TAPLET2 を直接コール
	moveq	#15,d1
	moveq	#-1,d2
	jsr	(a1)
	POP	tpalet_register
	rts

NEW_TPALET_end:
	move.l	(vector_TPALET,pc),-(sp)
	rts

NEW_TPALET_set:
	cmpi.b	#16,d1
	bcc	NEW_TPALET_end
	cmpi.b	#8,d1
	bcc	NEW_TPALET_set_8
	cmpi.b	#4,d1
	bcc	NEW_TPALET_end
	tst.b	d1
	beq	NEW_TPALET_set_0

	PUSH	tpalet_register
	movea.l	(vector_TPALET2,pc),a1
	jsr	(a1)
	bset	#3,d1
	jsr	(a1)
	POP	tpalet_register
	rts

NEW_TPALET_initialize:
	cmpi.b	#16,d1
	bcc	NEW_TPALET_end
	cmpi.b	#8,d1
	bcc	NEW_TPALET_initialize_8
	cmpi.b	#4,d1
	bcc	NEW_TPALET_end
	tst.b	d1
	beq	NEW_TPALET_initialize_0

	PUSH	tpalet_register
	lea	(SRAM_TPAL0),a0
	move.b	d1,d0
	ext	d0
	add	d0,d0
	move	(a0,d0.w),d2
	movea.l	(vector_TPALET2,pc),a1
	jsr	(a1)
	bset	#3,d1
	jsr	(a1)
	POP	tpalet_register
	rts

NEW_TPALET_set_0:
	PUSH	tpalet_register
	bra	@f

NEW_TPALET_initialize_0:
	PUSH	tpalet_register
	move	(SRAM_TPAL0),d2
@@:
	movea.l	(vector_TPALET2,pc),a1
	bsr	NEW_TPALET_initialize_0_sub
	POP	tpalet_register
	rts

NEW_TPALET_initialize_0_sub:
	jsr	(a1)
	move.l	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,d2
	moveq	#8,d1
	jmp	(a1)

NEW_TPALET_set_8:
	PUSH	tpalet_register
	bra	@f

NEW_TPALET_initialize_8:
	PUSH	tpalet_register
	move	(SRAM_TPAL8),d2
@@:
	movea.l	(vector_TPALET2,pc),a1
	bsr	NEW_TPALET_initialize_8_sub
	POP	tpalet_register
	rts

NEW_TPALET_initialize_8_sub:
	moveq	#15,d1
	jsr	(a1)
	.rept	3
	subq	#1,d1
	jsr	(a1)
	.endm

	.irp	pal,3,2,1
	moveq	#pal,d1
	bsr	NEW_TPALET_set_sub
	.endm

	move.l	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,d2
	moveq	#8,d1
	jmp	(a1)

NEW_TPALET_set_sub:
	moveq	#-1,d2
	jsr	(a1)
	move	d0,d2
	bset	#3,d1
	jmp	(a1)

*-------------------------------------------------------------------------------
* _CRTMODの処理

	.text
NEW_CRTMOD:
	move.b	(active_flag,pc),d0
	beq	NEW_CRTMOD_end

	lea	(graphic_data_16_flag,pc),a0
	cmpi	#-1,d1
	beq	@f

	clr.b	(a0)
@@:
	bsr	crtc_check_16
	beq	NEW_CRTMOD_16

	cmpi	#$0110,d1
	beq	@f

	clr.b	(save_force_flag-graphic_data_16_flag,a0)
@@:
	cmpi.b	#16,d1
	beq	NEW_CRTMOD_mask_check
	bhi	NEW_CRTMOD_end
	cmpi.b	#12,d1
	bcc	NEW_CRTMOD_mask_halt
	cmpi.b	#8,d1
	beq	NEW_CRTMOD_gx
	cmpi.b	#4,d1
	beq	NEW_CRTMOD_tone_fixed

NEW_CRTMOD_clear:
	bsr	tram_check_clear
	bsr	gnc64k_check
	tst.l	d0
	beq	NEW_CRTMOD_end

	bsr	graphic_scroll_register_clear
NEW_CRTMOD_initialize:
NEW_CRTMOD_end:
NEW_CRTMOD_16_end:
	move.l	(vector_CRTMOD,pc),-(sp)
	rts

NEW_CRTMOD_gx:
*	move	(VC_R2),d0
*	andi	#$ff,d0
*	move	d0,(VC_R2)
	clr.b	(VC_R2h)
	bra	NEW_CRTMOD_clear

NEW_CRTMOD_tone_fixed:
	cmpi	#$1900,(VC_R2)
	bne	NEW_CRTMOD_clear
	bsr	NEW_CRTMOD_clear
	ori	#$1900,(VC_R2)
	rts

NEW_CRTMOD_mask_64k:			* 明らかに６４Ｋぷにモードのとき
	bsr	gnc64k_check
	tst.l	d0
	beq	NEW_CRTMOD_mask_gnc_off

	bsr	NEW_CRTMOD_tone_save
	move	d0,-(sp)
	bsr	NEW_CRTMOD_mask_64k_mode_change
	move	(sp)+,d0
	bsr	NEW_CRTMOD_mask_graphic_not_clear

	bra	NEW_CRTMOD_clear_half_req_flag

NEW_CRTMOD_tone_save:
	move	#$1900,d0
	cmpi	#$0316,(CRTC_R20)
	bne	@f
	move	(VC_R2),d0
@@:
	move.b	#$1f,d0
	rts

NEW_CRTMOD_mask_64k_mode_change:
	move.l	d1,-(sp)
	move	#$0b16,d1		* モード保存で切り替えする
	moveq	#$1f,d0
	and	(VC_R2),d0
	beq	@f			* グラフィックは消えています
	move	#$0316,d1
@@:
	bsr	NEW_CRTMOD_screen_change
	move.l	(sp)+,d1
	bra	NEW_CRTMOD_screen_initialize

NEW_CRTMOD_mask_gnc_off:
	bsr	NEW_CRTMOD_initialize
NEW_CRTMOD_clear_half_req_flag:
	bsr	tram_check_mask
	lea	(mask_halt_flag,pc),a0
	clr.b	(a0)
	clr.b	(mask_request_flag-mask_halt_flag,a0)
	rts

;mode 16:768x512/16色への変更
NEW_CRTMOD_mask_check:			* 不都合解消ルーチン(^^;
	cmpi	#$001f,(VC_R2)
	beq	@f

	lea	(save_force_flag,pc),a0
	clr.b	(a0)
@@:
	btst	#8,d1
	beq	NEW_CRTMOD_mask_check_flag
	cmpi.b	#$04,(CRTC_R20h)
	bne	NEW_CRTMOD_mask_check_flag
	cmpi	#3,(VC_R0)
	beq	NEW_CRTMOD_clear		;実画面1024x1024の64K色だった

NEW_CRTMOD_mask_check_flag:
	move.b	(mask_disable_flag,pc),d0
	bne	NEW_CRTMOD_mask_disable
	move.b	(mask_enable_flag,pc),d0
	beq	NEW_CRTMOD_mask_enable

	move.b	(mask_request_flag,pc),d0
	bne	NEW_CRTMOD_mask_64k
	move.b	(mask_halt_flag,pc),d0
	bne	NEW_CRTMOD_mask_set_check

	moveq	#$1f,d0
	and	(VC_R2),d0
	beq	NEW_CRTMOD_clear	* グラフィックは消えています
	cmpi	#$0010,d0
	beq	NEW_CRTMOD_clear

	bsr	gpalette_zero_check	* 特殊な例だな
	tst.l	d0
	beq	@f

	bsr	gpalette_check
	tst.l	d0
	beq	NEW_CRTMOD_mask_64k	* ６４Ｋのパレット？
@@:
	bsr	NEW_CRTMOD_tone_save
	move	d0,-(sp)
	bsr	NEW_CRTMOD_initialize	* モード不明
	move	(sp)+,d0
	bsr	force_graphic_data_16_save
	bsr	tram_check_clear

	lea	(mask_halt_flag,pc),a0
	clr.b	(a0)
	clr.b	(mask_request_flag-mask_halt_flag,a0)
force_graphic_data_16_save_end:
	rts

force_graphic_data_16_save:
	move.b	(save_force_flag,pc),d0
	beq	force_graphic_data_16_save_end

	lea	(save_force_flag,pc),a0
	clr.b	(a0)
	bra	graphic_data_16_save

NEW_CRTMOD_mask_set_check:
	bsr	gpalette_check
	tst.l	d0
	beq	NEW_CRTMOD_mask_64k	* ６４Ｋのパレット？
	bra	NEW_CRTMOD_mask_gnc_off

NEW_CRTMOD_mask_halt:
	move.b	(mask_disable_flag,pc),d0
	bne	NEW_CRTMOD_mask_disable
	move.b	(mask_enable_flag,pc),d0
	beq	NEW_CRTMOD_end

	lea	(mask_halt_flag,pc),a0
	st	(a0)			* 次回に備える
	bra	NEW_CRTMOD_clear

NEW_CRTMOD_mask_enable:
	bsr	gnc64k_check
	tst.l	d0
	beq	NEW_CRTMOD_end

	moveq	#$1f,d0
	and	(VC_R2),d0
	beq	NEW_CRTMOD_clear	* グラフィックは消えています
	cmpi	#$0010,d0
	beq	NEW_CRTMOD_clear

	bsr	NEW_CRTMOD_tone_save
	move	d0,-(sp)

	bsr	gpalette_zero_check	* 特殊な例だな
	tst.l	d0
	beq	@f

	bsr	gpalette_check
	tst.l	d0
	beq	NEW_CRTMOD_mask_enable_64k
@@:
	bsr	NEW_CRTMOD_initialize	* 『G』一周中・・・
	bsr	force_graphic_data_16_save
	move	(sp)+,d0		* いらないから捨てる
	bra	NEW_CRTMOD_mask_enable_end
NEW_CRTMOD_mask_enable_64k:
	bsr	NEW_CRTMOD_mask_64k_mode_change
	move	(sp)+,d0
	bsr	NEW_CRTMOD_mask_graphic_not_clear
NEW_CRTMOD_mask_enable_end:
	bsr	tram_check_clear

	lea	(mask_request_flag,pc),a0
	clr.b	(a0)
	rts

NEW_CRTMOD_mask_disable:
	bsr	tram_check_clear
	lea	(mask_halt_flag,pc),a0
	clr.b	(a0)			* 禁止中はマスクなんかいらない
	clr.b	(mask_request_flag-mask_halt_flag,a0)

	cmpi.b	#16,d1
	bne	NEW_CRTMOD_end
	bra	NEW_CRTMOD_mask_enable

mask_graphic_not_clear_register	reg	d1/a0-a1

NEW_CRTMOD_mask_graphic_not_clear:
	PUSH	mask_graphic_not_clear_register
	move	d0,d1
	bsr	gram_check
	tst.l	d0
	bne	NEW_CRTMOD_mask_graphic_not_clear_end

	lea	(VC_R2),a1
	moveq	#$60,d0
	and	(a1),d0
	or	d0,d1

	lea	(CRTC_R12-VC_R2,a1),a0	* グラフィック・スクロール・レジスタのアドレス
					* 画面中央に来るようにする
	move.l	#$ff80_0000,d0
	.rept	4
	move.l	d0,(a0)+
	.endm

	moveq	#%111,d0
	and	(VC_R0-VC_R2,a1),d0
	lsl	#8,d0
	move.b	(1,a0),d0
	move	d0,(a0)
	move	d1,(a1)			* トーンダウン＋６４Ｋ色表示
NEW_CRTMOD_mask_graphic_not_clear_end:
	POP	mask_graphic_not_clear_register
	rts

*-------------------------------------------------------------------------------
* _CRTMODの１６色用のルーチン

	.text
NEW_CRTMOD_16:
	bsr	tram_check_clear

	lea	(save_force_flag,pc),a0
	cmpi	#$010c,d1
	seq	(a0)

	move.b	(gnc_flag,pc),d0
	beq	NEW_CRTMOD_16_end
*NEW_CRTMOD_16_check:
	cmpi.b	#16,d1
	bne	NEW_CRTMOD_16_end

*NEW_CRTMOD_16_gnc:
	move.l	d1,-(sp)
	move	#$0c16,d1		* モード保存で切り替えする
	moveq	#$1f,d0
	and	(VC_R2),d0
	beq	@f			* グラフィックは消えています
	move	#$0416,d1
@@:
	bsr	NEW_CRTMOD_screen_change
	move.l	(sp)+,d1
	btst	#8,d1
	beq	@f
	bsr	graphic_scroll_register_clear
@@:
	bra	NEW_CRTMOD_screen_initialize

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
* 常駐パレット機能（謎）

graphic_palette_16_save_register	reg	d0/a0-a1

	.text
graphic_palette_16_save:
	PUSH	graphic_palette_16_save_register
	lea	(GRAPHIC_PAL),a0
	lea	(graphic_palette_16,pc),a1
	st	(graphic_palette_16_flag-graphic_palette_16,a1)

	moveq	#16-1,d0
	_HSYNC_WAIT
graphic_palette_16_save_loop:
	_HSYNC_WAIT2
	move	(a0)+,(a1)+
	dbra	d0,graphic_palette_16_save_loop

	POP	graphic_palette_16_save_register
	rts

*-------------------------------------------------------------------------------
* グラフィックが書き換わったか調べる（いい加減なやつ・・・）

graphic_data_16_check_register	reg	d0-d1/a0-a1

	.text
graphic_data_16_check:
	PUSH	graphic_data_16_check_register

	btst	#3,(CRTC_R20h)
	bne	graphic_data_16_check_end
	moveq	#$1f,d0
	and	(VC_R2),d0
	bclr	#4,d0
	bne	@f
	tst	d0
	beq	graphic_data_16_check_end	* グラフィックは消えています
@@:
	lea	(graphic_data_16,pc),a1
	lea	(G_VRAM),a0
	moveq	#4,d1
	swap	d1

	.irp	offset,0,$400
	move	(offset,a0),d0
	cmp	(a1)+,d0
	bne	graphic_data_16_check_new
	.endm

	adda.l	d1,a0
	.irp	offset,$100,$300
	move	(offset,a0),d0
	cmp	(a1)+,d0
	bne	graphic_data_16_check_new
	.endm

	adda.l	d1,a0
	move	($200,a0),d0
	cmp	(a1)+,d0
	bne	graphic_data_16_check_new

	adda.l	d1,a0
	.irp	offset,$100,$300
	move	(offset,a0),d0
	cmp	(a1)+,d0
	bne	graphic_data_16_check_new
	.endm

	adda.l	d1,a0
	.irp	offset,0,$400
	move	(offset,a0),d0
	cmp	(a1)+,d0
	bne	graphic_data_16_check_new
	.endm

	lea	(graphic_data_16_flag,pc),a0
	st	(a0)				* 以後のチェックを省く
	bra	graphic_data_16_check_end	* おそらく書き換わってない・・・

graphic_data_16_check_new:
	lea	(G_VRAM),a0
	moveq	#0,d0
	move	(a0),d0
	or	($400,a0),d0
	adda.l	d1,a0
	or	($100,a0),d0
	or	($300,a0),d0
	adda.l	d1,a0
	or	($200,a0),d0
	adda.l	d1,a0
	or	($100,a0),d0
	or	($300,a0),d0
	adda.l	d1,a0
	or	(a0),d0
	or	($400,a0),d0
	beq	graphic_data_16_check_end	* クリア中・・・

	bsr	graphic_data_16_save		* グラフィックデータの保存
	bsr	graphic_palette_16_save		* パレットデータの保存
graphic_data_16_check_end:
	POP	graphic_data_16_check_register
	rts

graphic_data_16_save:
	PUSH	d1/a0-a1
	moveq	#4,d1
	swap	d1
	lea	(G_VRAM),a0
	lea	(graphic_data_16,pc),a1
	st	(graphic_data_16_flag-graphic_data_16,a1)

	move	(a0),(a1)+
	move	($400,a0),(a1)+
	adda.l	d1,a0
	move	($100,a0),(a1)+
	move	($300,a0),(a1)+
	adda.l	d1,a0
	move	($200,a0),(a1)+
	adda.l	d1,a0
	move	($100,a0),(a1)+
	move	($300,a0),(a1)+
	adda.l	d1,a0
	move	(a0),(a1)+
	move	($400,a0),(a1)+

	POP	d1/a0-a1
	rts

*-------------------------------------------------------------------------------
* 画面モードを切り替えて・・・（７６８×５１２専用）
*
* entry:
*   d1.w = $e80028 に設定する値

	.text
NEW_CRTMOD_screen_change:
	move.b	#16,($93c)		* 現在の画面モードを保存

	clr	d0
	move.b	($992),d0		* カーソル表示フラグ
	move	d0,-(sp)
	movea.l	($400+_B_CUROFF*4),a0
	jsr	(a0)

	lea	(CRTC_R00),a0
	bsr	vdisp_wait
	move	(VC_R2-CRTC_R00,a0),d0
	clr	(VC_R2-CRTC_R00,a0)
	move	d1,(CRTC_R20-CRTC_R00,a0)

		*    |	    水平      |		垂直	 |   | ラスター割り込み位置
	.irp	data,$89_000e,$1c_007c,$237_0005,$28_0228,$1b_0000
	move.l	#data,(a0)+
	.endm
	clr.l	(a0)+			* テキスト・スクロール・レジスタ

	lsr	#8,d1
	andi	#%111,d1
	move	d1,(VC_R0)

	moveq	#-1,d1
	lea	(BGSR_BG0),a0
	move.l	d1,(a0)+		* ＢＧスクロール・レジスタ
	move.l	d1,(a0)+
	and	#$fff6,(a0)+		* ＢＧコントロール
	move.l	d1,(a0)+		* 画面モード・レジスタ
	move.l	d1,(a0)+

	lea	(CRTC_R12),a0		* グラフィック・スクロール・レジスタのアドレス
					* 画面中央に来るようにする
	move	(CRTC_R20-CRTC_R12,a0),d1
	andi	#$03ff,d1
	cmpi	#$0316,d1
	bne	@f

	move.l	#$ff80_0000,d1
	.rept	4
	move.l	d1,(a0)+
	.endm
@@:
	move	d0,(VC_R2)

	clr.l	($948)			* テキスト表示開始アドレスオフセット
	bsr	_graphic_color_max	* グラフィック画面の色数－１
	bsr	_graphic_line_length	* グラフィックＶＲＡＭ横サイズ
	bsr	_graphic_window		* グラフィッククリッピングエリア

	move.l	#(96-1)<<16+(32-1),($970)	* テキスト桁数-1 | 行数-1
	clr.l	($974)			* カーソル位置
	clr.l	($a9a)			* マウスカーソル移動範囲
	move.l	#(768-1)<<16+(512-1),($a9e)

	move	(sp)+,d0
	beq	NEW_CRTMOD_screen_change_end
	movea.l	($400+_B_CURON*4),a0
	jmp	(a0)

*-------------------------------------------------------------------------------
* 画面を初期化する（グラフィックパレット以外）

NEW_CRTMOD_screen_initialize_register	reg	d0-d2/a1

	.text
NEW_CRTMOD_screen_initialize:
	PUSH	NEW_CRTMOD_screen_initialize_register
	btst	#8,d1
	bne	NEW_CRTMOD_screen_initialize_end

	moveq	#2,d1
	movea.l	($400+_B_CLR_ST*4),a1
	jsr	(a1)			* 画面のクリア
	ori	#$20,(VC_R2)		* テキスト表示オン

	moveq	#-2,d1
	movea.l	($400+_CONTRAST*4),a1
	jsr	(a1)			* コントラスト初期化

	moveq	#-2,d2
	movea.l	($400+_TPALET*4),a1
	.irp	pal,0,1,2,3,4,8
	moveq	#pal,d1
	jsr	(a1)			* テキストパレット初期化
	.endm
NEW_CRTMOD_screen_initialize_end:
	POP	NEW_CRTMOD_screen_initialize_register
NEW_CRTMOD_screen_change_end:
	rts

*-------------------------------------------------------------------------------
* グラフィック・スクロール・レジスタをクリアする

	.text
graphic_scroll_register_clear:
	lea	(CRTC_R12),a0
	.rept	4
	clr.l	(a0)+
	.endm
	rts

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
* ＧＮＣモードが利用できるか調べる
*
* return:
*   d0.l  = 0 ＧＮＣ６４Ｋモードではありません
*        != 0 ぷにぷに６４Ｋモードです

	.text
gnc64k_check:
	move.b	(gnc_flag,pc),d0
	beq	gnc64k_check_not_gnc64k

	moveq	#$1f,d0
	and	(VC_R2),d0
	beq	gnc64k_check_not_gnc64k	* グラフィックは消えています

	btst	#1,(VC_R0l)
	beq	gnc64k_check_not_gnc64k
*gnc64k_check_gnc64k:
	moveq	#-1,d0
	rts

gnc64k_check_not_gnc64k:
	moveq	#0,d0
	rts

*-------------------------------------------------------------------------------
* グラフィックパレットを６４Ｋ用に設定します

gpalette_set_register	reg	d0-d2/a0

	.text
gpalette_set:
	PUSH	gpalette_set_register
	lea	(GRAPHIC_PAL),a0
	move.l	#$00010001,d0
	move.l	#$02020202,d1
	moveq	#128-1,d2
	bsr	vdisp_wait
gpalette_set_loop:
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
*gpalette_sum:
*	.dc.l	0
gpalette_check:
	PUSH	gpalette_check_register
	lea	(GRAPHIC_PAL),a0
	move	#256-1,d2
	moveq	#0,d3
	clr	d4
	moveq	#0,d0
	_HSYNC_WAIT
gpalette_check_loop:
	_HSYNC_WAIT2
	move	(a0)+,d0
	add.l	d0,d3
	eor	d0,d4
	dbra	d2,gpalette_check_loop

*	move.l	d3,gpalette_sum
	move	d4,d0
	ext.l	d0
gpalette_check_end:
	POP	gpalette_check_register
	rts

*-------------------------------------------------------------------------------
* グラフィックパレットが０か調べる
*
* return
*  d0.l  = 0 ０です.
*       != 0 違うね

gpalette_zero_check_register	reg	d1-d2/a0

	.text
gpalette_zero_check:
	PUSH	gpalette_zero_check_register
	lea	(GRAPHIC_PAL),a0
	moveq	#16-1,d2
	moveq	#0,d0
	moveq	#0,d1
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	move	(a0)+,d1
	add.l	d1,d0
	dbra	d2,@b
	POP	gpalette_zero_check_register
gpalette_check_set_end:
	rts

*-------------------------------------------------------------------------------
* グラフィックパレットが６４Ｋ用のものか調べて、違ったら設定する

	.text
gpalette_check_set:
	bsr	gram_check
	tst.l	d0
	bne	gpalette_check_set_end

	bsr	gpalette_check
	tst.l	d0
	beq	gpalette_check_set_end

	bra	gpalette_set

*-------------------------------------------------------------------------------
* テキスト、グラフィックラムの使用フラグを見てマスクをする

	.text
tram_check_mask:
	bsr	tram_check
	tst.l	d0
	bne	tram_check_mask_end

	bsr	gram_check
	tst.l	d0
	beq	mask_sub
tram_check_mask_end:
	rts

*-------------------------------------------------------------------------------
* テキストラムの使用フラグを見てマスククリアをする

	.text
tram_check_clear:
	move.b	(mask_set_flag,pc),d0
	beq	tram_check_clear_end

	bsr	tram_check
	tst.l	d0
	beq	clear_sub
tram_check_clear_end:
	rts

*-------------------------------------------------------------------------------
* _TGUSEMDの拡張ルーチン
*
* entry:
*   d1.b    = 0  グラフィック（$C00000 ～ $DFFFFF）
*   d1.b    = 1  テキスト（$E40000 ～ $E7FFFF）
*
*   d1.l hw = 'gm'  内部コール(拡張コール)モード
*
*        lw = $ff80 ＧＭバージョンナンバの読み取り
*        lw = $ff81 マスク状態の読み取り
*        lw = $ff82 ＧＮＣ状態の読み取り
*        lw = $ff83 オートマスク状態の読み取り
*        lw = $ff84 グラフィックモードの読み取り
*        lw = $ff85 ＧＭ主要機能の動作状況を見る(今のところ動作／停止しか返さない)
*        lw = $ff88 マスクリクエスト
*        lw = $ff89 マスク設定
*        lw = $ff8a マスク解除
*        lw = $ff8b オートマスク禁止
*        lw = $ff8c オートマスク許可
*        lw = $ff8d ＧＭの動作開始
*        lw = $ff8e ＧＭの動作停止
*        lw = $ff90 常駐パレット(16色)の先頭アドレスを得る
*        lw = $ff91 現在のパレットを強制保存
*        lw = $ff92 GVRAMのみ強制保存（パレットはそのまま）
*        lw = 上記以外 もとのルーチンを無条件コール
*
*   ☆この$ff80などの定数は余ほどのことがない限り変更はしないが
*     gm_internal.mac を使用する方がよい。
*
* return:
*   d0.l hw = ($ff80) バージョンナンバ
*        hw = ($ff81) マスク状態	0:マスクなし	0以外:マスクあり
*        hw = ($ff82) ＧＮＣ状態	0:無効		0以外:有効
*        hw = ($ff83) オートマスク状態	bit0:禁止	bit1:許可	(0:なし 1:あり)
*                   （内部で使用する） %00 禁止しない、マスクを新しく書くのは許可されない
*                    オートマスク許可  %10 禁止しない、マスクを新しく書くのは許可される
*                    オートマスク禁止  %01 禁止する、マスクを新しく書くのは許可されない
*                   （内部で使用する） %11 禁止する、マスクを新しく書くのは許可される
*        hw = ($ff84) グラフィックモード	0:６４Ｋ以外	0以外:６４Ｋモード
*        hw = ($ff85) ＧＭ主要機能の動作状況	0:停止		0以外:動作
*        hw = ($ff90) 常駐パレットの状態	0:無効		0以外:有効(a1.lにアドレス)
*        hw = その他は不定
*
*        lw = 'gm' 内部コール成功
*
*   d0.l    = -1 ＧＭが存在しない、または拡張コールがサポート範囲外
*
*   ☆拡張コールは d0.l 以外は保存される。
*     リターンの下位ワードに識別コードがあるので注意すること。

	.text
NEW_TGUSEMD:
	swap	d1
	cmpi	#_GM_INTERNAL_MODE,d1
	beq	NEW_TGUSEMD_internal
	swap	d1

	lea	(mask_enable_flag,pc),a0
	clr.b	(graphic_data_16_flag-mask_enable_flag,a0)

	cmpi.b	#1,d1
	beq	NEW_TGUSEMD_text
	bhi	NEW_TGUSEMD_end
	bra	NEW_TGUSEMD_graphic

NEW_TGUSEMD_graphic:
	cmpi.b	#-1,d2
	beq	NEW_TGUSEMD_clear
	cmpi.b	#4,d2
	bcc	NEW_TGUSEMD_end

	cmpi.b	#2,d2			;アプリケーションで使用するならフラグセット
	seq	(g_use_flag-mask_enable_flag,a0)

	bra	NEW_TGUSEMD_clear

NEW_TGUSEMD_text:
	cmpi.b	#-1,d2
	beq	NEW_TGUSEMD_end
	cmpi.b	#4,d2
	bcc	NEW_TGUSEMD_end
	cmpi.b	#2,d2
	beq	NEW_TGUSEMD_text_2

	st	(a0)			* mask_enable_flag
	tst.b	(mask_halt_flag-mask_enable_flag,a0)
	bne	NEW_TGUSEMD_mask
	bra	NEW_TGUSEMD_end

NEW_TGUSEMD_text_2:
	tst.b	(mask_set_flag-mask_enable_flag,a0)
	sne	(mask_halt_flag-mask_enable_flag,a0)
	beq	NEW_TGUSEMD_clear

	clr.b	(a0)			* mask_enable_flag
NEW_TGUSEMD_clear:
	bsr	tram_check_clear
	clr.b	(mask_request_flag-mask_enable_flag,a0)
NEW_TGUSEMD_end:
call_orig_tgusemd:
	move.l	(vector_TGUSEMD,pc),-(sp)
	rts

NEW_TGUSEMD_mask:
	move.b	(mask_disable_flag,pc),d0
	bne	NEW_TGUSEMD_end
	move.b	(mask_enable_flag,pc),d0
	beq	NEW_TGUSEMD_end

	movea.l	(vector_TGUSEMD,pc),a0
	jsr	(a0)
	cmpi	#$0316,(CRTC_R20)
	bne	NEW_TGUSEMD_mask_end
	bsr	tram_check_mask

	lea	(mask_halt_flag,pc),a0
	clr.b	(a0)
	clr.b	(mask_request_flag-mask_halt_flag,a0)
NEW_TGUSEMD_mask_end:
	rts

NEW_TGUSEMD_internal_MIN:	.equ	$ff80
NEW_TGUSEMD_internal_MAX:	.equ	$ff92

NEW_TGUSEMD_internal:
	swap	d1
	cmpi	#NEW_TGUSEMD_internal_MIN,d1
	bcs	NEW_TGUSEMD_end
	cmpi	#NEW_TGUSEMD_internal_MAX,d1
	bhi	NEW_TGUSEMD_end

	move	d1,d0
	sub	#NEW_TGUSEMD_internal_MIN,d0
	add	d0,d0
	lea	(NEW_TGUSEMD_jump_table,pc),a0
	adda	(a0,d0.w),a0
	jsr	(a0)
	swap	d0
	move	#_GM_INTERNAL_MODE,d0
	rts

NEW_TGUSEMD_jump_table:
@@:	.dc	NEW_TGUSEMD_internal_version-@b		* ff80
	.dc	NEW_TGUSEMD_internal_mask_state-@b	* ff81
	.dc	NEW_TGUSEMD_internal_gnc_state-@b	* ff82
	.dc	NEW_TGUSEMD_internal_auto_state-@b	* ff83
	.dc	NEW_TGUSEMD_internal_graphic_mode_state-@b	* ff84
	.dc	NEW_TGUSEMD_internal_active_state-@b	* ff85
	.dc	NEW_TGUSEMD_end-@b			* ff86
	.dc	NEW_TGUSEMD_end-@b			* ff87
	.dc	NEW_TGUSEMD_internal_mask_request-@b	* ff88
	.dc	NEW_TGUSEMD_internal_mask_set-@b	* ff89
	.dc	NEW_TGUSEMD_internal_mask_clear-@b	* ff8a
	.dc	NEW_TGUSEMD_internal_auto_disable-@b	* ff8b
	.dc	NEW_TGUSEMD_internal_auto_enable-@b	* ff8c
	.dc	NEW_TGUSEMD_internal_active-@b		* ff8d
	.dc	NEW_TGUSEMD_internal_inactive-@b	* ff8e
	.dc	NEW_TGUSEMD_end-@b			* ff8f
	.dc	NEW_TGUSEMD_internal_keep_palette-@b	* ff90
	.dc	NEW_TGUSEMD_internal_palette_save-@b	* ff91
	.dc	NEW_TGUSEMD_internal_gvram_save-@b	* ff92

NEW_TGUSEMD_internal_version:
	move	#GM_VERSION,d0
	rts

NEW_TGUSEMD_internal_mask_state:
	move.b	(mask_set_flag,pc),d0
	sne	d0
	ext	d0
	rts

NEW_TGUSEMD_internal_gnc_state:
	move.b	(gnc_flag,pc),d0
	sne	d0
	ext	d0
	rts

NEW_TGUSEMD_internal_auto_state:
	clr	d0
	move.b	(mask_enable_flag,pc),d0
	sne	d0
	add	d0,d0
	move.b	(mask_disable_flag,pc),d0
	sne	d0
	lsr	#7,d0
	rts

NEW_TGUSEMD_internal_graphic_mode_state:
	bsr	crtc_check_16
	sne	d0
	ext	d0
	rts

NEW_TGUSEMD_internal_active_state:
	move.b	(active_flag,pc),d0
	sne	d0
	ext	d0
	rts

NEW_TGUSEMD_internal_mask_request:
	lea	(mask_request_flag,pc),a0
	st	(a0)
@@:	rts

NEW_TGUSEMD_internal_mask_set:
	bsr	crtc_check_16
	beq	@b			* マスクをするのは６４Ｋの画像のみです
	btst	#1,(CRTC_R20h)
	beq	@b

	bsr	mask_sub
	bra	@f

NEW_TGUSEMD_internal_mask_clear:
	bsr	clear_sub
@@:
	lea	(mask_halt_flag,pc),a0
	clr.b	(a0)
	clr.b	(mask_request_flag-mask_halt_flag,a0)
	rts

NEW_TGUSEMD_internal_auto_disable:
	lea	(mask_disable_flag,pc),a0
	st	(a0)+
	clr.b	(mask_enable_flag-(mask_disable_flag+1),a0)
	rts

NEW_TGUSEMD_internal_auto_enable:
	lea	(mask_disable_flag,pc),a0
	clr.b	(a0)+
	st	(mask_enable_flag-(mask_disable_flag+1),a0)
	rts

NEW_TGUSEMD_internal_active:
	lea	(active_flag,pc),a0
	st	(a0)
	.ifdef	__DEBUG_ACT__
	PUSH	d0/a1
	lea	(@f,pc),a1
	IOCS	_B_PRINT
	POP	d0/a1
	bra	@@f
@@:	.dc.b	'gm: active',13,10,0
	.even
@@:
	.endif
	rts

NEW_TGUSEMD_internal_inactive:
	lea	(active_flag,pc),a0
	clr.b	(a0)
	.ifdef	__DEBUG_ACT__
	PUSH	d0/a1
	lea	(@f,pc),a1
	IOCS	_B_PRINT
	POP	d0/a1
	bra	@@f
@@:	.dc.b	'gm: inactive',13,10,0
	.even
@@:
	.endif
	rts

NEW_TGUSEMD_internal_keep_palette:
	move.b	(graphic_palette_16_flag,pc),d0
	sne	d0
	ext	d0
	lea	(graphic_palette_16,pc),a1
	rts

NEW_TGUSEMD_internal_palette_save:
	pea	(graphic_palette_16_save,pc)
	bra	@f

NEW_TGUSEMD_internal_gvram_save:
	pea	(graphic_data_16_save,pc)
@@:
	lea	(check_force_flag,pc),a0
	clr.b	(a0)+
	clr.b	(save_force_flag-(check_force_flag+1),a0)
	rts

*-------------------------------------------------------------------------------
* _G_CLR_ONの処理

gstop_gvram_used_mes:
	.dc.b	' グラフィック画面は占有されています、使用不可能です ',0
	.even

	.text
NEW_G_CLR_ON:
	move.b	(active_flag,pc),d0
	beq	NEW_G_CLR_ON_end

*** gstop start ***

	move.b	(gstop_flag,pc),d0
	beq	NEW_G_CLR_ON_gstop_end
	move.b	(g_use_flag,pc),d0
	bne	NEW_G_CLR_ON_gstop_end		;自分で占有して使うならOK

	PUSH	d1-d7/a1-a6
	moveq	#0,d1
	moveq	#-1,d2
	bsr	call_orig_tgusemd
	tst.b	d0
	beq	@f
	subq.b	#3,d0
	beq	@f

	move	#$1000,d7			* 中止のみ
	lea	(gstop_gvram_used_mes,pc),a5	* 表示文字列
	trap	#14
@@:
	POP	d1-d7/a1-a6
NEW_G_CLR_ON_gstop_end:

*** gstop end ***

	lea	(graphic_data_16_flag,pc),a0
	clr.b	(a0)

	move.b	(gnc_flag,pc),d0
	beq	NEW_G_CLR_ON_gnc_off

	bsr	graphic_scroll_register_clear
NEW_G_CLR_ON_gnc_off:
	bsr	tram_check_clear
	lea	(mask_request_flag,pc),a0
	clr.b	(a0)
NEW_G_CLR_ON_end:
	bra	NEW_G_CLR_ON_sub

NEW_G_CLR_ON_sub:
	PUSH	d1-d7/a1-a6
	move	#$20,(VC_R2)
	bset	#3,(CRTC_R20h)

	moveq	#0,d1
	.irp	reg,d2,d3,d4,d5,d6,d7,a1,a2,a3,a4,a5,a6
	move.l	d1,reg
	.endm
	lea	(G_VRAM+512*1024),a0
	move	#512-1,d0
NEW_G_CLR_ON_sub_loop:
	.rept	19
	movem.l	d1-d7/a1-a6,-(a0)	* 13*4=52*19=988
	.endm
	movem.l	d1-d7/a1-a2,-(a0)	* 9*4=36+988=1024
	dbra	d0,NEW_G_CLR_ON_sub_loop

	move.l	a0,($95c)		* active page address
	bclr	#3,(CRTC_R20h)

	moveq	#%11111000,d0
	and.b	(CRTC_R20h),d0
	moveq	#%00001111,d1
	and.b	($93c),d1
	cmpi.b	#4,d1
	bcc	@f
	bset	#2,d0
@@:
	cmpi.b	#8,d1
	bcs	@f
	bset	#0,d0
@@:
	cmpi.b	#12,d1
	bcs	@f
	bset	#1,d0
@@:
	moveq	#%00000111,d1
	and.b	d0,d1
	move.b	d0,(CRTC_R20h)
	move	d1,(VC_R0)

	andi	#%0000_0011,d0
	bne	@f
	bsr	NEW_G_CLR_ON_sub_palette_16
	bra	NEW_G_CLR_ON_sub_end
@@:
	subq	#1,d0
	bne	@f
	bsr	NEW_G_CLR_ON_sub_palette_256
	bra	NEW_G_CLR_ON_sub_end
@@:
	bsr	gpalette_set
NEW_G_CLR_ON_sub_end:
	bsr	_graphic_color_max
	bsr	_graphic_line_length
	bsr	_graphic_window
	bclr	#3,(CRTC_R20h)
	move	#$3f,(VC_R2)

	POP	d1-d7/a1-a6
	rts

gpalette_data_16:
	.dc	$0000,$5294,$0020,$003e,$0400,$07c0,$0420,$07fe
	.dc	$8000,$f800,$8020,$f83e,$8400,$ffc0,$ad6a,$fffe

	.even
NEW_G_CLR_ON_sub_palette_16:
	lea	(GRAPHIC_PAL),a0
	lea	(gpalette_data_16,pc),a1
	moveq	#16/2-1,d0
@@:
	move.l	(a1)+,(a0)+
	dbra	d0,@b
	rts

gpalette_data_256_g:				* G は 2bit
	.dc.b	31,21,10,0
gpalette_data_256_rb:				* R, B は 3bit づつ
	.dc.b	31,27,22,18,13,9,4,0

	.even
NEW_G_CLR_ON_sub_palette_256:
	lea	(gpalette_data_256_g,pc),a0
	lea	(gpalette_data_256_rb,pc),a1
	lea	(GRAPHIC_PAL),a2

	move	#4-1,d7
NEW_G_CLR_ON_sub_palette_256_g_loop:
	clr	d4
	move.b	(a0,d7.w),d4
	ror	#5,d4

		move	#8-1,d6
NEW_G_CLR_ON_sub_palette_256_r_loop:
		clr	d3
		move.b	(a1,d6.w),d3
		lsl	#6,d3

			move	#8-1,d5
NEW_G_CLR_ON_sub_palette_256_b_loop:
			clr	d2
			move.b	(a1,d5.w),d2	* B
			add	d2,d2		* I ビットは０
			or	d3,d2		* R
			or	d4,d2		* G
			move	d2,(a2)+
			dbra	d5,NEW_G_CLR_ON_sub_palette_256_b_loop

		dbra	d6,NEW_G_CLR_ON_sub_palette_256_r_loop

	dbra	d7,NEW_G_CLR_ON_sub_palette_256_g_loop
	rts

*-------------------------------------------------------------------------------
* テキストラムが使用中か調べる
*
* return:
*    d0.l = 0  未使用
*    d0.l = -1 アプリケーションで使用中

tram_check_register	reg	d1-d2

	.text
tram_check:
	PUSH	tram_check_register
	moveq	#1,d1			* 内部からのコール
	bsr	_gm_internal_tgusemd_d2m1
	move.b	d0,d1
	moveq	#0,d0
	cmpi.b	#2,d1
	bne	tram_check_end

	move.b	(force_flag,pc),d0
	bne	tram_check_force	* 強制使用モード

	moveq	#-1,d0			* アプリケーションで使用中
tram_check_end:
	POP	tram_check_register
	rts

tram_check_force:
	moveq	#1,d1			* 強制的にシステムで使います
	moveq	#1,d2
	bsr	_gm_internal_tgusemd
	moveq	#0,d0
	bra	tram_check_end

*-------------------------------------------------------------------------------
* グラフィックラムが使用中か調べる
*
* return:
*    d0.l = 0  未使用
*    d0.l = -1 アプリケーションで使用中

gram_check_register	reg	d1-d2

	.text
gram_check:
	PUSH	gram_check_register
	moveq	#0,d1			* 内部からのコール
	bsr	_gm_internal_tgusemd_d2m1
	move.b	d0,d1
	moveq	#0,d0
	cmpi.b	#2,d1
	bne	gram_check_end
	moveq	#-1,d0			* アプリケーションで使用中
gram_check_end:
	POP	gram_check_register
	rts

*-------------------------------------------------------------------------------
* 内部モードで TGUSEMD をコールする

	.text
_gm_internal_tgusemd_d2m1:
	moveq	#-1,d2
_gm_internal_tgusemd:
	swap	d1
	move	#_GM_INTERNAL_MODE,d1
	swap	d1
	IOCS	_TGUSEMD
	rts

*-------------------------------------------------------------------------------
* マスクしちゃうの

mask_sub_register	reg	d1-d2/a0-a1

	.text
mask_sub:
	PUSH	mask_sub_register

	lea	(mask_disable_flag,pc),a0
	tst.b	(a0)+
	bne	mask_sub_end
	move.b	(mask_enable_flag-(mask_disable_flag+1),a0),d0
	beq	mask_sub_end

	st	(mask_set_flag-(mask_disable_flag+1),a0)

	IOCS	_MS_STAT
	move	d0,-(sp)
	IOCS	_MS_CUROF

	.ifdef	__DEBUG__
COLOR	equ	8
	.else
COLOR	equ	0
	.endif

					* テキストパレット８～１１を変更する
	lea	(TPALET+2*1),a0
	lea	(2*8-2*1,a0),a1

	_HSYNC_WAIT
	move	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,(a1)+
	_HSYNC_WAIT2
	move	(a0)+,(a1)+
	_HSYNC_WAIT2
	move.l	(a0)+,(a1)+

	moveq	#-1,d0
	bsr	text_paint

	move	(sp)+,d0
	beq	mask_sub_end
	IOCS	_MS_CURON
mask_sub_end:
	POP	mask_sub_register
	rts

*-------------------------------------------------------------------------------
* マスクはずすの

clear_sub_register	reg	d1-d2/a0-a1

	.text
clear_sub:
	PUSH	clear_sub_register

	lea	(mask_set_flag,pc),a0
	clr.b	(a0)

	IOCS	_MS_STAT
	move	d0,-(sp)
	IOCS	_MS_CUROF

	moveq	#0,d0
	bsr	text_paint

					* テキストパレットをもとにもどす
	lea	(TPALET+2*14),a0
	lea	(2*8-2*14,a0),a1
	_HSYNC_WAIT
	move.l	(a0),(a1)+
	_HSYNC_WAIT2
	move.l	(a0),(a1)+

	move	(sp)+,d0
	beq	clear_sub_end
	IOCS	_MS_CURON
clear_sub_end:
	POP	clear_sub_register
	rts

*-------------------------------------------------------------------------------
*
* entry:
*   d0.l = 塗りつぶすデータ

text_paint_register	reg	d1-d5/a0-a1

	.text
text_paint:
	PUSH	text_paint_register
	.irp	reg,d1,d2,d3,d4
	move.l	d0,reg
	.endm

	lea	(TVRAM_P3),a0
	move	#($0080*4),d5
	move	#(512/4)-1,d0

	lea	(CRTC_R21),a1
	move	(a1),-(sp)
	clr.b	(a1)
text_paint_loop:
offset:	.set	0
	.rept	4
	movem.l	d1-d4,(offset,a0)	* テキストプレーン塗りつぶし
	movem.l	d1-d4,(offset+$50,a0)
offset:	.set	offset+$80
	.endm
	add	d5,a0
	dbra	d0,text_paint_loop

	move	(sp)+,(a1)
	POP	text_paint_register
	rts

*-------------------------------------------------------------------------------
* ここまで常駐させる

graphic_palette_16:
*	.ds	16
graphic_data_16:	.equ	graphic_palette_16+16*2
*	.ds	9
program_keep_end:	.equ	graphic_data_16+9*2


*-------------------------------------------------------------------------------
* オプションスイッチの定義

	.offset	0
OPT_M	.ds.b	1	* グラフィックマスク設定
OPT_C	.ds.b	1	* グラフィックマスク解除
OPT_D	.ds.b	1	* グラフィックオートマスク不許可
OPT_E	.ds.b	1	* グラフィックオートマスク許可
OPT_F	.ds.b	1	* テキストラムを強制使用する
OPT_N	.ds.b	1	* ＧＮＣモードを有効にする
OPT_K	.ds.b	1	* 電卓消去時にマスクをなおす
OPT_G	.ds.b	1	* グラフィック使用モードを監視する
OPT_V	.ds.b	1	* バージョン表示、メッセージの表示
OPT_P	.ds.b	1	* メモリ常駐
OPT_R	.ds.b	1	* 常駐解除
OPT_A	.ds.b	1	* 主要機能の動作
OPT_S	.ds.b	1	* 状態保存
OPT_HLP	.ds.b	1	* ヘルプ表示
	.fail	15<=$
OPT_ERR	.equ	15	* スイッチ指定の間違いなど：常に最上位ビット

	.text

*-------------------------------------------------------------------------------
* ここからメインプログラム

	.text
	.even

program_start:
	pea	(program_stack_end-program_text_start+STACK_SIZE+$f0).w
	pea	(16,a0)
	DOS	_SETBLOCK
	movea.l	(sp)+,a0		*
	adda.l	(sp)+,a0		* base of stack
	tst.l	d0
	bmi	program_error_setblock
	lea	(a0),sp

switch_check:
	moveq	#0,d7			* d7.w = オプションスイッチ
	bsr	option_check
	cmpi	#1<<OPT_V,d7
	beq	print_version
	tst	d7
	bne	exec_option
	ori	#1<<OPT_HLP+1<<OPT_V,d7	* スイッチがなければ使用法表示
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
		cmpi.b	#'M',d0
		beq	opt_m
		cmpi.b	#'C',d0
		beq	opt_c
		cmpi.b	#'D',d0
		beq	opt_d
		cmpi.b	#'E',d0
		beq	opt_e
		cmpi.b	#'F',d0
		beq	opt_f
		cmpi.b	#'N',d0
		beq	opt_n
		cmpi.b	#'K',d0
		beq	opt_k
		cmpi.b	#'G',d0
		beq	opt_g
		cmpi.b	#'V',d0
		beq	opt_v
		cmpi.b	#'P',d0
		beq	opt_p
		cmpi.b	#'R',d0
		beq	opt_r
		cmpi.b	#'A',d0
		beq	opt_a
		cmpi.b	#'S',d0
		beq	opt_s
		cmpi.b	#'H',d0
		beq	opt_h
option_check_error:
		bset	#OPT_ERR,d7
option_check_end:
		rts

opt_h:
		ori	#1<<OPT_HLP+1<<OPT_V,d7
		bra	option_check_next

opt_m:
		moveq	#OPT_M,d0
		moveq	#OPT_C,d1
		bra	@f
opt_c:
		moveq	#OPT_C,d0
		moveq	#OPT_M,d1
		bra	@f
opt_d:
		moveq	#OPT_D,d0
		moveq	#OPT_E,d1
		bra	@f
opt_e:
		moveq	#OPT_E,d0
		moveq	#OPT_D,d1
		bra	@f
opt_p:
		moveq	#OPT_P,d0
		moveq	#OPT_R,d1
		bra	@f
opt_r:
		moveq	#OPT_R,d0
		moveq	#OPT_P,d1
		bra	@f
@@:
		btst	d1,d7
		bne	option_check_error	;-cm/-ed/-prは不可
		bra	@f
opt_f:
		moveq	#OPT_F,d0
		bra	@f
opt_n:
		moveq	#OPT_N,d0
		bra	@f
opt_k:
		moveq	#OPT_K,d0
		bra	@f
opt_g:
		moveq	#OPT_G,d0
		bra	@f
opt_v:
		moveq	#OPT_V,d0
		bra	@f
@@:
		bset	d0,d7
		bra	option_check_next

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
opt_a_number:
	.dc	1			* デフォルトは１
	.text
opt_a:
	bset	#OPT_A,d7
	lea	(opt_a_number,pc),a1
	moveq	#1,d2			* 読み取り数値の最大値
	bra	opt_number

	.data
	.even
opt_s_number:
	.dc	2			* デフォルトは２
	.text
opt_s:
	bset	#OPT_S,d7
	lea	(opt_s_number,pc),a1
	moveq	#2,d2			* 読み取り数値の最大値
	bra	opt_number

*-------------------------------------------------------------------------------
* 数値を読み取ってワークにしまう
*
* entry:
*   d2.l = 最大数値
*   a1.l = 数値を保存するワークエリアのアドレス(１ワード)
* broken:
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
	.dc	     title-$
	.dc	     error-$
	.dc	      help-$
	.dc	     force-$
	.dc	       gnc-$
	.dc	  den_mask-$
	.dc	     gstop-$
	.dc	      keep-$
	.dc	   release-$
	.dc	    active-$
	.dc	save_state-$
	.dc	   disable-$
	.dc	    enable-$
	.dc	      mask-$
	.dc	     clear-$
	.dc	0

	.ifdef	__DEBUG__
message_exit:
	.dc.b	'debug:ちゃんと終わりました。',CRLF
	.dc.b	0
message_exit2:
	.dc.b	'debug:エラーがでちゃったぁ。',CRLF
	.dc.b	0
message_keeppr:
	.dc.b	'debug:メモリに常駐しちゃいます。',CRLF
	.dc.b	0
	.endif

exec_register	reg	d7/a1

	.text
exec_option:
	.ifdef	__DEBUG__
	bset.l	#OPT_V,d7
	.endif

	lea	(exec_table,pc),a1
exec_option_loop:
	move	(a1)+,d0
	beq	exec_option_end
	move.l	a1,-(sp)
	jsr	(-2,a1,d0.w)
	movea.l	(sp)+,a1
	tst.l	d0
	beq	exec_option_loop

*exec_option_exit:
	move	d0,-(sp)
	tst.l	d0
	bmi	exec_option_keeppr

	.ifdef	__DEBUG__
	pea	message_exit2
	DOS	_PRINT
	addq.l	#4,sp
	.endif

	DOS	_EXIT2

exec_option_keeppr:
	.ifdef	__DEBUG__
	pea	message_keeppr
	DOS	_PRINT
	addq.l	#4,sp
	.endif

	pea	(program_keep_end-program_text_start).w
	DOS	_KEEPPR

exec_option_end:

	.ifdef	__DEBUG__
	pea	message_exit
	DOS	_PRINT
	addq.l	#4,sp
	.endif

	DOS	_EXIT


*-------------------------------------------------------------------------------
* '-v' が設定されている時メッセージを表示する
*
* entry:
*   $04(sp) = 文字列のアドレス
* return:
*   d0.l = 0

	.text
_vprint:
	btst	#OPT_V,d7
	beq	_vprint_end
	move.l	(4,sp),-(sp)
	DOS	_PRINT
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
	move.l	d0,-(sp)
	move.l	(8,sp),-(sp)		* 見た目の問題・・・
	DOS	_PRINT
	addq.l	#4,sp
	move.l	(sp)+,d0
_error_print_end:
	rts

*-------------------------------------------------------------------------------
* 起動時のタイトル表示

	.text
title:
	move	#1<<OPT_V+1<<OPT_ERR+1<<OPT_HLP,d0
	and	d7,d0
	beq	title_end		* どれかセットされていれば表示
title_print:
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
	.dc.b	'スイッチの指定が間違ってます。',CRLF
	.dc.b	0

	.text
error:
	moveq	#0,d0
	tst	d7			* btst	#OPT_ERR,d7
	bpl	error_end		* beq	error_end

	pea	(message_error,pc)
	bsr	_error_print
	addq.l	#4,sp

	moveq	#EXIT_ERROR_OPTION,d0
error_end:
	rts

*-------------------------------------------------------------------------------
* ヘルプメッセージの表示

	.data
message_help:
	.dc.b	' usage: gm <option>',CRLF
	.dc.b	'option:',CRLF
	.dc.b	'	-m	マスク設定',CRLF
	.dc.b	'	-c	マスク解除',CRLF
	.dc.b	'	-d	オートマスク不許可',CRLF
	.dc.b	'	-e	オートマスク許可',CRLF
*	.dc.b	'	-f	ＴＶＲＡＭを強制使用する',CRLF
	.dc.b	'	-n	ＧＮＣモードを有効にする',CRLF
	.dc.b	'	-k	電卓消去時にマスクをなおす',CRLF
	.dc.b	'	-g	グラフィック使用モードを監視する',CRLF
	.dc.b	'	-p	メモリ常駐',CRLF
	.dc.b	'	-r	常駐解除',CRLF
	.dc.b	'	-a[n]	ＧＭ主要動作の制御 (0:停止 [1]:動作)',CRLF
	.dc.b	'	-s[n]	状態保存 (0:パレット 1:GVRAM [2]:両方)',CRLF
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
* 状態保存

	.data
message_save_palette:
	.dc.b	'パレットをＧＭ内部に保存します',CRLF
	.dc.b	0
message_save_gvram:
	.dc.b	'GVRAMをＧＭ内部に保存します',CRLF
	.dc.b	0
message_save_64k:
	.dc.b	'画面モードが６４Ｋモードなので保存しません',CRLF
	.dc.b	0

	.text
save_state:
	btst	#OPT_S,d7
	beq	save_state_end

	move	#_GM_VERSION_NUMBER,d1
	bsr	_gm_internal_tgusemd_d2m1
	cmpi	#_GM_INTERNAL_MODE,d0
	bne	save_state_not_keep
	swap	d0
	cmpi	#$0080,d0
	bcs	save_state_not_support

	move	#_GM_GRAPHIC_MODE_STATE,d1
	bsr	_gm_internal_tgusemd_d2m1
	swap	d0
	tst	d0
	bne	save_state_64k		* ６４Ｋだからやめる

	move	(opt_s_number,pc),d0
	beq	@f			* -s0ならパレットのみ

	move	#_GM_GVRAM_SAVE,d1
	bsr	_gm_internal_tgusemd_d2m1
	pea	(message_save_gvram,pc)
	bsr	_vprint
	addq.l	#4,sp
@@:
	move	(opt_s_number,pc),d0
	subq	#1,d0
	beq	save_state_end		* -s1ならGVRAMのみ

	move	#_GM_PALETTE_SAVE,d1
	bsr	_gm_internal_tgusemd_d2m1

	pea	(message_save_palette,pc)
save_state_print_and_return0:
	bsr	_vprint
	addq.l	#4,sp
save_state_end:
	moveq	#0,d0
	rts

save_state_64k:
	pea	(message_save_64k,pc)
	bra	save_state_print_and_return0

save_state_not_keep:
	moveq	#EXIT_ERROR_NOT_KEEP,d0
	pea	(message_gm_not_keep,pc)
	bra	save_state_error_end

save_state_not_support:
	moveq	#EXIT_ERROR_NOT_SUPPORT,d0
	pea	(message_gm_not_support,pc)
save_state_error_end:
	bsr	_error_print
	addq.l	#4,sp
	rts

*-------------------------------------------------------------------------------
* ＧＭ主要動作の制御

	.data
message_gm_not_keep:
	.dc.b	'ＧＭは常駐していないようです',CRLF
	.dc.b	0
message_gm_not_support:
	.dc.b	'このバージョンではサポートされていません',CRLF
	.dc.b	0
message_gm_active:
	.dc.b	'ＧＭの動作を開始します',CRLF
	.dc.b	0
message_gm_inactive:
	.dc.b	'ＧＭの動作を停止します',CRLF
	.dc.b	0

	.text
active:
	btst	#OPT_A,d7
	beq	active_end

	move	#_GM_VERSION_NUMBER,d1
	bsr	_gm_internal_tgusemd_d2m1
	cmpi	#_GM_INTERNAL_MODE,d0
	bne	active_not_keep
	swap	d0
	cmpi	#$0078,d0
	bcs	active_not_support

	move	(opt_a_number,pc),d0
	bne	active_active

	move	#_GM_INACTIVE,d1
	bsr	_gm_internal_tgusemd_d2m1
	pea	(message_gm_inactive,pc)
	bra	@f

active_active:
	move	#_GM_ACTIVE,d1
	bsr	_gm_internal_tgusemd_d2m1
	pea	(message_gm_active,pc)
@@:
	bsr	_vprint
	addq.l	#4,sp
active_end:
	moveq	#0,d0
	rts

active_not_keep:
	moveq	#EXIT_ERROR_NOT_KEEP,d0
	pea	(message_gm_not_keep,pc)
	bra	active_error_end

active_not_support:
	moveq	#EXIT_ERROR_NOT_SUPPORT,d0
	pea	(message_gm_not_support,pc)
active_error_end:
	bsr	_error_print
	addq.l	#4,sp
	rts

*-------------------------------------------------------------------------------
* テキストラムの強制使用フラグの設定

	.data
message_force:
	.dc.b	'ＴＶＲＡＭを強制使用します。',CRLF
	.dc.b	0

	.text
force:
	btst	#OPT_F,d7
	beq	force_end

	pea	(message_force,pc)
	bsr	_vprint
	addq.l	#4,sp

	move	#1,d1			* 内部からのコール
	moveq	#1,d2
	bsr	_gm_internal_tgusemd

	lea	(force_flag,pc),a1
	st	(a1)
force_end:
	moveq	#0,d0
	rts

*-------------------------------------------------------------------------------
* ＧＮＣモードの使用フラグの設定

	.data
message_gnc_on:
	.dc.b	'ＧＮＣモードを有効にします。',CRLF
	.dc.b	0
message_gnc_error:
	.dc.b	'-n は常駐する時しか意味がありません。',CRLF
	.dc.b	0

	.text
gnc:
	btst	#OPT_N,d7
	beq	gnc_end
	btst	#OPT_P,d7
	beq	gnc_error
	bsr	keep_check
	bne	gnc_error2

	pea	(message_gnc_on,pc)
	bsr	_vprint
	addq.l	#4,sp

	lea	(gnc_flag,pc),a1
	st	(a1)
gnc_end:
	moveq	#0,d0
	rts

gnc_error:
	moveq	#EXIT_ERROR_GNCMODE,d0
	bra	gnc_error_end
gnc_error2:
	moveq	#0,d0			* すでに常駐している。
	bra	gnc_error_end

gnc_error_end:
	pea	(message_gnc_error,pc)
	bsr	_error_print
	addq.l	#4,sp
	rts

*-------------------------------------------------------------------------------
* 電卓消去時のマスク使用フラグの設定

	.data
message_den_mask_on:
	.dc.b	'電卓消去時にマスクします。',CRLF
	.dc.b	0
message_den_mask_error:
	.dc.b	'-k は常駐する時しか意味がありません。',CRLF
	.dc.b	0

	.text
den_mask:
	btst	#OPT_K,d7
	beq	den_mask_end
	btst	#OPT_P,d7
	beq	den_mask_error
	bsr	keep_check
	bne	den_mask_error2

	pea	(message_den_mask_on,pc)
	bsr	_vprint
	addq.l	#4,sp

	lea	(den_mask_flag,pc),a1
	st	(a1)
den_mask_end:
	moveq	#0,d0
	rts

den_mask_error:
	moveq	#EXIT_ERROR_DEN_MASK,d0
	bra	den_mask_error_end
den_mask_error2:
	moveq	#0,d0
	bra	den_mask_error_end

den_mask_error_end:
	pea	(message_den_mask_error,pc)
	bsr	_error_print
	addq.l	#4,sp
	rts

*-------------------------------------------------------------------------------
* グラフィック画面使用モードの監視フラグの設定

	.data
message_gstop_on:
	.dc.b	'グラフィック画面の使用モードを監視します。',CRLF
	.dc.b	0
message_gstop_error:
	.dc.b	'-g は常駐する時しか意味がありません。',CRLF
	.dc.b	0

	.text

gstop:
	btst	#OPT_G,d7
	beq	gstop_end
	btst	#OPT_P,d7
	beq	gstop_error
	bsr	keep_check
	bne	gstop_error2

	pea	(message_gstop_on,pc)
	bsr	_vprint
	addq.l	#4,sp

	lea	(gstop_flag,pc),a1
	st	(a1)
gstop_end:
	moveq	#0,d0
	rts

gstop_error:
	moveq	#EXIT_ERROR_GSTOP,d0
	bra	gstop_error_end
gstop_error2:
	moveq	#0,d0
	bra	gstop_error_end

gstop_error_end:
	pea	(message_gstop_error,pc)
	bsr	_error_print
	addq.l	#4,sp
	rts

*-------------------------------------------------------------------------------
* 常駐していなければ常駐終了になるようにする

keep_register	reg	d7/a1

	.text
keep:
	moveq	#0,d0
	btst	#OPT_P,d7
	beq	keep_end

	bsr	keep_check
	bne	keep_error

	bsr	keep_sub
	tst.l	d0
	bmi	keep_error		* その他のエラー（ユーザー定義）

	pea	(message_keep,pc)
	bsr	_vprint
	addq.l	#4,sp

	move.l	#$8000_0100,d0		* 上位はDOS_KEEPPRするかのフラグ：下位は終了コード
	moveq	#0,d7			* その他のスイッチは無効です
keep_end:
	rts

keep_error:
	bsr	keep_error_print
	moveq	#EXIT_ERROR_KEEP,d0
	rts

*-------------------------------------------------------------------------------
* 常駐チェック時のエラーメッセージを表示する

keep_error_print:
	subq.l	#4,d0
	bcc	keep_error_print_end		* 数値が規定外（ユーザ定義）です
	add	d0,d0
	lea	(message_keep_table_end,pc,d0.w),a0
	adda	(a0),a0
	move.l	a0,-(sp)
	bsr	_error_print
	addq.l	#4,sp
keep_error_print_end:
	rts

	.dc	message_keep_error0-$
	.dc	message_keep_error1-$
	.dc	message_keep_error2-$
	.dc	message_keep_error3-$
message_keep_table_end:

	.data
message_keep:
	.dc.b	'プログラムを常駐します。',CRLF
	.dc.b	0
message_keep_error0:
	.dc.b	'プログラムは常駐していません。',CRLF
	.dc.b	0
message_keep_error1:
	.dc.b	'すでに常駐しています。',CRLF
	.dc.b	0
message_keep_error2:
	.dc.b	'バージョンの違うプログラムが常駐しています。',CRLF
	.dc.b	0
message_keep_error3:
	.dc.b	'内部エラーです。',CRLF
	.dc.b	0
	.even

	.text

*-------------------------------------------------------------------------------
* 実際にベクタの変更などを行う
*
* entry:
*   なし
* return:
*   d0.l = 0  常駐できます
*   d0.l < 0  ユーザー定義エラー

	.text
keep_sub:
	bsr	tram_check
	tst.l	d0
	bne	keep_sub_tram_used

	lea	(vector_table_top,pc),a0
	bra	vector_hook_start
vector_hook_loop:
	pea	(a0,d0.w)
	move.l	(a0),d0
	move	d0,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	move.l	d0,(a0)+
vector_hook_start:
	move	(a0),d0
	bne	vector_hook_loop

	pea	(clear_sub,pc)
	DOS	_SUPER_JSR
	addq.l	#4,sp

	bsr	active			* 動作制御、デフォルトは動作オン
	bsr	disable			* 常駐時から設定できるように
	bsr	enable

	lea	(CRTC_R20),a1
	IOCS	_B_WPEEK
	cmpi	#$0316,d0
	bne	keep_sub_not_64k
	move.b	(mask_enable_flag,pc),d0
	beq	keep_sub_not_64k

	pea	(mask_sub,pc)
	DOS	_SUPER_JSR
	addq.l	#4,sp
keep_sub_not_64k:
	moveq	#0,d0
keep_sub_end:
	rts

keep_sub_tram_used:
	pea	(message_tram_used,pc)	* テキストラム使用中
	bsr	_error_print
	addq.l	#4,sp
	moveq	#-1,d0
	bra	keep_sub_end

*-------------------------------------------------------------------------------
* 常駐解除する（メモリ解放など）

	.data
message_release:
	.dc.b	'プログラムを常駐解除しました。',CRLF
	.dc.b	0
message_release_error:
	.dc.b	'プログラムの常駐解除ができません。',CRLF
	.dc.b	0
message_release_mfree_error:
	.dc.b	'メモリ解放に失敗しました。',CRLF
	.dc.b	0
message_release_vector_error:
	.dc.b	'ベクタが書き換えられています。',CRLF
	.dc.b	0

release_register	reg	d7/a1

	.text
release:
	moveq	#0,d0
	btst	#OPT_R,d7
	beq	release_end

	bsr	keep_check
	moveq	#1,d1
	cmp.l	d0,d1
	bne	release_keep_error

	bsr	release_sub
	moveq	#-1,d1
	cmp.l	d0,d1
	beq	release_vector_error	* ベクタが変更されている
	tst.l	d0
	bmi	release_error		* その他のエラー(ユーザー定義)

	pea	(16,a0)
	DOS	_MFREE			* メモリ解放
	move.l	d0,(sp)+
	bmi	release_mfree_error

	pea	(message_release,pc)
	bsr	_vprint
	addq.l	#4,sp

	moveq	#0,d7			* その他のスイッチは無効です
	moveq	#1,d0			* d0.l hw != 0:release ok
	swap	d0			*
release_end:
	rts

release_keep_error:
	bsr	keep_error_print
	moveq	#EXIT_ERROR_RELEASE,d0
	rts

release_vector_error:
	pea	(message_release_vector_error,pc)
	bra	@f
release_mfree_error:
	pea	(message_release_mfree_error,pc)
@@:
	bsr	_error_print
	addq.l	#4,sp
	bra	release_error

release_error:
	pea	(message_release_error,pc)
	bsr	_error_print
	addq.l	#4,sp
	moveq	#EXIT_ERROR_RELEASE,d0
	rts


*-------------------------------------------------------------------------------
* ベクタをもとに戻す
*
* entry:
*   a0.l = 常駐部のメモリ管理ポインタ
* return:
*   d0.l = 0  常駐解除できます
*   d0.l = -1 ベクタが書き換えられています
*   d0.l < 0  (-1以外) ユーザー定義エラー

	.text
release_sub:
	lea	(program_text_start-$100,pc),a1
	lea	(vector_table_top,pc),a3
	lea	(a3),a4
	bra	vector_check_start
vector_check_loop:
	lea	(-2,a3,d0.w),a2
	suba.l	a1,a2
	adda.l	a0,a2
	move	(a3)+,-(sp)
	DOS	_INTVCG
	addq.l	#2,sp
	cmpa.l	d0,a2
	bne	release_sub_error
vector_check_start:
	move	(a3)+,d0
	bne	vector_check_loop

	lea	($100+vector_table_top-program_text_start,a0),a2
	bra	vector_remove_start
vector_remove_loop:
	move.l	(a2)+,-(sp)
	move	(a4)+,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
vector_remove_start:
	tst	(a4)+
	bne	vector_remove_loop

	bsr	tram_check
	tst.l	d0
	bne	@f			* T_VRAM使用中に解除する場合はマスクを剥さない

	pea	(clear_sub,pc)
	DOS	_SUPER_JSR
	addq.l	#4,sp
@@:
	moveq	#0,d0
	rts

release_sub_error:
	moveq	#-1,d0			* ベクタが書き換えられていた
	rts

*-------------------------------------------------------------------------------

	.data
message_disable:
	.dc.b	'これ以後のオートマスクを許可しません。',CRLF
	.dc.b	0
message_disable_not_keep:
	.dc.b	'常駐してないと意味がありません。',CRLF
	.dc.b	0

	.text
disable:
	btst	#OPT_D,d7
	beq	disable_end

	move	#_GM_VERSION_NUMBER,d1
	bsr	_gm_internal_tgusemd_d2m1
	cmpi	#_GM_INTERNAL_MODE,d0
	bne	disable_not_keep

	pea	(message_disable,pc)
	bsr	_vprint
	addq.l	#4,sp

	move	#_GM_AUTO_DISABLE,d1
	bsr	_gm_internal_tgusemd_d2m1	* 常駐していればマスク不許可フラグをセット
disable_end:
	moveq	#0,d0
	rts

disable_not_keep:
	pea	(message_disable_not_keep,pc)
	bsr	_error_print
	addq.l	#4,sp
	moveq	#EXIT_ERROR_NOT_KEEP,d0
	rts

*-------------------------------------------------------------------------------

	.data
message_enable:
	.dc.b	'これ以後のオートマスクを許可します。',CRLF
	.dc.b	0

	.text
enable:
	btst	#OPT_E,d7
	beq	enable_end

	move	#_GM_VERSION_NUMBER,d1
	bsr	_gm_internal_tgusemd_d2m1
	cmpi	#_GM_INTERNAL_MODE,d0
	bne	enable_not_keep

	pea	(message_enable,pc)
	bsr	_vprint
	addq.l	#4,sp

	move	#_GM_AUTO_ENABLE,d1
	bsr	_gm_internal_tgusemd_d2m1	* 常駐していればマスク許可フラグをセット
enable_end:
	moveq	#0,d0
	rts

enable_not_keep:
	pea	(message_disable_not_keep,pc)
	bsr	_error_print
	addq.l	#4,sp
	moveq	#EXIT_ERROR_NOT_KEEP,d0
	rts

*-------------------------------------------------------------------------------

	.data
message_mask:
	.dc.b	'テキストプレーン３でグラフィック画面をマスクします。',CRLF
	.dc.b	0
message_mask_request:
	.dc.b	'グラフィック画面のマスクをリクエストします。',CRLF
	.dc.b	0
message_tram_used:
	.dc.b	'ＴＶＲＡＭはアプリケーションで使用中です。',CRLF
	.dc.b	0

	.text
mask:
	btst	#OPT_M,d7
	beq	mask_end

	move	#_GM_VERSION_NUMBER,d1
	bsr	_gm_internal_tgusemd_d2m1
	cmpi	#_GM_INTERNAL_MODE,d0
	bne	mask_not_keep

	moveq	#-1,d1
	IOCS	_CRTMOD
	cmpi.b	#16,d0
	bne	mask_keep_request
	lea	(VC_R0),a1
	IOCS	_B_WPEEK
	andi	#7,d0
	subq	#3,d0
	bne	mask_keep_request

	bsr	tram_check
	tst.l	d0
	bne	mask_tram_used		* アプリケーションで使用中
	move	#_GM_MASK_SET,d1
	bsr	_gm_internal_tgusemd_d2m1	* 画面モードが７６８×５１２ならば即マスクする

	pea	(message_mask,pc)
	bra	mask_keep_print_end

mask_keep_request:
	move	#_GM_MASK_REQUEST,d1
	bsr	_gm_internal_tgusemd_d2m1	* 常駐していればマスクのリクエスト

	pea	(message_mask_request,pc)
mask_keep_print_end:
	bsr	_vprint
	addq.l	#4,sp
	bra	mask_end

mask_not_keep:
	bsr	tram_check
	tst.l	d0
	bne	mask_tram_used		* アプリケーションで使用中

	pea	(message_mask,pc)
	bsr	_vprint
	addq.l	#4,sp

	pea	(mask_sub,pc)
	DOS	_SUPER_JSR
	addq.l	#4,sp
mask_end:
	moveq	#0,d0
	rts

mask_tram_used:
	pea	(message_tram_used,pc)
	bsr	_error_print
	addq.l	#4,sp
	moveq	#EXIT_ERROR_TRAM_USED,d0
	rts

*-------------------------------------------------------------------------------

	.data
message_clear:
	.dc.b	'グラフィック画面のマスク解除します。',CRLF
	.dc.b	0

	.text
clear:
	btst	#OPT_C,d7
	beq	clear_end

	move	#_GM_VERSION_NUMBER,d1
	bsr	_gm_internal_tgusemd_d2m1
	cmpi	#_GM_INTERNAL_MODE,d0
	bne	clear_not_keep

	pea	(message_clear,pc)
	bsr	_vprint
	addq.l	#4,sp

	move	#_GM_MASK_CLEAR,d1
	bsr	_gm_internal_tgusemd_d2m1	* 常駐していれば即マスククリアする
	bra	clear_end

clear_not_keep:
	bsr	tram_check
	tst.l	d0
	bne	clear_tram_used		* アプリケーションで使用中

	pea	(message_clear,pc)
	bsr	_vprint
	addq.l	#4,sp

	pea	(clear_sub,pc)
	DOS	_SUPER_JSR
	addq.l	#4,sp
clear_end:
	moveq	#0,d0
	rts

clear_tram_used:
	pea	(message_tram_used,pc)
	bsr	_error_print
	addq.l	#4,sp
	moveq	#EXIT_ERROR_TRAM_USED,d0
	rts

*-------------------------------------------------------------------------------
* エラー処理

	.data
message_program_error_setblock:
	.dc.b	'メモリブロックの変更ができません。',CRLF
	.dc.b	0
message_program_error:
	.dc.b	'強制終了します。',CRLF
	.dc.b	0

	.text
program_error_setblock:
	lea	(message_program_error_setblock,pc),a0
	moveq	#EXIT_ERROR_SETBLOCK,d0
	bra	program_error

program_error:
	move	d0,-(sp)		* 終了コード
	move.l	a0,-(sp)
	DOS	_PRINT
	pea	(message_program_error,pc)
	DOS	_PRINT
	addq.l	#8,sp
	DOS	_EXIT2

*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
* 常駐チェック
*
* return:
*   d0.l = 0 プログラムが見つかりません
*        = 1 すでに常駐済みです
*        = 2 バージョン違いです
*        = 3 内部エラーです (動作は保証されません)
*   a0.l = メモリ管理ポインタのアドレス (d0.l = 1, 2の時、それ以外は不定)
* note:
*   ユーザモードで呼び出すこと
*   引数は受け取らないで自分で設定するように変更した

keep_check_register	reg	d1-d5/a1-a2

	.text
keep_check:
	PUSH	keep_check_register

	lea	(program_id_name,pc),a0	* 識別文字列(name + versionを設定すること)
	lea	(program_text_start-$100,pc),a1
					* 自分のメモリ管理ポインタ
	movea.l	a0,a2
	move.l	a0,d2
	sub.l	a1,d2			* d2.l = 識別文字列の先頭までのオフセット

	moveq	#-1,d4
keep_check_name_length:
	addq.l	#1,d4
	tst.b	(a0)+
	bne	keep_check_name_length
					* d4.l = nameの長さ（末尾の０を含まない）
	moveq	#-1,d5
keep_check_version_length:
	addq.l	#1,d5
	tst.b	(a0)+
	bne	keep_check_version_length
					* d5.l = versionの長さ（末尾の０を含まない）
	move.l	d2,d3
	add.l	d4,d3
	add.l	d5,d3
	addq.l	#2,d3			* d3.l = 識別文字列最後の０までのオフセット

	clr.l	-(sp)
	DOS	_SUPER			* スーパーバイザーモードへ
	move.l	d0,(sp)

	move.l	a1,d0			* 自分のメモリ管理ポインタから親をたどる
keep_check_backward_loop:
	movea.l	d0,a0

	.ifdef	__DEBUG__
	move	#'B',-(sp)
	DOS	_PUTCHAR
	addq.l	#2,sp
	.endif

	move.l	(4,a0),d0		* 親があるか？
	bne	keep_check_backward_loop
keep_check_forward_loop:

	.ifdef	__DEBUG__
	move	#'F',-(sp)
	DOS	_PUTCHAR
	addq.l	#2,sp
	.endif

	move.l	(12,a0),d1
	beq	keep_check_not_found	* 見つからなかった
	move.l	d1,a0
	cmpi.b	#$ff,(4,a0)
	bne	keep_check_forward_loop	* 常駐プロセスではない

	move.l	(8,a0),d0
	lea	(a0,d3.l),a1
	cmp.l	a1,d0
	bls	keep_check_forward_loop	* メモリブロックの範囲外

	lea	(a0,d2.l),a1
keep_check_forward_name:
	move.l	a2,d1
	move.l	d4,d0
keep_check_forward_name_compare:
	cmpm.b	(a2)+,(a1)+
	dbne	d0,keep_check_forward_name_compare
	beq	keep_check_forward_version
	move.l	d1,a2
	bra	keep_check_forward_loop	* name が違ったら次にいく

keep_check_forward_version:
	move.l	d5,d0
keep_check_forward_version_compare:
	cmpm.b	(a2)+,(a1)+
	dbne	d0,keep_check_forward_version_compare
	beq	keep_check_match

keep_check_version_no_match:		* バージョンが違うみたいだなぁ
	moveq	#2,d1
	bra	keep_check_end

keep_check_match:
	moveq	#1,d1
	bra	keep_check_end

keep_check_not_found:
*	moveq	#0,d1
	bra	keep_check_end

*keep_check_error:			* 未使用
*	moveq	#3,d1
*	bra	keep_check_end

keep_check_end:
*	tst.b	(sp)
*	bmi	@f
	DOS	_SUPER			* ユーザーモードへ
*@@:
	addq.l	#4,sp

	.ifdef	__DEBUG__
	move	#CR,-(sp)
	DOS	_PUTCHAR
	move	#LF,(sp)
	DOS	_PUTCHAR
	addq.l	#2,sp
	.endif

	move.l	d1,d0
	POP	keep_check_register
	rts

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

	.end	program_start_0
