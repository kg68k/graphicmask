* $Id: gm.s,v 1.2 1994/09/15 22:18:58 JACK Exp $

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
EXIT_ERROR_OS_VERSION	.ds.b	1
EXIT_ERROR_OPTION	.ds.b	1
EXIT_ERROR_GNCMODE	.ds.b	1
EXIT_ERROR_DEN_MASK	.ds.b	1
EXIT_ERROR_SETBLOCK	.ds.b	1
EXIT_ERROR_KEEP		.ds.b	1
EXIT_ERROR_RELEASE	.ds.b	1
EXIT_ERROR_NOT_KEEP	.ds.b	1
EXIT_ERROR_NOT_SUPPORT	.ds.b	1
EXIT_ERROR_TRAM_USED	.ds.b	1
	.text

*-------------------------------------------------------------------------------
* プログラム識別文字列

	.text
program_id_name:
	.dc.b	'Graphic Mask'
	.dc.b	0
program_id_version:
	.dc.b	'0.87'
	.dc.b	0
	.quad

*-------------------------------------------------------------------------------
* ＧＭのバージョン

GM_VERSION	equ	$0087

*-------------------------------------------------------------------------------
* タイトルメッセージ

	.data
message_title:
	.dc.b	'Graphic Mask version 0.87 programmed by JACK',13,10
	.dc.b	0

*-------------------------------------------------------------------------------
* ベクタ保存領域

	.text
	.quad
vector_TPALET:
	.ds.l	1
vector_TPALET2:
	.ds.l	1
vector_CRTMOD:
	.ds.l	1
vector_TGUSEMD:
	.ds.l	1
vector_G_CLR_ON:
	.ds.l	1
vector_B_KEYSNS:
	.ds.l	1
vector_DENSNS:
	.ds.l	1
vector_TXXLINE:
	.ds.l	1
vector_TXYLINE:
	.ds.l	1
vector_TXBOX:
	.ds.l	1
vector_B_WPOKE:
	.ds.l	1
vector_trap15:
	.ds.l	1
vector_EXIT:
	.ds.l	1
vector_EXIT2:
	.ds.l	1

*-------------------------------------------------------------------------------
* フラグ領域

	.text
active_flag:
	.dc.b	1			* ＧＭ主要機能の動作フラグ 0:停止 0以外:動作
force_flag:
	.ds.b	1			* 強制フラグ 0:IOCSに従う 0以外:強制使用する
gnc_flag:
	.ds.b	1			* GNCフラグ 0:無効 0以外:有効
den_mask_flag:
	.ds.b	1			* 電卓消去時のマスクフラグ 0:無効 0以外:有効
wpoke_flag:
	.ds.b	1			* うっしっし（μEmacs用）
check_force_flag:
	.ds.b	1			* 不都合解消
save_force_flag:
	.ds.b	1			* 不都合解消

mask_set_flag:
	.ds.b	1			* マスクフラグ 0:マスクなし 0以外:マスクあり
mask_halt_flag:
	.ds.b	1
mask_disable_flag:
	.ds.b	1
mask_enable_flag:
	.ds.b	1
mask_request_flag:
	.ds.b	1
	.even

*-------------------------------------------------------------------------------
* trap15の処理

	.text
NEW_trap15:
	cmp.w	#__G_CLR_ON,d0		* グラフィックを消えないように...
	bne	NEW_trap15_end		* _G_CLR_ONのみフックする

	tst.b	active_flag		* 動作するか？
	beq	NEW_trap15_end

	bsr	crtc_check_16
	bne	NEW_trap15_end		* 画面モードが違う
	bra	NEW_trap15_G_CLR_ON
NEW_trap15_end:
	move.l	vector_trap15,-(sp)
	rts

NEW_trap15_G_CLR_ON:
	clr.b	graphic_data_16_flag
	bsr	_graphic_color_max
	bsr	_graphic_line_length
	bsr	_graphic_window
	bclr.b	#3,$e80028		* 表示オンにする
	move.w	#$003f,$e82600
	rte

*-------------------------------------------------------------------------------
* グラフィック画面の最大色－１

	.text
_graphic_color_max:
	movem.l	d0-d1,-(sp)
	moveq.l	#16-1,d0
	move.b	$093c.w,d1
	cmp.b	#16,d1
	bcc	@f
	ror.b	#4,d1
	bcc	@f
	move.w	#256-1,d0
	rol.b	#2,d1
	bcc	@f
	moveq.l	#$ff,d0			* 65536-1
@@:
	move.w	d0,$0964.w
	movem.l	(sp)+,d0-d1
	rts

*-------------------------------------------------------------------------------
* ＧＶＲＡＭ１ラインのサイズ

	.text
_graphic_line_length:
	move.l	d0,-(sp)
	move.l	#$400,d0
	btst.b	#2,$e80028
	beq	@f
	add.l	d0,d0
@@:
	move.l	d0,$0960.w
	move.l	(sp)+,d0
	rts

*-------------------------------------------------------------------------------
* グラフィッククリッピングエリア

	.text
_graphic_window:
	clr.w	$0968.w
	clr.w	$096a.w
	btst.b	#2,$e80028
	bne	@f
	move.w	#512-1,$096c.w
	move.w	#512-1,$096e.w
	rts
@@:
	move.w	#768-1,$096c.w
	move.w	#512-1,$096e.w
	rts

*-------------------------------------------------------------------------------
* CRTCが１６色用になっているか調べる
*
* return:
*   ccr:z  = 0 違うなぁ
*   ccr:z  = 1 １６色です

	.text
crtc_check_16:
	cmp.w	#$0c15,$e80028
	bcc	crtc_check_16_goff
	cmp.w	#$0415,$e80028
	beq	crtc_check_16_end
	cmp.w	#$0416,$e80028
	beq	crtc_check_16_end
	cmp.w	#$041a,$e80028
crtc_check_16_end:
	rts

crtc_check_16_goff:
	beq	crtc_check_16_end
	cmp.w	#$0c16,$e80028
	beq	crtc_check_16_end
	cmp.w	#$0c1a,$e80028
	bra	crtc_check_16_end

*-------------------------------------------------------------------------------
* _EXITの処理

	.text
