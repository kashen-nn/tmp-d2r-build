// D2R Mobile 启动器（Hades 风格重做，launcher-hades-ui）。
// Launcher, Hades-style redesign (launcher-hades-ui).
//
// 样式目标（只参考 Hades II 截图的样式，不照搬它的游戏和数值）：
//  - 左侧：游戏图标 / 名字 / 版本 / 大蓝色 Play 按钮；
//  - 右侧：设置列表，每行标题 + 副标题说明；右侧面板和点开的下拉框
//    都是半透明玻璃样：右侧面板用 UIVisualEffectView（系统毛玻璃材质），
//    下拉用系统 UIMenu 弹出框（iOS 自带半透明玻璃弹出框），不是死白实色；
//  - 所有设置都是真的可以点开的：帧率、主机模式、语言用 UIButton + UIMenu
//    下拉，不是静态文字；帧数计数器、按键用开关；超分是真开关（MetalFX Spatial：底座降分辨率渲染再放大）。
// Style target (Hades II screenshot style only, not its game or numbers):
//  - Left: game icon / name / version / large blue Play button;
//  - Right: settings list, each row title + subtitle; the right panel is a
//    UIVisualEffectView (system glass material) and the dropdowns are system
//    UIMenu popups (also translucent glass), not dead-white solid colour;
//  - Every setting is really tappable: frame rate, host mode and language
//    are UIButton + UIMenu dropdowns, not static labels; FPS counter and
//    Controls are switches; upscaling is a real switch (MetalFX Spatial:
//    docked renders at handheld height, then upscales to fullscreen).
//
// 设置文件（独立于游戏内自定义页，不混用）：
//  - Documents/dm_launcher.txt，一行一个「键=值」，键：
//      fps          30 / 60（120 已删除：旧设置里的 120 读到后回落 60）
//      opmode       0 掌机 / 1 底座
//      upscaling    on / off（MetalFX Spatial 真开关；底座降分辨率渲染再放大到全屏；掌机只换放大算法）
//      aniso        follow / off / 2 / 4 / 8 / 16（各向异性初始值；游戏内菜单运行中可改）
//      lang         zh / en
//      fps_counter  0 / 1（接通：见下面帧数显示；不是只存盘）
//      touch_swap   0 传送门左侧 / 1 技能区上方（现成自定义键）
//      framebuf     1 三缓冲 / 0 双缓冲
//      menubtn_x    0–1（游戏内菜单悬浮按钮横向位置，屏宽比例）
//      menubtn_y    0–1（游戏内菜单悬浮按钮纵向位置，屏高比例）
//      menu_fps     0 跟随 / 30 / 40 / 50 / 55 / 60（游戏内菜单「帧率」锁定的存盘值：
//                   菜单里选档即写盘，Play 时 syncToHost 恢复进 dm_menu_fps_set；
//                   与启动器自己的 fps 键是两回事，优先级是菜单锁定 > DM_FPS 钉住）
//      pace_adapt   0 / 1（自适应节拍：Play 时同步成环境变量 DM_PACE_ADAPT，
//                   引擎 hle_nvn.c 首帧定节拍时读一次；缺省关 = 现状行为）
//      shader_prep_threads  0 缺省 / 6 / 8（着色器预热线程数：Play 时同步成
//                   环境变量 DM_SHADER_PREP_THREADS（0 时不设变量，走引擎缺省
//                   核数-2、上限 6）；dm_shader_prep_begin 在 Play 回调里、
//                   host_start 之前读，时序上赶得上）
// Launcher settings file (separate from the in-game Custom page):
//  - Documents/dm_launcher.txt, one "key=value" per line, keys:
//      fps, opmode, upscaling (on / off: MetalFX Spatial real switch; docked renders
//      at handheld height then upscales to fullscreen; handheld only swaps the upscale algorithm), aniso, lang,
//      fps_counter (wired, see FPS overlay below, not persisted-only),
//      touch_swap (the existing custom key touch_swap_above), menubtn_x/y,
//      menu_fps (the in-game menu's frame-rate lock: 0 follow / 30 / 40 / 50 / 55 / 60;
//      written when picked in the menu, restored by syncToHost on Play;
//      not the launcher's own fps key -- precedence: menu lock > DM_FPS pin).
//      pace_adapt (0 / 1: adaptive pacing; synced to env DM_PACE_ADAPT on Play,
//      read once by hle_nvn.c when the first frame fixes the pacing baseline;
//      off by default = current behaviour).
//      shader_prep_threads (0 default / 6 / 8: shader warm-up parallelism; synced
//      to env DM_SHADER_PREP_THREADS on Play, left unset at 0 so the engine's own
//      default of cores-2 capped at 6 applies; dm_shader_prep_begin reads it in
//      the Play callback before host_start, so the timing works).
//
// 点 Play 时才同步给宿主的键（宿主在 host_start 之后、boot_prepare 里读盘 /
// 启动时读一次环境变量，所以 Play 前写一定生效；跑起来后再改无效）：
//  - 环境变量 DM_OPMODE：0 掌机 / 1 底座
//  - 环境变量 DM_LANG：zh -> zh-Hans，en -> en-US
//  - 环境变量 DM_FPS_COUNTER：1 开 / 0 关（供排查与后续前端接线留档；
//    本次的左上角显示由 LauncherVC 自己在 Play 后装的静态浮层窗口实现，
//    见 DmFpsOverlayController，不依赖前端读这个变量）
//  - 环境变量 DM_PACE_ADAPT：1 开 / 0 关（自适应节拍，hle_nvn.c 读一次）
//  - 环境变量 DM_SHADER_PREP_THREADS：6 / 8（预热线程数，dm_shader_prep.m 读；
//    设置里选缺省时不设这个变量）
//  - sw_custom.txt：eco_fps（30 帧=1 / 60 帧=0）、lang（0 简中 / 1 英文）、
//    touch_swap_above（0 / 1）；只改这三行，其余行原样保留。
// On Play only, synced to the host (the host reads sw_custom.txt in
// boot_prepare after host_start, and reads DM_OPMODE / DM_LANG once at
// startup, so writing before Play takes effect; writing later would not):
//  - env DM_OPMODE, env DM_LANG, env DM_FPS_COUNTER (1/0, for traceability
//    and future front-end wiring; this branch's top-left overlay is installed
//    by LauncherVC itself after Play, see DmFpsOverlayController, and does
//    not depend on the front end reading this variable)
//  - env DM_PACE_ADAPT (1/0, adaptive pacing, read once by hle_nvn.c),
//    env DM_SHADER_PREP_THREADS (6 / 8, shader warm-up parallelism, read by
//    dm_shader_prep.m; left unset when the setting is Default)
//  - sw_custom.txt keys eco_fps, lang, touch_swap_above (only those three
//    lines are touched).
//
// 帧数显示（本次真正接通，不是假显示）：
//  - 数据源是真实的出图计数 mtl_present_count()（图形层已导出，tvOS 的
//    main.m 和 front_ios.m 的发热归因都用同一声明），每秒取一次差值就是
//    上屏帧率；温控直接读 NSProcessInfo.thermalState（0 正常 / 1 微热 /
//    2 严重 / 3 危急），和系统档位同一来源。
//  - 实现位置：LauncherVC.m 里的 DmFpsOverlayController。点 Play 后、
//    onPlay 回调已经把根视图换成游戏视图时，才装一个不拦截触摸的浮层
//    窗口（windowLevel 在游戏窗口之上、userInteractionEnabled=NO），
//    左上角一个半透明黑底小标签，每秒刷新一次。之所以不改 main.m，是
//    因为 main.m 里 DmGameVC 的视图就是 front_ios_view 返回的 Metal 视图，
//    启动器自己装浮层窗口同样能盖在游戏画面之上，且改动只集中在启动器
//    文件里；如果资源校验失败回落到 AssetVC，则不装浮层。
// FPS overlay (really wired this time, not a fake display):
//  - Data sources are real: mtl_present_count() (exported by the graphics
//    layer, same declaration used by tvOS main.m and front_ios.m heat
//    attribution), sampled once per second for presented FPS; thermal state
//    from NSProcessInfo.thermalState (0 nominal / 1 fair / 2 serious /
//    3 critical), same source as the system.
//  - Implementation: DmFpsOverlayController in this file. After Play, once
//    the onPlay callback has swapped the root view to the game view, it
//    installs a non-interactive overlay window above the game window
//    (userInteractionEnabled=NO) with a small translucent black label at
//    the top-left, refreshed once per second. This avoids editing main.m:
//    DmGameVC's view is the Metal view returned by front_ios_view, and a
//    launcher-owned overlay window sits above it just as well, keeping the
//    change inside the launcher files. If resource validation falls back
//    to AssetVC, no overlay is installed.
//
// 本文件不实现：运行中主机模式切换；超分菜单开关只开关 scaler，底座降分辨率是启动时定的，
// 运行中改开关不改出图尺寸。
// Not implemented here: switching host mode while the game is running; the in-game menu's
// upscaling switch only toggles the scaler — the docked resolution drop is set at launch,
// so flipping it live does not change the output size.

#import "LauncherVC.h"
#import "DmGlassSettings.h"
#include "../../host/dm_i18n.h"
#include <stdlib.h>
#include <os/proc.h>

#pragma mark - Settings

