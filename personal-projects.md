---
layout: single
title: "Personal Projects"
permalink: /personal-projects/
---

Smaller builds, prototypes, experiments, and “weekend engineering”.

## Featured
{% assign items = site.projects | where: "pillar", "personal-projects" %}
{% for p in items %}
- [{{ p.title }}]({{ p.url }}) — {{ p.excerpt }}
{% endfor %}

## Latest logs
{% assign posts = site.posts | where: "pillar", "personal-projects" %}
{% for post in posts limit:10 %}
- [{{ post.title }}]({{ post.url }}) ({{ post.date | date: "%Y-%m-%d" }})
{% endfor %}
