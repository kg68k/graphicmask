* $Id: gsvexe.s,v 1.4 1994/11/15 10:38:37 JACK Exp $

	.include	iocscall.mac
	.include	doscall.mac
	.include	gm_internal.mac

*-------------------------------------------------------------------------------
* 終了コードの定義

	.offset	0
EXIT_NO_ERROR		.ds.b	1
EXIT_HELP		.ds.b	1
EXIT_ERROR_SETBLOCK	.ds.b	1
EXIT_ERROR_MALLOC	.ds.b	1
EXIT_ERROR_MFREE	.ds.b	1
EXIT_ERROR_FILE_SEARCH	.ds.b	1
EXIT_ERROR_FILE_EXECUTE	.ds.b	1
	.text

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
environment_pointer:
	.ds.l	1
filename:
	.ds.b	256
command_line:
	.ds.b	256

	.text
program_start:
	lea	$10(a0),a0
	sub.l	a0,a1
	move.l	a1,-(sp)
	move.l	a0,-(sp)
	DOS	__SETBLOCK
	addq.l	#8,sp
	tst.l	d0
	bmi	error_setblock

	move.l	a3,environment_pointer
	lea	filename(pc),a4
	lea	command_line(pc),a5

	move.l	a2,a0
	tst.b	(a0)+
	beq	help

	clr.b	hi_speed_mode_flag
	clr.b	screen_off_flag
	clr.b	key_buffer_flush_flag
	clr.b	led_blink_flag
switch:
	move.b	(a0),d0
	beq	help
	cmp.b	#'-',d0
	bne	switch_end
	addq.l	#1,a0
switch_loop:
	move.b	(a0)+,d0
	beq	help
	cmp.b	#' ',d0
	beq	switch
	cmp.b	#'s',d0
	beq	opt_s
	cmp.b	#'o',d0
	beq	opt_o
	cmp.b	#'k',d0
	beq	opt_k
	cmp.b	#'l',d0
	beq	opt_l
	bra	help
opt_s:
	move.b	#$ff,hi_speed_mode_flag
	bra	switch_loop
opt_o:
	move.b	#$ff,screen_off_flag
	bra	switch_loop
opt_k:
	move.b	#$ff,key_buffer_flush_flag
	bra	switch_loop

	.bss
	.even
opt_l_number:
	.ds.l	1
	.text
opt_l:
	move.b	#$ff,led_blink_flag
	lea	opt_l_number,a1
	move.l	#150,(a1)		* デフォルトは１５０
	move.l	#$7fff,d0		* 読み取り数値の最大値
	bsr	opt_number
	bmi	help			* 最大値超えたか数値の読み取りでエラーがでた
	bra	switch_loop

switch_end:

*-----------------------------------------------------------------------------
* パラメータを受け取る

	move.l	a4,a1
@@:
	move.b	(a0)+,(a1)+
	bne	@b

*-----------------------------------------------------------------------------
* 実行する

	bsr	key_buffer_flush
	bsr	graphic_push
	bsr	led_blink_on

	clr.l	-(sp)
	pea	(a5)
	pea	(a4)
	move.w	#2,-(sp)
	DOS	__EXEC			* プログラムのpathをサーチ
	lea	14(sp),sp
	tst.l	d0
	bmi	error_file_search	* 見あたらない

	movem.l	d1-d7/a0-a6,-(sp)
	clr.l	-(sp)
	pea	(a5)
	pea	(a4)
	clr.w	-(sp)
	DOS	__EXEC			* プログラム実行
	lea	14(sp),sp
	movem.l	(sp)+,d1-d7/a0-a6
	tst.l	d0
	bmi	error_file_execute

	bsr	led_blink_off
	bsr	graphic_pop
	bsr	key_buffer_flush2

	move.w	d0,-(sp)
	DOS	__EXIT2

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
* LED点滅ルーチン

	.bss