static NSString *DmLauncherDocuments(void) {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

static NSString *DmLauncherFile(void) {
    return [DmLauncherDocuments() stringByAppendingPathComponent:@"dm_launcher.txt"];
}

static NSString *DmLauncherValue(NSString *text, NSString *key) {
    for (NSString *line in [text componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        if ([line hasPrefix:[key stringByAppendingString:@"="]]) {
            return [line substringFromIndex:key.length + 1];
        }
    }
    return nil;
}

// 只改给定的键，其余行原样保留；键不存在则追加。
// Only the given keys are changed; all other lines are kept verbatim.
static NSString *DmLauncherReplace(NSString *text, NSDictionary<NSString *, NSString *> *kv) {
    NSMutableArray<NSString *> *out = [NSMutableArray array];
    NSMutableSet<NSString *> *done = [NSMutableSet set];
    for (NSString *line in [text componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSString *hit = nil;
        for (NSString *key in kv) {
            if ([line hasPrefix:[key stringByAppendingString:@"="]]) { hit = key; break; }
        }
        if (hit) {
            if (![done containsObject:hit]) {
                [out addObject:[NSString stringWithFormat:@"%@=%@", hit, kv[hit]]];
                [done addObject:hit];
            }
        } else if (line.length) {
            [out addObject:line];
        }
    }
    for (NSString *key in kv) {
        if (![done containsObject:key]) {
            [out addObject:[NSString stringWithFormat:@"%@=%@", key, kv[key]]];
        }
    }
    return [[out componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
}

// 新增行的文案走多语表（dm/i18n/ui_text.tsv，dm_ui 按当前语言取串）；表里取不到
// 时回落给定的中文，与本文件其余硬编码中文行同表现。
// Text for newly added rows comes from the string table (dm/i18n/ui_text.tsv,
// dm_ui picks by current language); when the table has nothing, fall back to the
// given Chinese, matching the rest of this file's hardcoded Chinese rows.
static NSString *DmLauncherUI(const char *key, NSString *fallback) {
    const char *s = dm_ui(key);
    return s && *s ? [NSString stringWithUTF8String:s] : fallback;
}

#pragma mark - FPS overlay (installed by the launcher after Play)

uint64_t mtl_present_count(void);
int mtl_fps_target(void);
// 游戏内菜单调的运行期接口（图形层 / 宿主层提供，见 nvn_mtl.m 与 hle_oe.c）：
// dm_3d_scale_manual_set(0 = 自动，0.50–1.00 = 手动锁定）、dm_menu_fps_set(0 = 跟随自定义页，30 / 40 / 50 / 55 / 60 = 锁定）、
// dm_aniso_set(-1 = 跟随游戏，1 = 关，2 / 4 / 8 / 16 = 强制档位）+ dm_aniso_apply_now（立即作废已建采样器缓存）、
// dm_mtlfx_set(1 = 开，0 = 关）+ dm_mtlfx_get（只开关 scaler；底座降分辨率由启动时 front_game_res 的 DM_MTLFX_SPATIAL 定）。
// dm_3d_quality_mode_get（q3d 的运行期生效值，0 = 流畅优先，1 = 画质优先；菜单画质行只用它读回显示，
// 写不再直调 dm_3d_quality_mode_set，改走 dm_custom_set_immediate("q3d", …)：落盘 + 由 dm_custom 内部同步运行期值）。
// Runtime setters the in-game menu calls (provided by nvn_mtl.m / hle_oe.c).
void dm_3d_scale_manual_set(float v);
float dm_3d_scale_manual_get(void);
float dm_3d_scale_cur(void);
void dm_menu_fps_set(int v);
int dm_menu_fps_get(void);
void dm_aniso_set(int v);
int dm_aniso_get(void);
void dm_aniso_apply_now(void);
void dm_mtlfx_set(int v);
int dm_mtlfx_get(void);
void dm_3d_quality_mode_set(int mode);
int dm_3d_quality_mode_get(void);
// 特效档位（键 vfx，0 低 / 1 中 / 2 高，缺省中）：与游戏内「自定义」页共用
// dm_custom 的同一份 g_val / sw_custom.txt；菜单里选中即走 dm_custom_set_immediate
// 改值 + 存盘，图形层 nvn_mtl.m 每帧读 dm_vfx_level()，下一帧就按新档走。
// Effects tier (key vfx, 0 low / 1 medium / 2 high, medium by default): shares
// dm_custom's g_val / sw_custom.txt with the in-game Custom page; selecting in
// the menu writes via dm_custom_set_immediate and saves; nvn_mtl.m reads
// dm_vfx_level() every frame, so the new tier applies from the next frame.
void dm_custom_set_immediate(const char *key, int value);
int dm_vfx_level(void);

@interface DmFpsOverlayController : NSObject
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) uint64_t lastPresents;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) BOOL started;
- (void)startWithScene:(UIWindowScene *)scene;
- (void)tick;
- (void)setVisible:(BOOL)visible scene:(UIWindowScene *)scene;
- (BOOL)visible;
@end

@implementation DmFpsOverlayController

- (void)startWithScene:(UIWindowScene *)scene {
    if (self.started || !scene) return;
    self.started = YES;
    UIWindow *w = [[UIWindow alloc] initWithWindowScene:scene];
    w.windowLevel = UIWindowLevelAlert + 1;
    w.backgroundColor = UIColor.clearColor;
    w.userInteractionEnabled = NO;
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = UIColor.clearColor;
    vc.view.userInteractionEnabled = NO;
    w.rootViewController = vc;
    UILabel *l = [[UILabel alloc] init];
    l.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55];
    l.textColor = UIColor.whiteColor;
    l.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    l.textAlignment = NSTextAlignmentCenter;
    l.layer.cornerRadius = 12;
    l.clipsToBounds = YES;
    l.userInteractionEnabled = NO;
    l.text = @"  FPS —  ";
    // 顶部留出安全区：窗口刚建时 safeAreaInsets 可能还是 0，tick 里每次
    // 都按当前安全区重摆一次，所以这里先给一个保底位置。
    l.frame = CGRectMake(16, 16, 200, 24);
    [vc.view addSubview:l];
    self.window = w;
    self.label = l;
    w.hidden = NO;
    self.timer = [NSTimer timerWithTimeInterval:1.0 target:self
                                       selector:@selector(tick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    [self tick];
}

- (void)tick {
    if (!self.label || !self.window) return;
    // 安全区重摆：横竖屏 / 灵动岛下都贴左上角，不盖住系统区域。
    UIEdgeInsets safe = self.window.safeAreaInsets;
    self.label.frame = CGRectMake(16, safe.top + 6, 200, 24);
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    uint64_t presents = mtl_present_count();
    NSString *thermal;
    switch (NSProcessInfo.processInfo.thermalState) {
        case NSProcessInfoThermalStateNominal: thermal = @"温控正常"; break;
        case NSProcessInfoThermalStateFair: thermal = @"温控微热"; break;
        case NSProcessInfoThermalStateSerious: thermal = @"温控严重"; break;
        case NSProcessInfoThermalStateCritical: thermal = @"温控危急"; break;
        default: thermal = @"温控未知"; break;
    }
    // 刚启动 / 后台回来时间隔太长时只重设基线，不算一次误导性的帧率。
    if (self.lastTime == 0 || now - self.lastTime > 2.5) {
        self.lastPresents = presents;
        self.lastTime = now;
        self.label.text = [NSString stringWithFormat:@"  FPS — · %@  ", thermal];
        return;
    }
    double dt = now - self.lastTime;
    double fps = dt > 0 ? (double)(presents - self.lastPresents) / dt : 0;
    self.lastPresents = presents;
    self.lastTime = now;
    self.label.text = [NSString stringWithFormat:@"  %.0f FPS · %@  ", fps, thermal];
}

// 游戏内菜单的 FPS 显示开关：开 = 需要时装浮层并显示；关 = 藏窗口并停计时器。
// FPS switch in the in-game menu: on = install (if needed) and show; off = hide the window and stop the timer.
- (void)setVisible:(BOOL)visible scene:(UIWindowScene *)scene {
    if (visible && !self.started) { [self startWithScene:scene]; return; }
    if (!self.started) return;
    self.window.hidden = !visible;
    if (visible) {
        if (!self.timer) {
            self.timer = [NSTimer timerWithTimeInterval:1.0 target:self
                                               selector:@selector(tick) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        }
        [self tick];
    } else {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (BOOL)visible {
    return self.started && self.window && !self.window.hidden;
}

@end

static DmFpsOverlayController *DmFpsOverlayShared(void) {
    static DmFpsOverlayController *c;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ c = [DmFpsOverlayController new]; });
    return c;
}
#pragma mark - In-game menu (floating button + compact glass panel)

// 紧凑要求（launcher-spatial-menu 起，menu-opt 优化）：面板 240 宽、靠右边缘、不居中；
// 行高 36、7 行（全部立马生效）；悬浮按钮看着 40x40、可点范围 60x60；
// 菜单区外点按关闭且放行给游戏（根视图只在按钮区 / 菜单区内拦截触摸）。
// Compactness (launcher-spatial-menu, refined by menu-opt): 240-wide panel at the right edge,
// never centered; 36-high rows, 7 rows (all take effect immediately); the floating button
// looks 40x40 but taps in a 60x60 area; taps outside the menu close it AND pass through
// to the game (the root view only intercepts touches in the button / menu areas).

// 只在自己区域内拦截触摸的根视图：按钮区 / 菜单区内走正常 hitTest，其余一律返回 nil 放行给游戏窗口。
// Root view that only intercepts touches in its own areas: normal hit-testing inside the button / menu areas,
// nil everywhere else so touches fall through to the game window.
// 悬浮按钮：看着小、点按范围大——pointInside 向外扩 10pt，与根视图的扩框判定配合，
// 让 40x40 的按钮拥有 60x60 的可点区域（游戏区只让出这一圈）。
// Floating button: small to look at, big to tap — pointInside expands 10pt on every
// side, matching the root view's expanded-frame check, so a 40x40 button taps like 60x60.
@interface DmMenuFloatButton : UIButton
@end
@implementation DmMenuFloatButton
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(CGRectInset(self.bounds, -10, -10), point);
}
@end

@interface DmMenuRootView : UIView
@property (nonatomic, weak) UIView *buttonView;
@property (nonatomic, weak) UIView *panelView;
@property (nonatomic, weak) UIView *glassView;   // 毛玻璃设置面板的遮罩（开着时整屏归它）| the glass panel's shade (owns the whole screen while open)
@property (nonatomic, assign) BOOL menuOpen;
@end

@implementation DmMenuRootView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // 毛玻璃面板是模态的：开着时先于悬浮按钮 / 菜单面板判定，整屏触摸归它。
    // The glass panel is modal: while open it is hit-tested before the floating
    // button / menu panel and takes the whole screen.
    if (self.glassView && self.glassView.superview == self && CGRectContainsPoint(self.glassView.frame, point)) return [super hitTest:point withEvent:event];
    if (self.buttonView && CGRectContainsPoint(CGRectInset(self.buttonView.frame, -10, -10), point)) return [super hitTest:point withEvent:event];
    if (self.menuOpen && self.panelView && CGRectContainsPoint(self.panelView.frame, point)) return [super hitTest:point withEvent:event];
    return nil;
}
@end

@class DmGameMenuController;

@interface DmMenuRootVC : UIViewController
@property (nonatomic, weak) DmGameMenuController *menu;
@end

@interface DmGameMenuController : NSObject
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIWindowScene *scene;
@property (nonatomic, strong) DmMenuRootView *rootView;
@property (nonatomic, strong) UIButton *floatButton;
@property (nonatomic, strong) UIVisualEffectView *panel;
@property (nonatomic, strong) NSArray<UIView *> *menuRows;
@property (nonatomic, strong) UILabel *menuFootnote;
@property (nonatomic, strong) UIButton *menuScaleButton;
@property (nonatomic, strong) UIButton *menuQualityButton;
@property (nonatomic, strong) UIButton *menuVfxButton;
@property (nonatomic, strong) UIButton *menuFpsButton;
@property (nonatomic, strong) UIButton *menuAnisoButton;
@property (nonatomic, strong) UIButton *menuGlassButton;
@property (nonatomic, strong) UISwitch *menuMfxSwitch;
@property (nonatomic, strong) UISwitch *menuFpsSwitch;
@property (nonatomic, assign) CGPoint panStart;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) BOOL menuOpen;
@property (nonatomic, assign) CGFloat buttonXFrac;
@property (nonatomic, assign) CGFloat buttonYFrac;
- (void)startWithScene:(UIWindowScene *)scene;
- (void)layoutInBounds:(CGRect)b safe:(UIEdgeInsets)safe;
- (void)refreshMenu;
- (void)closeMenu;
@end

// 全屏透明菜单窗口：只在内层视图 hitTest 返回 nil 是不够的，
// iOS 会把窗口自身当成命中视图吃掉触摸，所以必须在窗口层返回 nil 放行。
@interface DmMenuPassthroughWindow : UIWindow
@end

@implementation DmMenuPassthroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self) {
        DmMenuRootVC *vc = (DmMenuRootVC *)self.rootViewController;
        // 只在触摸刚落下时才算「点外面关菜单」：hitTest 在一次触摸里会被反复调用
        // （控件拖动 / 下拉菜单弹出前后），若每次落到窗口自身都关菜单，面板会被
        // 隐藏、正在操作的开关/下拉触摸随之被取消，表现就是「按了/拖了没反应」。
        // Only a fresh touch-down counts as an outside tap: hitTest runs repeatedly
        // during one touch (control drags, UIMenu presentation); closing the menu on
        // any pass that resolves to the window hides the panel mid-gesture and
        // cancels the control being operated.
        UITouch *t = event.allTouches.anyObject;
        if (vc.menu.menuOpen && t.phase == UITouchPhaseBegan) [vc.menu closeMenu];
        return nil;
    }
    return hit;
}
@end

