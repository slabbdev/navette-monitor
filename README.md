# navette-monitor

**The check Checkly can't run.** Landing + runnable evidence that synthetic
monitoring built on a real browser engine with a real session walks past bot
walls (Cloudflare challenges, DataDome) that stop headless-Chromium-from-a-
datacenter monitors.

- **Page:** https://slabbdev.github.io/navette-monitor/
- **Evidence:** captured 2026-10-27 18:12 UTC against
  `vinted.fr/catalog?search_text=nike` — naive HTTP monitor got
  `403 cf-mitigated: challenge`; a navette session cleared the challenge in
  ~6 s and asserted 1,358 listing cards.
- **Re-run it:** `./check.sh [url]` (needs a navette daemon on :8766).

## Repo layout

```
index.html                     the landing page (self-contained, no build)
check.sh                       the actual two-monitor check, ~40 lines of bash
assets/vinted-check-pass.png   screenshot of the passing check (2026-10-27)
```

## What is navette?

A local browser daemon: the OS WebKit engine, isolated sessions, cookie jars
in the system keychain, human handoff for 2FA/consent — all driven over a
plain JSON HTTP API. No SDK, no headless Chromium, no automation flags.
Fleet evidence from datacenter IPs: [starflotte](https://github.com/slabbdev/starflotte).

Independent project. Not affiliated with Checkly, Cloudflare, DataDome or
Vinted; all trademarks are their owners'.
