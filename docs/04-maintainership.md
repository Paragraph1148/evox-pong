# 4. Maintainership — the official rules, and where you stand

## The rule that decides your next move

From the [Evolution X wiki, "Apply for maintainership"](https://wiki.evolution-x.org/apply-for-maintainership):

> **If the device already have the active maintainer, you are not allowed to publish any
> unofficial builds unless the maintainer resigned, removed, or approved it.**

And Pong's own OTA metadata says, right now:

```json
"maintainer": "hiroshi. (Superuser)",
"currently_maintained": true,
"github": "joshuah345"
```

So: **building for yourself is fine. Publishing is not — not yet.** A five-week gap in commits
(device tree last touched 2026-08-05; today 2026-09-10) is not abandonment by any project's
standard, and "Superuser" marks hiroshi as senior within the project rather than a lapsed
volunteer. Treating this as a vacancy would be both factually premature and the fastest way to
have an application rejected.

## The full requirements

- You must **own the device**
- **Medium knowledge of git**
- **English only** with users and the team
- You must already have an **unofficial build that is stable for daily use** before applying
- Your **device tree must be public**
- You must not be a placeholder for a removed maintainer
- **18 or older**
- Apply by joining the official Discord and sending **`/apply`**

Read their Maintainers Code of Conduct in full before applying.

Note the ordering built into that list: **the working build comes before the application.** You
cannot apply your way into this. Phases 1–4 in [`02-bringup-plan.md`](02-bringup-plan.md) *are*
the application.

## What being official actually involves

From [`Evolution-X/onboarding`](https://github.com/Evolution-X/onboarding):

- Device repos are created under the **Evolution-X-Devices** GitHub org and you get push access
- You wire up `evolution.dependencies` in each repo so **roomservice** can auto-sync your trees
- You must **sign all releases** with the project's private keys
  (`vendor/evolution-priv/keys/`) — leaking them, even accidentally, is permanent removal
- You **upload releases and installation images to SourceForge** yourself, via `scp`
- You declare the **initial installation images** needed to boot EvoX recovery from stock
  (for Pong that is just `recovery`)
- **TWRP and derivatives may not be substituted** for Evolution X recovery
- You maintain the XDA thread and handle user support

That last line is the real job. The build is a weekend; the support is forever. You said you are
willing to maintain indefinitely — good, because that is what is actually being asked.

---

## The path that works

**1. Do the work first, quietly.** Get a self-built 11.9 booting, then get an A17 build booting.
Keep your trees public on your own GitHub from day one — that is both a requirement and your
evidence.

**2. Contribute upstream before you ask for anything.** Send fixes to hiroshi's Pong trees and to
LineageOS. A maintainer's endorsement of someone already sending them good patches is worth more
than any application text, and it is how you find out whether they are actually stepping away.

**3. Talk to hiroshi before publishing anything.** Not to ask them to step aside — to ask whether
they would approve unofficial A17 builds, or want a co-maintainer, or would like the A17 work
merged into the official trees. Any of those three outcomes gets Pong onto 12.x, which is your
actual goal. Being the person whose name is on it is not the same goal, and confusing the two is
what gets applications rejected.

**4. Apply only when you have a build people could daily-drive** — and after hiroshi has either
approved, resigned, or been removed.

## A realistic note on timing

You would not be porting Pong to a mature branch. **Zero of LineageOS's 315 official devices are
on `lineage-24.0` yet**, and only 3 devices across all of Evolution X have a 12.x build. Much of
what you hit will be genuinely unsolved rather than solved-and-documented, and some of it will be
fixed upstream a month later by someone else.

That is not a reason to stop. It is a reason to expect the first working build to take months
rather than weekends, to keep 11.9 as your daily driver throughout, and to measure progress in
subsystems that came up rather than in release dates.
