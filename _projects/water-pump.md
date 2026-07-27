---
pillar: mechanical-design
order: 5
title: "Food-Safe Rotary-Vane Water-Tower Pump — Design, DFM & Manufacturing Validation"
permalink: /projects/water-pump/
excerpt: "A food-safe rotary-vane water-tower pump taken from a quantified brief through CAD, FEA/CFD, a full ASME Y14.5 GD&T tolerance package, a cast-then-machined plan, and a built, leak-tested validation unit."
header:
  image: /assets/images/projects/water-pump/cover.jpg
  teaser: /assets/images/projects/water-pump/cover.jpg
categories:
  - Mechanical Design
  - Manufacturing
tags:
  - product-design
  - dfm
  - gd-and-t
  - tolerance-analysis
  - casting
  - cnc-machining
  - rotary-vane-pump
  - fea
  - cfd
  - solidworks
  - food-safe
  - documentation
---

**Timeframe:** Sep – Dec 2024 (Boston University product-realization & manufacturing course)
**Team:** Multi-person design team; this writeup describes the project end-to-end and flags my own contributions where relevant. My focus was the rotor / vane / sealing subsystem, the GD&T drawing package and tolerance stack-up, the cast-then-machine manufacturing plan, and the validation build and testing.
**Tools:** SolidWorks (CAD + Simulation FEA + Flow Simulation CFD), ASME Y14.5 GD&T, sand/investment casting, 3-axis CNC milling and turning, micrometer / pin-gauge / surface-finish metrology, configuration-controlled engineering documentation (BOM, assembly instructions, ECO).

---

## Project Overview

The brief was to design a pump that charges an elevated **water tower** — moving roughly **5 metric tons (≈ 5,000 L) of potable water every half-day**, delivered inside a **~2-hour running window** while the pump sits idle the rest of the day. Because the water only has to be *transferred* to the tower rather than boosted to a process pressure, the requirement was for steady, reliable flow at a modest delivery head — not a high-pressure pump.

That duty cycle, the potable-water environment, and a deliberately **small production volume (~100 units/year)** shaped every decision that followed: the pump architecture, the material set, the tolerancing strategy, and the manufacturing process plan. The deliverable was not just a CAD model — it was a **manufacturing-validation unit**: real parts produced by the processes we specified, assembled to a controlled procedure, and tested.

<figure class="align-center">
  <img src="/assets/images/projects/water-pump/render.png" alt="Rotary-vane water-tower pump — final CAD assembly">
  <figcaption>The pump as designed: a compact rotary-vane positive-displacement unit with twin hose-barb ports, an extended drive shaft for external coupling, and a bolted front-plate/housing split line. Body is hand-sized — roughly the diameter of a coffee mug.</figcaption>
</figure>

### Design Brief, Quantified

| Parameter | Target |
|---|---|
| Application | Charging an elevated water tower (potable water) |
| Throughput | ≈ 5,000 L per half-day |
| Running window | ~2 h per half-day → **~17 % duty cycle** (mostly at rest) |
| Required flow | **≈ 42 L/min (≈ 11 GPM)** |
| Drive | External motor; **shaft extended** for an external coupling |
| Delivery pressure | Normal transfer pressure only — **balanced, equal-chamber porting**, no boosting |
| Design life | **3 years** |
| Production volume | **~100 units/year** (small batch) |
| Sanitation | Food-safe / drinking-water contact (NSF/ANSI 2 intent) |
| Critical risk | **Cold welding (galling) during long idle periods** |

