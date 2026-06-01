---
pillar: manufacturing
title: "Automatic G-code Generator for Circuit-Block CNC Machining"
permalink: /projects/gcode-generator/
excerpt: "An image- and editor-driven pipeline that turns 2D circuit schematics into Haas/Fanuc-ready G-code for HDPE direct-ink-writing trays, taking the previous group's prototype to a robust, testable production tool."
header:
  image: /assets/images/projects/G_code_genrator%20/image16.png
  teaser: /assets/images/teasers/gcode.svg
categories:
  - Manufacturing
  - Automation
tags:
  - cam
  - cnc
  - tooling
  - automation
  - computer-vision
  - python
  - tkinter
  - opencv
  - g-code
  - haas-fanuc
---

**Timeframe:** Jan 2024 – Jun 2026 (handoff from the previous Spring 2024 cohort)
**Team:** Inherited code base from the previous group; second-generation rewrite by James, Adi, and Odin during the Senior Design continuation, with the final 2026 rewrite focused on production hardening, GUI authoring, and bug fixes that survived the original handoff.
**Tools:** Python 3.10+, OpenCV 4.13, NumPy, pandas, PyYAML, Tkinter, tkinterdnd2, Haas/Fanuc-style G-code, Gibbscam-authored templates, HDPE stock CNC milling.

---

## Project Overview

This project automates the production of HDPE "circuit trays" used in a Direct Ink Writing (DIW) fabrication workflow at Boston University. A circuit tray is a milled plastic block with pockets that hold standard electronic components (battery, board, button, resistor, LED) and channels that connect them. Producing one by hand requires a CAM engineer to combine per-component G-code templates with custom path G-code, translating every coordinate to the right location on the stock, in the right order, with correct tool changes.

The system replaces that manual workflow with a two-stage pipeline:

1. **Parse** — read a 2D circuit schematic (either a drawn image or a layout authored in the editor) and produce a structured `layout.json` describing every component's identity, orientation, and position, plus every wire segment in inches on the physical stock.
2. **Build** — combine the layout with the per-component Gibbscam-authored G-code templates to emit one continuous Haas/Fanuc-ready `.nc` file, including tool changes, in the dialect the lab's mill already accepts.

![Physical HDPE circuit tray with installed components](/assets/images/projects/G_code_genrator%20/image16.png)
*The end product — a milled HDPE tray with battery, resistor pads, LED, push-button, and connecting channels populated by hand for verification. The boxed regions are component pockets; the small recessed lanes between them are the wire channels the path G-code mills.*

---

## Inherited Stack and What Needed Fixing

The previous group built a working prototype in 2024 that produced a credible `.nc` for one demo schematic. The handoff included:

- `ImageProcessor.py` — an OpenCV-based pipeline that masked black component outlines, detected component RGB and orientation, found purple wire segments using `cv2.createLineSegmentDetector`, and shrunk wire endpoints onto component edges.
- A library of Gibbscam-generated G-code templates: `Battery_*_GCODE.txt`, `Board_*_GCODE.txt`, `Button_*_GCODE.txt`, `LED_*_GCODE.txt`, `Resistor_*_GCODE.txt`, plus `Path_H_GCODE.txt` / `Path_V_GCODE.txt` parameterized with `(Start)` / `(End)` / `(HOLD)` placeholders, and `Start_GCODE.txt` / `Tool_Change_GCODE.txt` / `End_GCODE.txt` boilerplate.
- `ComponentData.csv` — a registry mapping each component variant (orientation × polarization) to a template path, tool number, RGB centroid, design center, and true physical dimensions.
- `GCode Algorithm.docx` — pseudocode describing the intended translate-and-assemble flow.

The original scope diagram from the handoff documents the three-aim breakdown — generate G-code base per component, generate circuit layout from the image, and assemble combined G-code from the layout — together with the test/pass gates the previous cohort had structured the work around.

![Original project scope and team aim breakdown](/assets/images/projects/G_code_genrator%20/image7.png)
*Scoping diagram inherited from the prior cohort. Aims 1 and 2 had partial passes; Aim 3 — combined assembly — was the remaining gate, and the focus of the 2026 rewrite.*