NEW_EXIT:
	bsr	exit_mask_check
	bsr	crtc_check_16
	bne	NEW_EXIT_end
	bsr	graphic_data_16_check		* ちぇっく、ちぇ～っく(^^;
NEW_EXIT_end:
	move.l	vector_EXIT,-(sp)
	rts

*-------------------------------------------------------------------------------
* _EXIT2の処理

	.text
NEW_EXIT2:
	bsr	exit_mask_check
	bsr	crtc_check_16
	bne	NEW_EXIT2_end
	bsr	graphic_data_16_check
NEW_EXIT2_end:
	move.l	vector_EXIT2,-(sp)
	rts

*-------------------------------------------------------------------------------
* 不都合を取る

	.text
exit_mask_check:
	tst.b	mask_set_flag
	beq	exit_mask_check_end

	tst.w	$e60000
	bne	exit_mask_check_end

	bsr	mask_sub
exit_mask_check_end:
	rts

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
	tst.b	active_flag
	beq	NEW_TXXLINE_end

	tst.b	mask_set_flag
	beq	NEW_TXXLINE_end
	cmp.w	#2,vram_page(a1)	* テキストプレーン２かな？
	bne	NEW_TXXLINE_end
	tst.w	line_length(a1)
	beq	NEW_TXXLINE_end		* 長さ０？

	cmp.w	#512,line_y(a1)
	bcc	NEW_TXXLINE_end		* Ｙ座標 512 以上はマスクがない

	tst.w	line_style(a1)		* クリア？
	seq.b	d0
	ext.w	d0

txxline_mask_register	reg	a1-a4
	movem.l	txxline_mask_register,-(sp)
	lea	-txline_work_size(sp),sp	* ワークエリアを得る
	lea	(sp),a2
	exg.l	a1,a2

	lea	$e8002a,a3
	move.w	(a3),-(sp)
	clr.b	(a3)
	move.l	vector_TXXLINE,a4
	move.w	#3,(a1)				* vram_page
	move.w	line_y(a2),line_y(a1)
	move.w	d0,line_style(a1)

	move.w	line_x(a2),d0
	cmp.w	#128,d0
	bcc	NEW_TXXLINE_clear_right

NEW_TXXLINE_clear_left:
	move.w	d0,line_x(a1)
	add.w	line_length(a2),d0
	cmp.w	#128,d0
	bcs	@f
	move.w	#127,d0
@@:
	sub.w	line_x(a1),d0
	addq.w	#1,d0
	move.w	d0,line_length(a1)
	jsr	(a4)

NEW_TXXLINE_clear_right:
	move.w	line_x(a2),d0
	add.w	line_length(a2),d0
	cmp.w	#640,d0
	bcs	NEW_TXXLINE_clear_end

	move.w	#640,line_x(a1)
	sub.w	#640,d0
	addq.w	#1,d0
	move.w	d0,line_length(a1)
	jsr	(a4)

NEW_TXXLINE_clear_end:
	move.w	(sp)+,(a3)

	lea	txline_work_size(sp),sp		* ワークエリアを戻す
	movem.l	(sp)+,txxline_mask_register
NEW_TXXLINE_end:
	move.l	vector_TXXLINE,-(sp)
	rts

*-------------------------------------------------------------------------------
* _TXYLINEの処理

	.text
NEW_TXYLINE:
	tst.b	active_flag
	beq	NEW_TXYLINE_end

	tst.b	mask_set_flag
	beq	NEW_TXYLINE_end
	cmp.w	#2,(a1)			* テキストプレーン２かな？
	bne	NEW_TXYLINE_end
	tst.w	line_length(a1)
	beq	NEW_TXYLINE_end		* 長さ０？

	clr.l	d0
	cmp.w	#512,line_y(a1)
	bcc	NEW_TXYLINE_end		* Ｙ座標 512 以上はマスクがない
	move.w	line_x(a1),d0
	cmp.w	#768,d0
	bcc	NEW_TXYLINE_end		* Ｘ座標 768 以上は論外
	cmp.w	#640,d0
	bcc	NEW_TXYLINE_mask
	cmp.w	#128,d0
	bcc	NEW_TXYLINE_end		* Ｘ座標 128 ～ 639 はマスクがない
NEW_TXYLINE_mask:
txyline_mask_register	reg	d1-d5/a1

	movem.l	txyline_mask_register,-(sp)
	moveq.l	#%111,d1
	and.b	d0,d1
	lsr.l	#3,d0			* Ｘ座標 -> アドレス
	lea	TEXTVRAM_P3_ADDRESS,a0
	add.l	d0,a0
	move.w	line_y(a1),d0
	lsl.l	#7,d0			* Ｙ座標 -> アドレス
	add.l	d0,a0

	neg.b	d1
	addq.b	#7,d1			* ビット列を反転させる
	st.b	d2
	bclr.l	d1,d2			* d2.b = マスクパターン
	move.b	d2,d5
	tst.w	line_style(a1)		* クリア？
	bne	NEW_TXYLINE_mask_clear
NEW_TXYLINE_mask_set:
	bset.l	d1,d2
NEW_TXYLINE_mask_clear:
	move.w	line_length(a1),d0
	subq.w	#1,d0
	lea	$e8002a,a1
	move.w	(a1),-(sp)
	clr.b	(a1)
	move.w	#$0080,d1
	move.l	#-$20000,d3
NEW_TXYLINE_mask_loop:
	move.b	(a0,d3.l),d4
	and.b	d5,d4
	not.b	d4
	and.b	d2,d4
	move.b	d4,(a0)
	add.w	d1,a0
	dbra	d0,NEW_TXYLINE_mask_loop
	move.w	(sp)+,(a1)
	movem.l	(sp)+,txyline_mask_register
NEW_TXYLINE_end:
	move.l	vector_TXYLINE,-(sp)
	rts

*-------------------------------------------------------------------------------
* _TXBOXの処理

	.text
NEW_TXBOX:
	tst.b	active_flag
	beq	NEW_TXBOX_end

	tst.b	mask_set_flag
	beq	NEW_TXBOX_end
	cmp.w	#2,(a1)			* テキストプレーン２かな？
	bne	NEW_TXBOX_end

	tst.w	line_style(a1)		* クリア？
	seq.b	d0
	ext.w	d0

txbox_mask_register	reg	a1-a3
	movem.l	txbox_mask_register,-(sp)
	lea	-2*6(sp),sp			* ワークエリアを得る
	lea	(sp),a2
	exg.l	a1,a2

	lea	$e8002a,a3
	move.w	(a3),-(sp)
	clr.b	(a3)
	move.w	#3,(a1)+
	addq.l	#2,a2
	move.l	(a2)+,(a1)+
	move.l	(a2)+,(a1)+
	move.w	d0,(a1)+
	lea	(sp),a1
	move.l	vector_TXBOX,a0
	jsr	(a0)
	move.w	(sp)+,(a3)

	lea	2*6(sp),sp			* ワークエリアを戻す
	movem.l	(sp)+,txbox_mask_register
NEW_TXBOX_end:
	move.l	vector_TXBOX,-(sp)
	rts

*-------------------------------------------------------------------------------
* _B_KEYSNSの処理

	.text
NEW_B_KEYSNS:
	tst.b	active_flag
	beq	NEW_B_KEYSNS_end

	tst.b	mask_set_flag
	beq	NEW_B_KEYSNS_no_mask
	tst.b	$e88001
	bpl	NEW_B_KEYSNS_no_mask
	tst.w	$e60000
	bne	NEW_B_KEYSNS_no_mask
	bsr	mask_sub
NEW_B_KEYSNS_no_mask:
	move.l	vector_B_KEYSNS,a0
	bsr	dentaku_mask		* 電卓マスクに対応したルーチン
	rts

NEW_B_KEYSNS_end:
	move.l	vector_B_KEYSNS,-(sp)
	rts

*-------------------------------------------------------------------------------
* _DENSNSの処理

	.text
NEW_DENSNS:
	tst.b	active_flag
	beq	NEW_DENSNS_end

	move.l	vector_DENSNS,a0
	bsr	dentaku_mask
	rts

NEW_DENSNS_end:
	move.l	vector_DENSNS,-(sp)
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
dentaku_mask:
	tst.b	den_mask_flag
	beq	dentaku_mask_off
	tst.b	(DEN_PRINT).w
	beq	dentaku_mask_off
	jsr	(a0)
	tst.b	(DEN_PRINT).w
	bne	dentaku_mask_end	* 電卓表示中

	tst.b	mask_set_flag
	beq	dentaku_mask_end	* マスクされていない
	cmp.w	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,TEXTPALETTE_ADDRESS+2*8
	bne	dentaku_mask_end	* 表示カラーが違う

	cmp.w	#512,(DEN_YPOS).w
	bcc	dentaku_mask_end	* Ｙ座標 512 以上はマスクがない
	cmp.w	#768,(DEN_XPOS).w
	bcc	dentaku_mask_end	* Ｘ座標 768 以上はマスクがない
	cmp.w	#640-(DEN_XSIZE*8)+1,(DEN_XPOS).w
	bcc	dentaku_mask_right	* Ｘ座標 640 からマスクがある
	cmp.w	#128,(DEN_XPOS).w
	bcc	dentaku_mask_end	* Ｘ座標 128 ～ 639 はマスクがない

dentaku_mask_left:
	movem.l	dentaku_mask_register,-(sp)
	clr.l	d0
	move.w	(DEN_YPOS).w,d0
	lsl.l	#7,d0			* Ｙ座標 -> アドレス
	lea	TEXTVRAM_P3_ADDRESS,a0
	add.l	d0,a0
	bra	dentaku_mask_paint

dentaku_mask_right:
	movem.l	dentaku_mask_register,-(sp)
	clr.l	d0
	move.w	(DEN_YPOS).w,d0
	lsl.l	#7,d0			* Ｙ座標 -> アドレス
	lea	TEXTVRAM_P3_ADDRESS,a0
	add.l	d0,a0
	lea	$50(a0),a0		* Ｘ座標 640 から

dentaku_mask_paint:
	moveq.l	#$ff,d1
	move.l	d1,d2
	move.l	d1,d3
	move.l	d1,d4
	move.w	#$0080,d5
	move.w	#16-1,d0

	lea	$e8002a,a1
	move.w	(a1),-(sp)
	clr.b	(a1)
dentaku_mask_paint_loop:
	movem.l	d1-d4,(a0)		* テキストプレーン塗りつぶし
	add.w	d5,a0
	dbra	d0,dentaku_mask_paint_loop
	move.w	(sp)+,(a1)
	movem.l	(sp)+,dentaku_mask_register
dentaku_mask_end:
	rts

dentaku_mask_off:
	jsr	(a0)			* 表示なし、または使用しない
	rts

*-------------------------------------------------------------------------------
* _B_WPOKEの処理

	.text
NEW_B_WPOKE:
	tst.b	active_flag
	beq	NEW_B_WPOKE_end

	tst.b	mask_set_flag
	beq	NEW_B_WPOKE_end
	cmp.l	#$e82200,a1
	bne	NEW_B_WPOKE_end

	st.b	wpoke_flag
	move.l	vector_B_WPOKE,a0
	lea	2*8(a1),a1
	move.l	d1,-(sp)
	bne	@f
	move.l	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,d1
@@:
	jsr	(a0)			* a1.l += 2
	move.l	(sp)+,d1
	lea	-2*9(a1),a1
NEW_B_WPOKE_end:
	move.l	vector_B_WPOKE,-(sp)
	rts

*-------------------------------------------------------------------------------
* _TPALET2の処理

tpalet2_register	reg	d1-d2/a1

	.text
NEW_TPALET2:
	tst.b	active_flag
	beq	NEW_TPALET2_end

	tst.b	mask_set_flag
	beq	NEW_TPALET2_end
	tst.b	wpoke_flag
	bne	NEW_TPALET2_wpoke
	tst.l	d2
	bmi	NEW_TPALET2_end

NEW_TPALET2_set:
	cmp.b	#16,d1
	bcc	NEW_TPALET2_end
	cmp.b	#12,d1
	bcc	NEW_TPALET2_end
	cmp.b	#9,d1
	bcc	NEW_TPALET2_set_9
	cmp.b	#8,d1
	beq	NEW_TPALET2_set_0
	cmp.b	#4,d1
	bcc	NEW_TPALET2_end
	cmp.b	#0,d1
	beq	NEW_TPALET2_set_0

	movem.l	tpalet2_register,-(sp)
NEW_TPALET2_set_9_sub:
	move.l	vector_TPALET2,a1
	jsr	(a1)
	bset.l	#3,d1
NEW_TPALET2_set_0_sub:
	jsr	(a1)
	movem.l	(sp)+,tpalet2_register
	rts

NEW_TPALET2_set_9:
	movem.l	tpalet2_register,-(sp)
	bclr.l	#3,d1
	moveq.l	#-1,d2
	bra	NEW_TPALET2_set_9_sub

NEW_TPALET2_set_0:
	movem.l	tpalet2_register,-(sp)
	move.l	vector_TPALET2,a1
	btst.l	#3,d1
	bne	@f
	jsr	(a1)
	bset.l	#3,d1
@@:
	move.l	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,d2
	bra	NEW_TPALET2_set_0_sub

NEW_TPALET2_wpoke:
	clr.b	wpoke_flag
	tst.l	d1
	bne	NEW_TPALET2_end
	tst.l	d2
	bmi	NEW_TPALET2_end

	move.l	vector_TPALET2,a0
	moveq.l	#8,d1
	move.l	d2,-(sp)
	move.l	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,d2
	jsr	(a0)
	move.l	(sp)+,d2
	clr.l	d1
NEW_TPALET2_end:
	move.l	vector_TPALET2,-(sp)
	rts

*-------------------------------------------------------------------------------
* _TPALETの処理

tpalet_register	reg	d1-d2/a1

	.text
NEW_TPALET:
	tst.b	active_flag
	beq	NEW_TPALET_end

	tst.b	mask_set_flag
	beq	NEW_TPALET_end
	cmp.l	#-2,d2
	beq	NEW_TPALET_initialize
	cmp.l	#-1,d2
	beq	NEW_TPALET_get
	bra	NEW_TPALET_set
NEW_TPALET_end:
	move.l	vector_TPALET,-(sp)
	rts

NEW_TPALET_get:
	cmp.b	#16,d1
	bcc	NEW_TPALET_end
	cmp.b	#8,d1
	bcs	NEW_TPALET_end		* パレット８～１５以外はもとのルーチンに行く

	movem.l	tpalet_register,-(sp)
	move.l	vector_TPALET2,a1	* IOCS _TAPLET2 を直接コール
	moveq.l	#15,d1
	moveq.l	#-1,d2
	jsr	(a1)
	movem.l	(sp)+,tpalet_register
	rts

NEW_TPALET_set:
	cmp.b	#16,d1
	bcc	NEW_TPALET_end
	cmp.b	#8,d1
	bcc	NEW_TPALET_set_8
	cmp.b	#4,d1
	bcc	NEW_TPALET_end
	cmp.b	#0,d1
	beq	NEW_TPALET_set_0

	movem.l	tpalet_register,-(sp)
	move.l	vector_TPALET2,a1
	jsr	(a1)
	bset.l	#3,d1
	jsr	(a1)
	movem.l	(sp)+,tpalet_register
	rts

NEW_TPALET_set_0:
	movem.l	tpalet_register,-(sp)
	move.l	vector_TPALET2,a1
	bsr	NEW_TPALET_initialize_0_sub
	movem.l	(sp)+,tpalet_register
	rts

NEW_TPALET_set_8:
	movem.l	tpalet_register,-(sp)
	move.l	vector_TPALET2,a1
	bsr	NEW_TPALET_initialize_8_sub
	movem.l	(sp)+,tpalet_register
	rts

NEW_TPALET_initialize:
	cmp.b	#16,d1
	bcc	NEW_TPALET_end
	cmp.b	#8,d1
	bcc	NEW_TPALET_initialize_8
	cmp.b	#4,d1
	bcc	NEW_TPALET_end
	cmp.b	#0,d1
	beq	NEW_TPALET_initialize_0

	movem.l	tpalet_register,-(sp)
	lea	$ed002e,a0
	move.b	d1,d0
	ext.w	d0
	add.w	d0,d0
	move.w	(a0,d0.w),d2
	move.l	vector_TPALET2,a1
	jsr	(a1)
	bset.l	#3,d1
	jsr	(a1)
	movem.l	(sp)+,tpalet_register
	rts

NEW_TPALET_initialize_0:
	movem.l	tpalet_register,-(sp)
	move.l	vector_TPALET2,a1
	move.w	$ed002e,d2
	bsr	NEW_TPALET_initialize_0_sub
	movem.l	(sp)+,tpalet_register
	rts

NEW_TPALET_initialize_0_sub:
	jsr	(a1)
	move.l	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,d2
	moveq.l	#8,d1
	jsr	(a1)
	rts

NEW_TPALET_initialize_8:
	movem.l	tpalet_register,-(sp)
	move.l	vector_TPALET2,a1
	move.w	$ed0038,d2
	bsr	NEW_TPALET_initialize_8_sub
	movem.l	(sp)+,tpalet_register
	rts

NEW_TPALET_initialize_8_sub:
	moveq.l	#15,d1
	jsr	(a1)
	subq.w	#1,d1
	jsr	(a1)
	subq.w	#1,d1
	jsr	(a1)
	subq.w	#1,d1
	jsr	(a1)
	moveq.l	#3,d1
	bsr	NEW_TPALET_set_sub
	moveq.l	#2,d1
	bsr	NEW_TPALET_set_sub
	moveq.l	#1,d1
	bsr	NEW_TPALET_set_sub
	move.l	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,d2
	moveq.l	#8,d1
	jsr	(a1)
	rts

NEW_TPALET_set_sub:
	moveq.l	#-1,d2
	jsr	(a1)
	move.w	d0,d2
	bset.l	#3,d1
	jsr	(a1)
	rts

*-------------------------------------------------------------------------------
* _CRTMODの処理

	.text
NEW_CRTMOD:
	tst.b	active_flag
	beq	NEW_CRTMOD_end

	cmp.w	#-1,d1
	beq	@f
	clr.b	graphic_data_16_flag
@@:
	bsr	crtc_check_16
	beq	NEW_CRTMOD_16

	cmp.w	#$0110,d1
	beq	@f
	clr.b	save_force_flag
@@:
	cmp.w	#-1,d1
	beq	NEW_CRTMOD_end
	cmp.b	#17,d1
	bcc	NEW_CRTMOD_end
	cmp.b	#16,d1
	beq	NEW_CRTMOD_mask_check
	cmp.b	#12,d1
	bcc	NEW_CRTMOD_mask_halt
	cmp.b	#8,d1
	beq	NEW_CRTMOD_gx
	cmp.w	#4,d1
	beq	NEW_CRTMOD_tone_fixed

NEW_CRTMOD_clear:
	bsr	tram_check_clear
	bsr	gnc64k_check
	tst.l	d0
	beq	NEW_CRTMOD_end

	bsr	graphic_scroll_register_clear
NEW_CRTMOD_initialize:
NEW_CRTMOD_end:
	move.l	vector_CRTMOD,-(sp)
	rts

NEW_CRTMOD_gx:
	move.w	$e82600,d0
	and.w	#$00ff,d0
	move.w	d0,$e82600
	bra	NEW_CRTMOD_clear

NEW_CRTMOD_tone_fixed:
	cmp.w	#$1900,$e82600
	bne	NEW_CRTMOD_clear
	bsr	NEW_CRTMOD_clear
	or.w	#$1900,$e82600
	rts

NEW_CRTMOD_mask_64k:			* 明らかに６４Ｋぷにモードのとき
	bsr	gnc64k_check
	tst.l	d0
	beq	NEW_CRTMOD_mask_gnc_off

	bsr	NEW_CRTMOD_tone_save
	move.w	d0,-(sp)
	bsr	NEW_CRTMOD_mask_64k_mode_change
	move.w	(sp)+,d0
	bsr	NEW_CRTMOD_mask_graphic_not_clear

	bsr	tram_check_mask
	clr.b	mask_halt_flag
	clr.b	mask_request_flag
	rts

NEW_CRTMOD_tone_save:
	move.w	#$1900,d0
	cmp.w	#$0316,$e80028
	bne	@f
	move.w	$e82600,d0
@@:
	move.b	#$1f,d0
	rts

NEW_CRTMOD_mask_64k_mode_change:
	move.l	d1,-(sp)
	move.w	#$0b16,d1		* モード保存で切り替えする
	moveq.l	#$1f,d0
	and.w	$e82600,d0
	beq	@f			* グラフィックは消えています
	move.w	#$0316,d1
@@:
	bsr	NEW_CRTMOD_screen_change
	move.l	(sp)+,d1
	bsr	NEW_CRTMOD_screen_initialize
	rts

NEW_CRTMOD_mask_gnc_off:
	bsr	NEW_CRTMOD_initialize
	bsr	tram_check_clear	* 不必要なマスクを外す（普通のモード変更）
	clr.b	mask_halt_flag
	clr.b	mask_request_flag
	rts

NEW_CRTMOD_mask_check:			* 不都合解消ルーチン(^^;
	cmp.w	#$001f,$e82600
	beq	@f
	clr.b	save_force_flag
@@:
	btst.l	#8,d1
	beq	NEW_CRTMOD_mask_check_flag
	cmp.b	#$04,$e80028
	bne	NEW_CRTMOD_mask_check_flag
	cmp.b	#$03,$e82401
	beq	NEW_CRTMOD_clear

NEW_CRTMOD_mask_check_flag:
	tst.b	mask_disable_flag
	bne	NEW_CRTMOD_mask_disable
	tst.b	mask_enable_flag
	beq	NEW_CRTMOD_mask_enable

	tst.b	mask_request_flag
	bne	NEW_CRTMOD_mask_64k
	tst.b	mask_halt_flag
	bne	NEW_CRTMOD_mask_set_check

	moveq.l	#$1f,d0
	and.w	$e82600,d0
	beq	NEW_CRTMOD_clear	* グラフィックは消えています
	cmp.w	#$0010,d0
	beq	NEW_CRTMOD_clear

	bsr	gpalette_zero_check	* 特殊な例だな
	tst.l	d0
	beq	@f

	bsr	gpalette_check
	tst.l	d0
	beq	NEW_CRTMOD_mask_64k	* ６４Ｋのパレット？
@@:
	bsr	NEW_CRTMOD_tone_save
	move.w	d0,-(sp)
	bsr	NEW_CRTMOD_initialize	* モード不明
	move.w	(sp)+,d0
	bsr	force_graphic_data_16_save
	bsr	tram_check_clear
	clr.b	mask_halt_flag
	clr.b	mask_request_flag
	rts

force_graphic_data_16_save:
	tst.b	save_force_flag
	beq	force_graphic_data_16_save_end
	clr.b	save_force_flag
	bsr	graphic_data_16_save
force_graphic_data_16_save_end:
	rts

NEW_CRTMOD_mask_set_check:
	bsr	gpalette_check
	tst.l	d0
	beq	NEW_CRTMOD_mask_64k	* ６４Ｋのパレット？
	bra	NEW_CRTMOD_mask_gnc_off

NEW_CRTMOD_mask_halt:
	tst.b	mask_disable_flag
	bne	NEW_CRTMOD_mask_disable
	tst.b	mask_enable_flag
	beq	NEW_CRTMOD_end

	st.b	mask_halt_flag		* 次回に備える
	bra	NEW_CRTMOD_clear

NEW_CRTMOD_mask_enable:
	bsr	gnc64k_check
	tst.l	d0
	beq	NEW_CRTMOD_end

	moveq.l	#$1f,d0
	and.w	$e82600,d0
	beq	NEW_CRTMOD_clear	* グラフィックは消えています
	cmp.w	#$0010,d0
	beq	NEW_CRTMOD_clear

	bsr	NEW_CRTMOD_tone_save
	move.w	d0,-(sp)

	bsr	gpalette_zero_check	* 特殊な例だな
	tst.l	d0
	beq	@f

	bsr	gpalette_check
	tst.l	d0
	beq	NEW_CRTMOD_mask_enable_64k
@@:
	bsr	NEW_CRTMOD_initialize	* 『G』一周中・・・
	bsr	force_graphic_data_16_save
	move.w	(sp)+,d0		* いらないから捨てる
	bra	NEW_CRTMOD_mask_enable_end
NEW_CRTMOD_mask_enable_64k:
	bsr	NEW_CRTMOD_mask_64k_mode_change
	move.w	(sp)+,d0
	bsr	NEW_CRTMOD_mask_graphic_not_clear
NEW_CRTMOD_mask_enable_end:
	bsr	tram_check_clear
	clr.b	mask_request_flag
	rts

NEW_CRTMOD_mask_disable:
	bsr	tram_check_clear
	clr.b	mask_halt_flag		* 禁止中はマスクなんかいらない
	clr.b	mask_request_flag

	cmp.b	#16,d1
	bne	NEW_CRTMOD_end
	bra	NEW_CRTMOD_mask_enable

mask_graphic_not_clear_register	reg	d1/a0-a1

NEW_CRTMOD_mask_graphic_not_clear:
	movem.l	mask_graphic_not_clear_register,-(sp)
	move.w	d0,d1
	bsr	gram_check
	tst.l	d0
	bne	NEW_CRTMOD_mask_graphic_not_clear_end

	lea	$e82600,a1
	moveq.l	#$60,d0
	and.w	(a1),d0
	or.w	d0,d1

	lea	$e80018,a0		* グラフィック・スクロール・レジスタのアドレス
					* 画面中央に来るようにする
	move.l	#$ff80_0000,d0
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+

	moveq.l	#%111,d0
	and.w	-$200(a1),d0		* $e82400
	lsl.w	#8,d0
	move.b	$01(a0),d0
	move.w	d0,(a0)
	move.w	d1,(a1)			* トーンダウン＋６４Ｋ色表示
NEW_CRTMOD_mask_graphic_not_clear_end:
	movem.l	(sp)+,mask_graphic_not_clear_register
	rts

*-------------------------------------------------------------------------------
* _CRTMODの１６色用のルーチン

	.text
NEW_CRTMOD_16:
	bsr	tram_check_clear
	clr.b	save_force_flag
	cmp.w	#$010c,d1
	bne	@f
	st.b	save_force_flag
@@:
	tst.b	gnc_flag
	beq	NEW_CRTMOD_16_end

NEW_CRTMOD_16_check:
	cmp.w	#-1,d1
	beq	NEW_CRTMOD_16_end
	cmp.b	#17,d1
	bcc	NEW_CRTMOD_16_end
	cmp.b	#16,d1
	beq	NEW_CRTMOD_16_gnc
	bra	NEW_CRTMOD_16_end

NEW_CRTMOD_16_gnc:
	move.l	d1,-(sp)
	move.w	#$0c16,d1		* モード保存で切り替えする
	moveq.l	#$1f,d0
	and.w	$e82600,d0
	beq	@f			* グラフィックは消えています
	move.w	#$0416,d1
@@:
	bsr	NEW_CRTMOD_screen_change
	move.l	(sp)+,d1
	btst.l	#8,d1
	beq	@f
	bsr	graphic_scroll_register_clear
@@:
	bsr	NEW_CRTMOD_screen_initialize
	rts

NEW_CRTMOD_16_end:
	move.l	vector_CRTMOD,-(sp)
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
* 常駐パレット機能（謎）

	.text
	.even
graphic_palette_16_flag:
	.ds.b	1
	.even
graphic_palette_16:
	.ds.w	16

graphic_palette_16_save_register	reg	d0/a0-a1

	.text
graphic_palette_16_save:
	movem.l	graphic_palette_16_save_register,-(sp)
	lea	$e82000,a0
	lea	graphic_palette_16(pc),a1
	moveq.l	#16-1,d0
	_HSYNC_WAIT
graphic_palette_16_save_loop:
	_HSYNC_WAIT2
	move.w	(a0)+,(a1)+
	dbra	d0,graphic_palette_16_save_loop
	st.b	graphic_palette_16_flag
	movem.l	(sp)+,graphic_palette_16_save_register
	rts

*-------------------------------------------------------------------------------
* グラフィックが書き換わったか調べる（いい加減なやつ・・・）

	.text
	.even
graphic_data_16_flag:
	.ds.b	1
	.even
graphic_data_16:
	.ds.w	9

graphic_data_16_check_register	reg	d0-d1/a0-a1

	.text
graphic_data_16_check:
	movem.l	graphic_data_16_check_register,-(sp)

	btst.b	#3,$e80028
	bne	graphic_data_16_check_end
	moveq.l	#%0001_1111,d0
	and.w	$e82600,d0
	bclr.l	#4,d0
	bne	@f
	tst.w	d0
	bne	@f
	bra	graphic_data_16_check_end	* グラフィックは消えています
@@:
	lea	graphic_data_16(pc),a1
	lea	$c00000,a0
	moveq.l	#$04,d1
	swap.w	d1

	move.w	(a0),d0
	cmp.w	(a1)+,d0
	bne	graphic_data_16_check_new
	move.w	$400(a0),d0
	cmp.w	(a1)+,d0
	bne	graphic_data_16_check_new

	add.l	d1,a0
	move.w	$100(a0),d0
	cmp.w	(a1)+,d0
	bne	graphic_data_16_check_new
	move.w	$300(a0),d0
	cmp.w	(a1)+,d0
	bne	graphic_data_16_check_new

	add.l	d1,a0
	move.w	$200(a0),d0
	cmp.w	(a1)+,d0
	bne	graphic_data_16_check_new

	add.l	d1,a0
	move.w	$100(a0),d0
	cmp.w	(a1)+,d0
	bne	graphic_data_16_check_new
	move.w	$300(a0),d0
	cmp.w	(a1)+,d0
	bne	graphic_data_16_check_new

	add.l	d1,a0
	move.w	(a0),d0
	cmp.w	(a1)+,d0
	bne	graphic_data_16_check_new
	move.w	$400(a0),d0
	cmp.w	(a1)+,d0
	bne	graphic_data_16_check_new

	st.b	graphic_data_16_flag		* 以後のチェックを省く
	bra	graphic_data_16_check_end	* おそらく書き換わってない・・・

graphic_data_16_check_new:
	lea	$c00000,a0
	clr.l	d0
	move.w	(a0),d0
	add.w	$400(a0),d0
	add.l	d1,a0
	add.w	$100(a0),d0
	add.w	$300(a0),d0
	add.l	d1,a0
	add.w	$200(a0),d0
	add.l	d1,a0
	add.w	$100(a0),d0
	add.w	$300(a0),d0
	add.l	d1,a0
	add.w	(a0),d0
	add.w	$400(a0),d0
	tst.l	d0
	beq	graphic_data_16_check_end	* クリア中・・・

	bsr	graphic_data_16_save		* グラフィックデータの保存
	bsr	graphic_palette_16_save		* パレットデータの保存
graphic_data_16_check_end:
	movem.l	(sp)+,graphic_data_16_check_register
	rts

graphic_data_16_save:
	movem.l	d1/a0-a1,-(sp)
	moveq.l	#$04,d1
	swap.w	d1
	lea	graphic_data_16(pc),a1
	lea	$c00000,a0
	move.w	(a0),(a1)+
	move.w	$400(a0),(a1)+
	add.l	d1,a0
	move.w	$100(a0),(a1)+
	move.w	$300(a0),(a1)+
	add.l	d1,a0
	move.w	$200(a0),(a1)+
	add.l	d1,a0
	move.w	$100(a0),(a1)+
	move.w	$300(a0),(a1)+
	add.l	d1,a0
	move.w	(a0),(a1)+
	move.w	$400(a0),(a1)+
	st.b	graphic_data_16_flag
	movem.l	(sp)+,d1/a0-a1
	rts

*-------------------------------------------------------------------------------
* 画面モードを切り替えて・・・（７６８×５１２専用）
*
* entry:
*   d1.w = $e80028 に設定する値

	.text
NEW_CRTMOD_screen_change:
	move.b	#16,$093c.w		* 現在の画面モードを保存

	clr.w	d0
	move.b	$0992.w,d0		* カーソル表示フラグ
	move.w	d0,-(sp)
	move.l	($400+(__B_CUROFF*4)).w,a0
	jsr	(a0)

	lea	$e80000,a0
	bsr	vdisp_wait
	move.w	$2600(a0),d0
	clr.w	$2600(a0)
	move.w	d1,$28(a0)

	move.w	#$0089,(a0)+		* 水平
	move.w	#$000e,(a0)+
	move.w	#$001c,(a0)+
	move.w	#$007c,(a0)+
	move.w	#$0237,(a0)+		* 垂直
	move.w	#$0005,(a0)+
	move.w	#$0028,(a0)+
	move.w	#$0228,(a0)+
	move.w	#$001b,(a0)+
	clr.w	(a0)+			* ラスター割り込み位置
	clr.l	(a0)+			* テキスト・スクロール・レジスタ

	lsr.w	#8,d1
	and.w	#%111,d1
	move.w	d1,$e82400

	moveq.l	#$ff,d1
	lea	$eb0800,a0
	move.l	d1,(a0)+		* ＢＧスクロール・レジスタ
	move.l	d1,(a0)+
	and.w	#$fff6,(a0)+		* ＢＧコントロール
	move.l	d1,(a0)+		* 画面モード・レジスタ
	move.l	d1,(a0)+

	lea	$e80018,a0		* グラフィック・スクロール・レジスタのアドレス
					* 画面中央に来るようにする
	move.w	$10(a0),d1
	and.w	#$03ff,d1
	cmp.w	#$0316,d1
	bne	@f
	move.l	#$ff80_0000,d1
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
@@:

	move.w	d0,$e82600

	clr.l	$0948.w			* テキスト表示開始アドレスオフセット
	bsr	_graphic_color_max	* グラフィック画面の色数－１
	bsr	_graphic_line_length	* グラフィックＶＲＡＭ横サイズ
	bsr	_graphic_window		* グラフィッククリッピングエリア
	move.w	#96-1,$0970.w		* テキスト桁数－１
	move.w	#32-1,$0972.w		* テキスト行数－１
	clr.w	$0974.w			* カーソル位置
	clr.w	$0976.w
	clr.w	$0a9a.w			* マウスカーソル移動範囲
	clr.w	$0a9c.w
	move.w	#768-1,$0a9e.w
	move.w	#512-1,$0aa0.w

	move.w	(sp)+,d0
	beq	NEW_CRTMOD_screen_change_end
	move.l	($400+(__B_CURON*4)).w,a0
	jsr	(a0)
NEW_CRTMOD_screen_change_end:
	rts

*-------------------------------------------------------------------------------
* 画面を初期化する（グラフィックパレット以外）

NEW_CRTMOD_screen_initialize_register	reg	d0-d2/a1

	.text
NEW_CRTMOD_screen_initialize:
	movem.l	NEW_CRTMOD_screen_initialize_register,-(sp)
	btst.l	#8,d1
	bne	NEW_CRTMOD_screen_initialize_end

	moveq.l	#2,d1
	move.l	($400+(__B_CLR_ST*4)).w,a1
	jsr	(a1)			* 画面のクリア
	or.w	#$0020,$e82600		* テキスト表示オン
	moveq.l	#-2,d1
	move.l	($400+(__CONTRAST*4)).w,a1
	jsr	(a1)			* コントラスト初期化
	moveq.l	#0,d1
	moveq.l	#-2,d2
	move.l	($400+(__TPALET*4)).w,a1
	jsr	(a1)			* テキストパレット初期化
	moveq.l	#1,d1
	jsr	(a1)
	moveq.l	#2,d1
	jsr	(a1)
	moveq.l	#3,d1
	jsr	(a1)
	moveq.l	#4,d1
	jsr	(a1)
	moveq.l	#8,d1
	jsr	(a1)
NEW_CRTMOD_screen_initialize_end:
	movem.l	(sp)+,NEW_CRTMOD_screen_initialize_register
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
* ＧＮＣモードが利用できるか調べる
*
* return:
*   d0.l  = 0 ＧＮＣ６４Ｋモードではありません
*        != 0 ぷにぷに６４Ｋモードです

gnc64k_check_register	reg	d1

	.text
gnc64k_check:
	movem.l	gnc64k_check_register,-(sp)
	clr.l	d0
	tst.b	gnc_flag
	beq	gnc64k_check_end

	moveq.l	#$1f,d1
	and.w	$e82600,d1
	beq	gnc64k_check_end	* グラフィックは消えています

	moveq.l	#%111,d1
	and.w	$e82400,d1
	btst.l	#1,d1
	beq	gnc64k_check_end

	moveq.l	#$ff,d0
gnc64k_check_end:
	movem.l	(sp)+,gnc64k_check_register
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
	bsr	vdisp_wait
gpalette_set_loop:
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
	clr.l	d0
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
* グラフィックパレットが０か調べる
*
* return
*  d0.l  = 0 ０です.
*       != 0 違うね

gpalette_zero_check_register	reg	d1-d2/a0

	.text
gpalette_zero_check:
	movem.l	gpalette_zero_check_register,-(sp)
	lea	$e82000,a0
	moveq.l	#16-1,d2
	clr.l	d0
	clr.l	d1
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	move.w	(a0)+,d1
	add.l	d1,d0
	dbra	d2,@b
	movem.l	(sp)+,gpalette_zero_check_register
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

	bsr	gpalette_set
gpalette_check_set_end:
	rts

*-------------------------------------------------------------------------------
* テキスト、グラフィックラムの使用フラグを見てマスクをする

	.text
tram_check_mask:
	bsr	tram_check
	tst.l	d0
	bne	tram_check_mask_end

	bsr	gram_check
	tst.l	d0
	bne	tram_check_mask_end

	bsr	mask_sub
	st.b	mask_set_flag
tram_check_mask_end:
	rts

*-------------------------------------------------------------------------------
* テキストラムの使用フラグを見てマスククリアをする

	.text
tram_check_clear:
	tst.b	mask_set_flag
	beq	tram_check_clear_end

	bsr	tram_check
	tst.l	d0
	bne	tram_check_clear_end

	bsr	clear_sub
	clr.b	mask_set_flag
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
	swap.w	d1
	cmp.w	#_GM_INTERNAL_MODE,d1
	beq	NEW_TGUSEMD_internal
	swap.w	d1

	clr.b	graphic_data_16_flag
	cmp.b	#0,d1
	beq	NEW_TGUSEMD_graphic
	cmp.b	#1,d1
	beq	NEW_TGUSEMD_text
	bra	NEW_TGUSEMD_end

NEW_TGUSEMD_graphic:
	cmp.b	#-1,d2
	beq	NEW_TGUSEMD_clear
	cmp.b	#4,d2
	bcc	NEW_TGUSEMD_end
	bra	NEW_TGUSEMD_clear

NEW_TGUSEMD_text:
	cmp.b	#-1,d2
	beq	NEW_TGUSEMD_end
	cmp.b	#4,d2
	bcc	NEW_TGUSEMD_end
	cmp.b	#2,d2
	beq	NEW_TGUSEMD_text_2

	st.b	mask_enable_flag
	tst.b	mask_halt_flag
	bne	NEW_TGUSEMD_mask
	bra	NEW_TGUSEMD_end

NEW_TGUSEMD_text_2:
	tst.b	mask_set_flag
	sne.b	mask_halt_flag
	beq	NEW_TGUSEMD_clear
	clr.b	mask_enable_flag
NEW_TGUSEMD_clear:
	bsr	tram_check_clear
	clr.b	mask_request_flag
NEW_TGUSEMD_end:
	move.l	vector_TGUSEMD,-(sp)
	rts

NEW_TGUSEMD_mask:
	tst.b	mask_disable_flag
	bne	NEW_TGUSEMD_end
	tst.b	mask_enable_flag
	beq	NEW_TGUSEMD_end

	move.l	vector_TGUSEMD,a0
	jsr	(a0)
	cmp.w	#$0316,$e80028
	bne	NEW_TGUSEMD_mask_end
	bsr	tram_check_mask
	clr.b	mask_halt_flag
	clr.b	mask_request_flag
NEW_TGUSEMD_mask_end:
	rts

NEW_TGUSEMD_internal:
	swap.w	d1
	cmp.b	#-1,d1
	beq	NEW_TGUSEMD_end
	tst.b	d1
	bpl	NEW_TGUSEMD_end
	cmp.w	#$ff80,d1
	bcs	NEW_TGUSEMD_end
	cmp.w	#$ffa0,d1
	bcc	NEW_TGUSEMD_end

	move.w	d1,d0
	sub.w	#$ff80,d0
	add.w	d0,d0
	add.w	d0,d0
	lea	NEW_TGUSEMD_jump_table(pc),a0
	move.l	(a0,d0.w),a0
	jsr	(a0)
	swap.w	d0
	move.w	#_GM_INTERNAL_MODE,d0
	rts

NEW_TGUSEMD_jump_table:
	.dc.l	NEW_TGUSEMD_internal_version			* ff80
	.dc.l	NEW_TGUSEMD_internal_mask_state			* ff81
	.dc.l	NEW_TGUSEMD_internal_gnc_state			* ff82
	.dc.l	NEW_TGUSEMD_internal_auto_state			* ff83
	.dc.l	NEW_TGUSEMD_internal_graphic_mode_state		* ff84
	.dc.l	NEW_TGUSEMD_internal_active_state		* ff85
	.dc.l	NEW_TGUSEMD_end					* ff86
	.dc.l	NEW_TGUSEMD_end					* ff87
	.dc.l	NEW_TGUSEMD_internal_mask_request		* ff88
	.dc.l	NEW_TGUSEMD_internal_mask_set			* ff89
	.dc.l	NEW_TGUSEMD_internal_mask_clear			* ff8a
	.dc.l	NEW_TGUSEMD_internal_auto_disable		* ff8b
	.dc.l	NEW_TGUSEMD_internal_auto_enable		* ff8c
	.dc.l	NEW_TGUSEMD_internal_active			* ff8d
	.dc.l	NEW_TGUSEMD_internal_inactive			* ff8e
	.dc.l	NEW_TGUSEMD_end					* ff8f
	.dc.l	NEW_TGUSEMD_internal_keep_palette		* ff90
	.dc.l	NEW_TGUSEMD_internal_palette_save		* ff91
	.dc.l	NEW_TGUSEMD_internal_gvram_save			* ff92
	.dc.l	NEW_TGUSEMD_end					* ff93
	.dc.l	NEW_TGUSEMD_end					* ff94
	.dc.l	NEW_TGUSEMD_end					* ff95
	.dc.l	NEW_TGUSEMD_end					* ff96
	.dc.l	NEW_TGUSEMD_end					* ff97
	.dc.l	NEW_TGUSEMD_end					* ff98
	.dc.l	NEW_TGUSEMD_end					* ff99
	.dc.l	NEW_TGUSEMD_end					* ff9a
	.dc.l	NEW_TGUSEMD_end					* ff9b
	.dc.l	NEW_TGUSEMD_end					* ff9c
	.dc.l	NEW_TGUSEMD_end					* ff9d
	.dc.l	NEW_TGUSEMD_end					* ff9e
	.dc.l	NEW_TGUSEMD_end					* ff9f

NEW_TGUSEMD_internal_version:
	move.w	#GM_VERSION,d0
	rts

NEW_TGUSEMD_internal_mask_state:
	tst.b	mask_set_flag
	sne.b	d0
	ext.w	d0
	rts

NEW_TGUSEMD_internal_gnc_state:
	tst.b	gnc_flag
	sne.b	d0
	ext.w	d0
	rts

NEW_TGUSEMD_internal_auto_state:
	clr.w	d0
	tst.b	mask_enable_flag
	sne.b	d0
	add.w	d0,d0
	tst.b	mask_disable_flag
	sne.b	d0
	lsr.w	#7,d0
	rts

NEW_TGUSEMD_internal_graphic_mode_state:
	bsr	crtc_check_16
	sne.b	d0
	ext.w	d0
	rts

NEW_TGUSEMD_internal_active_state:
	tst.b	active_flag
	sne.b	d0
	ext.w	d0
	rts

NEW_TGUSEMD_internal_mask_request:
	st.b	mask_request_flag
	rts

NEW_TGUSEMD_internal_mask_set:
	bsr	crtc_check_16
	beq	@f			* マスクをするのは６４Ｋの画像のみです
	btst.b	#1,$e80028
	beq	@f
	bsr	mask_sub
	st.b	mask_set_flag
	clr.b	mask_halt_flag
	clr.b	mask_request_flag
@@:
	rts

NEW_TGUSEMD_internal_mask_clear:
	bsr	clear_sub
	clr.b	mask_set_flag
	clr.b	mask_halt_flag
	clr.b	mask_request_flag
	rts

NEW_TGUSEMD_internal_auto_disable:
	st.b	mask_disable_flag
	clr.b	mask_enable_flag
	rts

NEW_TGUSEMD_internal_auto_enable:
	clr.b	mask_disable_flag
	st.b	mask_enable_flag
	rts

NEW_TGUSEMD_internal_active
	st.b	active_flag
	rts

NEW_TGUSEMD_internal_inactive:
	clr.b	active_flag
	rts

NEW_TGUSEMD_internal_keep_palette:
	tst.b	graphic_palette_16_flag
	sne.b	d0
	ext.w	d0
	lea	graphic_palette_16,a1
	rts

NEW_TGUSEMD_internal_palette_save:
	clr.b	check_force_flag
	clr.b	save_force_flag
	bsr	graphic_palette_16_save
	rts

NEW_TGUSEMD_internal_gvram_save:
	clr.b	check_force_flag
	clr.b	save_force_flag
	bsr	graphic_data_16_save
	rts

*-------------------------------------------------------------------------------
* _G_CLR_ONの処理

	.text
NEW_G_CLR_ON:
	tst.b	active_flag
	beq	NEW_G_CLR_ON_end

	clr.b	graphic_data_16_flag

	tst.b	gnc_flag
	beq	NEW_G_CLR_ON_gnc_off

	bsr	graphic_scroll_register_clear
NEW_G_CLR_ON_gnc_off:
	bsr	tram_check_clear
	clr.b	mask_request_flag
NEW_G_CLR_ON_end:
	bsr	NEW_G_CLR_ON_sub
	rts

NEW_G_CLR_ON_sub:
	movem.l	d1-d7/a1-a6,-(sp)
	move.w	#$0020,$e82600
	bset.b	#3,$e80028

	clr.l	d1
	move.l	d1,d2
	move.l	d1,d3
	move.l	d1,d4
	move.l	d1,d5
	move.l	d1,d6
	move.l	d1,d7
	move.l	d1,a1
	move.l	d1,a2
	move.l	d1,a3
	move.l	d1,a4
	move.l	d1,a5
	move.l	d1,a6
	lea.l	$c00000,a0
	move.l	a0,$95c.w
	lea	$400(a0),a0
	move.w	#512-1,d0
NEW_G_CLR_ON_sub_loop:
	.rept	19
	movem.l	d1-d7/a1-a6,-(a0)	* 13*4=52*19=988
	.endm
	movem.l	d1-d7/a1-a2,-(a0)	* 9*4=36+988=1024
	lea	$800(a0),a0
	dbra	d0,NEW_G_CLR_ON_sub_loop

	bclr.b	#$03,$00e80028

	moveq.l	#%11111000,d0
	and.b	$00e80028,d0
	moveq.l	#%00001111,d1
	and.b	$93c.w,d1
	cmp.b	#4,d1
	bcc	@f
	bset.l	#2,d0
@@:
	cmp.b	#8,d1
	bcs	@f
	bset.l	#0,d0
@@:
	cmp.b	#12,d1
	bcs	@f
	bset.l	#1,d0
@@:
	
	moveq.l	#%00000111,d1
	and.b	d0,d1
	move.b	d0,$e80028
	move.w	d1,$e82400

	and.w	#%0000_0011,d0
	bne	@f
	bsr	NEW_G_CLR_ON_sub_palette_16
	bra	NEW_G_CLR_ON_sub_end
@@:
	subq.w	#1,d0
	bne	@f
	bsr	NEW_G_CLR_ON_sub_palette_256
	bra	NEW_G_CLR_ON_sub_end
@@:
	bsr	gpalette_set
NEW_G_CLR_ON_sub_end:
	bsr	_graphic_color_max
	bsr	_graphic_line_length
	bsr	_graphic_window
	bclr.b	#$03,$00e80028
	move.w	#$003f,$00e82600
	movem.l	(sp)+,d1-d7/a1-a6
	rts

gpalette_data_16:
	.dc.w	$0000,$5294,$0020,$003e,$0400,$07c0,$0420,$07fe
	.dc.w	$8000,$f800,$8020,$f83e,$8400,$ffc0,$ad6a,$fffe

	.even
NEW_G_CLR_ON_sub_palette_16:
	lea	$e82000,a0
	lea	gpalette_data_16(pc),a1
	moveq.l	#16-1,d0
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
	lea	gpalette_data_256_g,a0
	lea	gpalette_data_256_rb,a1
	lea	$e82000,a2

	move.w	#4-1,d7
NEW_G_CLR_ON_sub_palette_256_g_loop:
	clr.w	d4
	move.b	(a0,d7.w),d4
	ror.w	#5,d4

		move.w	#8-1,d6
NEW_G_CLR_ON_sub_palette_256_r_loop:
		clr.w	d3
		move.b	(a1,d6.w),d3
		lsl.w	#6,d3

			move.w	#8-1,d5
NEW_G_CLR_ON_sub_palette_256_b_loop:
			clr.w	d2
			move.b	(a1,d5.w),d2	* B
			add.w	d2,d2		* I ビットは０
			or.w	d3,d2		* R
			or.w	d4,d2		* G
			move.w	d2,(a2)+
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
	movem.l	tram_check_register,-(sp)
	moveq.l	#1,d1			* 内部からのコール
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	move.b	d0,d1
	clr.l	d0
	cmp.b	#2,d1
	bne	tram_check_end

	tst.b	force_flag
	bne	tram_check_force	* 強制使用モード

	moveq.l	#-1,d0			* アプリケーションで使用中
tram_check_end:
	movem.l	(sp)+,tram_check_register
	rts

tram_check_force:
	moveq.l	#1,d1			* 強制的にシステムで使います
	moveq.l	#1,d2
	bsr	_gm_internal_tgusemd
	clr.l	d0
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
	movem.l	gram_check_register,-(sp)
	moveq.l	#0,d1			* 内部からのコール
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	move.b	d0,d1
	clr.l	d0
	cmp.b	#2,d1
	bne	gram_check_end
	moveq.l	#-1,d0			* アプリケーションで使用中
gram_check_end:
	movem.l	(sp)+,gram_check_register
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
* マスクしちゃうの

mask_sub_register	reg	d1-d2/a0-a1

	.text
mask_sub:
	movem.l	mask_sub_register,-(sp)

	IOCS	__MS_STAT
	move.w	d0,-(sp)
	IOCS	__MS_CUROF

	.ifdef	__DEBUG__
COLOR	equ	8
	.else
COLOR	equ	0
	.endif

					* テキストパレット８～１１を変更する
	lea	TEXTPALETTE_ADDRESS+2*1,a0
	lea	TEXTPALETTE_ADDRESS+2*8,a1

	_HSYNC_WAIT
	move.w	#(COLOR<<11)+(COLOR<<6)+(COLOR<<1)+1,(a1)+
	_HSYNC_WAIT2
	move.w	(a0)+,(a1)+
	_HSYNC_WAIT2
	move.l	(a0)+,(a1)+

	moveq.l	#$ff,d0
	bsr	text_paint

	move.w	(sp)+,d0
	beq	mask_sub_end
	IOCS	__MS_CURON
mask_sub_end:
	movem.l	(sp)+,mask_sub_register
	rts

*-------------------------------------------------------------------------------
* マスクはずすの

clear_sub_register	reg	d1-d2/a0-a1

	.text
clear_sub:
	movem.l	clear_sub_register,-(sp)

	IOCS	__MS_STAT
	move.w	d0,-(sp)
	IOCS	__MS_CUROF

	moveq.l	#$00,d0
	bsr	text_paint

					* テキストパレットをもとにもどす
	lea	TEXTPALETTE_ADDRESS+2*14,a0
	lea	TEXTPALETTE_ADDRESS+2*8,a1
	_HSYNC_WAIT
	move.l	(a0),(a1)+
	_HSYNC_WAIT2
	move.l	(a0),(a1)+

	move.w	(sp)+,d0
	beq	clear_sub_end
	IOCS	__MS_CURON
clear_sub_end:
	movem.l	(sp)+,clear_sub_register
	rts

*-------------------------------------------------------------------------------
*
* entry:
*   d0.l = 塗りつぶすデータ

text_paint_register	reg	d1-d5/a0-a1

	.text
text_paint:
	movem.l	text_paint_register,-(sp)
	move.l	d0,d1
	move.l	d0,d2
	move.l	d0,d3
	move.l	d0,d4

	lea	TEXTVRAM_P3_ADDRESS,a0
	move.w	#($0080*4),d5
	move.w	#(512/4)-1,d0

	lea	$e8002a,a1
	move.w	(a1),-(sp)
	clr.b	(a1)
text_paint_loop:
	movem.l	d1-d4,(a0)		* テキストプレーン塗りつぶし
	movem.l	d1-d4,$50(a0)
	movem.l	d1-d4,$80(a0)
	movem.l	d1-d4,$80+$50(a0)
	movem.l	d1-d4,$80*2(a0)
	movem.l	d1-d4,$80*2+$50(a0)
	movem.l	d1-d4,$80*3(a0)
	movem.l	d1-d4,$80*3+$50(a0)
	add.w	d5,a0
	dbra	d0,text_paint_loop
	move.w	(sp)+,(a1)

	movem.l	(sp)+,text_paint_register
	rts

*-------------------------------------------------------------------------------
* ここまで常駐させる

program_keep_end:

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
	.even
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
	move.b	(a0)+,d0
	beq	switch_check_end
switch_check_loop:
	bsr	get_character
	beq	switch_check_end
	cmp.b	#'-',d0
	beq	switch_check_option
	bra	switch_check_error
switch_check_option:
	bsr	option_check
	bra	switch_check_loop
switch_check_error:
	bset.l	#OPT_ERR,d7

switch_check_end:
	tst.l	d7
	bne	exec_option
	bset.l	#OPT_ERR,d7		* スイッチがなければエラー
	bra	exec_option

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
OPT_V	.ds.b	1	* バージョン表示、メッセージの表示
OPT_P	.ds.b	1	* メモリ常駐
OPT_R	.ds.b	1	* 常駐解除
OPT_A	.ds.b	1	* 主要機能の動作
OPT_S	.ds.b	1	* 状態保存
OPT_HLP	.ds.b	1	* ヘルプ表示
OPT_ERR	equ	31	* スイッチ指定の間違いなど：常に最上位ビット
	.text

*-------------------------------------------------------------------------------

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
	cmp.b	#'M',d0
	beq	opt_m
	cmp.b	#'C',d0
	beq	opt_c
	cmp.b	#'D',d0
	beq	opt_d
	cmp.b	#'E',d0
	beq	opt_e
	cmp.b	#'F',d0
	beq	opt_f
	cmp.b	#'N',d0
	beq	opt_n
	cmp.b	#'K',d0
	beq	opt_k
	cmp.b	#'V',d0
	beq	opt_v
	cmp.b	#'P',d0
	beq	opt_p
	cmp.b	#'R',d0
	beq	opt_r
	cmp.b	#'A',d0
	beq	opt_a
	cmp.b	#'S',d0
	beq	opt_s
	cmp.b	#'H',d0
	beq	opt_h
	bra	opt_err

opt_m:
	btst.l	#OPT_C,d7		* -m/-c同時に設定するやつなんかいないだろうなぁ？
	bne	opt_err
	bset.l	#OPT_M,d7
	bra	option_check_loop

opt_c:
	btst.l	#OPT_M,d7
	bne	opt_err
	bset.l	#OPT_C,d7
	bra	option_check_loop

opt_d:
	btst.l	#OPT_E,d7		* -d/-e・・・
	bne	opt_err
	bset.l	#OPT_D,d7
	bra	option_check_loop

opt_e:
	btst.l	#OPT_D,d7
	bne	opt_err
	bset.l	#OPT_E,d7
	bra	option_check_loop

opt_f:
	bset.l	#OPT_F,d7
	bra	option_check_loop

opt_n:
	bset.l	#OPT_N,d7
	bra	option_check_loop

opt_k:
	bset.l	#OPT_K,d7
	bra	option_check_loop

opt_v:
	bset.l	#OPT_V,d7
	bra	option_check_loop

opt_p:
	btst.l	#OPT_R,d7		* -p/-r・・・
	bne	opt_err
	bset.l	#OPT_P,d7
	bra	option_check_loop

opt_r:
	btst.l	#OPT_P,d7
	bne	opt_err
	bset.l	#OPT_R,d7
	bra	option_check_loop

	.bss
	.even
opt_a_number:
	.ds.l	1
	.text
opt_a:
	bset.l	#OPT_A,d7
	lea	opt_a_number,a1
	moveq.l	#1,d0			* 読み取り数値の最大値
	move.l	d0,(a1)			* デフォルトは１らしい
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
	moveq.l	#2,d0			* 読み取り数値の最大値
	move.l	d0,(a1)			* デフォルトは２
	bsr	opt_number
	bmi	opt_err			* 最大値超えたか数値の読み取りでエラーがでた
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
	.dc.l	force
	.dc.l	gnc
	.dc.l	den_mask
	.dc.l	keep
	.dc.l	release
	.dc.l	active
	.dc.l	save_state
	.dc.l	disable
	.dc.l	enable
	.dc.l	mask
	.dc.l	clear
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
	.dc.b	'使用法: gm <スイッチ>',13,10
	.dc.b	'スイッチ:',13,10
	.dc.b	'	-m	マスク設定',13,10
	.dc.b	'	-c	マスク解除',13,10
	.dc.b	'	-d	オートマスク不許可',13,10
	.dc.b	'	-e	オートマスク許可',13,10
	.dc.b	'	-f	テキストラムを強制使用する',13,10
	.dc.b	'	-n	ＧＮＣモードを有効にする',13,10
	.dc.b	'	-k	電卓消去時にマスクをなおす',13,10
	.dc.b	'	-p	メモリ常駐',13,10
	.dc.b	'	-r	常駐解除',13,10
	.dc.b	'	-a[n]	ＧＭ主要動作の制御 (0:停止 [1]:動作)',13,10
	.dc.b	'	-s[n]	状態保存 (0:パレット 1:GVRAM [2]:両方)',13,10
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
* 状態保存

	.data
message_save_palette:
	.dc.b	'パレットをＧＭ内部に保存します',13,10
	.dc.b	0
message_save_gvram:
	.dc.b	'GVRAMをＧＭ内部に保存します',13,10
	.dc.b	0
message_save_64k:
	.dc.b	'画面モードが６４Ｋモードなので保存しません',13,10
	.dc.b	0

	.text
save_state:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_S,d7
	beq	save_state_end

	move.w	#_GM_VERSION_NUMBER,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	cmp.l	#-1,d0
	beq	save_state_not_keep
	cmp.w	#_GM_INTERNAL_MODE,d0
	bne	save_state_not_keep
	swap.w	d0
	cmp.w	#$0080,d0
	bcs	save_state_not_support

	move.w	#_GM_GRAPHIC_MODE_STATE,d1
	moveq.l	#-1,d2			* ダミーデータ
	bsr	_gm_internal_tgusemd
	swap.w	d0
	tst.w	d0
	bne	save_state_64k		* ６４Ｋだからやめる

	move.l	opt_s_number,d0
	tst.l	d0
	beq	@f
	move.w	#_GM_GVRAM_SAVE,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	pea	message_save_gvram
	bsr	_vprint
	addq.l	#4,sp
@@:
	cmp.l	#1,d0
	beq	@f
	move.w	#_GM_PALETTE_SAVE,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	pea	message_save_palette
	bsr	_vprint
	addq.l	#4,sp
@@:
	clr.l	d0

save_state_end:
	movem.l	(sp)+,exec_register
	rts

save_state_64k:
	pea	message_save_64k
	bsr	_vprint
	addq.l	#4,sp
	clr.l	d0
	bra	save_state_end

save_state_not_keep:
	pea	message_gm_not_keep
	bsr	_error_print
	addq.l	#4,sp
	moveq.l	#EXIT_ERROR_NOT_KEEP,d0
	bra	save_state_end

save_state_not_support:
	pea	message_gm_not_support
	bsr	_error_print
	addq.l	#4,sp
	moveq.l	#EXIT_ERROR_NOT_SUPPORT,d0
	bra	save_state_end

*-------------------------------------------------------------------------------
* ＧＭ主要動作の制御

	.data
message_gm_not_keep:
	.dc.b	'ＧＭは常駐していないようです',13,10
	.dc.b	0
message_gm_not_support:
	.dc.b	'このバージョンではサポートされていません',13,10
	.dc.b	0
message_gm_active:
	.dc.b	'ＧＭの動作を開始します',13,10
	.dc.b	0
message_gm_inactive:
	.dc.b	'ＧＭの動作を停止します',13,10
	.dc.b	0

	.text
active:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_A,d7
	beq	active_end

	move.w	#_GM_VERSION_NUMBER,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	cmp.l	#-1,d0
	beq	active_not_keep
	cmp.w	#_GM_INTERNAL_MODE,d0
	bne	active_not_keep
	swap.w	d0
	cmp.w	#$0078,d0
	bcs	active_not_support

	move.l	opt_a_number,d0
	bne	active_active

	move.w	#_GM_INACTIVE,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	pea	message_gm_inactive
	bsr	_vprint
	addq.l	#4,sp
	clr.l	d0
	bra	active_end

active_active:
	move.w	#_GM_ACTIVE,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	pea	message_gm_active
	bsr	_vprint
	addq.l	#4,sp
	clr.l	d0

active_end:
	movem.l	(sp)+,exec_register
	rts

active_not_keep:
	pea	message_gm_not_keep
	bsr	_error_print
	addq.l	#4,sp
	moveq.l	#EXIT_ERROR_NOT_KEEP,d0
	bra	active_end

active_not_support:
	pea	message_gm_not_support
	bsr	_error_print
	addq.l	#4,sp
	moveq.l	#EXIT_ERROR_NOT_SUPPORT,d0
	bra	active_end

*-------------------------------------------------------------------------------
* テキストラムの強制使用フラグの設定

	.data
message_force:
	.dc.b	'テキストラムを強制使用します。',13,10
	.dc.b	0

	.text
force:
	movem.l	exec_register,-(sp)
	clr.l	d0
	clr.b	force_flag
	btst.l	#OPT_F,d7
	beq	force_end

	pea	message_force
	bsr	_vprint
	addq.l	#4,sp
	move.w	#1,d1			* 内部からのコール
	moveq.l	#1,d2
	bsr	_gm_internal_tgusemd
	clr.l	d0
	st.b	force_flag
force_end:
	movem.l	(sp)+,exec_register
	rts

*-------------------------------------------------------------------------------
* ＧＮＣモードの使用フラグの設定

	.data
message_gnc_on:
	.dc.b	'ＧＮＣモードを有効にします。',13,10
	.dc.b	0
message_gnc_error:
	.dc.b	'-n は常駐する時しか意味がありません。',13,10
	.dc.b	0

	.text
gnc:
	movem.l	exec_register,-(sp)
	clr.l	d0
	clr.b	gnc_flag
	btst.l	#OPT_N,d7
	beq	gnc_end

	btst.l	#OPT_P,d7
	beq	gnc_error

	lea	program_id_name,a0
	move.l	parameter_a0,a1
	bsr	keep_check
	tst.l	d0
	bne	gnc_error2

	pea	message_gnc_on
	bsr	_vprint
	addq.l	#4,sp
	st.b	gnc_flag
	clr.l	d0
gnc_end:
	movem.l	(sp)+,exec_register
	rts

gnc_error:
	moveq.l	#EXIT_ERROR_GNCMODE,d0
gnc_error_end:
	move.l	d0,-(sp)
	pea	message_gnc_error
	bsr	_error_print
	addq.l	#4,sp
	move.l	(sp)+,d0
	bra	gnc_end

gnc_error2:
	clr.l	d0			* すでに常駐している。
	bra	gnc_error_end

*-------------------------------------------------------------------------------
* 電卓消去時のマスク使用フラグの設定

	.data
message_den_mask_on:
	.dc.b	'電卓消去時にマスクします。',13,10
	.dc.b	0
message_den_mask_error:
	.dc.b	'-k は常駐する時しか意味がありません。',13,10
	.dc.b	0

	.text
den_mask:
	movem.l	exec_register,-(sp)
	clr.l	d0
	clr.b	den_mask_flag
	btst.l	#OPT_K,d7
	beq	den_mask_end

	btst.l	#OPT_P,d7
	beq	den_mask_error

	lea	program_id_name,a0
	move.l	parameter_a0,a1
	bsr	keep_check
	tst.l	d0
	bne	den_mask_error2

	pea	message_den_mask_on
	bsr	_vprint
	addq.l	#4,sp
	st.b	den_mask_flag
	clr.l	d0
den_mask_end:
	movem.l	(sp)+,exec_register
	rts

den_mask_error:
	moveq.l	#EXIT_ERROR_DEN_MASK,d0
den_mask_error_end:
	move.l	d0,-(sp)
	pea	message_den_mask_error
	bsr	_error_print
	addq.l	#4,sp
	move.l	(sp)+,d0
	bra	den_mask_end

den_mask_error2:
	clr.l	d0
	bra	den_mask_error_end

*-------------------------------------------------------------------------------
* 常駐していなければ常駐終了になるようにする

	.data
message_keep:
	.dc.b	'プログラムを常駐します。',13,10
	.dc.b	0
message_keep_error0:
	.dc.b	'プログラムは常駐していません。',13,10
	.dc.b	0
message_keep_error1:
	.dc.b	'すでに常駐しています。',13,10
	.dc.b	0
message_keep_error2:
	.dc.b	'バージョンの違うプログラムが常駐しています。',13,10
	.dc.b	0
message_keep_error3:
	.dc.b	'内部エラーです。',13,10
	.dc.b	0
	.even
message_keep_table:
	.dc.l	message_keep_error0
	.dc.l	message_keep_error1
	.dc.l	message_keep_error2
	.dc.l	message_keep_error3
	.dc.l	0

keep_register	reg	d7/a1

	.text
keep:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_P,d7
	beq	keep_end

	lea	program_id_name,a0
	move.l	parameter_a0,a1
	bsr	keep_check
	tst.l	d0
	bne	keep_error

	bsr	keep_sub
	tst.l	d0
	bmi	keep_error		* その他のエラー（ユーザー定義）

	pea	message_keep
	bsr	_vprint
	addq.l	#4,sp

	move.l	#$8000_0100,d0		* 上位はDOS_KEEPPRするかのフラグ：下位は終了コード
	move.l	#program_stack_end,d2
	sub.l	#program_keep_end,d2	* d2.l = 非常駐部のサイズ
	move.l	program_size,d1
	sub.l	d2,d1			* d1.l = 常駐サイズ
	movem.l	(sp)+,exec_register
	clr.l	d7			* その他のスイッチは無効です
	movem.l	exec_register,-(sp)
keep_end:
	movem.l	(sp)+,exec_register
	rts

keep_error:
	bsr	keep_error_print
	moveq.l	#EXIT_ERROR_KEEP,d0
	bra	keep_end

*-------------------------------------------------------------------------------
* 常駐チェック時のエラーメッセージを表示する

	.text
keep_error_print:
	cmp.l	#4,d0
	bcc	keep_error_print_end		* 数値が規定外（ユーザ定義）です
	lea	message_keep_table,a0
	lsl.w	#2,d0
	move.l	(a0,d0.w),-(sp)
	bsr	_error_print
	addq.l	#4,sp
keep_error_print_end:
	rts

*-------------------------------------------------------------------------------
* マクロ定義

_IOCS_VECTOR_CHANGE	.macro	_a1,_a2,_n1
* _a1 = 新しい処理アドレス
* _a2 = 変更前のアドレス保存場所
* _n1 = 変更するコールナンバ

_IOCS_VECTOR_CHANGE_COUNT	set	_IOCS_VECTOR_CHANGE_COUNT+1

	pea.l	_a1
	move.w	#$100+_n1,-(sp)
	DOS	__INTVCS
	addq.l	#6,sp
	move.l	d0,_a2
	.endm

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
* 実際にベクタの変更などを行う
*
* entry:
*   なし
* return:
*   d0.l = 0  常駐できます
*   d0.l < 0  ユーザー定義エラー

	.text
keep_sub:
	movem.l	keep_register,-(sp)

	bsr	tram_check
	tst.l	d0
	bne	keep_sub_tram_used

	.ifdef	__DEBUG__
	.lall
	.endif

	pea.l	NEW_EXIT		* _EXIT, _EXIT2 を乗っ取る ver. 0.81
	move.w	#__EXIT,-(sp)
	DOS	__INTVCS
	addq.l	#6,sp
	move.l	d0,vector_EXIT

	pea.l	NEW_EXIT2
	move.w	#__EXIT2,-(sp)
	DOS	__INTVCS
	addq.l	#6,sp
	move.l	d0,vector_EXIT2

	pea.l	NEW_trap15		* trap15を乗っ取る ver. 0.67
	move.w	#$2f,-(sp)
	DOS	__INTVCS
	addq.l	#6,sp
	move.l	d0,vector_trap15

_IOCS_VECTOR_CHANGE_COUNT	set	0
	_IOCS_VECTOR_CHANGE	NEW_TPALET,vector_TPALET,__TPALET
	_IOCS_VECTOR_CHANGE	NEW_TPALET2,vector_TPALET2,__TPALET2
	_IOCS_VECTOR_CHANGE	NEW_CRTMOD,vector_CRTMOD,__CRTMOD
	_IOCS_VECTOR_CHANGE	NEW_TGUSEMD,vector_TGUSEMD,__TGUSEMD
	_IOCS_VECTOR_CHANGE	NEW_G_CLR_ON,vector_G_CLR_ON,__G_CLR_ON
	_IOCS_VECTOR_CHANGE	NEW_B_KEYSNS,vector_B_KEYSNS,__B_KEYSNS
	_IOCS_VECTOR_CHANGE	NEW_DENSNS,vector_DENSNS,__DENSNS
	_IOCS_VECTOR_CHANGE	NEW_TXXLINE,vector_TXXLINE,__TXXLINE
	_IOCS_VECTOR_CHANGE	NEW_TXYLINE,vector_TXYLINE,__TXYLINE
	_IOCS_VECTOR_CHANGE	NEW_TXBOX,vector_TXBOX,__TXBOX
	_IOCS_VECTOR_CHANGE	NEW_B_WPOKE,vector_B_WPOKE,__B_WPOKE

	.ifdef	__DEBUG__
	.sall
	.endif

	_TO_SUPER
	bsr	clear_sub
	clr.b	mask_set_flag
	clr.b	mask_halt_flag
	clr.b	mask_disable_flag
	st.b	mask_enable_flag	* デフォルトはオートマスク許可
	clr.b	mask_request_flag

	clr.b	graphic_data_16_flag	* 常駐パレット用のフラグ
	clr.b	graphic_palette_16_flag


	clr.b	wpoke_flag
	clr.b	check_force_flag

	bsr	active			* 動作制御、デフォルトは動作オン
	bsr	disable			* 常駐時から設定できるように
	bsr	enable

	cmp.w	#$0316,$e80028
	bne	keep_sub_not_64k
	tst.b	mask_enable_flag
	beq	keep_sub_not_64k
	bsr	mask_sub
	st.b	mask_set_flag
keep_sub_not_64k:
	_TO_USER

	clr.l	d0
keep_sub_end:
	movem.l	(sp)+,keep_register
	rts

keep_sub_tram_used:
	pea	message_tram_used	* テキストラム使用中
	bsr	_error_print
	addq.l	#4,sp
	moveq.l	#-1,d0
	bra	keep_sub_end

*-------------------------------------------------------------------------------
* 常駐解除する（メモリ解放など）

	.data
message_release:
	.dc.b	'プログラムを常駐解除しました。',13,10
	.dc.b	0
message_release_error:
	.dc.b	'プログラムの常駐解除ができません。',13,10
	.dc.b	0
message_release_mfree_error:
	.dc.b	'メモリ解放に失敗しました。',13,10
	.dc.b	0
message_release_vector_error:
	.dc.b	'ベクタが書き換えられています。',13,10
	.dc.b	0

release_register	reg	d7/a1

	.text
release:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_R,d7
	beq	release_end

	lea	program_id_name,a0
	move.l	parameter_a0,a1
	bsr	keep_check
	cmp.l	#1,d0
	bne	release_keep_error

	bsr	release_sub
	cmp.l	#-1,d0
	beq	release_vector_error
	tst.l	d0
	bmi	release_error		* その他のエラー（ユーザー定義）

	pea	$10(a0)
	DOS	__MFREE			* メモリ解放
	addq.l	#4,sp
	tst.l	d0
	bmi	release_mfree_error

	pea	message_release
	bsr	_vprint
	addq.l	#4,sp

	clr.l	d0
	movem.l	(sp)+,exec_register
	clr.l	d7			* その他のスイッチは無効です
	movem.l	exec_register,-(sp)
	move.l	#$10000,d0		* d0.l hw != 0:release ok
release_end:
	movem.l	(sp)+,exec_register
	rts

release_keep_error:
	bsr	keep_error_print
	moveq.l	#EXIT_ERROR_RELEASE,d0
	bra	release_end

release_error:
	pea	message_release_error
	bsr	_error_print
	addq.l	#4,sp
	moveq.l	#EXIT_ERROR_RELEASE,d0
	bra	release_end

release_vector_error:
	pea	message_release_vector_error
	bsr	_error_print
	addq.l	#4,sp
	bra	release_error

release_mfree_error:
	pea	message_release_mfree_error
	bsr	_error_print
	addq.l	#4,sp
	bra	release_error

*-------------------------------------------------------------------------------
* マクロ定義

_IOCS_VECTOR_CHECK	.macro	_p1,_a1,_n1,_j1
* a0 = 常駐プログラムのメモリ管理ポインタ
* a1 = 自分のメモリ管理ポインタ
* _p1 = 使用するレジスタ
* _a1 = 設定したアドレス
* _n1 = 変更したコールナンバ
* _j1 = 一致しない時のジャンプ先

_IOCS_VECTOR_CHECK_COUNT	set	_IOCS_VECTOR_CHECK_COUNT+1

	lea.l	_a1,_p1
	sub.l	a1,_p1
	lea.l	(a0,_p1.l),_p1
	move.w	#$100+_n1,-(sp)
	DOS	__INTVCG
	addq.l	#2,sp
	cmp.l	d0,_p1
	bne	_j1
	.endm

_IOCS_VECTOR_RESTORE	.macro	_p1,_a1,_n1
* a0 = 常駐プログラムのメモリ管理ポインタ
* a1 = 自分のメモリ管理ポインタ
* _p1 = 使用するレジスタ
* _a1 = 変更前のアドレス保存場所
* _n1 = 変更したコールナンバ

_IOCS_VECTOR_RESTORE_COUNT	set	_IOCS_VECTOR_RESTORE_COUNT+1

	lea	_a1,_p1
	sub.l	a1,_p1
	move.l	(a0,_p1.l),_p1
	pea	(_p1)
	move.w	#$100+_n1,-(sp)
	DOS	__INTVCS
	addq.l	#6,sp
	.endm

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
	movem.l	release_register,-(sp)

	bsr	tram_check
	tst.l	d0
	bne	release_sub_tram_used

	.ifdef	__DEBUG__
	.lall
	.endif

	move.l	parameter_a0,a1
_IOCS_VECTOR_CHECK_COUNT	set	0
	_IOCS_VECTOR_CHECK	a2,NEW_TPALET,__TPALET,release_sub_error
	_IOCS_VECTOR_CHECK	a2,NEW_TPALET2,__TPALET2,release_sub_error
	_IOCS_VECTOR_CHECK	a2,NEW_CRTMOD,__CRTMOD,release_sub_error
	_IOCS_VECTOR_CHECK	a2,NEW_TGUSEMD,__TGUSEMD,release_sub_error
	_IOCS_VECTOR_CHECK	a2,NEW_G_CLR_ON,__G_CLR_ON,release_sub_error
	_IOCS_VECTOR_CHECK	a2,NEW_B_KEYSNS,__B_KEYSNS,release_sub_error
	_IOCS_VECTOR_CHECK	a2,NEW_DENSNS,__DENSNS,release_sub_error
	_IOCS_VECTOR_CHECK	a2,NEW_TXXLINE,__TXXLINE,release_sub_error
	_IOCS_VECTOR_CHECK	a2,NEW_TXYLINE,__TXYLINE,release_sub_error
	_IOCS_VECTOR_CHECK	a2,NEW_TXBOX,__TXBOX,release_sub_error
	_IOCS_VECTOR_CHECK	a2,NEW_B_WPOKE,__B_WPOKE,release_sub_error
	.fail	_IOCS_VECTOR_CHECK_COUNT.ne._IOCS_VECTOR_CHANGE_COUNT

	lea.l	NEW_trap15,a2		* trap15のチェック ver. 0.67
	sub.l	a1,a2
	lea.l	(a0,a2.l),a2
	move.w	#$2f,-(sp)
	DOS	__INTVCG
	addq.l	#2,sp
	cmp.l	d0,a2
	bne	release_sub_error

	lea	NEW_EXIT,a2		* _EXIT, _EXIT2 のチェック ver. 0.81
	sub.l	a1,a2
	lea.l	(a0,a2.l),a2
	move.w	#__EXIT,-(sp)
	DOS	__INTVCG
	addq.l	#2,sp
	cmp.l	d0,a2
	bne	release_sub_error

	lea	NEW_EXIT2,a2
	sub.l	a1,a2
	lea.l	(a0,a2.l),a2
	move.w	#__EXIT2,-(sp)
	DOS	__INTVCS
	addq.l	#2,sp
	cmp.l	d0,a2
	bne	release_sub_error

_IOCS_VECTOR_RESTORE_COUNT	set	0
	_IOCS_VECTOR_RESTORE	a2,vector_TPALET,__TPALET
	_IOCS_VECTOR_RESTORE	a2,vector_TPALET2,__TPALET2
	_IOCS_VECTOR_RESTORE	a2,vector_CRTMOD,__CRTMOD
	_IOCS_VECTOR_RESTORE	a2,vector_TGUSEMD,__TGUSEMD
	_IOCS_VECTOR_RESTORE	a2,vector_G_CLR_ON,__G_CLR_ON
	_IOCS_VECTOR_RESTORE	a2,vector_B_KEYSNS,__B_KEYSNS
	_IOCS_VECTOR_RESTORE	a2,vector_DENSNS,__DENSNS
	_IOCS_VECTOR_RESTORE	a2,vector_TXXLINE,__TXXLINE
	_IOCS_VECTOR_RESTORE	a2,vector_TXYLINE,__TXYLINE
	_IOCS_VECTOR_RESTORE	a2,vector_TXBOX,__TXBOX
	_IOCS_VECTOR_RESTORE	a2,vector_B_WPOKE,__B_WPOKE
	.fail	_IOCS_VECTOR_RESTORE_COUNT.ne._IOCS_VECTOR_CHANGE_COUNT

	lea	vector_trap15,a2	* trap15を戻す ver. 0.67
	sub.l	a1,a2
	move.l	(a0,a2.l),a2
	pea	(a2)
	move.w	#$2f,-(sp)
	DOS	__INTVCS
	addq.l	#6,sp

	lea	vector_EXIT,a2		* _EXIT, _EXIT2 を戻す ver. 0.81
	sub.l	a1,a2
	move.l	(a0,a2.l),a2
	pea	(a2)
	move.w	#__EXIT,-(sp)
	DOS	__INTVCS
	addq.l	#6,sp

	lea	vector_EXIT2,a2
	sub.l	a1,a2
	move.l	(a0,a2.l),a2
	pea	(a2)
	move.w	#__EXIT2,-(sp)
	DOS	__INTVCS
	addq.l	#6,sp

	.ifdef	__DEBUG__
	.sall
	.endif

	_TO_SUPER
	bsr	clear_sub
	_TO_USER

	clr.l	d0
release_sub_end:
	movem.l	(sp)+,release_register
	rts

release_sub_error:
	moveq.l	#-1,d0			* ベクタが書き換えられていた
	bra	release_sub_end

release_sub_tram_used:
	pea	message_tram_used	* テキストラム使用中
	bsr	_error_print
	addq.l	#4,sp
	moveq.l	#-2,d0
	bra	release_sub_end

*-------------------------------------------------------------------------------

	.data
message_disable:
	.dc.b	'これ以後のオートマスクを許可しません。',13,10
	.dc.b	0
message_disable_not_keep:
	.dc.b	'常駐してないと意味がありません。',13,10
	.dc.b	0

	.text
disable:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_D,d7
	beq	disable_end

	move.w	#_GM_VERSION_NUMBER,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	cmp.w	#_GM_INTERNAL_MODE,d0
	bne	disable_not_keep

	pea	message_disable
	bsr	_vprint
	addq.l	#4,sp

	move.w	#_GM_AUTO_DISABLE,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd	* 常駐していればマスク不許可フラグをセット
	clr.l	d0
disable_end:
	movem.l	(sp)+,exec_register
	rts

disable_not_keep:
	pea	message_disable_not_keep
	bsr	_error_print
	addq.l	#4,sp
	moveq.l	#EXIT_ERROR_NOT_KEEP,d0
	bra	disable_end

*-------------------------------------------------------------------------------

	.data
message_enable:
	.dc.b	'これ以後のオートマスクを許可します。',13,10
	.dc.b	0

	.text
enable:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_E,d7
	beq	enable_end

	move.w	#_GM_VERSION_NUMBER,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	cmp.w	#_GM_INTERNAL_MODE,d0
	bne	enable_not_keep

	pea	message_enable
	bsr	_vprint
	addq.l	#4,sp

	move.w	#_GM_AUTO_ENABLE,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd	* 常駐していればマスク許可フラグをセット
	clr.l	d0
enable_end:
	movem.l	(sp)+,exec_register
	rts

enable_not_keep:
	pea	message_disable_not_keep
	bsr	_error_print
	addq.l	#4,sp
	moveq.l	#EXIT_ERROR_NOT_KEEP,d0
	bra	enable_end

*-------------------------------------------------------------------------------

	.data
message_mask:
	.dc.b	'テキストプレーン３でグラフィック画面をマスクします。',13,10
	.dc.b	0
message_mask_request:
	.dc.b	'グラフィック画面のマスクをリクエストします。',13,10
	.dc.b	0
message_tram_used:
	.dc.b	'テキストラムはアプリケーションで使用中です。',13,10
	.dc.b	0

TEXTVRAM_P3_ADDRESS	equ	$e60000
TEXTPALETTE_ADDRESS	equ	$e82200

	.text
mask:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_M,d7
	beq	mask_end

	move.w	#_GM_VERSION_NUMBER,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	cmp.w	#_GM_INTERNAL_MODE,d0
	bne	mask_not_keep

	moveq.l	#-1,d1
	IOCS	__CRTMOD
	cmp.b	#16,d0
	bne	mask_keep_request
	lea	$e82400,a1
	IOCS	__B_WPEEK
	and.w	#$0007,d0
	cmp.w	#$0003,d0
	bne	mask_keep_request

	bsr	tram_check
	tst.l	d0
	bne	mask_tram_used		* アプリケーションで使用中
	move.w	#_GM_MASK_SET,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd	* 画面モードが７６８×５１２ならば即マスクする

	pea	message_mask
	bra	mask_keep_print_end

mask_keep_request:
	move.w	#_GM_MASK_REQUEST,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd	* 常駐していればマスクのリクエスト

	pea	message_mask_request
mask_keep_print_end:
	bsr	_vprint
	addq.l	#4,sp
	clr.l	d0
	bra	mask_end

mask_not_keep:
	bsr	tram_check
	tst.l	d0
	bne	mask_tram_used		* アプリケーションで使用中

	pea	message_mask
	bsr	_vprint
	addq.l	#4,sp

	_TO_SUPER
	bsr	mask_sub
	_TO_USER

	clr.l	d0
mask_end:
	movem.l	(sp)+,exec_register
	rts

mask_tram_used:
	pea	message_tram_used
	bsr	_error_print
	addq.l	#4,sp
	moveq.l	#EXIT_ERROR_TRAM_USED,d0
	bra	mask_end

*-------------------------------------------------------------------------------

	.data
message_clear:
	.dc.b	'グラフィック画面のマスク解除します。',13,10
	.dc.b	0

	.text
clear:
	movem.l	exec_register,-(sp)
	clr.l	d0
	btst.l	#OPT_C,d7
	beq	clear_end

	move.w	#_GM_VERSION_NUMBER,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	cmp.w	#_GM_INTERNAL_MODE,d0
	bne	clear_not_keep

	pea	message_clear
	bsr	_vprint
	addq.l	#4,sp

	move.w	#_GM_MASK_CLEAR,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd	* 常駐していれば即マスククリアする
	clr.l	d0
	bra	clear_end

clear_not_keep:
	bsr	tram_check
	tst.l	d0
	bne	clear_tram_used		* アプリケーションで使用中

	pea	message_clear
	bsr	_vprint
	addq.l	#4,sp

	_TO_SUPER
	bsr	clear_sub
	_TO_USER

	clr.l	d0
clear_end:
	movem.l	(sp)+,exec_register
	rts

clear_tram_used:
	pea	message_tram_used
	bsr	_error_print
	addq.l	#4,sp
	moveq.l	#EXIT_ERROR_TRAM_USED,d0
	bra	clear_end

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
	move.w	d0,-(sp)		* 終了コード
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

	.text
program_error_setblock:
	lea	message_program_error_setblock,a0
	move.w	#EXIT_ERROR_SETBLOCK,d0
	bra	program_error

*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
* 常駐チェック
*
* entry:
*   a0.l = 識別文字列のアドレス (name + versionを設定すること)
*   a1.l = 自分のメモリ管理ポインタのアドレス
* return:
*   d0.l = 0 プログラムが見つかりません
*        = 1 すでに常駐済みです
*        = 2 バージョン違いです
*        = 3 内部エラーです (動作は保証されません)
*   a0.l = メモリ管理ポインタのアドレス (d0.l = 1, 2の時、それ以外は不定)

keep_check_register	reg	d1-d5/a1-a3

	.text
keep_check:
	movem.l	keep_check_register,-(sp)
	move.l	a0,a2
	move.l	a1,a3
	move.l	a0,d2
	sub.l	a1,d2			* d2.l = 識別文字列の先頭までのオフセット

	moveq.l	#-1,d4
keep_check_name_length:
	addq.l	#1,d4
	tst.b	(a0)+
	bne	keep_check_name_length
					* d4.l = nameの長さ（末尾の０を含まない）
	moveq.l	#-1,d5
keep_check_version_length:
	addq.l	#1,d5
	tst.b	(a0)+
	bne	keep_check_version_length
					* d5.l = versionの長さ（末尾の０を含まない）
	move.l	d2,d3
	add.l	d4,d3
	add.l	d5,d3
	addq.l	#2,d3			* d3.l = 識別文字列最後の０までのオフセット

	_TO_SUPER

	move.l	a3,a0			* 自分のメモリ管理ポインタから親をたどる
keep_check_backward_loop:

	.ifdef	__DEBUG__
	move.w	#'B',-(sp)
	DOS	__PUTCHAR
	addq.l	#2,sp
	.endif

	tst.l	$04(a0)			* 親があるか？
	beq	keep_check_forward_loop
	move.l	$04(a0),a0		* 親のメモリ管理ポインタを得る
	bra	keep_check_backward_loop

keep_check_forward_loop:

	.ifdef	__DEBUG__
	move.w	#'F',-(sp)
	DOS	__PUTCHAR
	addq.l	#2,sp
	.endif

	move.l	$0c(a0),d0
	beq	keep_check_not_found	* 見つからなかった
	move.l	d0,a0
	move.l	$08(a0),d0
	lea	(a0,d3.l),a1
	cmp.l	a1,d0
	bls	keep_check_forward_loop	* メモリブロックの範囲外
	lea	(a0,d2.l),a1
	cmp.l	a1,a2
	beq	keep_check_forward_loop	* 自分自身だった・・・

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
	bne	keep_check_version_no_match	* バージョンが違うみたいだなぁ
	bra	keep_check_match

keep_check_not_found:
	moveq.l	#0,d0
	bra	keep_check_end

keep_check_match:
	moveq.l	#1,d0
	bra	keep_check_end

keep_check_version_no_match:
	moveq.l	#2,d0
	bra	keep_check_end

keep_check_error:
	moveq.l	#3,d0

keep_check_end:
	move.l	d0,d1
	_TO_USER

	.ifdef	__DEBUG__
	move.w	#13,-(sp)
	DOS	__PUTCHAR
	addq.l	#2,sp
	move.w	#10,-(sp)
	DOS	__PUTCHAR
	addq.l	#2,sp
	.endif

	move.l	d1,d0
	movem.l	(sp)+,keep_check_register
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

	.end	program_start
