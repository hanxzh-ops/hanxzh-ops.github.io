---
pillar: mechanical-design
title: "Transformable Carry-On / Checked Luggage Prototype"
permalink: /projects/transformable-luggage/
excerpt: "Led the concept, mechanism development, CAD, and prototype build of a transformable suitcase that expands between compact and high-capacity travel modes."
header:
  teaser: /assets/images/projects/suitcase/Concept%20Final.jpg
  image: /assets/images/projects/suitcase/Concept%20Final.jpg
categories:
  - Product Design
tags:
  - mechanism
  - prototype
  - product-design
  - dfm
---

**Timeframe:** Sep 2024 – May 2025  
**Tools:** Product strategy, mechanism design, CAD, design iteration, vacuum forming, prototyping, BOM development, GD&T documentation

## Project Overview
This project started from a clear consumer problem: most suitcases are fixed-volume products, so travelers often need multiple cases for different trip lengths and packing conditions. That creates a second pain point as well. Travelers frequently have to choose between packing light for flexibility and carrying a larger suitcase in case they want more volume on the return trip for items such as souvenirs or additional purchases.

My team framed the design opportunity around a single product that could shift between compact travel and expanded storage modes instead of forcing the user to own multiple suitcases. After market research on the existing luggage market, we concluded that we were not seeing a true multi-mode expanding suitcase solution that addressed this need in a fully integrated way.

The resulting concept was a transformable luggage platform that could change form factor through an internal expansion mechanism while preserving the identity of a single suitcase. The mechanism details are currently under patent protection, so some implementation specifics are intentionally omitted here.

## Problem Definition & Research
We began with brainstorming and customer-needs mapping focused on three questions:

- How can one suitcase support both carry-oriented travel and higher-volume packing?
- How can the volume change happen without turning the product into a set of detachable modules?
- How can the product remain intuitive, structurally credible, and manufacturable?

Early discussion quickly eliminated a purely modular architecture. While modular add-ons could technically increase volume, that approach did not actually solve the core user problem because it still behaved like owning or carrying multiple luggage components. The design direction then shifted toward a single integrated mechanism that could reconfigure the suitcase body itself.

### Media
![Initial Brainstorm](/assets/images/projects/suitcase/initial_brainstorm.jpeg)
*Early team brainstorming around use cases, constraints, loading scenarios, and impact conditions.*

## Concept Generation & Selection
From that point, we explored several expansion architectures, including:

- dual-shell concepts,
- central geared expansion concepts,
- slider-based telescoping concepts, and
- folding structures inspired by deployable systems such as satellite solar panels.

Each concept was evaluated against user simplicity, packaging efficiency, manufacturability, structural continuity, and how convincingly it could behave as one coherent product. The final direction was selected because it offered the best balance between compact storage, meaningful expansion, and a user experience that still felt like operating a normal suitcase rather than assembling a kit.

## Mechanism Development
Once the concept direction was chosen, I developed the transformable architecture in CAD and used digital analysis to validate that the expansion sequence was kinematically feasible. The goal at this stage was not only to prove that the suitcase could enlarge, but also to confirm that the shell interfaces, moving members, and packaging envelope could coexist without obvious interference problems.

The initial concept-validation stage is captured in the early mechanism simulation below:

<video controls width="100%">
  <source src="/assets/images/projects/suitcase/explading_mechanism_initial.mp4" type="video/mp4">
</video>

This stage established that the core concept could transition between configurations before full detail design began. After validating the motion concept, we developed the project identity and refined the first integrated product presentation.

### Media
![Concept Final](/assets/images/projects/suitcase/Concept%20Final.jpg)
*Final concept render showing the suitcase in compact, expanded, and open configurations.*

![Project Logo](/assets/images/projects/suitcase/HorizonLogo_V1.jpg)
*Early brand identity developed alongside the product concept presentation.*

