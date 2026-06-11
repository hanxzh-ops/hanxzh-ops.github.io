---
layout: splash
title: "Hanxiao Zhang"
permalink: /
header:
  overlay_color: "#000"
  overlay_filter: "0.45"
  overlay_image: /assets/images/cover.jpg
  actions:
    - label: "View Projects"
      url: "/control-robotics/"
    - label: "Download Resume"
      url: "/resume/"
excerpt: "Controls & robotics engineer who also designs and builds the hardware."
intro:
  - excerpt: "I work at the intersection of **controls, robotics, and manufacturing** — building **RL/MPC locomotion and inverse-kinematics** systems, then taking the hardware all the way through **DFM, GD&T, and production**. From a quadruped that carries objects alongside a human using onboard sensors only, to a sold-out 20-unit product run."
feature_row:
  - title: "Control & Robotics"
    excerpt: "RL + MPC locomotion, inverse kinematics, sim-to-real, sensor fusion. MuJoCo, Isaac Lab, ROS 2."
    url: "/control-robotics/"
    btn_label: "Open"
    btn_class: "btn--primary"
  - title: "Mechanical Design"
    excerpt: "Mechanisms and product design, CAD → prototype → test, FEA/CFD, GD&T."
    url: "/mechanical-design/"
    btn_label: "Open"
    btn_class: "btn--primary"
  - title: "Manufacturing"
    excerpt: "CNC, casting, automation tooling, QA and configuration-controlled docs."
    url: "/manufacturing/"
    btn_label: "Open"
    btn_class: "btn--primary"
  - title: "Personal Projects"
    excerpt: "Data science and smaller builds — including 15-model F1 race-outcome ML study."
    url: "/personal-projects/"
    btn_label: "Open"
    btn_class: "btn--primary"
---

{% include feature_row id="intro" type="center" %}

## Featured Demo — Cooperative Human-Robot Carrying

<div style="max-width: 860px; margin: 0 auto 1rem; border-radius: 14px; overflow: hidden; box-shadow: 0 14px 34px rgba(0,0,0,0.16);">
  <video autoplay loop muted playsinline preload="metadata"
         poster="/assets/images/projects/Go2/coop-demo-poster.jpg"
         style="width: 100%; display: block;">
    <source src="/assets/images/projects/Go2/coop-demo.mp4" type="video/mp4">
  </video>
</div>

<p style="text-align:center; color:#666; font-size:0.95rem; max-width:860px; margin:0 auto 2rem;">
A Unitree Go2 quadruped and a human jointly carry an oversized object — intent inferred from the robot's <strong>onboard IMU, foot-force, and joint sensors only</strong>, with no external motion capture. Built on a unified three-layer RL + MPC control stack. <a href="/projects/go2-quadruped/">Read the full write-up →</a>
</p>

## Explore by discipline

{% include feature_row %}
