---
pillar: mechanical-design
title: "End-to-End Development and Commercialisation of a Rotary Calendar Product"
permalink: /projects/rotary-calendar/
excerpt: "From market survey and concept selection through mechanism design, iterative prototyping, materials engineering, and a fully sold-out 20-unit production run."
header:
  teaser: /assets/images/projects/rotary/rotary_calendar.jpg
  image: /assets/images/projects/rotary/rotary_calendar.jpg
categories:
  - Product Design
  - Manufacturing
tags:
  - product-design
  - manufacturing
  - cad
  - dfm
  - mechanism-design
  - ratchet
  - casting
  - cnc
  - documentation
---

**Timeframe:** Jan 2025 – May 2025  
**Tools:** CAD/CAM, CNC lathe, manual lathe, water jet cutting, resin casting, wood milling, sheet metal forming, QA documentation  
**Outcome:** 20-unit production batch, fully sold out at material cost before end of semester

---

## Project Overview

This project ran the full product development cycle, from a blank-slate survey through mechanism invention, iterative prototyping, materials engineering, manufacturing process optimization, and a small-batch production run. The end result was a compact mechanical desktop calendar with a deliberate one-way ratchet interaction: you can only move forward, because time only goes forward.

Every major decision on this project, mechanism geometry, material selection, casting process, and fastener manufacturing, was forced by a failure at the previous stage. The hardest lesson was that you cannot predict what the next stage will break. The skill is building a process that finds failures early and cheaply, then fixes them before they reach production.

---

## Annotated Timeline

### Milestone 1 - Market Survey & Concept Selection
*January 2025*

The project began with a structured survey of classmates, professors, and friends. The key finding was consistent: compared to other desk objects, people preferred something **useful, simple, and tactilely satisfying**, not purely decorative. A desk calendar scored highest on all three dimensions and gave us a clear design direction.

We generated four distinct concepts before committing:

**Concept 1 - Slot Machine Calendar**  
A tumbler-style display where digits flip like a slot machine. Visually striking but operationally impractical because it was hard to read mid-rotation and felt too toy-like for daily use.

![Slot machine concept sketch](/assets/images/projects/rotary/Brainstorm_concept1.jpg)
*Concept 1 - slot machine style digit tumbler.*

**Concept 2 - Self-Aligning Gear Calendar**  
A mechanical calendar where advancing the last digit of the day automatically carries over to the next wheel through a gear train, similar to an odometer. Elegant in principle, but the gear train required too many precision parts and pushed the cost estimate well over budget.

![Self-aligning gear concept](/assets/images/projects/rotary/Brainstorm_concept2.jpeg)
*Concept 2 - self-aligning gear carry mechanism. Eliminated due to part count and cost.*

**Concept 3 - Stacked "Burger" Calendar**  
A stacked disc format with flat date layers. Functional but visually unremarkable, and too close to existing products to justify as a new design.

![Burger shape calendar concept](/assets/images/projects/rotary/Brainstorm_concept3.jpg)
*Concept 3 - stacked disc "burger" format. Eliminated for lack of differentiation.*

**Chosen Concept - Ratchet Rotary Calendar**  
The selected design combined a rotating roller display with a **ratchet mechanism** integrated into the frame. The ratchet produces an audible click on each step advance and, critically, allows rotation in one direction only. This one-way constraint was an intentional design choice: the calendar cannot be turned back, which serves as a small physical reminder that time only moves forward. The interaction is deliberate, satisfying, and distinct from anything currently on the market.

---

### Milestone 2 - Mechanism Design: Four-Wheel Ratchet System
*January-February 2025*

The calendar uses **four rollers on a single shared axle**:

| Wheel | Display | Ratchet Teeth |
|---|---|---|
| 1 | Month (Jan-Dec) | 36 |
| 2 | Day tens digit (0-3) | 30 |
| 3 | Day units digit (0-9) | 30 |
| 4 | Weekday (Mon-Sun) | 35 |

Each wheel is independently rotatable on the axle. The ratchet teeth on each wheel engage a fixed pawl on the frame, locking each wheel against reverse rotation while allowing forward stepping. Because each wheel has a different tooth count, the geometry had to be carefully validated to ensure every wheel's display window aligned correctly at rest. A tooth-count mismatch would leave dates offset from the viewing window.

---