@implementation DmMenuRootVC
- (void)loadView {
    self.view = [DmMenuRootView new];
    self.view.backgroundColor = UIColor.clearColor;
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.menu layoutInBounds:self.view.bounds safe:self.view.safeAreaInsets];
}
@end

@implementation DmGameMenuController

- (UIButton *)menuDropdownWithTitle:(NSString *)title menu:(UIMenu *)menu {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:[NSString stringWithFormat:@"%@ ▾", title] forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    b.menu = menu;
    b.showsMenuAsPrimaryAction = YES;
    return b;
}

- (UIView *)menuRowWithTitle:(NSString *)title control:(UIView *)control {
    UIView *row = [[UIView alloc] init];
    UILabel *t = [[UILabel alloc] init];
    t.text = title;
    t.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    t.textColor = UIColor.whiteColor;   // 面板恒为深色毛玻璃：labelColor 在浅色系统下是黑字，压在深面板上看不清，固定白字
    [row addSubview:t];
    if (control) [row addSubview:control];
    return row;
}

// 菜单当前选中的分辨率名：手动值只可能是下拉给出的那几个，区间比较足够，不用 fabsf。
// Scale selection name: manual values are only ever the dropdown's own values, so range checks suffice.
- (NSString *)scaleSelectionTitle {
    float m = dm_3d_scale_manual_get();
    if (m <= 0) return @"自动";
    if (m >= 0.995f) return @"1.00";
    if (m >= 0.70f) return @"0.75";
    if (m >= 0.60f) return @"0.65";
    return @"0.50";
}

- (UIMenu *)scaleMenu {
    __weak typeof(self) weakSelf = self;
    NSArray<NSNumber *> *vals = @[@(0), @(1.0), @(0.75), @(0.65), @(0.50)];
    NSArray<NSString *> *names = @[@"自动", @"1.00", @"0.75", @"0.65", @"0.50"];
    float cur = dm_3d_scale_manual_get();
    NSMutableArray<UIAction *> *acts = [NSMutableArray array];
    for (NSUInteger i = 0; i < vals.count; i++) {
        float v = vals[i].floatValue;
        UIAction *a = [UIAction actionWithTitle:names[i] image:nil identifier:nil handler:^(__kindof UIAction *act) {
            typeof(self) s = weakSelf; if (!s) return;
            dm_3d_scale_manual_set(v); [s refreshMenu];
        }];
        BOOL on = (v == 0 && cur <= 0) || (v > 0 && cur > v - 0.01f && cur < v + 0.01f);
        a.state = on ? UIMenuElementStateOn : UIMenuElementStateOff;
        [acts addObject:a];
    }
    return [UIMenu menuWithTitle:@"" children:acts];
}

// 菜单帧率锁定存盘（dm_launcher.txt 的 menu_fps 键）：选档即写、其余行原样
// 保留，写法与拖按钮位置时写 menubtn_x/y 完全同款（DmLauncherReplace）。
// 恢复在启动器 syncToHost 里做：它比菜单装起来还早，赶在第一帧定节拍基线之前。
// Persist the menu frame-rate lock (menu_fps in dm_launcher.txt): written on
// every pick, other lines untouched -- the same DmLauncherReplace pattern as
// menubtn_x/y. Restoration happens in the launcher's syncToHost, which runs
// before the menu is installed, ahead of the first frame's pacing baseline.
- (void)persistMenuFps:(int)v {
    NSString *old = [NSString stringWithContentsOfFile:DmLauncherFile() encoding:NSUTF8StringEncoding error:nil] ?: @"";
    NSString *next = DmLauncherReplace(old, @{ @"menu_fps": [NSString stringWithFormat:@"%d", v] });
    [next writeToFile:DmLauncherFile() atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (UIMenu *)menuFpsMenu {
    __weak typeof(self) weakSelf = self;
    int cur = dm_menu_fps_get();
    UIAction *a30 = [UIAction actionWithTitle:@"30 帧" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; dm_menu_fps_set(30); [s persistMenuFps:30]; [s refreshMenu];
    }];
    UIAction *a40 = [UIAction actionWithTitle:@"40 帧" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; dm_menu_fps_set(40); [s persistMenuFps:40]; [s refreshMenu];
    }];
    UIAction *a50 = [UIAction actionWithTitle:@"50 帧" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; dm_menu_fps_set(50); [s persistMenuFps:50]; [s refreshMenu];
    }];
    UIAction *a55 = [UIAction actionWithTitle:@"55 帧" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; dm_menu_fps_set(55); [s persistMenuFps:55]; [s refreshMenu];
    }];
    UIAction *a60 = [UIAction actionWithTitle:@"60 帧" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; dm_menu_fps_set(60); [s persistMenuFps:60]; [s refreshMenu];
    }];
    UIAction *aFollow = [UIAction actionWithTitle:@"跟随游戏内设置" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; dm_menu_fps_set(0); [s persistMenuFps:0]; [s refreshMenu];
    }];
    a30.state = cur == 30 ? UIMenuElementStateOn : UIMenuElementStateOff;
    a40.state = cur == 40 ? UIMenuElementStateOn : UIMenuElementStateOff;
    a50.state = cur == 50 ? UIMenuElementStateOn : UIMenuElementStateOff;
    a55.state = cur == 55 ? UIMenuElementStateOn : UIMenuElementStateOff;
    a60.state = cur == 60 ? UIMenuElementStateOn : UIMenuElementStateOff;
    aFollow.state = cur == 0 ? UIMenuElementStateOn : UIMenuElementStateOff;
    return [UIMenu menuWithTitle:@"" children:@[a30, a40, a50, a55, a60, aFollow]];
}

- (NSString *)menuFpsTitle {
    int cur = dm_menu_fps_get();
    if (cur == 30) return @"30 帧";
    if (cur == 40) return @"40 帧";
    if (cur == 50) return @"50 帧";
    if (cur == 55) return @"55 帧";
    if (cur == 60) return @"60 帧";
    return @"跟随游戏内设置";
}

- (UIMenu *)menuAnisoMenu {
    __weak typeof(self) weakSelf = self;
    NSArray<NSNumber *> *vals = @[@(-1), @(1), @(2), @(4), @(8), @(16)];
    NSArray<NSString *> *names = @[@"跟随游戏", @"关", @"2x", @"4x", @"8x", @"16x"];
    int cur = dm_aniso_get();
    NSMutableArray<UIAction *> *acts = [NSMutableArray array];
    for (NSUInteger i = 0; i < vals.count; i++) {
        int v = vals[i].intValue;
        UIAction *a = [UIAction actionWithTitle:names[i] image:nil identifier:nil handler:^(__kindof UIAction *act) {
            typeof(self) s = weakSelf; if (!s) return;
            dm_aniso_set(v); dm_aniso_apply_now(); [s refreshMenu];
        }];
        a.state = cur == v ? UIMenuElementStateOn : UIMenuElementStateOff;
        [acts addObject:a];
    }
    return [UIMenu menuWithTitle:@"" children:acts];
}

- (NSString *)menuAnisoTitle {
    switch (dm_aniso_get()) {
        case 1: return @"关";
        case 2: return @"2x";
        case 4: return @"4x";
        case 8: return @"8x";
        case 16: return @"16x";
        default: return @"跟随游戏";
    }
}

// 帧率优先级（与 nvn_mtl.m 的 mtl_fps_target 一致）：菜单帧率锁定 > DM_FPS
// 钉住 > 自定义页。启动器选 60 时 DM_FPS=60 只是在菜单未锁定时兜底，菜单里
// 锁了 30 / 40 / 50 / 55 / 60 就以菜单为准；文件里没有 fps 键时启动器缺省 60，同样
// 只是兜底，不妨碍菜单锁定生效。
// Frame-rate precedence (as in nvn_mtl.m's mtl_fps_target): menu frame-rate
// lock > DM_FPS pin > Custom page. The launcher's DM_FPS=60 pin is only the
// fallback while the menu is unlocked; a menu lock of 30 / 40 / 60 wins over
// it. A missing fps key (launcher default 60) is likewise only the fallback
// and never blocks the menu lock.
// 画质模式行：显示值读 dm_3d_quality_mode_get()（q3d 的运行期生效值）；选中走
// dm_custom_set_immediate("q3d", …) 写回——落盘持久 + 由 dm_custom 内部同步运行期
// 值，与自定义页、DmGlassSettings 面板同一份存储、单写路径，重启不回落。
// Quality mode row: the shown value reads dm_3d_quality_mode_get() (the live
// q3d value); selections write through dm_custom_set_immediate("q3d", ...),
// which persists and syncs the runtime value inside dm_custom — one shared
// store and a single write path with the Custom page and DmGlassSettings.
- (NSString *)menuQualityTitle {
    return dm_3d_quality_mode_get() == 1 ? @"画质优先" : @"流畅优先";
}
- (UIMenu *)menuQualityMenu {
    __weak typeof(self) weakSelf = self;
    UIAction *smooth = [UIAction actionWithTitle:@"流畅优先" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; dm_custom_set_immediate("q3d", 0); [s refreshMenu];
    }];
    UIAction *quality = [UIAction actionWithTitle:@"画质优先" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; dm_custom_set_immediate("q3d", 1); [s refreshMenu];
    }];
    BOOL isQuality = dm_3d_quality_mode_get() == 1;
    smooth.state = isQuality ? UIMenuElementStateOff : UIMenuElementStateOn;
    quality.state = isQuality ? UIMenuElementStateOn : UIMenuElementStateOff;
    return [UIMenu menuWithTitle:@"" children:@[smooth, quality]];
}

// 特效档位行：结构照画质模式行（下拉 + 选中打勾）；显示值读 dm_vfx_level()
//（= 自定义页同一个键 vfx 的已生效值），选中走 dm_custom_set_immediate 写回
// 同一份存储，与自定义页互相同步、不会打架。
// Effects tier row: same shape as the quality-mode row (dropdown + checkmark);
// the shown value reads dm_vfx_level() (the effective value of the same vfx
// key the Custom page uses) and selections write back through
// dm_custom_set_immediate into the shared store.
- (NSString *)menuVfxTitle {
    switch (dm_vfx_level()) {
        case 0: return @"低";
        case 2: return @"高";
        default: return @"中";
    }
}
- (UIMenu *)menuVfxMenu {
    __weak typeof(self) weakSelf = self;
    NSArray<NSNumber *> *vals = @[@(0), @(1), @(2)];
    NSArray<NSString *> *names = @[@"低", @"中", @"高"];
    int cur = dm_vfx_level();
    NSMutableArray<UIAction *> *acts = [NSMutableArray array];
    for (NSUInteger i = 0; i < vals.count; i++) {
        int v = vals[i].intValue;
        UIAction *a = [UIAction actionWithTitle:names[i] image:nil identifier:nil handler:^(__kindof UIAction *act) {
            typeof(self) s = weakSelf; if (!s) return;
            dm_custom_set_immediate("vfx", v); [s refreshMenu];
        }];
        a.state = cur == v ? UIMenuElementStateOn : UIMenuElementStateOff;
        [acts addObject:a];
    }
    return [UIMenu menuWithTitle:@"" children:acts];
}

