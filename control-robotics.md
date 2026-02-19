---
layout: single
title: "Control & Robotics"
permalink: /control-robotics/
---

Controls, simulation-to-real, validation, and mechatronics projects (kept recruiter-friendly).

## Featured case studies
{% assign items = site.projects | where: "pillar", "control-robotics" %}
{% for p in items %}
- [{{ p.title }}]({{ p.url }}) — {{ p.excerpt }}
{% endfor %}

## Latest build logs
{% assign posts = site.posts | where: "pillar", "control-robotics" %}
{% for post in posts limit:6 %}
- [{{ post.title }}]({{ post.url }}) ({{ post.date | date: "%Y-%m-%d" }})
{% endfor %}