### Pivot 1 - Ratchet Geometry: Too Small to Click
*February 2025*

The first ratchet prototypes were printed to validate the geometry before committing to tooling.

![First roller prints](/assets/images/projects/rotary/Roller1.jpg)
*First printed rollers used to validate tooth geometry and ratchet engagement.*

The initial tooth size was too small. The pawl engaged correctly and prevented back-rotation, but the teeth were so fine that the click sound was inaudible and the tactile feedback was negligible. The defining interaction of the product was not working.

We iterated through multiple tooth geometries, varying tooth depth, face angle, and tip radius, printing and testing each configuration by hand.

![Ratchet tooth geometry iterations](/assets/images/projects/rotary/roller_designs.jpg)
*Printed ratchet tooth geometry iterations with different depth, angle, and tip radius combinations.*

The working configuration used **36/30/30/35 teeth** respectively, with each forward step requiring **3-5 clicks** to advance one full position. The dense, small teeth prevented back-rotation reliably, but this introduced a new usability problem.

---

### Pivot 2 - Usability Failure: The Blurry Date Problem
*February 2025*

When we put the first working prototypes in front of users, classmates, other students, and the supervising professor, the mechanism response was well received. But a consistent piece of feedback emerged: because each step required 3-5 clicks, users would often stop mid-advance, leaving the roller in a transitional state between two numbers. The display window would show a blurry half-number rather than a clean date.

The requirement was clear: **one click must equal one full step.** One interaction, one unambiguous date.

The engineering problem was that if each step requires only one tooth engagement, the teeth must be much larger. Larger teeth create more backlash, allowing the roller to rock backward slightly within the tooth gap and making the display feel loose while undermining the one-way constraint.

We worked through several more tooth profile iterations to reconcile step resolution with backlash control.

![Intermediate tooth profile iterations](/assets/images/projects/rotary/early-iterations.png)
*Intermediate iterations attempting to achieve one-click-per-step without introducing backlash.*

---

### Milestone 3 - Major-Minor Tooth Profile Solution
*March 2025*

The final solution was a **major-minor tooth profile**: two interleaved tooth sizes on the same ratchet wheel.

- **Major teeth** - full-depth, wide-face teeth that produce the audible click and drive the one-step advance. One major tooth engagement equals one full calendar position.
- **Minor teeth** - shallow, narrow teeth positioned between each major tooth pair. They do not produce a click or drive a step, but they fill the backlash space within the major tooth gap, preventing the roller from rocking backward between steps.

![Final major-minor tooth profile](/assets/images/projects/rotary/Final_design_ratchet.png)
*Final major-minor tooth profile where major teeth drive the step and minor teeth constrain backlash.*

This was the core mechanism invention of the project. The result was a single, definitive click per calendar advance with no detectable backlash, exactly the interaction the user feedback had asked for.

---

### Pivot 3 - Materials Cascade: Axle, Frame, and Galling
*March 2025*

With the mechanism geometry resolved, the team turned to material selection for the metal components. The axle, frame, and bolts are all metal parts in close contact, making **galling** (adhesive wear between sliding metal surfaces under load) an immediate concern.

**Axle - shaft steel to brass:**  
The first axle material was standard shaft steel. Under machining it showed cracking tendencies because of brittleness, and the hardness made it difficult to work with on the available equipment. We switched to **brass**, which machines cleanly, has self-lubricating behavior that reduces galling risk against the roller bore, and is visually consistent with the product aesthetic.

**Frame/window - stainless steel to aluminum 6061-T1:**  
The display window frame was initially prototyped in stainless steel sheet. Stainless is highly ductile and forms cleanly, but its yield strength meant the rollers required significantly more force to turn. The friction between the steel pawl and steel ratchet teeth was too high for comfortable daily use. We switched to **aluminum 6061**, which dramatically reduced the interface friction. The alloy temper was specifically chosen as **T1** rather than the more common T6, because T6 proved too hard to bend without surface cracking, a problem that reappeared during production and required another process change later.

**Bolts - off-the-shelf to custom machined:**  
Standard hardware fasteners were dimensionally compatible but visually inconsistent with the compact, refined packaging of the final product. We chose to machine custom bolts to maintain a clean aesthetic across the assembly.