- (void)startWithScene:(UIWindowScene *)scene {
    if (self.started || !scene) return;
    self.started = YES;
    self.scene = scene;
    NSString *text = [NSString stringWithContentsOfFile:DmLauncherFile() encoding:NSUTF8StringEncoding error:nil];
    NSString *v;
    self.buttonXFrac = 0.93; self.buttonYFrac = 0.12;
    if ((v = DmLauncherValue(text, @"menubtn_x"))) { CGFloat f = v.doubleValue; if (f > 0.05 && f < 0.98) self.buttonXFrac = f; }
    if ((v = DmLauncherValue(text, @"menubtn_y"))) { CGFloat f = v.doubleValue; if (f > 0.02 && f < 0.98) self.buttonYFrac = f; }
    DmMenuPassthroughWindow *w = [[DmMenuPassthroughWindow alloc] initWithWindowScene:scene];
    w.windowLevel = UIWindowLevelAlert + 1;
    w.backgroundColor = UIColor.clearColor;
    DmMenuRootVC *vc = [DmMenuRootVC new];
    vc.menu = self;
    w.rootViewController = vc;
    self.window = w;
    DmMenuRootView *root = (DmMenuRootView *)vc.view;   // 访问 view 触发 loadView 建好根视图
    self.rootView = root;
    DmMenuFloatButton *btn = [DmMenuFloatButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"菜单" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.42];
    btn.layer.cornerRadius = 20;
    btn.clipsToBounds = YES;
    btn.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.25].CGColor;
    btn.layer.borderWidth = 0.5;
    [btn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragButton:)];
    [btn addGestureRecognizer:pan];
    [root addSubview:btn];
    self.floatButton = btn;
    UIVisualEffectView *panel = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    panel.layer.cornerRadius = 18;
    panel.clipsToBounds = YES;
    panel.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18].CGColor;
    panel.layer.borderWidth = 0.5;
    panel.hidden = YES;
    [root addSubview:panel];
    self.panel = panel;
    self.menuScaleButton = [self menuDropdownWithTitle:[self scaleSelectionTitle] menu:[self scaleMenu]];
    self.menuQualityButton = [self menuDropdownWithTitle:[self menuQualityTitle] menu:[self menuQualityMenu]];
    self.menuVfxButton = [self menuDropdownWithTitle:[self menuVfxTitle] menu:[self menuVfxMenu]];
    self.menuFpsButton = [self menuDropdownWithTitle:[self menuFpsTitle] menu:[self menuFpsMenu]];
    self.menuAnisoButton = [self menuDropdownWithTitle:[self menuAnisoTitle] menu:[self menuAnisoMenu]];
    self.menuMfxSwitch = [[UISwitch alloc] init];
    [self.menuMfxSwitch addTarget:self action:@selector(mfxSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.menuFpsSwitch = [[UISwitch alloc] init];
    [self.menuFpsSwitch addTarget:self action:@selector(fpsSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    // 毛玻璃设置面板入口（DmGlassSettings，原 main 线面板）：行尾「打开」按钮，
    // 点了先关本菜单、再以菜单根视图为宿主把面板盖到游戏画面上（见 glassTapped）。
    // Entry to the frosted-glass settings panel (DmGlassSettings, the original
    // main-line panel): an Open button at the row's end; tapping closes this menu
    // and presents the panel over the game picture on the menu root view.
    self.menuGlassButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.menuGlassButton setTitle:DmLauncherUI("dmGlassOpen", @"打开") forState:UIControlStateNormal];
    self.menuGlassButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    [self.menuGlassButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.menuGlassButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.menuGlassButton addTarget:self action:@selector(glassTapped) forControlEvents:UIControlEventTouchUpInside];
    self.menuMfxSwitch.thumbTintColor = UIColor.whiteColor;
    self.menuMfxSwitch.onTintColor = UIColor.systemBlueColor;
    self.menuFpsSwitch.thumbTintColor = UIColor.whiteColor;
    self.menuFpsSwitch.onTintColor = UIColor.systemBlueColor;
    UIView *fpsRow = [self menuRowWithTitle:@"帧率" control:nil];
    [fpsRow addSubview:self.menuFpsButton];
    self.menuRows = @[
        [self menuRowWithTitle:@"分辨率" control:self.menuScaleButton],
        [self menuRowWithTitle:@"画质模式" control:self.menuQualityButton],
        [self menuRowWithTitle:@"特效" control:self.menuVfxButton],
        fpsRow,
        [self menuRowWithTitle:@"各向异性" control:self.menuAnisoButton],
        [self menuRowWithTitle:@"超分" control:self.menuMfxSwitch],
        [self menuRowWithTitle:@"FPS 显示" control:self.menuFpsSwitch],
        [self menuRowWithTitle:DmLauncherUI("dmGlassTitle", @"设置") control:self.menuGlassButton],
    ];
    for (UIView *row in self.menuRows) [panel.contentView addSubview:row];
    // 行间细分隔线（更好看）：除最后一行外每行底加一条半透明细线；tag 777，布局时跳过控件查找。
    for (NSUInteger i = 0; i + 1 < self.menuRows.count; i++) {
        UIView *sep = [[UIView alloc] init];
        sep.tag = 777;
        sep.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
        [self.menuRows[i] addSubview:sep];
    }
    self.menuFootnote = [[UILabel alloc] init];
    self.menuFootnote.font = [UIFont systemFontOfSize:10 weight:UIFontWeightRegular];
    self.menuFootnote.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75];   // 同上：深面板上的说明小字用白 75% 保层次
    self.menuFootnote.textAlignment = NSTextAlignmentCenter;
    [panel.contentView addSubview:self.menuFootnote];
    w.hidden = NO;
    [self refreshMenu];
}

- (void)toggleMenu {
    if (self.menuOpen) { [self closeMenu]; return; }
    [self refreshMenu];
    self.menuOpen = YES;
    self.panel.hidden = NO;
    self.rootView.menuOpen = YES;
}

- (void)closeMenu {
    self.menuOpen = NO;
    self.panel.hidden = YES;
    self.rootView.menuOpen = NO;
}

- (void)fpsSwitchChanged:(UISwitch *)sender {
    [DmFpsOverlayShared() setVisible:sender.on scene:self.scene];
}

- (void)mfxSwitchChanged:(UISwitch *)sender {
    // 只开关 scaler；底座降分辨率是启动时定的，运行中改开关不改出图尺寸。
    dm_mtlfx_set(sender.on ? 1 : 0);
    [self refreshMenu];
}

// 毛玻璃设置面板：先关菜单（两块玻璃面板不同时开），以根视图为宿主打开面板，
// 并把面板遮罩登记给根视图的 hitTest（面板开着时整屏触摸归它）；面板自己关掉
//（完成按钮 / 点遮罩空白处）后遮罩移除，弱引用自动清空，不用这边收尾。
// Frosted-glass panel: close this menu first (never two glass panels at once),
// present the panel on the root view, and register its shade with the root
// view's hitTest (while open, the shade owns the screen). When the panel closes
// itself (Done button / tap on the shade) the shade is removed and the weak
// reference clears itself; nothing to clean up here.
- (void)glassTapped {
    [self closeMenu];
    dm_glass_present(self.rootView);
    self.rootView.glassView = dm_glass_shade_view();
}

- (void)refreshMenu {
    if (!self.started) return;
    [self.menuScaleButton setTitle:[NSString stringWithFormat:@"%@ ▾", [self scaleSelectionTitle]] forState:UIControlStateNormal];
    self.menuScaleButton.menu = [self scaleMenu];
    [self.menuQualityButton setTitle:[NSString stringWithFormat:@"%@ ▾", [self menuQualityTitle]] forState:UIControlStateNormal];
    self.menuQualityButton.menu = [self menuQualityMenu];
    [self.menuVfxButton setTitle:[NSString stringWithFormat:@"%@ ▾", [self menuVfxTitle]] forState:UIControlStateNormal];
    self.menuVfxButton.menu = [self menuVfxMenu];
    [self.menuFpsButton setTitle:[NSString stringWithFormat:@"%@ ▾", [self menuFpsTitle]] forState:UIControlStateNormal];
    self.menuFpsButton.menu = [self menuFpsMenu];
    [self.menuAnisoButton setTitle:[NSString stringWithFormat:@"%@ ▾", [self menuAnisoTitle]] forState:UIControlStateNormal];
    self.menuAnisoButton.menu = [self menuAnisoMenu];
    self.menuFpsSwitch.on = [DmFpsOverlayShared() visible];
    self.menuMfxSwitch.on = dm_mtlfx_get() == 1;
    // 毛玻璃行文案在装菜单时按当时的语言取的，刷新时重取一次（语言在游戏起来后才定死）。
    // The glass row's text was taken at install time; re-take it on refresh (the
    // language only settles once the game is up).
    [self.menuGlassButton setTitle:DmLauncherUI("dmGlassOpen", @"打开") forState:UIControlStateNormal];
    UILabel *glassTitle = (UILabel *)self.menuRows.lastObject.subviews.firstObject;
    if ([glassTitle isKindOfClass:UILabel.class]) glassTitle.text = DmLauncherUI("dmGlassTitle", @"设置");
    self.menuFootnote.text = [NSString stringWithFormat:@"当前 3D 比例 %.2f · 帧率目标 %d · 超分 %@", dm_3d_scale_cur(), mtl_fps_target(), dm_mtlfx_get() == 1 ? @"开" : @"关"];
    [self.rootView setNeedsLayout];   // 帧率行控件显隐 / 下拉标题变长后重摆
}

- (void)dragButton:(UIPanGestureRecognizer *)pan {
    if (!self.floatButton || !self.rootView) return;
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.panStart = [pan locationInView:self.rootView];
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint t = [pan translationInView:self.rootView];
        CGPoint c = self.floatButton.center;
        c.x += t.x; c.y += t.y;
        CGRect b = self.rootView.bounds;
        CGFloat top = self.window ? self.window.safeAreaInsets.top : 0;
        c.x = fmax(20, fmin(b.size.width - 20, c.x));
        c.y = fmax(top + 20, fmin(b.size.height - 20, c.y));
        self.floatButton.center = c;
        [pan setTranslation:CGPointZero inView:self.rootView];
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        CGRect b = self.rootView.bounds;
        if (b.size.width > 0 && b.size.height > 0) {
            self.buttonXFrac = self.floatButton.center.x / b.size.width;
            self.buttonYFrac = self.floatButton.center.y / b.size.height;
            NSString *old = [NSString stringWithContentsOfFile:DmLauncherFile() encoding:NSUTF8StringEncoding error:nil] ?: @"";
            NSString *next = DmLauncherReplace(old, @{
                @"menubtn_x": [NSString stringWithFormat:@"%.3f", (double)self.buttonXFrac],
                @"menubtn_y": [NSString stringWithFormat:@"%.3f", (double)self.buttonYFrac],
            });
            [next writeToFile:DmLauncherFile() atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
        // 小位移的点按可能被 pan 手势认领、导致 touchUpInside 没触发：只有正常结束且位移 < 12pt 才当点按处理。
        if (pan.state == UIGestureRecognizerStateEnded) {
            CGPoint end = [pan locationInView:self.rootView];
            if (hypot(end.x - self.panStart.x, end.y - self.panStart.y) < 12) [self toggleMenu];
        }
    }
}

- (void)layoutInBounds:(CGRect)b safe:(UIEdgeInsets)safe {
    if (!self.floatButton || !self.panel || b.size.width <= 0) return;
    CGFloat bw = 40;
    CGFloat cx = self.buttonXFrac * b.size.width;
    CGFloat cy = self.buttonYFrac * b.size.height;
    cx = fmax(bw / 2, fmin(b.size.width - bw / 2, cx));
    cy = fmax(safe.top + bw / 2, fmin(b.size.height - bw / 2, cy));
    self.floatButton.frame = CGRectMake(cx - bw / 2, cy - bw / 2, bw, bw);
    CGFloat pw = 240;
    CGFloat px = b.size.width - pw - 12;
    CGFloat py = safe.top + 64;
    CGFloat y = 10;
    CGFloat innerW = pw - 24;
    for (UIView *row in self.menuRows) {
        UIView *control = nil;
        for (NSUInteger i = 1; i < row.subviews.count; i++) {
            UIView *sv = row.subviews[i];
            if (sv.tag == 777) continue;
            if (!sv.hidden) { control = sv; break; }
            sv.frame = CGRectZero;
        }
        CGFloat cw = 0, ch = 0;
        if (control) {
            [control sizeToFit];
            cw = control.bounds.size.width; ch = control.bounds.size.height;
            if ([control isKindOfClass:UIButton.class]) { if (cw > 150) cw = 150; if (ch < 32) ch = 32; }
        }
        UILabel *title = row.subviews[0];
        CGFloat textW = control ? innerW - cw - 8 : innerW;
        title.frame = CGRectMake(0, 0, textW, 36);
        if (control) control.frame = CGRectMake(innerW - cw, (36 - ch) / 2, cw, ch);
        row.frame = CGRectMake(12, y, innerW, 36);
        for (UIView *sv in row.subviews) {
            if (sv.tag == 777) sv.frame = CGRectMake(0, 36 - 0.5, innerW, 0.5);
        }
        y += 36;
    }
    self.menuFootnote.frame = CGRectMake(12, y + 2, innerW, 16);
    self.panel.frame = CGRectMake(px, py, pw, y + 2 + 16 + 10);
    self.rootView.buttonView = self.floatButton;
    self.rootView.panelView = self.panel;
}

@end

static DmGameMenuController *DmGameMenuShared(void) {
    static DmGameMenuController *c;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ c = [DmGameMenuController new]; });
    return c;
}


