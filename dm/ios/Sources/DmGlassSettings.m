// 原生毛玻璃设置面板（用户称「内置菜单」）：UIVisualEffectView 深色模糊 + 半透明黑 tint + 大圆角，盖在游戏画面上。
// 只放能立刻生效的两组设置，字全走中英表（dm/i18n/ui_text.tsv，跟游戏语言）：
// ① 3D 画质：流畅优先（掉帧时自动降低 3D 画面清晰度）/ 画质优先（始终保持设定的 3D 清晰度）——键 q3d；
// ② 特效：低 / 中 / 高——键 vfx（图形层每帧按档走：低 = 泛光降质 + 关 FXAA，中 = 原行为，高 = 泛光全质量）。
// 选中即写回：走宿主 dm_custom.c 的 dm_custom_set_immediate，与游戏内「自定义」页共用同一份生效值与 sw_custom.txt，不另起一套存储；面板没有「应用」步，点完当场生效。
// 入口：DmTouchOverlay 挂上父视图（DmMetalView）时 dm_glass_install 在右上角加一个半透明「设置」按钮；覆盖层隐藏（前端 / 手柄模式）时按钮与面板跟随隐藏。
// 【移植适配 · custom/v230-port】本分支的入口改接游戏内菜单（LauncherVC.m 的 DmGameMenuController 最后一行）：
// dm_glass_present(菜单根视图) 开 / 关面板，dm_glass_install / dm_glass_sync_hidden 原样保留（本分支未挂 DmTouchOverlay 钩子）。
// 勾选态的 q3d 读运行期生效值 dm_3d_quality_mode_get()（hle_oe.c 的原子量）：菜单「画质模式」行只写这个运行期值、
// 不落盘，读 dm_custom_get("q3d") 会与实际生效值对不上；写入仍只走 dm_custom_set_immediate（落盘 + 同步运行期值），
// 写路径依旧只有一条，不与自定义页 / 菜单打架。
// Port adaptation (custom/v230-port): the entry here is the in-game menu (last row of
// DmGameMenuController in LauncherVC.m) via dm_glass_present(menu root view);
// dm_glass_install / dm_glass_sync_hidden are kept as-is (no DmTouchOverlay hook in
// this branch). The q3d check state reads the live runtime value
// dm_3d_quality_mode_get() (the atomic in hle_oe.c): the menu's quality row writes
// only that runtime value without persisting, so reading dm_custom_get("q3d") could
// disagree with what is in effect. Writes still go solely through
// dm_custom_set_immediate (persist + sync the runtime value): a single write path.
// Native frosted-glass settings panel: a UIVisualEffectView with a dark blur, a translucent black tint and large corner radius, floating over the game picture.
// It holds only the two setting groups that take effect immediately, with all text from the string table (dm/i18n/ui_text.tsv, following the game language):
// (1) 3D quality: Smoothness first (lowers the 3D resolution when frames drop) / Quality first (always keeps the set 3D resolution) -- key q3d;
// (2) Effects: low / medium / high -- key vfx (the graphics layer follows the tier every frame).
// Selecting writes back at once through the host's dm_custom_set_immediate in dm_custom.c, sharing the same effective values and sw_custom.txt with the in-game Custom page; there is no Apply step.
#import "DmGlassSettings.h"
#include "../../host/dm_custom.h"
#include "../../host/dm_i18n.h"

int dm_3d_quality_mode_get(void);   // hle_oe.c：q3d 的运行期生效值（dm_custom_set_immediate("q3d") 与菜单画质行都同步它）| the live q3d value in hle_oe.c

static __weak UIView *g_host;          // 父视图（DmMetalView）
static __weak UIButton *g_btn;         // 右上角「设置」入口按钮
static __weak UIView *g_shade;         // 面板开着时的全屏遮罩（面板是它的子视图）；nil = 面板关着
static __weak UIView *g_rows_host;     // 面板里放选项行的容器（刷新勾选态时遍历它）

static NSString *S(const char *k) { const char *s = dm_ui(k); return s ? [NSString stringWithUTF8String:s] : @""; }