**Rollers - resin casting:**  
The rollers were produced by resin casting into custom molds, allowing the date numerals and surface texture to be cast directly rather than machined or printed.

**Base - CNC wood milling on synthetic wood block:**  
The base was initially milled from synthetic wood, chosen for machinability and dimensional stability.

These material decisions produced the first MVP.

![First MVP assembly](/assets/images/projects/rotary/first_mvp.jpg)
*First MVP with brass axle, aluminum 6061 frame, resin-cast rollers, custom bolts, and synthetic wood base.*

---

### Pivot 4 - MVP User Feedback: Base Material and Casting Quality
*March-April 2025*

User feedback on the MVP was positive on the mechanism and overall concept. The criticism concentrated on the base and the roller surface quality.

**Base - synthetic wood to real wood with fillets:**  
The synthetic wood base felt light, had a faint chemical smell, and left a dusty residue on hands after handling. Users consistently noticed it. We switched to **real wood**, added **fillets to all edges and corners** to soften the tactile experience, and refined the milling program to produce a cleaner surface finish.

**Casting - bubble defects:**  
The resin used for the initial roller casts was a fast-cure formulation. Fast cure introduced a second problem: the short pot life did not allow air bubbles to escape before the resin set, leaving visible voids in the roller surface. We addressed this through three parallel changes:

1. **Mold redesign** - switched from a single-piece to a **three-piece mold** to make demolding easier and reduce the mechanical stress on the cast part during release.
2. **Mix ratio iteration** - tested multiple resin-to-hardener ratios to find a formulation with a longer working time, allowing bubbles to rise and escape before cure.
3. **Surface preparation** - applied primer to the mold interior surfaces and polished them before casting to eliminate layer-pattern transfer from the mold walls onto the roller face.

These changes together produced bubble-free, smooth-surface rollers.

![Improved prototype](/assets/images/projects/rotary/improved_prototype.jpg)
*Improved prototype with real wood base, refined casting process, and cleaner surface finish.*

---

### Pivot 5 - Frame Production Failure: Bending Cracks
*April 2025*

Moving toward the production run, the aluminum frame became the highest-failure-rate component. The 6061-T6 alloy used in early frames, despite being replaced with T1 in later prototypes, reappeared in some stock, and even with T1, aggressive single-pass bending caused **stress-yield surface cracking** that eventually propagated through the part entirely.

![QC failure - cracked frame](/assets/images/projects/rotary/bad_qc.jpg)
*QC reject showing a surface crack from single-pass bending. This part would fracture in normal use.*

Two process changes resolved this:

1. **Increased bend radius** - reducing stress concentration at the bend line through a larger-radius forming tool.
2. **Multi-pass bending** - instead of forming the full angle in a single press, the part was bent incrementally across several passes, distributing plastic deformation and preventing localized strain from exceeding the material fracture limit.

We also optimized the **water jet cutting layout** to maximize the number of frame blanks per sheet, reducing material waste and per-unit cost.

![Second improved MVP](/assets/images/projects/rotary/mvp_2.jpg)
*Second improved MVP with multi-pass bent frame, real wood base, and production-ready assembly.*

---

### Milestone 4 - Production Process Optimization: Bolt CNC Automation
*April 2025*

Each finished calendar requires two custom bolts. In the prototype phase these were turned on a **manual lathe** and threaded with a hand die, a process taking about **20 minutes per bolt**. For a 20-unit batch, that represented more than 13 hours of lathe time for fasteners alone.

We redesigned the bolt production process for the CNC lathe:

- Programmed a fully automated turning and facing sequence
- Designed an **automated feeding procedure** so the operator only needed to load bar stock while the machine handled the rest
- Integrated surface finishing into the same CNC program

Result: bolt cycle time reduced from about 20 minutes to **under 5 minutes**, fully unattended.

![CNC-produced bolts](/assets/images/projects/rotary/production_bolts.jpg)
*CNC lathe produced bolts with automated feeding, consistent surface finish, and sub-5-minute cycle time.*

---

### Milestone 5 - Quality Control System
*April-May 2025*

We established a three-stage QC protocol applied to every part before assembly:

**Stage 1 - Dimensional check**  
Each part is test-fitted against a known-good reference part. Any part that cannot achieve the reference fit within tolerance is rejected before further processing.

