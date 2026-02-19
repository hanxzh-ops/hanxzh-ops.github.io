---
layout: single
title: "Mechanical Design"
permalink: /mechanical-design/
---

High-impact mechanism + product design work (CAD, prototyping, DFM, testing).

## Featured case studies
{% assign items = site.projects | where: "pillar", "mechanical-design" %}
{% for p in items %}
- [{{ p.title }}]({{ p.url }}) — {{ p.excerpt }}
{% endfor %}

## Latest build logs
{% assign posts = site.posts | where: "pillar", "mechanical-design" %}
{% for post in posts limit:6 %}
- [{{ post.title }}]({{ post.url }}) ({{ post.date | date: "%Y-%m-%d" }})
{% endfor %}