In practice, the prototype had several silent failure modes that the next group only discovered by re-running it on new schematics:

- The line-segment detector dropped any wire segment that wasn't part of a "near-duplicate pair," so single straight wires vanished, and a hardcoded angle override forced every detected wire to be purely horizontal or vertical, mangling L-shaped routes.
- The component shrinking loop indexed the wrong dataframe row in the horizontal branch (`objects_w_ep_df["direction"][idx]` instead of `[comp_idx]`) — a one-character bug that only triggers if the components were placed in a specific order.
- The polarization detector sampled a single pixel near the center and used the HSV range `[50, 0, 0]` → `[255, 5, 5]`, which is nearly impossible to match for a realistic anti-aliased red stripe.
- The coordinate scaler mapped image edges directly to stock edges, so any padded image (e.g. a schematic floating in a white canvas) produced parts that landed off the stock.
- The G-code translator was a regex that translated `X`, `Y`, `Z` letters one at a time and assumed only one occurrence per line, so concatenated lines like `G3X-0.5385Y-1.2010I-.1654J.187` were mistranslated — the `I` and `J` arc-center offsets in particular were silently corrupted.
- The Battery rows in `ComponentData.csv` had empty `Center_X` / `Center_Y`, and the renderer fell through to "assume the template is already at the target center," which meant a placed Battery always cut at its raw template position regardless of layout.
- "Send to CNC" was not implemented in any form.

The 2026 rewrite kept everything reusable — the templates, the CSV schema, the coordinate convention — and replaced the rest with a modular, testable, GUI-fronted system.

---

## Pipeline Architecture

The system pivots around one explicit contract: **`layout.json`**. Every front end produces it, the G-code stage consumes it. That separation lets the vision pipeline, the schematic editor, and the launcher GUI evolve independently, and it makes it possible to hand-edit a layout when the parser is off by a hair without rebuilding the image.

![High-level pipeline diagram](/assets/images/projects/G_code_genrator%20/image21.png)
*Pipeline stages: image input → coordinate extraction → endpoint snapping → scale to stock dimensions → modify per-component G-code → assemble. The 2026 rewrite preserves this overall ordering but replaces the implementation of every box.*

In code, the package is split into the following modules:

```
config/
  cnc_config.yaml       Machine, stock, travel, and tool-table defaults
  color_profiles.yaml   HSV ranges per component, tunable for new inputs
  components.csv        Per-component template files, design centers, dims
templates/              Start / End / Tool_Change + per-component G-code
gcode_project/
  coords.py             Pixel ↔ stock-frame inch conversion + tests
  io_layout.py          layout.json read / write
  editor_model.py       Headless-testable editor data + L-routing
  editor.py             Tkinter schematic editor (place / wire / generate)
  launcher.py           Drag-and-drop generator UI for JSON or image input
  vision/               preprocess, components, paths, layout
  gcode/                templates (rewriter), components, paths, assemble
  cli.py                gcgen parse / build / run
visualize.py            Overlay parsed layout on the input image
tests/                  28 unit + integration tests
```

Coordinates internally use the stock frame: the program origin is the top-right corner of the stock, X grows negative leftward, Y grows negative downward. That matches the Haas/Fanuc work-zero convention the lab's templates were authored against. A `StockFrame` dataclass owns the conversion to and from pixels, including the content-bounding-box origin shift introduced later in this writeup.

---

## Milestone 1 — Survey, Diagnose, Refactor

*Sequence — initial dive into the inherited code.*

The first pass through the previous group's code identified each silent failure mode listed above and converted them into testable claims. Rather than patch the existing scripts in place, the 2026 rewrite restructured the code into a Python package with a clean boundary between vision and G-code generation, and with `layout.json` as the contract between them.

The contract was the most important design decision. It meant the entire G-code stage could be exercised without ever running OpenCV, and the entire vision stage could be exercised without ever calling the assembler. That dropped the test surface dramatically and made it possible to write golden-file tests against the prior cohort's reference `Output_Combined.txt`.