@interface LauncherVC ()

@property (nonatomic, assign) NSInteger fps;        // 30 / 60（120 已删除）
@property (nonatomic, assign) NSInteger opmode;     // 0 掌机 / 1 底座
@property (nonatomic, assign) NSInteger lang;       // 0 简中 / 1 英文
@property (nonatomic, assign) BOOL fpsCounter;      // 已接通：Play 后装左上角浮层
@property (nonatomic, assign) BOOL touchSwap;       // 0 传送门左侧 / 1 技能区上方
@property (nonatomic, assign) BOOL framebuf;  // YES=三缓冲 / NO=双缓冲
@property (nonatomic, assign) NSInteger aniso;  // -1 跟随游戏 / 1 关 / 2 / 4 / 8 / 16
@property (nonatomic, assign) BOOL upscaling;  // MetalFX Spatial 真开关
@property (nonatomic, assign) CGFloat menubtnX;  // 悬浮按钮横向位置（屏宽比例）
@property (nonatomic, assign) CGFloat menubtnY;  // 悬浮按钮纵向位置（屏高比例）
@property (nonatomic, assign) NSInteger menuFps;  // 游戏内菜单帧率锁定的存盘值：0 跟随 / 30 / 40 / 50 / 55 / 60（菜单里选档写盘，这里镜像读写防 saveSettings 洗掉，Play 时恢复）
@property (nonatomic, assign) BOOL paceAdapt;  // 自适应节拍（环境变量 DM_PACE_ADAPT）：缺省开（存盘里有 pace_adapt 键时按存盘值）；Play 时 syncToHost 写环境变量，hle_nvn.c 首帧定节拍时读一次
@property (nonatomic, assign) NSInteger prepThreads;  // 着色器预热线程数（环境变量 DM_SHADER_PREP_THREADS）：0 缺省（不设变量，引擎按核数-2、上限 6）/ 6 / 8；Play 时 syncToHost 写
@property (nonatomic, strong) UIButton *anisoButton;
@property (nonatomic, strong) UIButton *upscaleButton;
@property (nonatomic, strong) UIVisualEffectView *rightGlass;
@property (nonatomic, strong) UIScrollView *rightScroll;
@property (nonatomic, strong) UIView *rightContent;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *fpsButton;
@property (nonatomic, strong) UIButton *opmodeButton;
@property (nonatomic, strong) UIButton *langButton;
@property (nonatomic, strong) UISwitch *fpsCounterSwitch;
@property (nonatomic, strong) UISwitch *touchSwapSwitch;
@property (nonatomic, strong) UISwitch *framebufSwitch;
@property (nonatomic, strong) UISwitch *paceAdaptSwitch;
@property (nonatomic, strong) UIButton *prepButton;
@property (nonatomic, strong) UILabel *memoryValueLabel;
@property (nonatomic, strong) UILabel *memorySubtitleLabel;

@end

@implementation LauncherVC

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures { return UIRectEdgeAll; }
- (BOOL)prefersHomeIndicatorAutoHidden { return YES; }
- (BOOL)prefersStatusBarHidden { return YES; }

#pragma mark - Settings load / save / reset

- (void)loadSettings {
    self.fps = 60;
    self.opmode = 1;
    self.lang = 0;
    self.fpsCounter = NO;
    self.touchSwap = NO;
    self.aniso = -1;
    self.upscaling = NO;
    self.menubtnX = 0.93;
    self.menubtnY = 0.12;
    self.menuFps = 0;
    self.paceAdapt = YES;
    self.prepThreads = 0;
self.framebuf = YES;
    NSString *text = [NSString stringWithContentsOfFile:DmLauncherFile()
                                            encoding:NSUTF8StringEncoding error:nil];
    if (!text) return;
    NSString *v;
    if ((v = DmLauncherValue(text, @"fps"))) {
        if ([v isEqualToString:@"30"] || [v isEqualToString:@"60"]) {
            self.fps = v.integerValue;
        } else if ([v isEqualToString:@"120"]) {
            self.fps = 60;  // 旧设置里的 120 已删除，回落 60
        }
    }
    if ((v = DmLauncherValue(text, @"opmode")) && ([v isEqualToString:@"0"] || [v isEqualToString:@"1"])) {
        self.opmode = v.integerValue;
    }
    if ((v = DmLauncherValue(text, @"lang")) && [v isEqualToString:@"en"]) {
        self.lang = 1;
    }
    if ((v = DmLauncherValue(text, @"fps_counter"))) {
        self.fpsCounter = ![v isEqualToString:@"0"];
    }
    if ((v = DmLauncherValue(text, @"touch_swap"))) {
        self.touchSwap = ![v isEqualToString:@"0"];
    }
    if ((v = DmLauncherValue(text, @"framebuf"))) {
        self.framebuf = ![v isEqualToString:@"0"];
    }
    if ((v = DmLauncherValue(text, @"aniso"))) {
        if ([v isEqualToString:@"off"] || [v isEqualToString:@"1"]) self.aniso = 1;
        else if ([v isEqualToString:@"2"]) self.aniso = 2;
        else if ([v isEqualToString:@"4"]) self.aniso = 4;
        else if ([v isEqualToString:@"8"]) self.aniso = 8;
        else if ([v isEqualToString:@"16"]) self.aniso = 16;
        else self.aniso = -1;
    }
    if ((v = DmLauncherValue(text, @"upscaling"))) {
        self.upscaling = [v isEqualToString:@"on"] || [v isEqualToString:@"1"];
    }
    if ((v = DmLauncherValue(text, @"menubtn_x"))) {
        CGFloat f = v.doubleValue; if (f > 0.05 && f < 0.98) self.menubtnX = f;
    }
    if ((v = DmLauncherValue(text, @"menubtn_y"))) {
        CGFloat f = v.doubleValue; if (f > 0.02 && f < 0.98) self.menubtnY = f;
    }
    if ((v = DmLauncherValue(text, @"menu_fps"))) {
        // 只认 30 / 40 / 50 / 55 / 60 五个锁定档；0、follow 及其它值一律按跟随（0）。
        // Only the 30 / 40 / 50 / 55 / 60 locks are honoured; 0, "follow" and
        // anything else all mean follow (0).
        self.menuFps = ([v isEqualToString:@"30"] || [v isEqualToString:@"40"] || [v isEqualToString:@"50"] || [v isEqualToString:@"55"] || [v isEqualToString:@"60"]) ? v.integerValue : 0;
    }
    if ((v = DmLauncherValue(text, @"pace_adapt"))) {
        self.paceAdapt = ![v isEqualToString:@"0"];
    }
    if ((v = DmLauncherValue(text, @"shader_prep_threads"))) {
        // 只认 6 / 8 两档；0、缺省及其它值一律按缺省（不设环境变量）。
        // Only 6 / 8 are honoured; 0, missing and anything else mean Default
        // (the environment variable is left unset).
        self.prepThreads = ([v isEqualToString:@"6"] || [v isEqualToString:@"8"]) ? v.integerValue : 0;
    }
    }
    
- (void)saveSettings {
    // menubtn_x/y、menu_fps 一起写回：启动器保存不能把菜单里定的按钮位置和帧率锁定洗掉。
    // menubtn_x/y and menu_fps are written back too: a launcher save must not wipe
    // the menu-picked button position or the menu frame-rate lock.
    NSString *anisoStr = self.aniso == 1 ? @"off" : self.aniso == 2 ? @"2" : self.aniso == 4 ? @"4" : self.aniso == 8 ? @"8" : self.aniso == 16 ? @"16" : @"follow";
    NSString *text = [NSString stringWithFormat:
        @"fps=%ld\nopmode=%ld\nupscaling=%@\naniso=%@\nlang=%@\nfps_counter=%d\ntouch_swap=%d\nframebuf=%d\nmenubtn_x=%.3f\nmenubtn_y=%.3f\nmenu_fps=%ld\npace_adapt=%d\nshader_prep_threads=%ld\n",
        (long)self.fps, (long)self.opmode, self.upscaling ? @"on" : @"off", anisoStr,
        self.lang == 1 ? @"en" : @"zh",
        self.fpsCounter ? 1 : 0, self.touchSwap ? 1 : 0, self.framebuf ? 1 : 0,
        (double)self.menubtnX, (double)self.menubtnY, (long)self.menuFps, self.paceAdapt ? 1 : 0, (long)self.prepThreads];
    [text writeToFile:DmLauncherFile() atomically:YES
             encoding:NSUTF8StringEncoding error:nil];
}