led_blink_flag:
	.ds.b	1
	.even
led_save:
	.ds.w	1
led_old:
	.ds.w	1
led_slide:
	.ds.w	1
timer_counter:
	.ds.w	1
timer_old:
	.dc.l	1
exit_old:
	.dc.l	1
ctrlc_old:
	.dc.l	1
abort_old:
	.dc.l	1

	.text
led_blink_on:
	tst.b	led_blink_flag
	beq	led_blink_on_end
	bsr	led_off
	bsr	timer_on
led_blink_on_end:
	rts

led_blink_off:
	tst.b	led_blink_flag
	beq	led_blink_off_end
	bsr	timer_off
	bsr	led_restore
led_blink_off_end:
	rts

	.text
timer_on:
	move.l	d0,-(sp)
	clr.l	timer_old
	move.l	opt_l_number,d0
	neg.w	d0
	move.w	d0,timer_counter

	pea	_timer_exit(pc)
	move.w	#$fff0,-(sp)
	DOS	__INTVCS
	move.l	d0,exit_old
	addq.l	#6,sp

	pea	_timer_ctrlc(pc)
	move.w	#$fff1,-(sp)
	DOS	__INTVCS
	move.l	d0,ctrlc_old
	addq.l	#6,sp

	pea	_timer_abort(pc)
	move.w	#$fff2,-(sp)
	DOS	__INTVCS
	move.l	d0,abort_old
	addq.l	#6,sp

	pea	_new_timer(pc)
	move.w	#$0045,-(sp)
	DOS	__INTVCS
	move.l	d0,timer_old
	addq.l	#6,sp

	move.l	(sp)+,d0
	rts

	.text
led_state:
	.dc.b	%0000_0000
	.dc.b	%0000_0001
	.dc.b	%0000_0011
	.dc.b	%0000_0110
	.dc.b	%0000_1100
	.dc.b	%0000_1000
	.dc.b	%0000_0000
	.dc.b	%0000_0000
	.dc.b	%0000_1000
	.dc.b	%0000_1100
	.dc.b	%0000_0110
	.dc.b	%0000_0011
	.dc.b	%0000_0001
	.dc.b	%0000_0000

	.text
	.quad
_new_timer:
	add.w	#1,timer_counter
	cmp.w	#10,timer_counter
	blt	_new_timer_end
	clr.w	timer_counter
	movem.l	d0-d1,-(sp)
	move.w	led_slide,d0
	move.b	led_state(pc,d0.w),d1
	not.b	d1
	addq.w	#1,d0
	cmp.w	#14,d0
	bcs	@f
	clr.w	d0
@@:	move.w	d0,led_slide
	move.b	d1,$e8802f
	movem.l	(sp)+,d0-d1
_new_timer_end:
	move.l	timer_old,-(sp)
	rts

_timer_exit:
	bsr	timer_off
	bsr	led_restore
	move.l	exit_old,-(sp)
	rts

_timer_ctrlc:
	bsr	timer_off
	bsr	led_restore
	move.l	ctrlc_old,-(sp)
	rts

_timer_abort:
	bsr	timer_off
	bsr	led_restore
	move.l	abort_old,-(sp)
	rts

timer_off:
	tst.l	timer_old
	beq	@f
	move.l	d0,-(sp)
	move.l	timer_old,-(sp)
	move.w	#$0045,-(sp)
	DOS	__INTVCS
	clr.l	timer_old
	addq.l	#6,sp
	move.l	(sp)+,d0
@@:
	rts

led_off:
	movem.l	d0-d3,-(sp)
	IOCS	__B_SFTSNS
	move.w	d0,led_save
	moveq.l	#0,d1
	moveq.l	#0,d2
	moveq.l	#6-1,d3
led_off_loop:
	IOCS	__LEDMOD
	addq.l	#1,d1
	dbra	d3,led_off_loop
	clr.w	led_slide
	move.w	#1,led_old
	movem.l	(sp)+,d0-d3
	rts