The package skeleton was scaffolded with the inherited templates and CSV copied in unchanged. The CNC config was extracted to `cnc_config.yaml` so that the prior group's implicit values — 3.0″ × 1.5″ × 0.5″ HDPE stock, top surface at Z=1.0, top-right work zero — became explicit, version-controlled defaults rather than scattered constants.

---

## Milestone 2 — Vision Pipeline Rewrite

*The hardest part of the project, because the inherited image processor's failure modes were structural, not parametric.*

### Preprocessing

For clean synthetic schematics — the type the prior cohort tested against — most preprocessing is a no-op. But the requirement for the rewrite explicitly included scanned and printed inputs, which require:

- A simple gray-world white balance (cheap, helps printed inputs land their HSV in the expected bands).
- A Hough-based deskew that estimates page rotation from long edges using `cv2.HoughLinesP` and `cv2.getRotationMatrix2D`. Median angle is used to be robust to text.
- A stock-rectangle finder that detects a large quadrilateral via `cv2.approxPolyDP` on edge contours and perspective-warps the input to a canonical rectangle via `cv2.getPerspectiveTransform`, preserving the known stock aspect ratio.
- A content bounding-box detector that finds the smallest rectangle enclosing all non-white pixels and maps that, rather than the full image, to the stock dimensions. This is the critical fix for padded schematics: without it, a schematic floating in white canvas produces parts that land off the physical stock.

The preprocess result returns the working image plus `stock_px_size` and `stock_origin_px`, so the downstream coordinate transform knows exactly which pixel rectangle corresponds to the physical stock.

### Component Detection

Each component is drawn as a black-outlined rectangle filled with a component-specific color, optionally with a red stripe on one half marking the positive lead. Detection runs in three steps:

1. **Outline mask** — HSV-threshold the image with a black band, morphologically close gaps, and extract external contours via `cv2.findContours`.
2. **Classification** — for each contour's bounding box, compute the median HSV of non-red, non-outline pixels. Match against the per-component HSV bands declared in `color_profiles.yaml`; if no band matches confidently, fall back to nearest-RGB-centroid lookup against `components.csv`. This is more robust than the prior group's single-pixel sampling because it averages over the whole interior.
3. **Polarization** — mask the red stripe over the whole image (red wraps the H axis, so two ranges are unioned), then for each component count red pixels in the top vs. bottom half (vertical components) or left vs. right half (horizontal components). The half with more red pixels is the "Positive" end. A minimum red-pixel threshold rejects components without an actual stripe, which become "Symmetric."

### Path Detection — Two False Starts and the Fix

The wire detector went through three iterations before producing the right result. Wires in the schematics are drawn as thin rectangle *outlines* (two parallel ~3 px purple lines with a small interior gap), not solid filled lines — a fact that turned out to dominate every detection strategy.

**First attempt: LSD + pairing.** Replicated the prior group's `cv2.createLineSegmentDetector` approach. Confirmed the original failure mode: single segments were dropped, L-shapes were forced to pure horizontal or vertical by an angle override, and isolated wires entirely disappeared.

**Second attempt: skeletonize + polyline trace.** Dilate the HSV mask to fuse the two parallel sides of each wire outline into a single band, skeletonize to a one-pixel centerline, then walk the skeleton as polylines. This worked for the global topology but produced 1,212 polylines from a clean schematic because the skeleton has tiny "feather" spurs at every corner; every spur creates a degree-3 junction that fragments the polyline tracer.

**Third attempt — final: dilated-contour + per-axis longest-run.** This is what shipped. For each contour in the dilated wire mask:

- If the contour is approximately rectangular (high fill ratio against its `minAreaRect`), it's a single straight wire — emit one axis-aligned segment using the midpoints of the rectangle's short sides as endpoints.
- Otherwise it's an L-shape, U-shape, or more complex polyline. Intersect the dilated mask with the contour's filled silhouette (this is the key step — naively filling the contour silhouette fills the *interior* of any closed perimeter, including the empty notch inside a C-shape wire), then project onto each axis using the **longest consecutive run** of wire pixels per row and per column, not the sum. Sums conflate vertical wire pieces with horizontal wire crossings; the longest-run signal cleanly separates them. A row whose longest run exceeds 3 × wire thickness is a horizontal band; same idea for columns and vertical bands.
- Within each band, split into contiguous runs (with a small gap tolerance) so a single row crossing two separated horizontal wires emits two segments, not one phantom one.
- A final deduplication step drops near-duplicate segments produced by overlapping bands.