**Stage 2 - Surface crack inspection (frame)**  
A color spray is applied to the bent frame surface. After cleaning, any residual color trapped in a surface crack remains visible. Any frame with retained color at a bend line is rejected. This caught the brittle-fracture failure mode reliably without requiring measurement equipment.

**Stage 3 - Bubble inspection (rollers)**  
Cast rollers are inspected visually under direct light. Any bubble larger than **0.5 mm** is a reject. Sub-threshold bubbles in non-display areas are accepted.

**Stage 4 - Functional rotation test (post-assembly)**  
Each assembled unit is cycled through a full rotation sequence on all four wheels to verify click sound, step alignment, and display window registration. Units that fail to produce a clear click or show misaligned dates are disassembled and the offending component replaced.

---

### Milestone 6 - Full Batch Production
*May 2025*

**Production breakdown by component:**

| Component | Material | Process | Notes |
|---|---|---|---|
| Rollers | Polyurethane resin | 3-piece cast mold | 6-8 hr cure; batch size of 4 per run |
| Frame / window | Aluminum 6061-T1 | Water jet cut + multi-pass bend | Color spray QC at bend lines |
| Axle | Brass | CNC turned | Self-lubricating, galling-resistant |
| Bolts | Brass | CNC lathe, automated feed | <5 min/bolt cycle time |
| Base | Hardwood | CNC wood milling + fillet routing | Natural finish |

The production bottleneck was roller solidification. Each cast batch of four rollers required **6-8 hours** of cure time before demolding. The production run was paced around this constraint, with casting batches staggered to keep other assembly steps continuously fed.

All manufacturing was carried out by the team on lab equipment. The 20-unit batch was completed over roughly three weeks of production scheduling.

**Color variants** - different roller color combinations were offered across the batch, allowing buyers to select a finish.

![Finished product variants](/assets/images/projects/rotary/product.jpg)
*Finished units across multiple color combinations, compared for fit, finish, and visual consistency.*

![Full production batch](/assets/images/projects/rotary/final-product.jpg)
*Completed 20-unit batch after final assembly, QC, and finishing.*

---

## Final Product

![Final rotary calendar](/assets/images/projects/rotary/rotary_calendar.jpg)
*Completed rotary calendar with brass axle and bolts, aluminum 6061-T1 frame, resin-cast rollers, and hardwood base.*

The completed units were offered at material cost to the class and wider school network. All 20 units were ordered and sold before the end of the semester, and several were pre-ordered before the batch was finished.

The final product delivered:
- A clean, one-click-per-step ratchet advance with audible click and zero backlash
- Four independently rotating wheels displaying month, day (two digits), and weekday
- A one-way interaction that cannot be reversed as a deliberate design statement
- Brass, aluminum, hardwood, and resin construction with a consistent hardware aesthetic
- A repeatable manufacturing process validated across a 20-unit run

---

## Key Learnings

**You cannot predict what the next stage will break.** The most important skill in this project was not any individual engineering solution. It was maintaining a process that surfaced failures early, in prototypes, in test fits, and in QC checks, before they propagated into the production batch. Every major pivot, the ratchet geometry, axle material, frame temper, casting process, and bolt-production method, was discovered by building something, testing it, and being willing to change it.

**Mechanism design is an iteration problem, not a calculation problem.** The major-minor tooth profile that solved the one-click requirement could not have been derived analytically from first principles given the constraints and tolerances we were working with. It came from printing, testing, observing failure, and trying something different. The final solution was simple, but only obvious in retrospect.

**Material selection cascades.** Changing the axle material affected galling behavior at the frame interface, which affected frame material choice, which affected formability, which affected bend process, which affected QC method. No material decision was isolated. Understanding the chain of dependencies between components is as important as getting any single selection right.

**Production economics are driven by bottlenecks, not averages.** The bolt machining time was 20 minutes per part on a manual lathe, but because it was not the bottleneck, casting was, the urgency of fixing it was easy to underestimate. Re-engineering the bolt process to under 5 minutes on the CNC lathe freed operator time for higher-value tasks during the casting cure window. Optimizing the constraint first is the right instinct; optimizing everything else is a bonus.

---

## References & Documentation

- Internal production documentation: parts planning sheet, assembly reference guide, QA checklist (available on request)
- Internal design notes on ratchet geometry and tooth-profile iterations
- Material and process references for casting, bending, and CNC production
