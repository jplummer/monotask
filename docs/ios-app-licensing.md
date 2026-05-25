# iOS App Licensing – Public Repo + Paid App Store

## The Situation

You want to keep your source code publicly visible on GitHub while selling the app on the App Store. Standard open source licenses work against that goal.

## Why Common Licenses Don't Work

**Permissive (MIT, Apache 2.0, BSD)**
Anyone can fork the repo and publish an identical free app. No recourse.

**GPL v2/v3**
Has a documented, unresolved conflict with Apple's App Store terms. Apple requires DRM and prohibits sublicensing – both incompatible with the GPL. You can distribute your own GPL app on the App Store only if you are the sole copyright holder. The moment you accept outside contributions without a CLA, you lose that control.

**LGPL**
Same App Store conflict as GPL.

---

## Recommendation: PolyForm Noncommercial 1.0

**https://polyformproject.org/licenses/noncommercial/1.0.0/**

Drafted by experienced open source lawyers (including Heather Meeker). Purpose-built for source-available commercial projects.

**What it allows:**
Anyone can read, study, modify, and redistribute the code for non-commercial purposes.

**What it prohibits:**
Commercial use – including App Store distribution at any price – without your explicit permission.

**Why it fits:**
- No GPL/App Store compatibility issue
- Clear and honest: "source is public, but you can't sell it"
- Modern, lawyer-vetted language
- No ambiguity about contributor rights (see CLA note below)

### How to apply it

1. Add a `LICENSE` file to the repo root containing the PolyForm Noncommercial 1.0 text.
2. Add a brief note to your `README`:

   > This project is source-available under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/). You may read, fork, and use it for non-commercial purposes. Commercial use requires a separate license – contact [your email].

---

## Runner-Up: Dual License (GPL + Commercial)

The MySQL/WordPress model. Publish under GPL; anyone who wants App Store distribution must buy a commercial license from you. The GPL/App Store incompatibility becomes the paywall.

**Requires:**
- You own 100% of the copyright in the repo
- A CLA for every outside contributor (non-negotiable)
- More complex to communicate to users

---

## Don't Skip: Contributor License Agreement (CLA)

If you accept pull requests, you need a CLA regardless of which license you choose.

Without one:
- Contributors retain copyright in their work
- You may not have the right to use their contributions commercially
- You lose the ability to relicense later

**Options:**
- Model it on the Apache Individual CLA
- Use [CLA Assistant](https://cla-assistant.io/) on GitHub to automate signing

---

## Decision Summary

| Goal | License |
|---|---|
| Simplest, maximum protection | **PolyForm Noncommercial 1.0** |
| "Open source" credibility + App Store paywall | **GPL v3 + Commercial License** (requires strict CLA discipline) |
| Source visible, all rights reserved | Custom source-available clause (one sentence, legally valid) |

**Go with PolyForm Noncommercial 1.0.**