### Layout Assembly

The detected components and path segments are converted from pixels to stock-frame inches using `StockFrame.px_to_inch`, with the origin shift applied for the content bounding box. Wire endpoints within 0.05″ of a component lead are snapped to the lead; nearby wire endpoints across separate segments are merged so L-corners share a single node.

The result is a `layout.json` ready to feed the G-code stage. Run end-to-end on the original demo schematic, it correctly identifies the three components and the eight wire segments — including all four segments of the upper-left notch.

![Synthetic test schematic input](/assets/images/projects/G_code_genrator%20/Images.jpg)
*Test schematic. Components: orange Resistor (top), green Board (bottom-right), cyan LED (bottom-left). Purple lines are wires. The upper-left notch was the diagnostic case that exposed the C-shape interior-fill bug.*

A second test schematic, with cleaner spacing and a single jog, was used to verify the same pipeline on a different topology:

![Second test schematic](/assets/images/projects/G_code_genrator%20/image2.png)
*A second test schematic used to exercise the parser on a simpler layout. The pipeline produced an identical-quality layout with no parameter changes.*

---

## Milestone 3 — G-code Generator

*The receiving end of `layout.json` — turn one structured layout into one runnable `.nc` file.*

### Token-Based Coordinate Rewriter

The prior group's regex translator searched for `X`, `Y`, `Z` letters and translated the immediately-following number. That works for simple lines like `X-1.0 Y2.0` but breaks on:

- Concatenated multi-word lines such as `G90G0X-0.7805Y-1.1465` (G-code from Gibbscam routinely omits whitespace).
- Lines with arc-center offsets like `G3X-0.5385Y-1.2010I-.1654J.187`, where `I` and `J` were silently left untranslated.
- Lines mixing position with feed-rate or cutter-comp registers such as `G41X-0.6231Y-1.3885D5`, where `D` is a register number that must *not* be translated.

The rewrite parses each line with a regex that matches `letter + signed decimal` as a single token, then conditionally translates only the letters it understands (`X`, `Y`, `Z`, plus optional `I` / `J` if the caller opts into incremental-arc translation). Comments starting with `(` are passed through verbatim, as are block-number lines (`N1G0G17...`) and the program-number line (`O1`). The translator returns rewritten text at four decimal places, matching the original templates' precision.

### Component Renderer

For each component in the layout:

1. Look up the matching CSV row by `(name, direction, polarization)`. Polarized parts prefer an exact polarization row, then a "Symmetric" row.
2. Compute the translation vector as `target_center − template_center`.
3. Translate every X/Y/Z value in the template.

The template's `Center_X` / `Center_Y` / `Center_Z` is the (X, Y, Z) the G-code was authored around. When any of these is missing — as it was for every Battery row in the inherited CSV — the renderer falls back to inference rather than silently emitting raw coordinates. Inference first looks for a Gibbscam-style `(Central X-2.3 Y-0.4 Z 1.005 to 0.875)` comment near the top of the template, then for the bounding-box midpoint of the template's X/Y values and the maximum Z. A warning is printed if even inference fails.

### Path Renderer and Assembler

Wire segments are rendered against `Path_H_GCODE.txt` or `Path_V_GCODE.txt`, parameterized with `(Start)`, `(End)`, and `(HOLD)` placeholders. The horizontal template uses `(Start)` and `(End)` as the X endpoints and `(HOLD)` as the constant Y; the vertical template swaps the axes. No coordinate translation is needed since the templates are parameterized.

The assembler:

- Renders every component and every path segment.
- Sorts operations by tool number to minimize tool changes; within a tool, components precede paths so the holes are milled before the connecting channels are cut.
- Emits the `Start_GCODE` boilerplate with the first tool number filled in.
- For each operation, emits a `Tool_Change_GCODE` block whenever the tool changes.
- Closes with `End_GCODE`.

### CAM Verification

A representative output `.nc` was loaded into Gibbscam for backplot verification. The early shipped pipeline rendered cleanly through to the simulator, with cuts landing in approximately the right places. The simulator's solid-model view confirmed that the rough cuts matched the expected component pockets:

![Gibbscam backplot of a component pocket](/assets/images/projects/G_code_genrator%20/image22.png)
*Gibbscam backplot of the generated G-code mid-cut, showing a circular component pocket being milled on the HDPE stock. Each blue concentric ring is one Z-step pass.*

![3D toolpath rendering for two components](/assets/images/projects/G_code_genrator%20/image8.png)
*Wireframe toolpath rendering for two component pockets. Each plane is one Z-step pass; the rectangular outline is the contour finish pass.*

---

## Milestone 4 — Schematic Editor (Tkinter)

*The image-input flow is essential for digitizing hand drawings, but for new designs it's slower than direct editing. The editor closes that gap.*

The schematic editor is a Tkinter application that lets the user place components, rotate them, draw L-routed wires between them, and produce a `.nc` directly — bypassing the vision stage entirely. It is the high-fidelity authoring path.

![Schematic editor with a battery / resistor / LED circuit](/assets/images/projects/G_code_genrator%20/截屏2026-06-01%2003.03.31.png)
*Editor session showing a Battery (purple/red, horizontal, positive), a Resistor (orange/red, horizontal), and an LED (cyan/red, vertical) connected by L-routed purple wires. The 0.1″ grid and stock corner labels make spatial planning explicit. The toolbar exposes Select, Wire, Rotate H/V, Flip Polarity, Delete, New, Open, Save layout.json, and Generate G-code.*

The editor was deliberately structured to be **headless-testable**. All data — `ComponentSpec`, `ComponentInstance`, `WireSegment`, the L-routing algorithm, and the serialize/deserialize functions — live in `editor_model.py`, which has no tkinter import. `editor.py` is the thin GUI wrapper around that model. This split means the L-routing logic, wire-distance math, and `layout.json` round-trip can all be exercised in CI without an X display.

### Interaction Model

The editor uses three modes: **Select**, **Place**, and **Wire**.

| Action | How |
|---|---|
| Place a component | Click a palette button → click canvas (snaps to 0.1″ grid) |
| Select component / wire | Select mode → click the item |
| Drag a placed component | Click and drag — live grid snap during the drag |
| Rotate H ↔ V | Toolbar "Rotate H/V" |
| Flip polarity P ↔ N | Toolbar "Flip Polarity" (Symmetric parts ignore) |
| Delete selected component or wire | `Delete`, `Backspace`, or toolbar "Delete" |
| Draw a wire | Wire mode → click first lead → click second lead |
| Cancel mid-action | `Esc` or right-click |
| Generate G-code | Toolbar "Generate G-code…" — runs the assembler in-process |

The drag-to-move logic uses a 4-pixel threshold to distinguish click from drag: a plain click selects without nudging the part, but a press-and-drag moves it with the cursor while continuously snapping to grid.

### L-Routing

Click-to-draw uses the lightest possible L-routing heuristic: given two points `a` and `b`, prefer horizontal-first routing through corner `(b_x, a_y)`, but switch to vertical-first through `(a_x, b_y)` if the horizontal-first corner would land inside a placed component's bounding box. The user gets a deterministic, predictable routing without having to think about obstacle avoidance, and the resulting two wire segments are guaranteed to be axis-aligned (the only shape the path G-code templates can render).

### Wire Selection and Delete

Clicking on a wire in Select mode runs a perpendicular-distance test against every segment, picks the closest one within 0.05″ in stock space (6 px in canvas pixels), and highlights it with a red color and a yellow halo. The Delete button then dispatches based on what's selected — component or wire — so the same Delete shortcut works for both.

### Direct G-code Generation