led_restore:
	tst.w	led_old
	beq	@f
	movem.l	d0-d5,-(sp)
	moveq.l	#0,d1
	move.w	led_save,d3
	lsr.w	#8,d3
	moveq.l	#6-1,d4
	moveq.l	#1,d5
led_restore_loop:
	btst.l	d1,d3
	sne.b	d2
	and.b	d5,d2
	IOCS	__LEDMOD
	addq.l	#1,d1
	dbra	d4,led_restore_loop
	clr.w	led_old
	movem.l	(sp)+,d0-d5
@@:
	rts

*-------------------------------------------------------------------------------
* キーバッファをクリアする.

	.bss
key_buffer_flush_flag:
	.ds.b	1

	.text
key_buffer_flush:
	tst.b	key_buffer_flush_flag
	beq	key_buffer_flush_end

	move.w	#$1000,d4		* ループMAX(バッファが死んだときの為)
key_buffer_flush_loop:
	subq.w	#1,d4
	bmi	key_buffer_flush_end

	bsr	key_buffer_flush_sub

	moveq.l	#$e,d2
	clr.b	d3
@@:
	move.w	d2,d1
	IOCS	__BITSNS
	or.b	d0,d3
	dbra	d2,@b
	tst.b	d3
	bne	key_buffer_flush_loop

	bsr	key_buffer_flush_sub
key_buffer_flush_end:
	rts

key_buffer_flush2:
	tst.b	key_buffer_flush_flag
	beq	key_buffer_flush2_end

	bsr	key_buffer_flush_sub
key_buffer_flush2_end:
	rts

key_buffer_flush_sub:
	move.w	#$ff,-(sp)
	move.w	#6,-(sp)
	DOS	__KFLUSH
	addq.l	#4,sp
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
* グラフィック保存

	.bss
gpalette_keep_flag:
	.ds.b	1
hi_speed_mode_flag:
	.ds.b	1
screen_off_flag:
	.ds.b	1
	.even
iocs_mode:
	.ds.w	1
malloc_pointer:
	.ds.l	1
gpalette:
	.ds.w	256
gpalette_keep:
	.ds.w	16
crtc_r20:
	.ds.w	1
crtc_r21:
	.ds.w	1
videoc_r1:
	.ds.w	1
videoc_r2:
	.ds.w	1
videoc_r3:
	.ds.w	1

	.text
	.xdef	graphic_push
graphic_push:
	movem.l	d0-d7/a0-a6,-(sp)

	clr.b	gpalette_keep_flag
	clr.l	malloc_pointer

	move.l	#512*1024,-(sp)
	move.w	#2,-(sp)		* 上位から確保
	DOS	__MALLOC2
	addq.l	#6,sp
	tst.l	d0
	bmi	graphic_push_end
	move.l	d0,malloc_pointer

	moveq.l	#-1,d1
	IOCS	__CRTMOD
	move.w	d0,iocs_mode

	_TO_SUPER
	move.w	$e80028,d0
	move.w	d0,crtc_r20
	lsr.w	#8,d0
	and.w	#%111,d0
	move.w	$e8002a,crtc_r21
	move.w	$e82400,videoc_r1
	move.w	$e82500,videoc_r2
	move.w	$e82600,videoc_r3

	tst.b	screen_off_flag
	beq	@f
	clr.w	$e82600
@@:

	move.l	malloc_pointer,a1
	lea	$c00000,a0

	btst.b	#3,crtc_r20
	beq	@f
	btst.l	#2,d0
	bne	graphic_push_16_off
	tst.b	d0
	beq	graphic_push_16_off
	bra	graphic_push_64k
@@:
	btst.l	#2,d0
	bne	graphic_push_16_1024
	tst.b	d0
	beq	graphic_push_16
	btst.l	#1,d0
	bne	graphic_push_64k
	bra	graphic_push_256