// 重置：只重置启动器自己的十三个键，不删存档、不动游戏内其他设置。
// Reset: only the launcher's own thirteen keys, no save deletion, no other
// in-game custom settings touched.
- (void)resetSettings {
    self.fps = 60;
    self.opmode = 1;
    self.lang = 0;
    self.fpsCounter = NO;
    self.touchSwap = NO;
    self.aniso = -1;
    self.upscaling = NO;
    self.menubtnX = 0.93;
    self.menubtnY = 0.12;
    self.menuFps = 0;
    self.paceAdapt = YES;
    self.prepThreads = 0;
self.framebuf = YES;
    [self saveSettings];
[self refreshControls];
}

// 只在点 Play 时调用：把宿主需读的键同步进 sw_custom.txt 与环境变量。
// Called only on Play: sync the host-read keys into sw_custom.txt and env.
- (void)syncToHost {
    [self saveSettings];
    setenv("DM_OPMODE", self.opmode == 1 ? "1" : "0", 1);
    setenv("DM_LANG", self.lang == 1 ? "en-US" : "zh-Hans", 1);
    setenv("DM_FPS_COUNTER", self.fpsCounter ? "1" : "0", 1);
    // 自适应节拍：开 = 出图节拍按屏幕实际刷新率取整除档、屏幕变频（LTPO）时保持
    // 帧周期不变；关 = 现状。hle_nvn.c 的 pace_adapt_enabled 首帧定节拍时读一次
    // 并缓存，所以必须 Play 前写、这里正合适。显式写 "0" 而不是不设：与引擎的
    // 读法（*e == '1' 才开）对齐，也防外部环境里混进来的同名变量。
    // Adaptive pacing: on = present pacing takes integer divisors of the actual
    // screen refresh rate and holds the frame period across LTPO refresh changes;
    // off = current behaviour. hle_nvn.c reads it once when the first frame fixes
    // the pacing baseline and caches it, so it must be written before Play --
    // exactly here. An explicit "0" (rather than leaving it unset) matches the
    // engine's read (*e == '1' means on) and overrides any stray inherited value.
    setenv("DM_PACE_ADAPT", self.paceAdapt ? "1" : "0", 1);
    // 着色器预热线程数：dm_shader_prep.m 的缺省 = 核数-2 并夹在 [2, 6]，环境变量
    // DM_SHADER_PREP_THREADS 给正数就原样用（不夹）。选 6 = 顶到缺省上限（核少的
    // 机器比缺省多，如 6 核机缺省 4）；选 8 = 超过缺省上限、首启预编更快，代价是
    // 那几分钟更吃 CPU / 发热。缺省档不设变量，保持引擎原行为。时序：prep 在
    // main.m 的 Play 回调里、host_start 之前才调 dm_shader_prep_begin 读这个变量，
    // syncToHost 在它之前跑，赶得上（仅壳包 DM_SHELL 有这个预编环节）。
    // Shader warm-up threads: dm_shader_prep.m's default is cores-2 clamped to
    // [2, 6]; a positive DM_SHADER_PREP_THREADS is used verbatim (unclamped).
    // 6 tops out the default cap (more than default on low-core devices, e.g.
    // 4 on a 6-core phone); 8 exceeds the cap and pre-compiles faster on first
    // launch, at the cost of more CPU / heat for those minutes. Default leaves
    // the variable unset, keeping the engine's own behaviour. Timing: prep reads
    // it in dm_shader_prep_begin, called from main.m's Play callback before
    // host_start -- after syncToHost runs (shell packages with DM_SHELL only).
    if (self.prepThreads > 0) {
        setenv("DM_SHADER_PREP_THREADS", [NSString stringWithFormat:@"%ld", (long)self.prepThreads].UTF8String, 1);
    } else {
        unsetenv("DM_SHADER_PREP_THREADS");
    }
    setenv("DM_ANISO", self.aniso == 1 ? "off" : self.aniso == 2 ? "2" : self.aniso == 4 ? "4" : self.aniso == 8 ? "8" : self.aniso == 16 ? "16" : "follow", 1);
    setenv("DM_MTLFX_SPATIAL", self.upscaling ? "1" : "0", 1);
setenv("DM_MAX_DRAWABLES", self.framebuf ? "3" : "2", 1);
setenv("DM_RT_AB", "0", 1); // 30+30 已从启动器删除，外推固定关闭
    // 诊断版：逐通道 GPU 计时，只记数据、不改画面；每 300 帧在日志里报前五，明细写 Documents/passgpu.txt。
    setenv("DM_NVN_PASSGPU", [DmLauncherDocuments() stringByAppendingPathComponent:@"passgpu.txt"].fileSystemRepresentation, 1);
    // 60 帧兜底（launcher-60fps-lock）：启动器选 60 时钉住 DM_FPS=60。
    // 原理：帧率目标的优先级是 菜单帧率锁定 > DM_FPS > 自定义页 eco_fps
    // （见 nvn_mtl.m 的 mtl_fps_target，它是唯一汇聚点）。DM_FPS 只压
    // 自定义页一头：钉住 60 后，菜单未锁定时（含选了跟随）即使自定义页
    // 把 eco_fps 改成 1，mtl_fps_target() 仍返回 60，link_sync() 就不会
    // 把显示节拍切到 30 Hz，front_ios.m 的 DmRateHint 也保持 60-60；
    // 但菜单里一旦锁定 30 / 40 / 60，就以菜单为准，DM_FPS 不再影响
    // 任何基线。选 30 时取消该变量，走原来的 eco_fps 路径。
    // 注意：这只去掉“软件主动降到 30”这一档；重场景下 GPU/CPU 本身跑不满
    // 16.7 ms 仍会掉帧，不能靠这段代码保证硬件不掉帧。
    // 60 fps fallback (launcher-60fps-lock): when the launcher selects 60,
    // pin DM_FPS=60. Precedence is menu frame-rate lock > DM_FPS > the
    // Custom page's eco_fps (see mtl_fps_target in nvn_mtl.m, the single
    // funnel). The pin only overrides the Custom page: with 60 pinned,
    // while the menu is unlocked (or set to follow) a later in-game
    // eco_fps=1 cannot pull the target back to 30, and link_sync() will
    // not switch the display link to 30 Hz. But once the menu locks
    // 30 / 40 / 60, the menu wins and DM_FPS no longer affects any
    // baseline. When 30 is selected, unset DM_FPS so the original
    // eco_fps path applies. This only removes the software drop to 30;
    // it cannot guarantee that heavy scenes still meet 16.7 ms on hardware.
    if (self.fps == 60) {
        setenv("DM_FPS", "60", 1);
    } else {
        unsetenv("DM_FPS");
    }
    // 菜单帧率锁定恢复：把上次在游戏内菜单里选的档（dm_launcher.txt 的
    // menu_fps，loadSettings 已读进 self.menuFps）写回运行期状态。这里是
    // Play 的同步阶段、宿主还没起，第一帧定节拍基线时就已经生效；
    // dm_menu_fps_set 是图形层的原子存储，宿主起来前后调用都安全。
    // 文件里没有 menu_fps 键时 menuFps 保持缺省 0 = 跟随，set(0) 后的
    // 运行期状态与现在完全没锁时一模一样，行为不变；存的是跟随档时
    // 同理，恢复后仍走 DM_FPS / eco_fps 的原优先级，不会被缺省 60 顶掉
    // 锁定语义（跟随本来就是不锁定）。
    // Restore the menu frame-rate lock: write the tier last picked in the
    // in-game menu (menu_fps in dm_launcher.txt, already loaded into
    // self.menuFps) back into the runtime state. This is the Play sync
    // phase, before the host starts, so the lock is in effect when the
    // first frame fixes the pacing baseline; dm_menu_fps_set is an atomic
    // store in the graphics layer and is safe to call before boot. With no
    // menu_fps key, menuFps stays at the default 0 (follow) and set(0)
    // leaves the runtime exactly as unlocked as today; a stored follow
    // restores as follow under the usual precedence, not as a 60 pin.
    dm_menu_fps_set((int)self.menuFps);
    NSString *path = [DmLauncherDocuments() stringByAppendingPathComponent:@"sw_custom.txt"];
    NSString *old = [NSString stringWithContentsOfFile:path
                                              encoding:NSUTF8StringEncoding error:nil] ?: @"";
    NSString *next = DmLauncherReplace(old, @{
        @"eco_fps": self.fps == 30 ? @"1" : @"0",
        @"lang": self.lang == 1 ? @"1" : @"0",
        @"touch_swap_above": self.touchSwap ? @"1" : @"0",
    });
    [next writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark - UI helpers

- (UIImage *)appIconImage {
    // 先按 CFBundleIcons 里登记的文件名取 AppIcon；取不到时返回 nil，调用方画占位。
    // Prefer the AppIcon file registered in CFBundleIcons; nil if unavailable.
    NSDictionary *icons = NSBundle.mainBundle.infoDictionary[@"CFBundleIcons"];
    NSArray *files = icons[@"CFBundlePrimaryIcon"][@"CFBundleIconFiles"];
    NSString *last = files.lastObject;
    if (last.length) {
        UIImage *img = [UIImage imageNamed:last];
        if (img) return img;
    }
    return [UIImage imageNamed:@"AppIcon"];
}

- (UILabel *)labelWithText:(NSString *)text size:(CGFloat)size bold:(BOOL)bold color:(UIColor *)color {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = bold ? [UIFont systemFontOfSize:size weight:UIFontWeightBold]
                  : [UIFont systemFontOfSize:size weight:UIFontWeightRegular];
    l.textColor = color;
    l.numberOfLines = 0;
    return l;
}

// 一行：左侧标题 + 副标题，右侧控件；分隔线由布局时补在行底。
// One row: title + subtitle on the left, control on the right; the
// separator line is placed at the row bottom during layout.
- (UIView *)rowWithTitle:(NSString *)title
                subtitle:(NSString *)subtitle
                 control:(UIView *)control {
    UIView *row = [[UIView alloc] init];
    UILabel *t = [self labelWithText:title size:14 bold:YES color:UIColor.labelColor];
    UILabel *s = [self labelWithText:subtitle size:11 bold:NO color:UIColor.secondaryLabelColor];
    [row addSubview:t];
    [row addSubview:s];
    if (control) [row addSubview:control];
    UIView *sep = [[UIView alloc] init];
    sep.backgroundColor = UIColor.separatorColor;
    [row addSubview:sep];
    // 子视图顺序固定为：标题、副标题、控件（可选）、分隔线。
    // Subview order is fixed: title, subtitle, control (optional), separator.
    return row;
}

// 可点开的下拉按钮：系统 UIMenu 弹出框自带半透明玻璃效果；标题带 ▾，
// 表示可以点开。注意：不要用静态 UILabel 冒充下拉。
// Tappable dropdown button: the system UIMenu popup is translucent glass
// by itself; the title carries a ▾ so it reads as tappable, never a
// static label pretending to be a dropdown.
- (UIButton *)dropdownButtonWithTitle:(NSString *)title menu:(UIMenu *)menu {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:[NSString stringWithFormat:@"%@ ▾", title] forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [b setTitleColor:[UIColor colorWithRed:0.10 green:0.45 blue:0.95 alpha:1.0] forState:UIControlStateNormal];
    b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    b.menu = menu;
    b.showsMenuAsPrimaryAction = YES;
    return b;
}

- (UIMenu *)fpsMenu {
    __weak typeof(self) weakSelf = self;
    UIAction *a30 = [UIAction actionWithTitle:@"30 帧" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; s.fps = 30; [s saveSettings]; [s refreshControls];
    }];
    UIAction *a60 = [UIAction actionWithTitle:@"60 帧" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; s.fps = 60; [s saveSettings]; [s refreshControls];
    }];
    a30.state = self.fps == 30 ? UIMenuElementStateOn : UIMenuElementStateOff;
    a60.state = self.fps == 60 ? UIMenuElementStateOn : UIMenuElementStateOff;
    return [UIMenu menuWithTitle:@"" children:@[a30, a60]];
}