// 行按钮的 tag：100 + 组 * 10 + 值（组 0 = q3d、值 0/1；组 1 = vfx、值 0/1/2）；行内勾选标记的 tag = 1
static void glass_refresh(void) {
    if (!g_rows_host) return;
    int q = dm_3d_quality_mode_get(), v = dm_vfx_level();
    for (UIView *row in g_rows_host.subviews) {
        if (row.tag < 100) continue;
        int grp = (int)(row.tag - 100) / 10, val = (int)(row.tag - 100) % 10, sel = grp == 0 ? val == q : val == v;
        UILabel *ck = (UILabel *)[row viewWithTag:1];
        ck.hidden = !sel;
        row.backgroundColor = [UIColor colorWithWhite:1 alpha:sel ? .13 : .05];
    }
}
static void glass_close(void) {
    UIView *sh = g_shade; if (!sh) return;
    g_shade = nil; g_rows_host = nil;
    [UIView animateWithDuration:.16 animations:^{ sh.alpha = 0; } completion:^(BOOL done) { [sh removeFromSuperview]; }];
}
static UIButton *glass_row(UIView *host, CGFloat x, CGFloat y, CGFloat w, int grp, int val, NSString *title, NSString *hint, id target, SEL act) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.frame = CGRectMake(x, y, w, 58); b.tag = 100 + grp * 10 + val;
    b.layer.cornerRadius = 14; b.clipsToBounds = YES;
    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(16, 7, w - 70, 24)];
    t.text = title; t.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium]; t.textColor = UIColor.whiteColor; [b addSubview:t];
    UILabel *h = [[UILabel alloc] initWithFrame:CGRectMake(16, 33, w - 70, 18)];
    h.text = hint; h.font = [UIFont systemFontOfSize:12.5]; h.textColor = [UIColor colorWithWhite:1 alpha:.55]; [b addSubview:h];
    UILabel *ck = [[UILabel alloc] initWithFrame:CGRectMake(w - 46, 14, 30, 30)];
    ck.text = @"✓"; ck.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold]; ck.textColor = [UIColor systemBlueColor]; ck.tag = 1; [b addSubview:ck];
    [b addTarget:target action:act forControlEvents:UIControlEventTouchUpInside];
    [host addSubview:b];
    return b;
}
static UILabel *glass_section(UIView *host, CGFloat x, CGFloat y, CGFloat w, NSString *text) {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w, 20)];
    l.text = text; l.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]; l.textColor = [UIColor colorWithWhite:1 alpha:.55];
    [host addSubview:l]; return l;
}

