---
layout: single
title: "Manufacturing"
permalink: /manufacturing/
---

Work focused on manufacturing processes, automation, throughput, QA, and documentation.

## Featured case studies
{% assign items = site.projects | where: "pillar", "manufacturing" %}
{% for p in items %}
- [{{ p.title }}]({{ p.url }}) — {{ p.excerpt }}
{% endfor %}

## Latest build logs
{% assign posts = site.posts | where: "pillar", "manufacturing" %}
{% for post in posts limit:6 %}
- [{{ post.title }}]({{ post.url }}) ({{ post.date | date: "%Y-%m-%d" }})
{% endfor %}