- (UIMenu *)opmodeMenu {
    __weak typeof(self) weakSelf = self;
    UIAction *dock = [UIAction actionWithTitle:@"底座" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; s.opmode = 1; [s saveSettings]; [s refreshControls];
    }];
    UIAction *hand = [UIAction actionWithTitle:@"掌机" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; s.opmode = 0; [s saveSettings]; [s refreshControls];
    }];
    dock.state = self.opmode == 1 ? UIMenuElementStateOn : UIMenuElementStateOff;
    hand.state = self.opmode == 0 ? UIMenuElementStateOn : UIMenuElementStateOff;
    return [UIMenu menuWithTitle:@"" children:@[dock, hand]];
}

- (UIMenu *)langMenu {
    __weak typeof(self) weakSelf = self;
    UIAction *zh = [UIAction actionWithTitle:@"简体中文" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; s.lang = 0; [s saveSettings]; [s refreshControls];
    }];
    UIAction *en = [UIAction actionWithTitle:@"English" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; s.lang = 1; [s saveSettings]; [s refreshControls];
    }];
    zh.state = self.lang == 0 ? UIMenuElementStateOn : UIMenuElementStateOff;
    en.state = self.lang == 1 ? UIMenuElementStateOn : UIMenuElementStateOff;
    return [UIMenu menuWithTitle:@"" children:@[zh, en]];
}

- (UIMenu *)anisoMenu {
    __weak typeof(self) weakSelf = self;
    NSArray<NSNumber *> *vals = @[@(-1), @(1), @(2), @(4), @(8), @(16)];
    NSArray<NSString *> *names = @[@"跟随游戏", @"关", @"2x", @"4x", @"8x", @"16x"];
    NSMutableArray<UIAction *> *acts = [NSMutableArray array];
    for (NSUInteger i = 0; i < vals.count; i++) {
        NSNumber *v = vals[i];
        UIAction *a = [UIAction actionWithTitle:names[i] image:nil identifier:nil handler:^(__kindof UIAction *act) {
            typeof(self) s = weakSelf; if (!s) return; s.aniso = v.integerValue; [s saveSettings]; [s refreshControls];
        }];
        a.state = self.aniso == v.integerValue ? UIMenuElementStateOn : UIMenuElementStateOff;
        [acts addObject:a];
    }
    return [UIMenu menuWithTitle:@"" children:acts];
}

- (UIMenu *)upscaleMenu {
    __weak typeof(self) weakSelf = self;
    UIAction *on = [UIAction actionWithTitle:@"开" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; s.upscaling = YES; [s saveSettings]; [s refreshControls];
    }];
    UIAction *off = [UIAction actionWithTitle:@"关" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        typeof(self) s = weakSelf; if (!s) return; s.upscaling = NO; [s saveSettings]; [s refreshControls];
    }];
    on.state = self.upscaling ? UIMenuElementStateOn : UIMenuElementStateOff;
    off.state = self.upscaling ? UIMenuElementStateOff : UIMenuElementStateOn;
    return [UIMenu menuWithTitle:@"" children:@[on, off]];
}

- (NSString *)upscaleTitle {
    return self.upscaling ? @"开" : @"关";
}

// 着色器预热线程数下拉：0 缺省 / 6 / 8（存的值就是线程数，0 = 不设环境变量）。
// Shader warm-up threads dropdown: 0 Default / 6 / 8 (the stored value is the
// thread count; 0 = the environment variable is left unset).
- (UIMenu *)prepThreadsMenu {
    __weak typeof(self) weakSelf = self;
    NSArray<NSNumber *> *vals = @[@(0), @(6), @(8)];
    NSArray<NSString *> *names = @[DmLauncherUI("dmLauncherPrepAuto", @"缺省"), DmLauncherUI("dmLauncherPrep6", @"6 线程"), DmLauncherUI("dmLauncherPrep8", @"8 线程")];
    NSMutableArray<UIAction *> *acts = [NSMutableArray array];
    for (NSUInteger i = 0; i < vals.count; i++) {
        NSNumber *v = vals[i];
        UIAction *a = [UIAction actionWithTitle:names[i] image:nil identifier:nil handler:^(__kindof UIAction *act) {
            typeof(self) s = weakSelf; if (!s) return; s.prepThreads = v.integerValue; [s saveSettings]; [s refreshControls];
        }];
        a.state = self.prepThreads == v.integerValue ? UIMenuElementStateOn : UIMenuElementStateOff;
        [acts addObject:a];
    }
    return [UIMenu menuWithTitle:@"" children:acts];
}

- (NSString *)prepThreadsTitle {
    if (self.prepThreads == 6) return DmLauncherUI("dmLauncherPrep6", @"6 线程");
    if (self.prepThreads == 8) return DmLauncherUI("dmLauncherPrep8", @"8 线程");
    return DmLauncherUI("dmLauncherPrepAuto", @"缺省");
}

- (NSString *)anisoTitle {
    switch (self.aniso) {
        case 1: return @"关";
        case 2: return @"2x";
        case 4: return @"4x";
        case 8: return @"8x";
        case 16: return @"16x";
        default: return @"跟随游戏";
    }
}

// 刷新所有控件的显示值（下拉标题 + 菜单勾选 + 开关），不改已存的设置。
// Refresh all control displays (dropdown titles + menu checkmarks +
// switches) without changing the persisted settings.
- (void)refreshControls {
    [self.fpsButton setTitle:[NSString stringWithFormat:@"%@ ▾", self.fps == 30 ? @"30 帧" : @"60 帧"] forState:UIControlStateNormal];
    self.fpsButton.menu = [self fpsMenu];
    [self.opmodeButton setTitle:[NSString stringWithFormat:@"%@ ▾", self.opmode == 1 ? @"底座" : @"掌机"] forState:UIControlStateNormal];
    self.opmodeButton.menu = [self opmodeMenu];
    [self.langButton setTitle:[NSString stringWithFormat:@"%@ ▾", self.lang == 1 ? @"English" : @"简体中文"] forState:UIControlStateNormal];
    self.langButton.menu = [self langMenu];
    [self.anisoButton setTitle:[NSString stringWithFormat:@"%@ ▾", [self anisoTitle]] forState:UIControlStateNormal];
    self.anisoButton.menu = [self anisoMenu];
    [self.upscaleButton setTitle:[NSString stringWithFormat:@"%@ ▾", [self upscaleTitle]] forState:UIControlStateNormal];
    self.upscaleButton.menu = [self upscaleMenu];
    [self.prepButton setTitle:[NSString stringWithFormat:@"%@ ▾", [self prepThreadsTitle]] forState:UIControlStateNormal];
    self.prepButton.menu = [self prepThreadsMenu];
    self.fpsCounterSwitch.on = self.fpsCounter;
    self.touchSwapSwitch.on = self.touchSwap;
    self.paceAdaptSwitch.on = self.paceAdapt;
    [self refreshMemory];
}