@interface DmGlassCtl : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
- (void)toggle;
@end
@implementation DmGlassCtl
+ (instancetype)shared { static DmGlassCtl *c; static dispatch_once_t o; dispatch_once(&o, ^{ c = [DmGlassCtl new]; }); return c; }
- (void)rowTapped:(UIButton *)b {
    int grp = (int)(b.tag - 100) / 10, val = (int)(b.tag - 100) % 10;
    dm_custom_set_immediate(grp == 0 ? "q3d" : "vfx", val);   // 选中即生效 + 存盘（与自定义页同一份存储）
    glass_refresh();
}
- (void)doneTapped { glass_close(); }
- (void)shadeTapped:(UITapGestureRecognizer *)g { if (g.state == UIGestureRecognizerStateEnded) glass_close(); }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)t { return t.view == g_shade; }   // 只认点在遮罩空白处（面板是子视图，点面板不关）
- (void)toggle {
    if (g_shade) { glass_close(); return; }
    UIView *host = g_host; if (!host) return;
    CGRect hb = host.bounds;
    UIView *shade = [[UIView alloc] initWithFrame:hb];
    shade.backgroundColor = [UIColor colorWithWhite:0 alpha:.45];
    shade.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shadeTapped:)];
    tap.delegate = self; [shade addGestureRecognizer:tap];
    CGFloat pw = MIN(560, hb.size.width - 48), x = (hb.size.width - pw) / 2, w = pw - 48;
    UIVisualEffectView *panel = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    panel.layer.cornerRadius = 26; panel.clipsToBounds = YES;
    panel.layer.borderWidth = 1; panel.layer.borderColor = [UIColor colorWithWhite:1 alpha:.18].CGColor;
    UIView *tint = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pw, 560)];   // 高度下面按行数收尾再改
    tint.backgroundColor = [UIColor colorWithWhite:0 alpha:.35]; tint.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [panel.contentView addSubview:tint];
    CGFloat cy = 20;
    UILabel *ttl = [[UILabel alloc] initWithFrame:CGRectMake(24, cy, w, 28)];
    ttl.text = S("dmGlassTitle"); ttl.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold]; ttl.textColor = UIColor.whiteColor;
    [panel.contentView addSubview:ttl]; cy += 28 + 16;
    glass_section(panel.contentView, 24, cy, w, S("dmGlassQ3d")); cy += 26;
    UIView *rows = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pw, 560)];
    rows.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [panel.contentView insertSubview:rows aboveSubview:tint];
    glass_row(rows, 24, cy, w, 0, 0, S("dmCustomQ3dSmooth"), S("dmCustomQ3dSmoothHint"), self, @selector(rowTapped:)); cy += 58 + 8;
    glass_row(rows, 24, cy, w, 0, 1, S("dmCustomQ3dQuality"), S("dmCustomQ3dQualityHint"), self, @selector(rowTapped:)); cy += 58 + 16;
    glass_section(panel.contentView, 24, cy, w, S("dmCustomVfx")); cy += 26;
    glass_row(rows, 24, cy, w, 1, 0, S("dmCustomVfxLow"), S("dmCustomVfxLowHint"), self, @selector(rowTapped:)); cy += 58 + 8;
    glass_row(rows, 24, cy, w, 1, 1, S("dmCustomVfxMid"), S("dmCustomVfxMidHint"), self, @selector(rowTapped:)); cy += 58 + 8;
    glass_row(rows, 24, cy, w, 1, 2, S("dmCustomVfxHigh"), S("dmCustomVfxHighHint"), self, @selector(rowTapped:)); cy += 58 + 18;
    UIButton *done = [UIButton buttonWithType:UIButtonTypeCustom];
    done.frame = CGRectMake(24, cy, w, 46);
    done.backgroundColor = [UIColor colorWithWhite:1 alpha:.14]; done.layer.cornerRadius = 12;
    done.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [done setTitle:S("dmGlassDone") forState:UIControlStateNormal];
    [done setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [done addTarget:self action:@selector(doneTapped) forControlEvents:UIControlEventTouchUpInside];
    [panel.contentView addSubview:done]; cy += 46 + 20;
    panel.frame = CGRectMake(x, MAX(12, (hb.size.height - cy) / 2), pw, cy);
    [shade addSubview:panel];
    shade.alpha = 0; [host addSubview:shade];
    g_shade = shade; g_rows_host = rows;
    glass_refresh();
    [UIView animateWithDuration:.18 animations:^{ shade.alpha = 1; }];
}
@end

void dm_glass_install(UIView *overlay) {
    if (!overlay || !overlay.superview) return;
    UIView *host = overlay.superview;
    if (g_btn && g_btn.superview == host) { g_host = host; g_btn.hidden = overlay.hidden; return; }
    g_host = host;
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.frame = CGRectMake(host.bounds.size.width - 104, 12, 88, 38);
    b.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    b.backgroundColor = [UIColor colorWithWhite:0 alpha:.38];
    b.layer.cornerRadius = 19; b.layer.borderWidth = 1; b.layer.borderColor = [UIColor colorWithWhite:1 alpha:.25].CGColor;
    b.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [b setTitle:S("dmGlassTitle") forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [b addTarget:[DmGlassCtl shared] action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
    b.hidden = overlay.hidden;
    [host addSubview:b];
    g_btn = b;
}
void dm_glass_sync_hidden(int hidden) {
    if (g_btn) g_btn.hidden = hidden != 0;
    if (hidden) glass_close();
}

// 本分支的入口（游戏内菜单调）：以给定视图为宿主开 / 关面板（宿主 = 菜单窗口的根视图，
// 面板盖在游戏画面之上、与悬浮按钮同窗口同级，z 序在按钮与菜单面板之后 = 更靠上）。
// This branch's entry (called by the in-game menu): toggle the panel on the given
// host view (the menu window's root view; the panel floats over the game picture in
// the same window as the floating button, stacked after it and the menu panel).
void dm_glass_present(UIView *host) {
    if (!host) return;
    g_host = host;
    [[DmGlassCtl shared] toggle];
}
UIView *dm_glass_shade_view(void) { return g_shade; }
