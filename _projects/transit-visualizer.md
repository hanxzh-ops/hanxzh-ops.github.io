---
pillar: control-robotics
order: 5
title: "Real-Time Transit Map from a Once-Every-4-Minutes Signal — Predict/Correct State Estimation on a Rate-Limited Feed"
permalink: /projects/transit-visualizer/
excerpt: "A live PCB-style transit board that turns a 60-request/hour feed — real position fixes only every ~4.5 minutes — into smooth real-time motion, using an along-track α–β filter with an integral 'pace' feedback loop, schedule-paced prediction, and on-route geometry, all tuned against real rush-hour drift logs."
header:
  teaser: /assets/images/projects/Traffic%20Visualizer/Cover.webp
  image: /assets/images/projects/Traffic%20Visualizer/Cover.webp
categories:
  - Controls
tags:
  - controls
  - state-estimation
  - filtering
  - data-viz
---

**Timeframe:** Jul 2026  
**Tools:** State estimation (α–β filtering, integral feedback), GTFS-Realtime, Python (standard library only), vanilla JavaScript + Canvas, protobuf

## Project Overview
This project is a desktop widget that shows every BART train and AC Transit bus moving across the San Francisco Bay Area in real time — a dark "PCB board" where stations are dots, routes are colored traces, and each vehicle is a glowing dot in its official line color. The visualization is the easy half. The interesting engineering lives underneath, and it is a **control and estimation** problem: the public transit feed (511.org) hard-limits each API token to **60 requests per hour**, so genuine ground-truth position fixes arrive only about **once every 4–5 minutes**. Everything the eye reads as "live" in between those fixes is produced by a per-vehicle estimator that predicts motion from a model and corrects it when a real measurement finally arrives.

The whole system is deliberately dependency-light: a Python **standard-library** proxy (no framework, no `pip install`, including a hand-written GTFS-Realtime protobuf decoder) and a single **vanilla-JavaScript Canvas** front-end. That constraint kept the focus where it belonged — on the filtering.

<video controls muted loop playsinline width="100%" poster="/assets/images/projects/Traffic%20Visualizer/Cover.webp">
  <source src="/assets/images/projects/Traffic%20Visualizer/30secsLiveRunning.mp4" type="video/mp4">
</video>
*30-second screen recording at 4× speed — the live board during rush hour. Every dot is being predicted between the ~4.5-minute API fixes and corrected on each sync.*

## The Core Problem
Framed plainly: I have a **sampled signal** — vehicle positions — arriving at a period of roughly \(T_s \approx 270\text{ s}\), and I need to render continuous motion at 60 fps that (a) looks alive, (b) does not systematically run ahead of or behind reality, and (c) never teleports. That is a textbook predict/correct estimation setup, complicated by three things specific to transit:

1. The motion model is not free-flowing — vehicles accelerate, crawl in traffic, and **dwell at stations**.
2. The available "model" (the agency's own schedule) is **biased**: published arrival predictions are optimistic.
3. One entire mode (**BART**) broadcasts **no GPS at all** — only predicted stop times — so its trains must be reconstructed from the schedule and placed on the correct curved track.

The rest of this write-up walks through the architecture, the estimator math, and each problem I had to solve to get honest real-time behavior — validated against real logged data rather than by eye.

## System Architecture
The system splits into a proxy and a renderer, connected by a tiny JSON API.

```text
 browser widget  ──fetch──▶  local Python proxy  ──poll──▶  511 GTFS-Realtime
 (Canvas, vanilla JS)        (server.py, stdlib)            (your free token)
        ▲                          │  decode · normalize · cache
        └────── /api/vehicles ◀────┘  (decouples the 60 fps UI from the rate limit)
```

The proxy holds the API key, polls upstream on a rate-budgeted schedule, decodes and normalizes every feed into a single schema — `{vehicles, stops, lines}` — and serves it locally. The browser never talks to the transit API directly and never sees the key; it just polls the local cache every few seconds and runs the estimator per frame. This separation is what lets a 60-requests-per-hour source drive a 60-frames-per-second display.

### Dependency-free GTFS-Realtime
511 publishes vehicle positions and trip updates as **GTFS-Realtime protobuf**. Rather than pull in a protobuf library, I wrote a ~30-line wire-format reader — protobuf is just tag/length-delimited varints — which keeps the whole backend to the Python standard library:

```python
def _pb_read_varint(buf, i):
    shift = result = 0
    while True:
        b = buf[i]; i += 1
        result |= (b & 0x7F) << shift
        if not (b & 0x80):
            return result, i
        shift += 7

def _pb_fields(buf):
    """Yield (field_number, wire_type, value) for one protobuf message."""
    i, n = 0, len(buf)
    while i < n:
        key, i = _pb_read_varint(buf, i)
        fn, wt = key >> 3, key & 7
        if   wt == 0: val, i = _pb_read_varint(buf, i)          # varint
        elif wt == 2: ln, i  = _pb_read_varint(buf, i); val = buf[i:i+ln]; i += ln  # length-delimited
        elif wt == 5: val = buf[i:i+4]; i += 4                  # 32-bit
        elif wt == 1: val = buf[i:i+8]; i += 8                  # 64-bit
        else: return
        yield fn, wt, val
```

From there, `VehiclePositions` gives `{trip_id, route_id, lat, lon, bearing, timestamp}` and `TripUpdates` gives each trip's predicted per-stop arrival/departure times. Route colors, modes, and the line geometry come from the static GTFS (parsed once with `zipfile` + `csv` and cached to disk).

## The Estimator
The key modeling decision is dimensionality. A bus or train is a 2-D dot on screen, but it is really a **1-D object**: it moves *along its route*. So I estimate each vehicle in a single scalar coordinate — **distance along its route polyline**, \(s\) (meters) — and only project to latitude/longitude for drawing. This collapses a messy 2-D tracking problem into a clean 1-D one where "on the line" is guaranteed by construction and "ahead/behind" has an unambiguous sign.

The state is position and velocity along the route:

<div class="equation">
$$
\mathbf{x}_k = \begin{bmatrix} s_k \\ v_k \end{bmatrix}, \qquad s_k \in \mathbb{R}\ \text{(m along route)},\quad v_k \in \mathbb{R}\ \text{(m/s)}.
$$
</div>

### Correct step — the α–β filter
When a real fix \(z_k\) arrives (the measured along-route distance, obtained by snapping the reported GPS point onto the route polyline), I run a classic **α–β filter**. It first predicts forward with the current velocity, then splits the residual between a position correction (α) and a velocity correction (β):

<div class="equation">
$$
\hat{s}_k^{-} = \hat{s}_{k-1} + \hat{v}_{k-1}\,\Delta t_k, \qquad
r_k = z_k - \hat{s}_k^{-},
$$
</div>

<div class="equation">
$$
\hat{s}_k = \hat{s}_k^{-} + \alpha\, r_k, \qquad
\hat{v}_k = \hat{v}_{k-1} + \frac{\beta}{\Delta t_k}\, r_k .
$$
</div>

Because velocity is *directly observable* here — the displacement between two snapped fixes divided by the elapsed time is a clean velocity measurement — I let the β term blend toward that measured velocity rather than relying only on the position residual. That removes the structural over-speed within a couple of syncs. A subtle but important detail: a fix is applied to the filter **exactly once**. The browser polls the local cache every few seconds, but the real fix only changes every ~270 s; gating the update on the server-side timestamp prevents duplicate "measurements" from telling the filter the vehicle is standing still.

### Predict step — schedule-paced motion
Between fixes, a constant-velocity extrapolation is wrong in a very visible way: it doesn't slow into stops or pause at platforms. So instead of predicting with \(v\) alone, I predict along the **shape of the timetable**. Let \(\Sigma(t)\) be the schedule's cumulative along-route distance at wall-clock time \(t\) — piecewise-linear between successive stop ETAs, and *flat* across the arrival→departure dwell window. Then the displayed position advances as

<div class="equation">
$$
s(t) = s_0 + \rho \,\big[\, \Sigma(t) - \Sigma(t_0) \,\big],
$$
</div>

where \(\rho\) is a **pace** scalar (defined next). In code this is a two-line per-frame update — read the schedule's position now, advance by the schedule's increment scaled by pace:

```javascript
// every animation frame, between syncs:
const sNow = schedDistAt(v.sched, now);   // timetable's along-route distance at 'now'
const dS   = sNow - v.pSchedPrev;         // how far the schedule moved this frame
v.pSchedPrev = sNow;
v.ps += v.pace * dS;                      // advance at the *corrected* pace
```

This makes a vehicle accelerate, crawl, and dwell exactly where the timetable says it should — the motion *looks* like transit, not like a dot sliding at constant speed.

### Integral feedback — cancelling the schedule bias
The schedule shape is good, but its absolute *pace* is biased: agencies publish optimistic ETAs, so a vehicle covers less ground than the timetable claims. A pure predict/correct loop would fight this bias forever, re-snapping backward at every fix. The fix is an **integral feedback loop** that measures the bias and cancels it.

At each sync I compute the observed pace — the ratio of what actually happened to what the schedule predicted over the just-finished interval — and drive both a per-vehicle estimate and a slow **fleet-wide** integrator toward it:

<div class="equation">
$$
\rho_{\text{obs},k} = \frac{z_k - z_{k-1}}{\Sigma(t_k) - \Sigma(t_{k-1})}, \qquad
\rho_k = \rho_{k-1} + \beta_\rho\big(\rho_{\text{obs},k} - \rho_{k-1}\big), \qquad
\bar{\rho}_k = \bar{\rho}_{k-1} + \eta\big(\rho_{\text{obs},k} - \bar{\rho}_{k-1}\big).
$$
</div>

```javascript
// at each real fix (sync):
v.ps += ALPHA * (sMeas - v.ps);                       // (α) position correction
const dSched = schedDistAt(prevSched, v.t) - schedDistAt(prevSched, v.pSyncT);
const dAct   = sMeas - v.pSyncS;                       // measured displacement
const paceObs = dAct / dSched;                         // observed pace over the interval
v.pace      += BETA * (paceObs - v.pace);              // per-vehicle
GLOBAL_PACE += KI   * (paceObs - GLOBAL_PACE);         // fleet-wide integral
```

The fleet integrator \(\bar\rho\) is what makes the whole thing feel instantly correct: a brand-new vehicle is *seeded* with the learned fleet pace, so it starts de-biased instead of over-running for its first interval. There is one non-obvious trap I hit here: because the server's schedule track always *starts at the current fix*, computing "scheduled displacement over the last interval" against it returns zero — so I keep the **previous** interval's schedule (`prevSched`) to measure against. Getting that wrong silently disabled the entire correction; getting it right is what makes the loop converge.

Convergence in simulation, starting from a +100% seeded over-estimate at the real ~130 s cadence, drives the prediction error to near zero within about five syncs, and the pace settles within a few percent of truth.

## Validating with Real Data
I did not tune the gains by eye. I wrote a diagnostic probe (`drift_probe.py`) that polls the running widget and, at *every* real fix, logs how far each model's prediction had drifted from the newly arrived ground truth — split into velocity-model vs schedule-model and bus vs rail — along with the sync intervals. A 2.5-hour rush-hour run produced this:

![Drift summary over a 153-minute rush-hour run](/assets/images/projects/Traffic%20Visualizer/Drifiting%20Summary.png)
*Drift summary: 1,972 syncs across 179 vehicles. Median sync gap 270 s. The velocity model's signed drift is median +0 m (ratio 0.96×) — the systematic over-run is gone. The raw schedule model reads +98 m median, which the on-device pace loop (≈0.85) is what removes. The lone rail row shows the velocity model is useless for BART (−6,194 m, it predicts zero) while the schedule model tracks it — exactly why BART is schedule-driven.*

Two things fall straight out of this log. First, the **velocity over-run is genuinely cancelled** at the median (0.96×, +0 m) — the α–β plus integral is doing its job. Second, the schedule's raw +98 m optimism (measured directly here) is precisely the bias the pace loop is built to absorb; the ~0.85 pace I hard-measured from earlier logs is the number the fleet integrator converges to.

<div style="display:flex;gap:1rem;flex-wrap:wrap;">
  <img src="/assets/images/projects/Traffic%20Visualizer/Drifting_before.jpg" style="flex:1;min-width:280px;" alt="Board before the estimation fixes">
  <img src="/assets/images/projects/Traffic%20Visualizer/Drifting_After.jpg" style="flex:1;min-width:280px;" alt="Board after the estimation fixes">
</div>
*The live board before (left) and after (right) the estimation and geometry fixes — vehicles sit cleanly on their routes and fill the whole window rather than clustering or drifting off-line.*

## Problem: BART Has No GPS
BART does not broadcast train positions — the `VehiclePositions` feed is buses only. But BART *does* publish `TripUpdates` (predicted arrival/departure per stop). So for every active BART trip with no GPS vehicle, the widget **synthesizes a train** from the schedule: find where the predicted stop times place it right now, and animate it forward with the same schedule-paced loop (with a separate rail-fleet pace, since rail delay behaves differently from buses).

The first version placed the train by **linearly interpolating between the two bounding stations**. That is fine on straight track and catastrophic on curved track. On the Rockridge→Orinda segment — the curved Berkeley-hills tunnel — the straight chord between stations cuts kilometers off the real route. I measured it directly against the GTFS shape:

<div class="equation">
$$
\text{chord midpoint} = \tfrac{1}{2}(p_{\text{Rockridge}} + p_{\text{Orinda}}), \qquad
\operatorname{dist}\!\big(\text{chord midpoint},\, \gamma_{\text{Orange}}\big) \approx 4{,}362\ \text{m}.
$$
</div>

A train **4.36 km off its own track** — a bright "Metro / rail" dot floating in the hills east of campus where there is no metro at all:

![A synthesized BART train mis-placed off its route](/assets/images/projects/Traffic%20Visualizer/BARTLineMissmatch.jpg)
*The failure mode: a synthesized Yellow-line train (the large bright dot, right of center) placed on the straight chord between distant stations, landing far off the actual curved BART line.*

The fix is to interpolate along the route **shape**, not the chord. I parameterize the polyline by arc length \(\ell\), map each stop \(p_j\) to its arc-length position on the shape, interpolate arc length by time between the bounding stops, and evaluate the polyline there:

<div class="equation">
$$
\ell_j = \arg\min_{\ell}\, \big\lVert \gamma(\ell) - p_j \big\rVert, \qquad
\ell(t) = \ell_a + \frac{t - t_a}{t_b - t_a}\,(\ell_b - \ell_a), \qquad
\hat{p}(t) = \gamma\big(\ell(t)\big).
$$
</div>

In practice the server sends the *stops* (a window of the one just passed plus the upcoming ones), the client snaps them to the route shape, and the schedule-paced loop interpolates the along-shape distance. The same test point that was 4,362 m off the track drops to **8 m** — the train now rides the curve through the tunnel instead of floating over the hills.

## Route-Key Snapping
Snapping a point to the *nearest* line is wrong when routes share a corridor — a bus can grab an adjacent rail trace. So every route line and every vehicle carry a normalized **route key** (agency + GTFS route id / short name, matched to the realtime route id), and a vehicle is snapped only onto **its own route's** geometry. The route key is authoritative, so a rail vehicle locks to its line even when its synthesized point is far from the curve (the schedule then places it correctly); a vehicle whose own route has *no* geometry must be within ~70 m to borrow a foreign line, otherwise it dead-reckons — which stops a mistracked signal from gliding along an unrelated route.

## Living Within the Rate Budget
The 60-requests/hour ceiling shapes the whole backend. The proxy polls **one agency per cycle** (round-robin) with the interval sized so the token never 429s, decodes two GTFS-RT endpoints per agency, and caches the near-static feeds (route colors, stop coordinates, static shapes) to disk so they are fetched roughly once a day. A few smaller robustness details mattered for a clean display:

- **Screen-space fading, not range fading.** The viewport is a tall rectangle but "range" is a circle, so fading vehicles at the geographic radius made them blink out *in the middle* of a portrait window where that circle crosses. Vehicles are now fetched to ~2× the range (to fill the corners) and faded only within a pixel band of the true window edge.
- **A one-poll grace.** A vehicle missing from a single upstream poll (a feed hiccup, or a synthesized train briefly past its last known stop) is kept for ~1.5 round-robin cycles and keeps moving, rather than blinking out and back.
- **A per-frame step clamp and schedule rebaseline** to guarantee the dot can never teleport when a fresh schedule replaces the old one.

## Results
The end result turns a signal you can only actually *sample* every four and a half minutes into a display that reads as continuously live, without lying about it:

- The bus velocity model's systematic over-run is **cancelled at the median** (0.96× ratio, +0 m signed drift over ~2,000 real syncs).
- BART — which provides **no position data whatsoever** — is reconstructed from its schedule and placed on the correct curved geometry (a 4.36 km placement error reduced to ~8 m).
- The whole backend is **standard-library Python** (including the protobuf decoder) and the front-end is a single dependency-free Canvas page.

What made this project satisfying was that the hardest parts were not the visualization but the estimation discipline: choosing the right coordinate (1-D along-route), separating a good *shape* model from its biased *pace*, closing an integral loop to cancel that bias, and — crucially — **measuring** everything against logged ground truth instead of trusting that it looked right.

## Repository
- [GitHub Repository](https://github.com/hanxzh-ops/SF_Traffic_visualizer)

<script>
window.MathJax = {
  tex: { inlineMath: [['\\(','\\)']], displayMath: [['$$','$$']], processEscapes: true },
  options: { skipHtmlTags: ['script','noscript','style','textarea','pre','code'] }
};
</script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/3.2.2/es5/tex-mml-chtml.min.js" async></script>