// Memory available：Play 前只能显示本进程余量 / 设备总内存，不能显示
// 游戏 Metal 占用（那时图形层还没起，读出来是 0，会误导）。
// Memory available: before Play only the per-process headroom / device
// total can be shown; game Metal usage cannot (the graphics layer has
// not started yet, so it would read 0 and mislead).
- (void)refreshMemory {
    if (!self.memoryValueLabel) return;
    double availGB = (double)os_proc_available_memory() / (1024.0 * 1024.0 * 1024.0);
    double totalGB = (double)NSProcessInfo.processInfo.physicalMemory / (1024.0 * 1024.0 * 1024.0);
    self.memoryValueLabel.text = [NSString stringWithFormat:@"%.2f GB", availGB];
    self.memorySubtitleLabel.text = [NSString stringWithFormat:
        @"Play 前读数：本进程余量；设备总内存 %.0f GB", totalGB];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadSettings];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    // ---- 左侧：图标 / 名字 / 版本 / Play ----
    // Left: icon / name / version / Play.
    UIImage *icon = [self appIconImage];
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.layer.cornerRadius = 18;
    iconView.clipsToBounds = YES;
    iconView.backgroundColor = UIColor.systemGray5Color;
    iconView.contentMode = UIViewContentModeScaleAspectFill;
    if (icon) {
        iconView.image = icon;
    } else {
        UILabel *fallback = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 96, 96)];
        fallback.text = @"D2R";
        fallback.textAlignment = NSTextAlignmentCenter;
        fallback.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
        fallback.textColor = UIColor.labelColor;
        [iconView addSubview:fallback];
    }
    iconView.tag = 101;
    [self.view addSubview:iconView];

    NSString *name = NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"];
    if (![name isKindOfClass:NSString.class] || !name.length) name = @"D2R Mobile";
    UILabel *nameLabel = [self labelWithText:name size:26 bold:YES color:UIColor.labelColor];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.tag = 102;
    [self.view addSubview:nameLabel];

    NSString *shortVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    NSString *build = NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"];
    NSString *version = [NSString stringWithFormat:@"Version %@",
                         [shortVersion isKindOfClass:NSString.class] && shortVersion.length ? shortVersion : @"-"];
    if ([build isKindOfClass:NSString.class] && build.length) {
        version = [version stringByAppendingFormat:@" (%@)", build];
    }
    UILabel *versionLabel = [self labelWithText:version size:14 bold:NO color:UIColor.secondaryLabelColor];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.tag = 103;
    [self.view addSubview:versionLabel];

    self.playButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    self.playButton.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    [self.playButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.playButton.backgroundColor = [UIColor colorWithRed:0.10 green:0.45 blue:0.95 alpha:1.0];
    self.playButton.layer.cornerRadius = 24;
    self.playButton.tag = 104;
    [self.playButton addTarget:self action:@selector(playTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playButton];

    // ---- 右侧：半透明玻璃面板 + 设置列表（可滚动） ----
    // Right: translucent glass panel + settings list (scrollable).
    // UIVisualEffectView + SystemMaterial 就是半透明毛玻璃材质；面板本身
    // 不用死白实色，透过它能看到底色并带模糊。
    self.rightGlass = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]];
    self.rightGlass.layer.cornerRadius = 20;
    self.rightGlass.clipsToBounds = YES;
    self.rightGlass.tag = 105;
    [self.view addSubview:self.rightGlass];

    self.rightScroll = [[UIScrollView alloc] init];
    self.rightScroll.backgroundColor = UIColor.clearColor;
    self.rightScroll.delaysContentTouches = NO;   // 列表里的开关要能立刻拖动：默认延迟下发 + 滚动手势取消会让拖开关被列表抢走
    [self.rightGlass.contentView addSubview:self.rightScroll];
    self.rightContent = [[UIView alloc] init];
    [self.rightScroll addSubview:self.rightContent];

    self.fpsButton = [self dropdownButtonWithTitle:self.fps == 30 ? @"30 帧" : @"60 帧" menu:[self fpsMenu]];
    self.opmodeButton = [self dropdownButtonWithTitle:self.opmode == 1 ? @"底座" : @"掌机" menu:[self opmodeMenu]];

    // 超分：MetalFX Spatial 真开关（launcher-metalfx-spatial，Metal 4 scaler API 已核对）。
    // 开：底座降至掌机分辨率渲染、scaler 放大到全屏；掌机：出图尺寸不变，只把线性放大换成 Spatial。
    // Upscaling: a real MetalFX Spatial switch (Metal 4 scaler API verified).
    // On: docked renders at handheld height and the scaler upscales to fullscreen; handheld keeps
    // its output size and only swaps the linear upscale for Spatial.
    self.upscaleButton = [self dropdownButtonWithTitle:[self upscaleTitle] menu:[self upscaleMenu]];

    self.langButton = [self dropdownButtonWithTitle:self.lang == 1 ? @"English" : @"简体中文" menu:[self langMenu]];
    self.anisoButton = [self dropdownButtonWithTitle:[self anisoTitle] menu:[self anisoMenu]];
    self.prepButton = [self dropdownButtonWithTitle:[self prepThreadsTitle] menu:[self prepThreadsMenu]];

    self.fpsCounterSwitch = [[UISwitch alloc] init];
    self.fpsCounterSwitch.on = self.fpsCounter;
    [self.fpsCounterSwitch addTarget:self action:@selector(fpsCounterChanged:) forControlEvents:UIControlEventValueChanged];

    self.touchSwapSwitch = [[UISwitch alloc] init];
    self.touchSwapSwitch.on = self.touchSwap;
    [self.touchSwapSwitch addTarget:self action:@selector(touchSwapChanged:) forControlEvents:UIControlEventValueChanged];
    self.framebufSwitch = [[UISwitch alloc] init];
    self.framebufSwitch.on = self.framebuf;
    [self.framebufSwitch addTarget:self action:@selector(framebufChanged:) forControlEvents:UIControlEventValueChanged];
    self.paceAdaptSwitch = [[UISwitch alloc] init];
    self.paceAdaptSwitch.on = self.paceAdapt;
    [self.paceAdaptSwitch addTarget:self action:@selector(paceAdaptChanged:) forControlEvents:UIControlEventValueChanged];
    self.memoryValueLabel = [self labelWithText:@"— GB" size:16 bold:YES color:UIColor.labelColor];
    self.memoryValueLabel.textAlignment = NSTextAlignmentRight;

    // 设置行：副标题写清真实含义，不抄 Hades 的 1080p / 标准超分。
    // Settings rows: subtitles state the real meaning; Hades' 1080p and
    // standard-upscaling labels are NOT copied.
    UIView *memoryRow = [self rowWithTitle:@"Memory available" subtitle:@"Play 前读数" control:self.memoryValueLabel];
    // 内存行的副标题要随读数更新，所以记下它（行里副标题是 subviews[1]）。
    self.memorySubtitleLabel = memoryRow.subviews[1];

    NSArray<UIView *> *rows = @[
        [self rowWithTitle:@"帧率" subtitle:@"高负载下可能因温控降频，请谨慎选择" control:self.fpsButton],
        [self rowWithTitle:@"主机模式" subtitle:@"底座：约 900p 高；掌机：约 720p 高；高负载下可能因温控降频" control:self.opmodeButton],
        [self rowWithTitle:@"超分" subtitle:@"开：底座降分辨率渲染再放大；掌机只换放大算法" control:self.upscaleButton],
        [self rowWithTitle:@"各向异性" subtitle:@"远处地面与墙面斜看时的清晰度；开高会多吃一点 GPU" control:self.anisoButton],
[self rowWithTitle:@"帧缓冲" subtitle:@"开=三缓冲（现状）；关=双缓冲，延迟低一点" control:self.framebufSwitch],
        [self rowWithTitle:DmLauncherUI("dmLauncherPaceAdapt", @"自适应节拍") subtitle:DmLauncherUI("dmLauncherPaceAdaptHint", @"出图节拍按屏幕刷新率整除对齐，帧周期更稳") control:self.paceAdaptSwitch],
        [self rowWithTitle:DmLauncherUI("dmLauncherPrepThreads", @"着色器预热线程") subtitle:DmLauncherUI("dmLauncherPrepThreadsHint", @"首次启动预编着色器时的并行数；越高编得越快，也越吃 CPU 和发热") control:self.prepButton],
    [self rowWithTitle:@"游戏语言" subtitle:@"游戏内文本语言" control:self.langButton],
        [self rowWithTitle:@"帧数计数器" subtitle:@"左上角显示实时帧数" control:self.fpsCounterSwitch],
        [self rowWithTitle:@"按键" subtitle:@"传送门位置：关=传送门左侧，开=技能区上方；完整键位请进游戏后在 Options 里调" control:self.touchSwapSwitch],
        memoryRow,
    ];
    for (UIView *row in rows) [self.rightContent addSubview:row];

    // 重置：单独的玻璃卡片按钮 + 副标题（Hades 图里也是单独一卡）。
    // Reset: its own glass-card button + subtitle, as in the Hades shot.
    UIView *resetCard = [[UIView alloc] init];
    resetCard.tag = 999;
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [resetButton setTitle:@"重置启动器设置" forState:UIControlStateNormal];
    resetButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [resetButton setTitleColor:[UIColor colorWithRed:0.10 green:0.45 blue:0.95 alpha:1.0] forState:UIControlStateNormal];
    resetButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.35];
    resetButton.layer.cornerRadius = 12;
    [resetButton addTarget:self action:@selector(resetTapped) forControlEvents:UIControlEventTouchUpInside];
    [resetCard addSubview:resetButton];
    UILabel *resetSub = [self labelWithText:@"只重置启动器自己的设置，不删存档、不动游戏内其他设置" size:13 bold:NO color:UIColor.secondaryLabelColor];
    [resetCard addSubview:resetSub];
    [self.rightContent addSubview:resetCard];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshMemory];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect b = self.view.bounds;
    UIEdgeInsets safe = self.view.safeAreaInsets;
    CGFloat leftW = 280;
    CGFloat leftX = safe.left + 24;
    CGFloat gap = 24;
    CGFloat rightX = leftX + leftW + gap;
    CGFloat rightW = b.size.width - rightX - safe.right - 24;
    if (rightW < 280) rightW = 280;

    UIView *iconView = [self.view viewWithTag:101];
    iconView.frame = CGRectMake(leftX + (leftW - 96) / 2, b.size.height / 2 - 130, 96, 96);
    for (UIView *v in iconView.subviews) v.frame = iconView.bounds;
    UIView *nameLabel = [self.view viewWithTag:102];
    nameLabel.frame = CGRectMake(leftX, CGRectGetMaxY(iconView.frame) + 12, leftW, 34);
    UIView *versionLabel = [self.view viewWithTag:103];
    versionLabel.frame = CGRectMake(leftX, CGRectGetMaxY(nameLabel.frame) + 4, leftW, 20);
    self.playButton.frame = CGRectMake(leftX + 20, CGRectGetMaxY(versionLabel.frame) + 20, leftW - 40, 48);

    self.rightGlass.frame = CGRectMake(rightX, safe.top + 16, rightW, b.size.height - safe.top - safe.bottom - 32);
    self.rightScroll.frame = self.rightGlass.contentView.bounds;
    CGFloat y = 16;
    CGFloat contentW = rightW - 32;
    for (UIView *row in self.rightContent.subviews) {
        if (row.tag == 999) {
            // 重置卡片：按钮整行 + 副标题在下。
            UIButton *btn = row.subviews[0];
            UILabel *sub = row.subviews[1];
            btn.frame = CGRectMake(0, 0, contentW, 44);
            CGFloat subH = [sub sizeThatFits:CGSizeMake(contentW, CGFLOAT_MAX)].height;
            sub.frame = CGRectMake(0, 48, contentW, subH);
            CGFloat rowH = 48 + subH + 8;
            row.frame = CGRectMake(16, y, contentW, rowH);
            y += rowH + 12;
            continue;
        }
        UILabel *title = row.subviews[0];
        UILabel *subtitle = row.subviews[1];
        UIView *control = row.subviews.count > 2 ? row.subviews[2] : nil;
        UIView *sep = row.subviews.lastObject;
        CGFloat controlW = 0, controlH = 0;
        if (control) {
            [control sizeToFit];
            // 下拉按钮的 sizeToFit 会按标题算宽；开关是固定 51x31。
            controlW = MIN(control.bounds.size.width, contentW * 0.55);
            controlH = control.bounds.size.height;
            if ([control isKindOfClass:UIButton.class]) controlH = MAX(controlH, 30);
        }
        CGFloat textW = controlW > 0 ? contentW - controlW - 12 : contentW;
        title.frame = CGRectMake(0, 0, textW, 22);
        CGFloat subH = [subtitle sizeThatFits:CGSizeMake(textW, CGFLOAT_MAX)].height;
        subtitle.frame = CGRectMake(0, 24, textW, subH);
        CGFloat rowH = 24 + subH + 12;
        if (control) {
            control.frame = CGRectMake(contentW - controlW, (rowH - 12 - controlH) / 2, controlW, controlH);
            if (controlH > rowH - 12) rowH = controlH + 12;
        }
        if (sep != control) sep.frame = CGRectMake(0, rowH - 0.5, contentW, 0.5);
        row.frame = CGRectMake(16, y, contentW, rowH);
        y += rowH + 12;
    }
    self.rightContent.frame = CGRectMake(0, 0, rightW, MAX(y, self.rightScroll.bounds.size.height));
    self.rightScroll.contentSize = CGSizeMake(rightW, y);
}

#pragma mark - Actions

- (void)fpsCounterChanged:(UISwitch *)sender {
    self.fpsCounter = sender.on;
    [self saveSettings];
}

- (void)framebufChanged:(UISwitch *)sender {
    self.framebuf = sender.on;
    [self saveSettings];
}

- (void)paceAdaptChanged:(UISwitch *)sender {
    self.paceAdapt = sender.on;
    [self saveSettings];
}

- (void)touchSwapChanged:(UISwitch *)sender {
    self.touchSwap = sender.on;
    [self saveSettings];
}

- (void)resetTapped {
    [self resetSettings];
}

- (void)playTapped {
    UIWindowScene *scene = self.view.window.windowScene;
    BOOL wantOverlay = self.fpsCounter;
    [self syncToHost];
    if (self.onPlay) self.onPlay();
    BOOL assetFallback = NO;
    if (scene) {
        for (UIWindow *w in scene.windows) {
            if (w.windowLevel == UIWindowLevelNormal) {
                NSString *rootName = NSStringFromClass(w.rootViewController.class);
                if ([rootName containsString:@"Asset"]) assetFallback = YES;
            }
        }
    }
    if (wantOverlay && scene && !assetFallback) [DmFpsOverlayShared() startWithScene:scene];
    // 游戏内菜单：与帧数浮层同款安装时机（根视图已换成游戏视图、非 AssetVC 回落时），平时只留一个小悬浮按钮。
    // In-game menu: same install timing as the FPS overlay (game root view installed, no AssetVC fallback);
    // normally only the small floating button is visible.
    if (scene && !assetFallback) [DmGameMenuShared() startWithScene:scene];
}

@end
