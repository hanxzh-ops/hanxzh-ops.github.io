---
layout: splash
title: "Hanxiao Zhang"
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
  - title: "Mechanical Design"
    excerpt: "Mechanisms, product design, CAD → prototype → test."
    url: "/mechanical-design/"
    btn_label: "Open"
    btn_class: "btn--primary"
  - title: "Manufacturing"
    excerpt: "Automation, processes, QA/docs, pilot builds."
    url: "/manufacturing/"
    btn_label: "Open"
    btn_class: "btn--primary"
  - title: "Control & Robotics"
    excerpt: "Simulation, validation, controls, mechatronics."
    url: "/control-robotics/"
    btn_label: "Open"
    btn_class: "btn--primary"
  - title: "Personal Projects"
    excerpt: "Smaller builds and experiments."
    url: "/personal-projects/"
    btn_label: "Open"
    btn_class: "btn--primary"

---

{% include feature_row id="intro" type="center" %}

{% include feature_row %}