## Detailed Design Engineering
After concept validation, the project moved into full part-level design. I continued translating the mechanism into a manufacturable product architecture and designed the major sub-systems required to make the suitcase functional as a prototype platform.

Key engineering work included:

- development of the primary transformable shell architecture,
- design of the supporting internal mechanism,
- design of a two-way expandable handle system that is also under patent protection,
- integration design for lock features, rim structure, housing details, and wheel mounts, and
- creation of a structured production BOM to organize purchased parts, fabricated parts, and assembly relationships.

This phase required balancing geometry, packaging, structural logic, and assembly strategy at the same time. The product needed to expand convincingly while still reading as a practical luggage object with realistic handles, rolling hardware, closures, and shell interfaces.

### Media
![Prototype BOM](/assets/images/projects/suitcase/BOM_Prototype.jpg)
*Prototype bill of materials used to organize fabricated and purchased components during the build.*

![Prototype Documentation](/assets/images/projects/suitcase/Prototype%20GD%26T%20drawing.jpg)
*Prototype documentation package including assembly references and engineering drawings.*

## Prototype Manufacturing Strategy
For the prototype phase, the main manufacturing constraint was forming the outer shell geometry at school scale. Because we did not have access to a large vacuum-forming machine suitable for full-size shells, I shifted to a scaled prototype strategy and designed smaller mold patterns that could still demonstrate the shell architecture and mechanism concept.

I designed the press-forming / mold pattern geometry and produced it with a nylon core so we could repeatedly form shell samples and improve the process. This let us test shell geometry, wrapping quality, edge behavior, and repeatability before assembly.

### Media
![Press Mold Pattern](/assets/images/projects/suitcase/PressMoldPattern.jpeg)
*Custom mold-pattern tooling used to produce shell samples for the scale prototype.*

## Process Debugging & DFM Iteration
The first batch of shell parts exposed process problems, especially vacuum exhaust limitations that led to uneven wall thickness and inconsistent wrapping over the mold geometry. Those defects were important because they affected both the visual quality of the prototype and the reliability of shell fit-up during assembly.

Instead of treating those parts as simple failed samples, I used them as process feedback to improve the mold and forming approach. That iteration loop focused on:

- improving air evacuation during forming,
- reducing uneven material draw,
- improving corner and edge wrapping quality, and
- making shell parts more repeatable for assembly.

Over successive trials, we were able to produce shell pieces quickly and with much better consistency, which made the final assembly stage practical.

### Media
![Defective Press Part](/assets/images/projects/suitcase/SamplePressPartwithDefect.jpeg)
*Early shell sample showing forming defects caused by poor vacuum exhaust and uneven material draw.*

![Shell Pieces](/assets/images/projects/suitcase/shell%20pieces.jpeg)
*Improved shell components prepared for prototype assembly after process refinement.*

## Final Prototype Assembly
With the shell process stabilized, I assembled the prototype into a fully working scale model that demonstrated both the expanded geometry and the transformable mechanism. At this point the project had moved beyond a concept study and into a physically validated product architecture with integrated shell parts, wheel packaging, and expansion behavior.

The final prototype demonstrated the central claim of the project: one suitcase could support multiple travel modes without relying on detachable modules or multiple separate luggage sizes.

### Media
![Fully Open Prototype](/assets/images/projects/suitcase/fully_open.jpg)
*Working scale prototype in the expanded/open configuration.*

<video controls width="100%">
  <source src="/assets/images/projects/suitcase/expanding_mechanism.webm" type="video/webm">
</video>

## Outcome
The project resulted in a transformable luggage prototype supported by concept research, mechanism development, CAD validation, part-level engineering, process iteration, and physical demonstration. It also produced the documentation backbone needed for continued development, including a prototype BOM, drawings, and assembly references.

The design is currently under patent application, so the public portfolio version focuses on the engineering process, design rationale, and prototype execution rather than the protected mechanism details themselves.
