// D2R Mobile 启动器（第 1 步，launcher-v1）。
// LauncherVC (step 1, launcher-v1).
//
// 只做启动器界面 + 设置存盘 + 点 Play 时同步启动期设置；不碰游戏管线。
// It only shows the launcher UI, persists launcher settings, and syncs the
// launch-time settings on Play. It does not touch the game pipeline.
//
// 与 main.m 的 AssetVC 同风格：纯 UIKit，不用 SwiftUI。
// Same style as AssetVC in main.m: plain UIKit, no SwiftUI.
//
// Play 的职责划分：
//  - LauncherVC：把设置写进 Documents/dm_launcher.txt，并在点 Play 时把
//    宿主需读的键同步进 Documents/sw_custom.txt 与环境变量；
//  - main.m（SceneDelegate 的 Play 回调）：把 g_launcher_played 置位、把根视图
//    换成游戏视图、再调 host_start()（内部先 romfs_locate() 资源校验，
//    没过回 AssetVC，不闪退）。
// Play responsibility split:
//  - LauncherVC: writes Documents/dm_launcher.txt, and on Play syncs the
//    host-read keys into Documents/sw_custom.txt and the environment;
//  - main.m (SceneDelegate's Play callback): marks the launcher as played,
//    swaps the root view to the game view, then calls host_start() (which
//    first runs romfs_locate(); on failure it falls back to AssetVC).
//
// 界面（launcher-hades-ui）：Hades 风格，左侧图标/名字/版本/大蓝色 Play，
// 右侧半透明玻璃面板 + 可点开的下拉（UIMenu），帧率只留 30/60（120 已删）。
// 帧数显示已接通：Play 后由 LauncherVC 装左上角浮层（出图计数 + 温控）。
// 游戏内菜单（launcher-spatial-menu）：Play 后再装一个悬浮小按钮，点开是半透明
// 玻璃小面板（分辨率 / 帧率 / 各向异性 / 超分 / FPS 显示 / 主机模式 / 帧缓冲 / 游戏语言 / 传送门位置），
// 前五项改完立刻生效（超分开关只开关 scaler，底座降分辨率是启动时定的），后四项重启游戏后生效。
// 各向异性启动器里也有（初始值），游戏内菜单运行中可改。
// 本文件不实现：运行中主机模式切换；运行中改超分开关不改出图尺寸。
// UI (launcher-hades-ui): Hades style, left icon/name/version/large blue
// Play, right translucent glass panel + tappable dropdowns (UIMenu),
// frame rate 30/60 only (120 removed). The FPS overlay is wired: after
// Play, LauncherVC installs a top-left overlay (present count + thermal).
// In-game menu (launcher-spatial-menu): after Play a small floating button is
// installed; it opens a compact translucent glass panel (resolution / frame rate /
// anisotropy / upscaling / FPS display / host mode / frame buffer / language / portal position);
// the first five apply immediately (the upscaling switch only toggles the scaler; the docked
// resolution drop is set at launch); the last four take effect on restart.
// Anisotropy is also in the launcher (initial value); the in-game menu changes it live.
// Not implemented here: switching host mode while the game is running; changing the upscaling
// switch live does not change the output size.

#import <UIKit/UIKit.h>

@interface LauncherVC : UIViewController

// 点 Play 时由 main.m 设置的回调；LauncherVC 本身不直接起宿主。
// Callback set by main.m on Play; LauncherVC itself never starts the host.
@property (nonatomic, copy) void (^onPlay)(void);

// 与 DmGameVC / AssetVC 相同的全屏声明，见实现文件。
// Same full-screen declarations as DmGameVC / AssetVC, see the .m file.
- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures;
- (BOOL)prefersHomeIndicatorAutoHidden;
- (BOOL)prefersStatusBarHidden;

@end