graphic_push_16_1024:
	tst.b	hi_speed_mode_flag
	bne	graphic_push_16_1024_hi_speed

	move.l	#(512/4)*(1024/2)-1,d7
	moveq.l	#4,d5
@@:
	movep.l	1+0(a0),d0
	movep.l	1+8(a0),d1
	lsl.l	d5,d0
	or.l	d1,d0
	move.l	d0,(a1)+
	movep.l	1+16(a0),d2
	movep.l	1+24(a0),d3
	lsl.l	d5,d2
	or.l	d3,d2
	move.l	d2,(a1)+
	lea.l	32(a0),a0

	dbra	d7,@b

	moveq.l	#0,d0
	bra	graphic_push_gpalette

graphic_push_16_1024_hi_speed:
	bset.b	#3,$e80028
	clr.w	$e82600

graphic_push_16_off:
	move.l	#(512/4)*(1024/8)-1-1,d7
	add.l	#512*1024,a1
@@:
	movem.l	(a0)+,d0-d6/a2
	movem.l	d0-d6/a2,-(a1)

	dbra	d7,@b

	movem.l	(a0)+,d0-d6
	move.l	(a0)+,a2
	movem.l	d0-d6/a2,-(a1)

	move.w	crtc_r20,$e80028
	moveq.l	#0,d0
	bra	graphic_push_gpalette

graphic_push_16:
	bra	graphic_push_16_1024		* ^^;

graphic_push_256:
	move.l	#(512/4)*(1024/4)-1,d7
	moveq.l	#8,d5
@@:
	movep.l	1+0(a0),d0
	move.l	d0,(a1)+
	movep.l	1+8(a0),d1
	move.l	d1,(a1)+
	movep.l	1+16(a0),d2
	move.l	d2,(a1)+
	movep.l	1+24(a0),d3
	move.l	d3,(a1)+
	lea.l	32(a0),a0

	dbra	d7,@b

	moveq.l	#0,d1
	bra	graphic_push_gpalette

graphic_push_64k:
	or.b	#3,$e80028
	move.l	#(512/4)*(1024/8)-1-1,d7
	add.l	#512*1024,a1
@@:
	movem.l	(a0)+,d0-d6/a2
	movem.l	d0-d6/a2,-(a1)

	dbra	d7,@b

	movem.l	(a0)+,d0-d6
	move.l	(a0)+,a2
	movem.l	d0-d6/a2,-(a1)

	moveq.l	#2,d0

graphic_push_gpalette:
	lea	$e82000,a0
	lea	gpalette,a1
	move.w	#256-1,d7
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	move.w	(a0)+,(a1)+
	dbra	d7,@b

	tst.l	d0
	bne	graphic_push_gpalette_not_keep_palette
	move.w	#_GM_KEEP_PALETTE_GET,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	cmp.l	d2,d0
	beq	graphic_push_gpalette_not_keep_palette
	cmp.w	#_GM_INTERNAL_MODE,d0
	bne	graphic_push_gpalette_not_keep_palette
	swap.w	d0
	tst.w	d0
	beq	graphic_push_gpalette_not_keep_palette
	lea	gpalette_keep,a0
	moveq.l	#16-1,d7
@@:
	move.w	(a1)+,(a0)+
	dbra	d7,@b
	move.b	#1,gpalette_keep_flag

graphic_push_gpalette_not_keep_palette:
	_TO_USER

graphic_push_end:
	movem.l	(sp)+,d0-d7/a0-a6
	rts

*-------------------------------------------------------------------------------
* グラフィック復帰

	.text
	.xdef	graphic_pop
