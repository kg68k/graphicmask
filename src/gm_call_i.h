/* gm_call_i.h */

/* $Id: gm_call_i.h,v 1.2 1994/11/14 16:50:29 JACK Exp $ */

#ifndef gm_call_i_h
#define gm_call_i_h

#define GM_MAGIC              0x676d  /* ＧＭ内部コールマジック */

#define GM_VERSION_NUMBER     0xff80  /* ＧＭバージョンナンバの読み取り */
#define GM_MASK_STATE         0xff81  /* マスク状態の読み取り */
#define GM_GNC_STATE          0xff82  /* ＧＮＣ状態の読み取り */
#define GM_AUTO_STATE         0xff83  /* オートマスク状態の読み取り */
#define GM_GRAPHIC_MODE_STATE 0xff84  /*グラフィックモードの読み取り */
#define GM_ACTIVE_STATE       0xff85  /* ＧＭ主要機能の動作状況を見る */

#define GM_MASK_REQUEST       0xff88  /* マスクリクエスト */
#define GM_MASK_SET           0xff89  /* マスク設定 */
#define GM_MASK_CLEAR         0xff8a  /* マスク解除 */
#define GM_AUTO_DISABLE       0xff8b  /* オートマスク禁止 */
#define GM_AUTO_ENABLE        0xff8c  /* オートマスク許可 */
#define GM_ACTIVE             0xff8d  /* ＧＭの動作開始 */
#define GM_INACTIVE           0xff8e  /* ＧＭの動作停止 */

#define GM_KEEP_PALETTE_GET   0xff90  /* 常駐パレット(16色)の先頭アドレスを得る */
#define GM_PALETTE_SAVE       0xff91  /* 現在のパレットを強制保存 */
#define GM_GVRAM_SAVE         0xff92  /* GVRAMのみ強制保存 */

#define GM_MAGIC_CHECK(n) (((n) & 0x0000ffff) == GM_MAGIC)

/* functions */

static inline int gm_version_number(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_VERSION_NUMBER))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_mask_state(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_MASK_STATE))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_gnc_state(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_GNC_STATE))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_auto_state(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_AUTO_STATE))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_graphic_mode_state(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_GRAPHIC_MODE_STATE))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_active_state(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_ACTIVE_STATE))
		 : "d0", "d1", "d2" );

	return reg_d0;
}


static inline int gm_mask_request(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_MASK_REQUEST))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_mask_set(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_MASK_SET))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_mask_clear(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_MASK_CLEAR))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_auto_disable(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_AUTO_DISABLE))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_auto_enable(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_AUTO_ENABLE))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_active(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_ACTIVE))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_inactive(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_INACTIVE))
		 : "d0", "d1", "d2" );

	return reg_d0;
}


static inline int gm_keep_palette_get(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_KEEP_PALETTE_GET))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_palette_save(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_PALETTE_SAVE))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

static inline int gm_gvram_save(void)
{
	register int reg_d0 asm ("d0");

	asm volatile ("move.l %1,d1\n\t"
		"moveq.l #-1,d2\n\t"
		"moveq.l #__TGUSEMD,%0\n\t"
		"trap #15"
		 : "=d" (reg_d0)
		 : "n" ((int)((GM_MAGIC<<16) + GM_GVRAM_SAVE))
		 : "d0", "d1", "d2" );

	return reg_d0;
}

/* variables */


#endif /* for gm_call_i_h */
