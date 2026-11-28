// 自适应出图的整数分档与线程CPU统计；不改变 nvn_pace.h 的 Apple「至少60」策略。
// Integer-divisor adaptive tiers and thread-CPU sampling; leaves nvn_pace.h's Apple "at least 60" policy unchanged.
#pragma once
#include <stdint.h>

static inline int nvn_adaptive_min_divisor(double hz) {
    double ratio = hz / 60.0;
    int k = (int)ratio;
    if (k < ratio) ++k;   // ceil：90Hz最高45帧，不能取floor而升到90。| ceil: at 90 Hz cap at 45 fps, never floor to 90.
    return k > 0 ? k : 1;
}
static inline int nvn_adaptive_max_divisor(double hz) {
    int k = (int)(hz / 20.0 + 0.02), lo = nvn_adaptive_min_divisor(hz);
    return k < lo ? lo : k;
}
static inline int nvn_adaptive_divisor(double hz, int current, double old_hz) {
    int lo = nvn_adaptive_min_divisor(hz), hi = nvn_adaptive_max_divisor(hz);
    int k = current > 0 ? current : lo;
    if (current > 0 && old_hz > 0 && hz != old_hz) k = (int)(current * hz / old_hz + 0.5);
    return k < lo ? lo : k > hi ? hi : k;
}

// 降档闸：单个 60 帧窗的错过数会被突发积压污染——换区收尾 / 流式加载 / 重锚纠正都会让出图队列
// 成批合并丢弃，稳态撑得住的档也能被一窗记满而误降（实测降档窗错过仅 7–10 帧、40 档预算
// 25 ms 而开销 16–21 ms 照样降）。故降档要两窗确认：首窗错过 ≥ 6 只开案；紧接着的下一窗
// 错过 ≥ 4 即确认降档（第二窗放宽，缩短真超载时的迟滞）；任何一窗错过 < 4 结案。
// 试升判失败仍用原口径，不经此闸。
// Step-down gate: a single 60-frame window's miss count is polluted by burst backlogs --
// zone-transition teardown / streaming loads / re-anchor corrections all make the present queue
// merge-drop frames in batches, so a tier that is sustainable in steady state can be voted down
// by one dirty window (measured: step-down windows at only 7-10 misses, and a step down out of
// the 40 tier whose 25 ms budget faced 16-21 ms of load). Stepping down therefore needs two
// windows: a first window with >= 6 misses only opens a case; the immediately following window
// with >= 4 misses confirms the step down (the relaxed second bar shortens the delay under
// genuine overload); any window with < 4 misses closes the case. Probe-up failure keeps its
// original rule and does not pass through this gate.
typedef struct { unsigned over_streak; } nvn_adaptive_dropgate;

static inline int nvn_adaptive_drop_verdict(nvn_adaptive_dropgate *g, unsigned misses) {
    if (misses >= 6) {
        if (g->over_streak) { g->over_streak = 0; return 1; }
        g->over_streak = 1; return 0;
    }
    if (misses >= 4 && g->over_streak) { g->over_streak = 0; return 1; }
    g->over_streak = 0; return 0;
}
static inline void nvn_adaptive_drop_reset(nvn_adaptive_dropgate *g) { g->over_streak = 0; }

// 输入必须是同一个线程的累计CPU纳秒；60帧窗与原图形负载统计一致，等待不会推进此时钟。
// Input is cumulative CPU nanoseconds of the same thread. The 60-frame window matches existing graphics load statistics; waits do not advance this clock.
typedef struct { uint64_t previous, sum; unsigned count; } nvn_frame_cpu_window;
static inline int nvn_frame_cpu_sample(nvn_frame_cpu_window *s, uint64_t cpu_ns, double *ms) {
    if (!s->previous || cpu_ns < s->previous) { s->previous = cpu_ns; s->sum = 0; s->count = 0; return 0; }
    s->sum += cpu_ns - s->previous; s->previous = cpu_ns;
    if (++s->count < 60) return 0;
    *ms = s->sum / 60000000.0; s->sum = 0; s->count = 0; return 1;
}
