#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif
// 原生毛玻璃设置面板（DmGlassSettings.m）的入口接线。
// Entry points of the native frosted-glass settings panel (DmGlassSettings.m).
//
// 本分支（custom/v230-port）的实际入口 = 游戏内菜单（LauncherVC.m 的 DmGameMenuController）
// 最后一行「设置 → 打开」：菜单把自己的根视图当宿主调 dm_glass_present，面板关掉后
// 用 dm_glass_shade_view 拿遮罩视图（菜单根视图的 hitTest 靠它放行面板区域的触摸）。
// In this branch the live entry is the last row of the in-game menu (DmGameMenuController
// in LauncherVC.m): the menu passes its own root view as host to dm_glass_present and
// afterwards fetches the shade via dm_glass_shade_view (the menu root view's hitTest
// uses it to let touches through to the panel).
void dm_glass_present(UIView *host);
// 面板当前开着时的全屏遮罩（面板是它的子视图）；关着返回 nil。
// The full-screen shade while the panel is open (the panel is its subview); nil when closed.
UIView *dm_glass_shade_view(void);
// 以下两个是 main 线原件的接线，原样保留与原件一致；本分支没有往 DmTouchOverlay 上挂钩子
//（build 线以游戏内菜单为入口）：install 在覆盖层挂上父视图后调一次（在父视图 DmMetalView
// 右上角加半透明「设置」小按钮，重复调不重复加）；sync_hidden 是覆盖层显隐同步（藏时按钮
// 一起藏、面板顺手关掉）。
// The two below are the original main-line wiring, kept identical to the original;
// this branch does not hook DmTouchOverlay (the in-game menu is the entry): install is
// called once the overlay joins its superview (adds a translucent Settings button at
// the top right of the parent DmMetalView; repeated calls do not stack), and
// sync_hidden mirrors the overlay's visibility (hiding the button and closing the panel).
#ifdef __cplusplus
}
#endif