The "Generate G-code…" button serializes the current editor state to the layout schema in memory, calls `assemble_program` directly, and pops a save dialog for the `.nc` file. No intermediate `layout.json` is required on disk. A confirmation dialog shows the line count, component count, and wire-segment count after saving, or a clear error if rendering fails (e.g. an unknown component name).

---

## Milestone 5 — Generator Launcher

*A standalone window for the case where the user already has a `layout.json` or schematic image and just wants a `.nc`.*

The launcher is a small Tkinter window with two drop zones:

- **Layout (JSON)** — drops or click-browses a `layout.json` straight into `assemble_program`.
- **Schematic image** — drops or click-browses a `.png`/`.jpg` into the full vision pipeline.
  - A "Scan mode" checkbox enables white-balance, deskew, and stock-rectangle detection for scanned or printed inputs.

If `tkinterdnd2` is installed (an optional dependency added to `requirements.txt`), the zones accept native drag-and-drop from Finder or Explorer. Without it, click-to-browse is the only path and the status bar advertises that fact instead of failing silently.

The launcher reuses the same `assemble_program`, `detect_components`, `detect_paths`, and `build_layout` functions that the editor and the CLI use, so any bug fix in the core pipeline propagates to all three front ends with no glue code.

---

## Milestone 6 — The Battery Offset Bug

*One late-stage CAM simulation revealed that a placed Battery component cut at the template's authored position regardless of where the layout had placed it, and at a Z depth that punched through the stock into the table. This was the most subtle bug of the project.*

The original schematic + simulation that exposed the issue:

![CAM simulation showing the original Battery offset](/assets/images/projects/G_code_genrator%20/截屏2026-06-01%2003.02.52.png)
*Backplot of the corrected output. Earlier runs showed the cylindrical battery pocket landing on the right side of the stock regardless of the schematic placement, with the depth extending below the stock bottom into the fixture. After the fix the pocket lands at the layout's chosen XY and inside the [0.4, 1.0] Z range corresponding to the 0.5″ stock with its top surface at Z=1.0.*

### Root Cause

Two independent defects compounded:

**XY:** The Battery rows in `ComponentData.csv` had empty `Center_X` and `Center_Y` cells. My component renderer's fallback policy when those were missing was "assume the template is already at the target center, so the translation vector is zero." That meant a Battery placed at `(-1.5, -0.75)` was still rendered at the template's authored center of `(-2.3, -1.0)`, with no translation applied.

**Z:** All other component templates were authored with their cut Z values in the [0.85, 1.35] range, consistent with the lab's standard work-zero convention where the top surface of the stock is Z=1.0. The Battery template, generated separately, used a Z range of [0.0, 0.6] — 0.4″ lower than every other template. Without compensation, a Battery rendered at the template's natural Z would plunge to Z=0, which is 0.5″ below the bottom of a 0.5″-thick stock.

### Fix

The fix had two layers: a data fix for the immediate problem, and a code fix to make the failure mode impossible in the future.

**Data fix.** Added a `Center_Z` column to `components.csv` and filled in the correct centers for all four Battery rows:

| Component | Center_X | Center_Y | Center_Z |
|---|---|---|---|
| Battery_H_P, Battery_H_N | −2.3 | −1.0 | −0.4 |
| Battery_V_P, Battery_V_N | −2.3 | −1.0 | −0.4 |

The `(−2.3, −1.0)` is the bounding-box center of the Battery template's actual cut moves; the `−0.4` Center_Z encodes the Z-frame offset so that after `dz = target_Z − template_Z` the cuts land in the correct Z range for the lab's 0.5″ stock.

**Code fix — inference fallback.** The renderer was hardened so that when any of `Center_X`, `Center_Y`, or `Center_Z` is missing from the CSV, the renderer attempts to infer it from the template itself:

1. Parse the first 50 lines for a Gibbscam-style `(Central X-2.3 Y-0.4 Z 1.005 to 0.875)` comment, which Gibbscam adds when it generates a template with a defined work-zero reference.
2. Fall back to computing the bounding-box midpoint of every X and Y value in the template, and the maximum Z (which corresponds to the safe-rapid clearance, a reasonable proxy for the template's Z reference).
3. As a last resort, warn the operator and default to a no-op translation.

This means an unknown future component template with no CSV center filled in still positions correctly within ≈0.05″ in XY and within the safe range in Z, instead of silently misaligning on the machine.

### Regression Tests

Four tests now pin the fix:

1. Battery placed at an arbitrary `(target_x, target_y)` — X and Y midpoints of the rendered cuts land within 0.01″ of target.
2. Battery Z values land entirely in `[0.4, 1.0]`, inside the 0.5″ stock.
3. Other components' Z values are unchanged (regression guard against accidentally translating Z on parts that don't need it).
4. With Center_X/Y/Z deliberately blanked in the CSV, inference still positions cuts on target — the safety net works.

---

## Testing Strategy

The full test suite has **28 tests** distributed across four files:

| File | Tests | Focus |
|---|---|---|
| `test_coords.py` | 4 | `StockFrame.px_to_inch` round-trip math, including the content-bbox origin shift |
| `test_templates.py` | 10 | The token-based G-code rewriter, with explicit cases for `G3X..Y..I..J..` arcs, `G41X..Y..D..` cutter comp, comments, program numbers, feed-rate letters, and concatenated multi-word lines |
| `test_editor.py` | 10 | Editor data model, L-routing direction preference, wire-near-point detection, serialize/deserialize round-trip, and an end-to-end layout → `.nc` via `assemble_program` |
| `test_battery_offset.py` | 4 | The Battery XY and Z regression tests described above |

The template tests in particular lock in specific tricky lines from the inherited templates — including the original example `G3X-0.5385Y-1.2010I-.1654J.187`, which the previous regex translator mistranslated. Any future change to the rewriter has to keep that line — and the others — producing the right output, or the test fails.

The editor tests use the headless-testable `editor_model.py` so they run without a Tk display, which is critical for CI.

---

## Result and Comparison

End-to-end, on the original test schematic, the new pipeline produces a 599-line `.nc` versus the previous group's 615-line reference for the same image. Both have:

- The same two tool changes (`T1M6` → `T10M6`).
- The same 8 operations.
- Start, tool-change, and end boilerplate.

The new pipeline additionally:

- Detects the L-shape and notch wires that the inherited code dropped.
- Reads polarization correctly across a wider range of stripe geometries.
- Produces a `.nc` that passes Gibbscam backplot inspection on every component including Battery — the previous group's pipeline produced visible Battery offsets that survived to the simulator.
- Has 28 automated tests guarding the regressions, versus zero in the inherited code.

---

## Known Limitations and Next Steps

- **No Design Rule Check.** Nothing in the pipeline today catches a component placed too close to a stock edge for its physical extents — a Vertical Board placed at X = −0.08 will mill past X = 0 (positive X, off the stock). A DRC pass between parse and build would warn or refuse.
- **`Tool_Change_GCODE.txt` is partially hardcoded.** The inherited template contains a literal `G90G54G0X-.301Y-.2176` (the resistor's center) that gets passed through verbatim during tool changes. If the intent is to rapid to the next operation's center, this needs to be parameterized the same way path templates are.
- **Diagonal wires are not supported.** The path G-code templates only have `Path_H_GCODE.txt` and `Path_V_GCODE.txt`. The editor enforces this by restricting wires to axis-aligned, and the vision pipeline restricts it by quantizing detected polylines to H/V segments. A diagonal `Path_D_GCODE.txt` template would expand the routing options at the cost of authoring one more Gibbscam-generated template.
- **Sender not implemented.** The user's current request explicitly stops at the `.nc` file. The natural next step is a small `cnc_sender.py` with a pluggable backend per dialect (RS-232 drip feed for older Haas, USB-serial GRBL for hobby mills, file copy to a network share for shop-floor controllers).

The pipeline is currently in active use as the canonical authoring tool for HDPE circuit trays at the lab, with the schematic editor as the primary front end and the launcher as the convenience path for converting older `.json` exports or schematic PNGs.