graphic_pop:
	movem.l	d0-d7/a0-a6,-(sp)

	move.l	malloc_pointer,d0
	tst.l	d0
	beq	graphic_pop_end

	move.w	iocs_mode,d1
	or.w	#$0100,d1
	IOCS	__CRTMOD

	_TO_SUPER
	move.w	crtc_r20,d0
	move.w	d0,$e80028
	lsr.w	#8,d0
	and.w	#%111,d0
	move.w	crtc_r21,$e8002a
	move.w	videoc_r1,$e82400
	move.w	videoc_r2,$e82500
	move.w	videoc_r3,d1
	and.w	#$ffe0,d1
	move.w	d1,$e82600

	move.l	malloc_pointer,a1
	lea	$c00000,a0

	btst.b	#3,crtc_r20
	beq	@f
	btst.l	#2,d0
	bne	graphic_pop_16_off
	tst.b	d0
	beq	graphic_pop_16_off
	bra	graphic_pop_64k
@@:
	btst.l	#2,d0
	bne	graphic_pop_16_1024
	tst.b	d0
	beq	graphic_pop_16
	btst.l	#1,d0
	bne	graphic_pop_64k
	bra	graphic_pop_256

graphic_pop_16_1024:
	tst.b	hi_speed_mode_flag
	bne	graphic_pop_16_1024_hi_speed

	move.l	#(512/4)*(1024/2)-1,d7
	moveq.l	#4,d5
	add.l	#512*1024*4,a0
	add.l	#512*1024,a1
@@:
	lea.l	-32(a0),a0
	move.l	-(a1),d0
	move.l	d0,d1
	lsr.l	d5,d0
	movep.l	d0,1+16(a0)
	movep.l	d1,1+24(a0)
	move.l	-(a1),d2
	move.l	d2,d3
	lsr.l	d5,d2
	movep.l	d2,1+0(a0)
	movep.l	d3,1+8(a0)

	dbra	d7,@b

	moveq.l	#0,d0
	bra	graphic_pop_gpalette

graphic_pop_16_1024_hi_speed:
	bset.b	#3,$e80028

graphic_pop_16_off:
	move.l	#(512/4)*(1024/8)-1,d7
	add.l	#512*1024,a0
@@:
	movem.l	(a1)+,d0-d6/a2
	movem.l	d0-d6/a2,-(a0)

	dbra	d7,@b
	move.w	crtc_r20,$e80028
	moveq.l	#0,d0
	bra	graphic_pop_gpalette

graphic_pop_16:
	bra	graphic_pop_16_1024		* ^^;

graphic_pop_256:
	move.l	#(512/4)*(1024/4)-1,d7
	moveq.l	#8,d5
	add.l	#512*1024*2,a0
	add.l	#512*1024,a1
@@:
	lea.l	-32(a0),a0
	move.l	-(a1),d0
	movep.l	d0,1+24(a0)
	move.l	-(a1),d1
	movep.l	d1,1+16(a0)
	move.l	-(a1),d2
	movep.l	d2,1+8(a0)
	move.l	-(a1),d3
	movep.l	d3,1+0(a0)

	dbra	d7,@b

	moveq.l	#1,d0
	bra	graphic_pop_gpalette

graphic_pop_64k:
	or.b	#3,$e80028
	move.l	#(512/4)*(1024/8)-1,d7
	add.l	#512*1024,a0
@@:
	movem.l	(a1)+,d0-d6/a2
	movem.l	d0-d6/a2,-(a0)

	dbra	d7,@b

	moveq.l	#2,d0

graphic_pop_gpalette:
	lea	$e82000,a0
	lea	gpalette,a1
	move.w	#256-1,d7
	_HSYNC_WAIT
@@:
	_HSYNC_WAIT2
	move.w	(a1)+,(a0)+
	dbra	d7,@b

	tst.l	d0
	bne	graphic_pop_gpalette_256
	tst.b	gpalette_keep_flag
	beq	graphic_pop_gpalette_not_keep_palette
	move.w	#_GM_KEEP_PALETTE_GET,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	swap.w	d0
	lea	gpalette_keep,a0
	moveq.l	#16-1,d7
