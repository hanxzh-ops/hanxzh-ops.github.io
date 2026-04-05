---
layout: single
title: "Mechanical Design"
permalink: /mechanical-design/
---

High-impact mechanism + product design work (CAD, prototyping, DFM, testing).

<style>
  .project-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
    gap: 1.5rem;
    margin: 1.5rem 0 2rem;
  }
  .project-card {
    border: 1px solid #e5e5e5;
    border-radius: 14px;
    overflow: hidden;
    background: #fff;
    box-shadow: 0 10px 24px rgba(0, 0, 0, 0.06);
    transition: transform 0.18s ease, box-shadow 0.18s ease;
  }
  .project-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 14px 30px rgba(0, 0, 0, 0.1);
  }
  .project-card a {
    color: inherit;
    text-decoration: none;
    display: block;
  }
  .project-card__image {
    aspect-ratio: 4 / 3;
    overflow: hidden;
    background: #f3f3f3;
  }
  .project-card__image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }
  .project-card__body {
    padding: 1rem 1rem 1.1rem;
  }
  .project-card__title {
    margin: 0 0 0.5rem;
    font-size: 1.05rem;
    line-height: 1.3;
  }
  .project-card__excerpt {
    margin: 0;
    color: #555;
    font-size: 0.95rem;
    line-height: 1.55;
  }
</style>

## Featured case studies
{% assign items = site.projects | where: "pillar", "mechanical-design" %}
<div class="project-grid">
{% for p in items %}
  <article class="project-card">
    <a href="{{ p.url }}">
      <div class="project-card__image">
        <img src="{{ p.header.teaser | default: '/assets/images/avatar.jpg' }}" alt="{{ p.title }}">
      </div>
      <div class="project-card__body">
        <h3 class="project-card__title">{{ p.title }}</h3>
        <p class="project-card__excerpt">{{ p.excerpt }}</p>
      </div>
    </a>
  </article>
{% endfor %}
</div>

## Latest build logs
{% assign posts = site.posts | where: "pillar", "mechanical-design" %}
{% for post in posts limit:6 %}
- [{{ post.title }}]({{ post.url }}) ({{ post.date | date: "%Y-%m-%d" }})
{% endfor %}
