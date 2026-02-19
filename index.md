---
layout: splash
title: "YOUR_NAME"
permalink: /
header:
  overlay_color: "#000"
  overlay_filter: "0.45"
  overlay_image: /assets/images/hero.svg
  actions:
    - label: "View Projects"
      url: "/projects/"
    - label: "Download Resume"
      url: "/resume/"
intro:
  - excerpt: "Mechanical Engineer focused on **product design, prototyping, and manufacturing** — with strong mechatronics + simulation skills."
feature_row:
  - image_path: /assets/images/teasers/rotary_calendar.svg
    title: "Rotary Calendar Product"
    excerpt: "End-to-end product development → CAD/CAM → pilot build (20 units) → documentation (BOM, QA, assembly)."
    url: "/projects/rotary-calendar/"
    btn_label: "Case study"
    btn_class: "btn--primary"
  - image_path: /assets/images/teasers/luggage.svg
    title: "Transformable Luggage Prototype"
    excerpt: "Mechanical expansion–contraction mechanism; designed, fabricated, and tested a scaled prototype for manufacturability."
    url: "/projects/transformable-luggage/"
    btn_label: "Case study"
    btn_class: "btn--primary"
  - image_path: /assets/images/teasers/batching.svg
    title: "Automatic Rubber Batching"
    excerpt: "Arduino batching system + Python UI for recipe-driven dispensing and real-time discrepancy alerts."
    url: "/projects/rubber-batching/"
    btn_label: "Case study"
    btn_class: "btn--primary"
---

{% include feature_row id="intro" type="center" %}

{% include feature_row %}