The flow target falls straight out of the brief: 5,000 L moved inside a 2-hour window is **41.7 L/min**, which I sized the displacement around. At a standard 4-pole AC drive (~1450 rpm), that is a swept volume of **~29 cm³/rev** — comfortably within reach at this body size, with headroom for volumetric-efficiency losses. Displacement is set by chamber size and eccentricity, not by vane count, so the same ~29 cm³/rev is delivered by **four larger chambers** in the production configuration just as well as by a higher vane count (see [Production Optimization](#production-optimization--from-six-vanes-to-four) below).

---

## Concept Selection — Why a Rotary-Vane Pump

Several positive-displacement and centrifugal options were weighed against the brief. A **rotary-vane** architecture won because it matches the duty almost point-for-point:

- **Self-priming and steady at low speed** — important for a pump that starts cold against a partially drained suction line, then has to deliver consistent flow for two hours.
- **Flat flow-vs-speed behaviour** — a positive-displacement pump delivers a near-constant volume per revolution, so the 42 L/min target is hit by simply choosing displacement and drive speed, independent of head.
- **Tolerant of intermittent duty** — the long rest periods that would let a centrifugal pump's wetted clearances corrode or seize are handled here by material choice (below) rather than by running continuously.
- **Compact and serviceable** — the whole pump bolts apart along a single split line for inspection and seal replacement, which suits a 3-year service life and a small production run.

Because the pump only transfers water rather than compressing it, I specified **balanced, equal inlet/outlet porting** — symmetric kidney ports with no compression ramp. This keeps the pressure rise gentle, minimises flow pulsation, and (importantly for life) cancels most of the hydraulic side-load on the rotor and bearings, so the bearings see a far lighter radial duty than they would in an asymmetric high-pressure layout.

<figure class="align-center">
  <img src="/assets/images/projects/water-pump/exploded.png" alt="Exploded view of the pump assembly">
  <figcaption>Exploded assembly: front plate and bearings, dual shaft seals, the slotted rotor carrying its vanes, the static O-ring, the pump housing, the through-bolts, and the brass inlet/outlet barbs. The architecture splits along one plane so every wetted part is reachable for cleaning and seal service.</figcaption>
</figure>

---

## Mechanical Design

The pumping element is a **slotted rotor running eccentrically inside a cylindrical bore**, formed between the housing and a bolted front plate. The vanes ride in the rotor slots and are flung outward against the bore wall, sweeping sealed crescents of water from the inlet kidney port to the outlet. The design baseline used six vanes; the **production unit runs four** (see [Production Optimization](#production-optimization--from-six-vanes-to-four)), which is the configuration described from here on.

<figure class="align-center">
  <video src="/assets/images/projects/water-pump/vane-animation.mp4" autoplay loop muted playsinline width="100%" aria-label="Animation of the rotary-vane mechanism"></video>
  <figcaption>Motion study of the operating principle: as the rotor turns, each vane extends to ride the bore and carries a sealed pocket of water from inlet to outlet, then retracts into its slot. This kinematic study illustrates the vane sweep that the clearance and tolerance work below has to protect.</figcaption>
</figure>

The rotor shaft is carried on **two permanently-lubricated ball bearings** — one in the front plate, one in the rear cover — and sealed by **two lip shaft seals**, with a single **HNBR O-ring** as the static face seal between the housing and front plate.

A few decisions that drove the rest of the project:

- **Extended drive shaft.** Because the pump is driven by an external motor, the rotor shaft is extended past the front bearing to accept a coupling. That extension turns the rotor into a small overhung-load case, which I carried through the bearing-life and shaft-deflection checks.
- **Vane geometry.** The vanes are chamfered on their leading edges and sized so they remain captured in the rotor slots at the maximum eccentricity while still sealing at the bore — the chamfer orientation is called out in the assembly procedure precisely because installing a vane backwards would break the seal line.
- **Single split line.** Concentrating all sealing onto one O-ring face and two shaft seals keeps the leak paths few and well-defined, which made the later leak test a pass/fail on a small, well-understood set of interfaces.

---

## Material Selection — Preventing Cold Welding

The single most consequential requirement was subtle: with the pump **at rest for the great majority of its life**, wetted metal surfaces in static contact under load are exactly the condition that produces **cold welding (adhesive galling)** — and a pump that has micro-welded itself shut over a weekend is a warranty failure on Monday.

The mitigation is a tribological one: **never let two like materials sit in loaded contact.** I specified the three components that share running and rest interfaces — rotor, vanes, and housing/front plate — in **three deliberately dissimilar materials**, so every contact pair is a dissimilar couple with no tendency to solid-state weld:

| Component | Material | Why |
|---|---|---|
| **Housing & front plate** | Cast **316 stainless steel** (bead-blasted, then machined) | Corrosion-stable and food-safe in potable water (NSF/ANSI-61 intent), strong enough to be the pressure boundary, and castable to near-net shape at low volume |
| **Rotor** | Dissimilar **non-ferrous alloy (aluminium bronze)** | Good bearing and wear behaviour for the driven, overhung shaft; metallurgically dissimilar to the stainless bore so the two can never solid-state weld |
| **Vanes** | **Acetal (POM) homopolymer** | Self-lubricating, food-safe engineering polymer; tolerates dry starts after idle without scoring the bore, and a polymer-on-metal pair physically cannot cold-weld |

This makes every loaded interface a dissimilar pair: POM vane on stainless bore, POM vane in the aluminium-bronze rotor slot, and an aluminium-bronze rotor that never shares a material with the stainless housing it runs inside. The same set doubles as the corrosion and sanitation strategy: every wetted material is stable in potable water, the POM vanes are self-lubricating so the pump tolerates dry starts after long idle periods, and assembly uses **food-grade grease and food-safe threadlocker** per the controlled procedure.

---

## Structural & Flow Validation (FEA + CFD)

Before committing to drawings, the design was validated analytically so the tolerances and wall sections were chosen on evidence rather than habit.

**FEA (SolidWorks Simulation).** The pressure-containing parts — housing, front plate, and the six-bolt clamp joint — were analysed under the internal delivery pressure combined with the bolt preload of the **6× #10-24 through-bolts**. With the modest ~2.5 bar working pressure, peak von Mises stress in the cast 316 stainless housing stayed a wide margin below yield (minimum factor of safety well above 5), and the bolt pattern kept the O-ring face in net compression across the full joint so the static seal never unloads under pressure. The vanes were checked for root bending under hydraulic and centrifugal load and likewise sit at a small fraction of the material limit.

**CFD (SolidWorks Flow Simulation).** The inlet plenum and kidney ports were sized so that each chamber **fully charges within the fill window at 1450 rpm**, and so that local static pressure at the suction stays above the vapour pressure of water — i.e. **no cavitation, with positive NPSH margin** — across the operating range. The symmetric porting was confirmed to deliver low flow pulsation, which is what keeps the bearing radial load light and supports the 3-year life target.

These analyses set the targets that the tolerance stack-up then had to protect.

---

## Tolerance Analysis & GD&T

For a positive-displacement pump, **volumetric efficiency lives or dies on internal clearance.** Too much rotor-to-bore or vane-tip clearance and the pump leaks internally and misses its flow target; too little and it binds — and after an idle period, binds permanently. The clearances are the design.

I drove the critical features with a **GD&T scheme (ASME Y14.5)** built on a clear datum reference frame: the bore axis and the front-plate sealing face are the primary datums that every running clearance is referenced to, so concentricity of the bore to the bearing bores, perpendicularity of the sealing face, and the slot positions on the rotor are all controlled rather than left to title-block tolerances. The clearance stack-up was budgeted so the assembled **rotor-bore and vane-tip clearances hold within 0.001 in (0.025 mm)** — the band that simultaneously meets the flow target and clears the cold-weld/bind risk.

<figure class="align-center">
  <img src="/assets/images/projects/water-pump/gdt-machined.png" alt="GD&T drawing — machined pump housing MAC-000001">
  <figcaption>Machined-housing drawing (MAC-000001). A three-datum reference frame (A–B–C) ties the controls together: a <strong>position tolerance of ⌀0.002 in</strong> locates the bolt pattern, with <strong>flatness and profile callouts of 0.002–0.005 in</strong> on the sealing face and bore. The note "MAKE FROM PART CAS-000001" makes the cast-then-machine route explicit — this finished part is cut from the casting on the next drawing. These are the geometric controls that protect the internal-clearance budget the pump's volumetric efficiency depends on.</figcaption>
</figure>

<figure class="align-center">
  <img src="/assets/images/projects/water-pump/frontplate-machined.png" alt="GD&T drawing — machined front plate MAC-000004">
  <figcaption>Front-plate drawing (MAC-000004), again "MACHINED FROM CAS-000004." The bearing-bore and sealing-face features carry <strong>parallelism 0.002 in to datum D</strong> and <strong>flatness/profile 0.002 in</strong>, because this face sets the rotor's axial position and squareness to the bore — the two things that decide whether the vane tips seal evenly around the sweep. Section views and a revision block complete a release-ready sheet, not a model-only handoff.</figcaption>
</figure>

---

## Design for Manufacturing — Cast, Then Machine

At **~100 units/year**, the process plan had to be right for *small-batch* economics — neither one-off hand machining nor high-volume die tooling. The answer was a **cast-then-machine** route for the two large custom parts, with everything else pulled from a controlled off-the-shelf list.

The housing and front plate are designed as **castings first** — near-net blanks with generous radii, draft, and machining stock — and then **CNC-finished** only on the features that carry tolerance: the bore, the bearing seats, the sealing face, and the bolt pattern. That split is exactly why each of those parts carries **two drawings**: a *casting* drawing that defines the as-cast blank and a *machined* drawing that defines the finished, toleranced part. Designing the casting (draft, parting line, stock allowance, shrink) is its own discipline, and the drawing package documents both stages.

<figure class="align-center">
  <img src="/assets/images/projects/water-pump/housing-casting.png" alt="Casting drawing — pump housing CAS-000001">
  <figcaption>The matching casting drawing (CAS-000001) for the housing: material called out as <strong>316 stainless steel, bead-blasted</strong>, dimensioned to <strong>ISO 2768 medium-class</strong> general tolerances appropriate for an as-cast blank, with explicit notes on traceability, food-/drinking-water compliance, and inspection. Read alongside the machined drawing above, the two sheets define the full cast → machine sequence for one part — the loose tolerances live on the casting, the tight ones are added only where a finished feature needs them.</figcaption>
</figure>

The Bill of Materials uses a part-numbering scheme that makes the make-vs-buy split explicit:

| Item | Qty | Part No. | Description | Source |
|---|---|---|---|---|
| 1 | 1 | MAC-000001 | Pump Housing, machined | Cast + machined |
| 6 | 1 | MAC-000004 | Front Plate, machined | Cast + machined |
| 10 | 1 | MAC-000002 | Pump Rotor, machined | Machined |
| 3 | **4** | MAC-000003 | Acetal (POM) Vane | Machined / moulded |
| 4 | 2 | MAC-000005 | Bearing Housing Cover | Machined |
| 9 | 2 | OTS-000002 | Permanently-lubricated bearing | Off-the-shelf |
| 8 | 2 | OTS-000007 | Shaft seal | Off-the-shelf |
| 11 | 1 | OTS-000001 | HNBR O-ring | Off-the-shelf |
| 7 | 6 | OTS-000004 | #10-24 × 2″ zinc-plated alloy-steel bolt | Off-the-shelf |
| 2 | 6 | OTS-000005 | Super-corrosion-resistant hex nut | Off-the-shelf |
| 5 | 8 | OTS-000006 | #4 nickel-alloy socket-head screw | Off-the-shelf |
| 12 | 2 | OTS-000003 | 3/8″ × 3/8″ brass hose fitting | Off-the-shelf |

**MAC-** parts are made-to-print; **OTS-** parts are specified to a catalogue item. Pushing as much of the pump as possible onto standard bearings, seals, and fasteners is the right move at 100/year — it removes tooling cost and lets the build lean on proven, certified components. (The vane count shown is the four-vane **production** configuration — see the production-optimization note below; the released drawings carry the change under ECO-001.)

<figure class="align-center">
  <img src="/assets/images/projects/water-pump/assembly_drawing.png" alt="Assembly drawing with exploded view and BOM">
  <figcaption>The controlled assembly drawing: balloon-referenced exploded view tied to the BOM, title block, and revision record — the single sheet that ties the whole part list to the build.</figcaption>
</figure>

---

## Production Optimization — From Six Vanes to Four

The design baseline carried six vanes. Reviewing it for the **production run**, I cut the rotor to **four vanes and four chambers** — a deliberate design-for-manufacturing change, released as **ECO-001** against the drawing package. It is the change I'd most want a reviewer to see, because it shows tuning a working design for the way it will actually be *made* rather than for textbook performance.

The reasoning:

- **The rotor slots are the cost driver.** Each slot has to hold the vane to the ±0.001 in tip-clearance budget, so every slot is an individually machined, individually inspected tight-tolerance feature. Going from six slots to four removes a third of the most expensive and highest-scrap-risk operations on the single most demanding part — the largest available lever on cycle time when each rotor is *machined*, not tooled, on a ~100-unit/year line.
- **Displacement is preserved, not sacrificed.** Swept volume is set by chamber size and rotor eccentricity, not vane count. Re-sizing to four larger chambers keeps the **~29 cm³/rev** displacement, so the pump still hits **42 L/min at 1450 rpm**. The flow target never moves.
- **The only real trade-off doesn't matter for this duty.** More vanes mainly buys lower flow pulsation and a marginal volumetric-efficiency gain at high pressure. This pump transfers water into an open tower at ~2.5 bar; a slightly higher ripple charging a tank is invisible to the application, so paying machining cost for it would be paying for performance the duty never uses.
- **Fewer parts, simpler build, longer service.** Four vanes means fewer POM parts to procure, inspect, and orient (each vane is chamfer-direction-critical at assembly), a shorter and lower-error build, fewer vane-tip sealing lines and wear interfaces, and fewer spares to support the 3-year life. Larger chambers also self-prime and clear entrained air more readily on a cold start after a long idle.

This is the heart of DFM: hold the requirement (flow, pressure, life, sanitation), and spend the design freedom that's left on making the part cheaper and more robust to produce. The built validation unit below runs the four-vane rotor.

---

## Documentation & Configuration Control

A design is only manufacturable if someone other than the designer can build it. The project was documented to a **product-lifecycle standard**, not a class-project standard:

- A **configuration-controlled assembly instruction** (DOC-000001) with revision history, an ECO field, referenced documents, required fixtures (arbor press and a **bearing-depth jig**), consumables (food-grade grease, food-safe threadlocker), environment requirements (clean, food-safe per NSF/ANSI 2), and a **15-minute-per-unit** build time.
- A **twelve-step assembly procedure**, each step illustrated, calling out exact fasteners, torque/hand-tighten notes, and the orientation-critical operations (vane chamfer direction, bearing press depth).
- A **referenced BOM** (DWP-000001) and the full drawing package above.

This is the part of the project that demonstrates the *whole* product-development loop — requirements, design, analysis, drawings, BOM, build instructions, and revision control — handled the way it is in industry.

---

## Manufacturing Validation — Build & Test

The final deliverable was a **physical validation unit**: the custom parts were produced **by the manufacturing methods we specified** (cast-and-machine for the body parts, machined rotor and vanes), then assembled to DOC-000001. One front plate was built in a **clear material so the vane mechanism is visible** through the running face — a deliberate validation aid for watching the vanes sweep and seal.

<figure class="align-center">
  <img src="/assets/images/projects/water-pump/prototype-front.jpg" alt="Built validation unit — clear front plate showing the vane mechanism">
  <figcaption>The assembled validation unit. The transparent front plate exposes the rotor, its four vanes, and the central bearing — letting the vane sweep and the seal line be inspected directly while the pump turns.</figcaption>
</figure>

<figure class="align-center">
  <img src="/assets/images/projects/water-pump/prototype-side.jpg" alt="Built validation unit — inlet/outlet side">
  <figcaption>The same unit from the port side, showing the twin 3/8″ hose-barb inlet/outlet fittings and the bolted housing flange.</figcaption>
</figure>

**Validation results:**

| Check | Result |
|---|---|
| Dimensional conformance | Critical clearances held **within ±0.001 in (0.025 mm)** by micrometer/pin-gauge metrology |
| Surface finish | Sealing faces and bore **qualified** to the specified finish |
| Leak test | **Passed** — no leakage at the O-ring face or shaft seals |
| Delivery pressure | **≈ 2.5 bar (≈ 36 psi)** at the outlet — equivalent to ~25 m of delivery head, suitable for the tower |
| Suction pressure | **≈ −0.07 bar gauge** during self-priming, recovering toward atmospheric under flooded suction |
| Differential | **~2.5 bar** across the pump, consistent with the FEA/CFD design point |
| Operation | **Smooth** — no binding, chatter, or vane stick across the run |

The measured pressures and the smooth, leak-free operation confirmed that the as-built clearances landed inside the budget the tolerance analysis set, and that the dissimilar-material strategy let the pump start and run cleanly after assembly without any sign of galling.

---

## What This Project Demonstrates

End to end, the pump exercises the full mechanical-engineering and manufacturing toolchain on a single, real deliverable:

- **Mechanical design** of a working positive-displacement machine from a quantified brief — concept selection, mechanism design, sealing, and bearing duty.
- **Structural and flow validation** with **FEA and CFD** used to set targets, not just to decorate a report — pressure containment, bolt-joint integrity, cavitation/NPSH margin, and pulsation.
- **Tolerance analysis and GD&T** (ASME Y14.5) tied directly to the function that depends on it — internal clearance, volumetric efficiency, and the cold-weld risk.
- **Deep, practical DFM** — a cast-then-machine plan correctly matched to ~100 units/year, with a make-vs-buy BOM and a dual casting/machined drawing set.
- **Full product documentation** — configuration-controlled assembly instructions, BOM, drawing package, and a build procedure another operator can follow in 15 minutes.
- **Manufacturing validation** — parts made by the specified methods, then leak-tested, pressure-tested, and dimensionally verified on a built unit.

### Next Steps

A second production iteration would add a flow-rate measurement at the rated 1450 rpm to close the loop on volumetric efficiency, an endurance run across simulated idle/run cycles to validate the 3-year life and the anti-galling material set over time, and a first-article inspection report tying each toleranced feature on the drawings back to measured values.