@@:
	move.w	(a0)+,(a1)+
	dbra	d7,@b

graphic_pop_gpalette_not_keep_palette:
	bclr.b	#3,$e80028
	move.w	#_GM_GVRAM_SAVE,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	move.w	crtc_r20,$e80028

	move.w	#_GM_MASK_CLEAR,d1
	bsr	_gm_internal_tgusemd
	lea	$e80018,a0
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	bra	graphic_pop_on

graphic_pop_gpalette_256:
	cmp.b	#1,d0
	bne	graphic_pop_gpalette_64k
	move.w	#_GM_MASK_CLEAR,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	lea	$e80018,a0
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	bra	graphic_pop_on

graphic_pop_gpalette_64k:
	cmp.b	#2,d0
	bne	graphic_pop_on
	move.w	#_GM_AUTO_STATE,d1
	moveq.l	#-1,d2
	bsr	_gm_internal_tgusemd
	cmp.l	d2,d0
	beq	graphic_pop_no_gm
	cmp.w	#_GM_INTERNAL_MODE,d0
	bne	graphic_pop_no_gm
	swap.w	d0
	move.w	#_GM_MASK_CLEAR,d1
	btst.l	#0,d0
	bne	@f			* マスク禁止
	btst.l	#1,d0
	beq	@f			* マスク許可しない
	move.w	#_GM_MASK_SET,d1
@@:
	bsr	_gm_internal_tgusemd
graphic_pop_no_gm:
	clr.l	d0
	cmp.w	#$0316,$e80028
	bne	@f
	move.l	#$ff80_0000,d0
@@:
	lea	$e80018,a0
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+

graphic_pop_on:
	bsr	vdisp_wait
	move.w	videoc_r3,$e82600
	_TO_USER

graphic_pop_end:
	movem.l	(sp)+,d0-d7/a0-a6
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
* ヘルプ終了

	.data
message_help:
	.dc.b	'Graphic Saving Execute v0.31 (c)JACK',13,10
	.dc.b	'usage: gsvexe [-sok] [-l time] <command>',13,10
	.dc.b	'	-s	hi speed mode(16 colors only)',13,10
	.dc.b	'	-o	screen off',13,10
	.dc.b	'	-k	key-buffer flush',13,10
	.dc.b	'	-l time	LED blink mode',13,10
	.dc.b	13,10
	.dc.b	0

	.text
help:
	pea	message_help
	DOS	__PRINT
	addq.l	#4,sp
	move.w	#EXIT_HELP,-(sp)
	DOS	__EXIT2

*-------------------------------------------------------------------------------
* エラー処理

	.data
message_error_setblock:
	.dc.b	'メモリブロックの変更ができません。',13,10
	.dc.b	0
message_error_file_search:
	.dc.b	'が見つかりません。',13,10
	.dc.b	0
message_error_file_execute:
	.dc.b	'が実行できません。',13,10
	.dc.b	0
message_error_file:
	.dc.b	'ファイル'
	.dc.b	0

	.text
error_setblock:
	lea	message_error_setblock(pc),a0
	move.w	#EXIT_ERROR_SETBLOCK,d0
	bra	error_exit

error_file_search:
	lea	message_error_file_search(pc),a0
	move.w	#EXIT_ERROR_FILE_SEARCH,d0
	bra	error_file

error_file_execute:
	lea	message_error_file_execute(pc),a0
	move.w	#EXIT_ERROR_FILE_EXECUTE,d0
	bra	error_file

error_file:
	exg.l	d0,d1
	pea	message_error_file(pc)
	DOS	__PRINT
	addq.l	#4,sp
	exg.l	d0,d1

error_exit:
	move.w	d0,-(sp)
	move.l	a0,-(sp)
	DOS	__PRINT
	addq.l	#4,sp
	DOS	__ALLCLOSE
	DOS	__EXIT2

*-------------------------------------------------------------------------------

	.end	program_start
