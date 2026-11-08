// 「自定义」设置：我们自己加的功能的启停开关，统一在这里读写。各模块只调 dm_custom_get，不各自读文件 / 环境变量当设置。
// 「自定义」(Custom) settings: on/off switches for the features we added ourselves, all read and written here. Each module only calls dm_custom_get and does not read files / environment variables as settings on its own.
#pragma once

// 已生效的值 0 / 1：只在玩家点选项页「应用」后变，「放弃」不变，「默认」= 各键缺省（省电模式关，其余开）。键不认识返回 1。
// 任意线程可调：第一次调用读一次文件，之后只是原子量读 + 几项字符串比较，无锁。iOS 上启动期（存档挂上之前）就能读。
// 键：auto_mana 自动喝药水（红蓝两种，键名沿用）/ drop_light 高价值掉落光柱 / map_mark 小地图标注出入口、小站与任务终点 / pot_pick 药水自动拾取（dm_potpick.c）/ drop_haptic 高价值掉落震动（dm_drophaptic.c） / gem_pick 符文宝石自动拾取进高级仓库（百宝囊）/ store_btn 背包「存放」按钮（dm_pouch.c）/ eco_fps 省电模式 30 帧（nvn_mtl.m，缺省关）/ vfx 特效档位 0 低 1 中 2 高（nvn_mtl.m，缺省中）
// item_notes（物品注释）/ icloud（iCloud 同步）两行已从自定义页删除（都不能点「应用」立刻生效）：键不再进键表，dm_custom_get 对不认识的键返回 1 = 两者保持缺省开（物品注释覆盖层变体由 main.m 启动时按此挑、iCloud 同步照常开）；lang / voice 两行同样删页，但文件里已有的选择仍解析（见 dm_custom_lang_explicit / dm_custom_voice_explicit）
// touch_swap_above：0 = 传送门左侧（默认），1 = 技能区上方；点「应用」后生效。
// Effective value 0 / 1: changes only after the player taps Apply on the options page; Discard leaves it unchanged; Default = each key's default (power-saving mode off, the rest on). Returns 1 for an unknown key.
// Callable from any thread: the first call reads the file once, after that it is an atomic read plus a few string comparisons, lock-free. On iOS it can be read during startup (before the save is mounted).
// Keys: auto_mana auto-drink potions (red and blue; key name kept) / drop_light light beam on high-value drops / map_mark minimap markers for entrances and exits, waypoints and quest goals / pot_pick potion auto-pickup (dm_potpick.c) / drop_haptic haptics on high-value drops (dm_drophaptic.c) / gem_pick auto-pickup of runes and gems into the advanced stash (pouch) / store_btn the inventory Deposit button (dm_pouch.c) / eco_fps power-saving mode at 30 fps (nvn_mtl.m, off by default) / vfx effects tier 0 low 1 medium 2 high (nvn_mtl.m, medium by default)
// The item_notes / icloud rows were removed from the Custom page (neither takes effect on Apply): the keys are no longer in the key table, and dm_custom_get returns 1 for unknown keys, so both stay at their default on; the lang / voice rows were removed from the page too, but values already in the file are still parsed (see dm_custom_lang_explicit / dm_custom_voice_explicit)
// touch_swap_above: 0 = left of portal (default), 1 = above the skill fan; applies after Apply.
int dm_custom_get(const char *key);
int dm_custom_lang_explicit(void);   // 语言开关（键 lang）在设置文件里写着的值：-1 没写过（不动原版设置）/ 0 中文 / 1 English / 2 Español / 3 Русский / 4 한국어 / 5 Português；hle_fs.c 挂存档时读 | Value of the language switch (key lang) as written in the settings file: -1 never written (original settings left alone) / 0 Chinese / 1 English / 2 Spanish / 3 Russian / 4 Korean / 5 Portuguese; read by hle_fs.c at save mount
int dm_custom_voice_explicit(void);   // 单独配音开关（键 voice）：-1 没写过 / 0 中文配音 / 1 英文配音；hle_fs.c 挂存档时读
// q3d 3D 画质（缺省 0 = 流畅优先：掉帧自动降 3D 比例；1 = 画质优先：不自动降），读盘 / 应用时调 hle_oe.c 的 dm_3d_quality_mode_set 生效
// q3d 3D quality (default 0 = smoothness first: automatically lowers the 3D scale on frame drops; 1 = quality first: no automatic lowering); applied on load / apply by calling hle_oe.c's dm_3d_quality_mode_set
int dm_fps_setting(void);   // 省电模式（键 eco_fps，缺省关）：开 = 30 帧、关 = 60；nvn_mtl.m mtl_fps_target 读 | Power-saving mode (key eco_fps, off by default): on = 30 fps, off = 60; read by mtl_fps_target in nvn_mtl.m
int dm_vfx_level(void);   // 特效档位（键 vfx）：0 低（泛光降质 + 关 FXAA）/ 1 中（缺省，原行为）/ 2 高（泛光全质量）；nvn_mtl.m 每帧读（弱符号的强定义，同 dm_fps_setting） | Effects tier (key vfx): 0 low (reduced bloom + FXAA off) / 1 medium (default, original behavior) / 2 high (full-quality bloom); read every frame by nvn_mtl.m (strong definition of a weak symbol, like dm_fps_setting)
void dm_custom_set_immediate(const char *key, int value);   // 游戏内菜单（LauncherVC.m）用：没有「应用」一步，选中即改生效值、走同一套回调（q3d → dm_3d_quality_mode_set、cam → dm_cam_set_mode）并存盘，与自定义页共用同一份 g_val / sw_custom.txt | For the in-game menu (LauncherVC.m): there is no Apply step; selecting writes the effective value at once, goes through the same callbacks (q3d -> dm_3d_quality_mode_set, cam -> dm_cam_set_mode) and saves, sharing the same g_val / sw_custom.txt with the Custom page

void dm_custom_init(const char *dir);   // 设置文件所在目录（iOS 外壳启动时给 Documents）；不调则用存档提交目录的上一级（Mac 宿主） | Directory holding the settings file (the iOS shell passes Documents at startup); if not called, the parent of the save commit directory is used (Mac host)

// 以下只给自定义页的界面接线用
// The following are only for the UI wiring of the custom page
void dm_custom_on_uimsg(const char *cat, const char *act, const char *arg);   // 选项页应用 / 默认 / 放弃（dm_cursor.c 的界面消息回调转来） | Options page apply / default / discard (forwarded from the UI message callback in dm_cursor.c)
void dm_custom_ui_pump(unsigned long long root);                               // 游戏主线程每帧：选项页开着时读各行勾选框（控件名 TouchCustom_<键>） | Game main thread, every frame: while the options page is open, read the checkbox of each row (widget name TouchCustom_<key>)
