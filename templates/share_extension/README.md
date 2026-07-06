# Share-extension intake — platform templates

The platform half of `packages/surge_import_queue`, extracted from Ladle's
share pipeline. Content shared INTO the app (a URL from Safari/TikTok, a
blob of caption text) is queued durably by the platform layer and drained
by Flutter over one method channel. Copy these files into a stamped app and
replace the marked constants; the Dart half (inbox, drain plan, coalescing)
comes from `surge_import_queue`.

## The contract

One method channel (name it `<slug>/share`), same calls on both platforms:

| Call | Returns | Semantics |
|---|---|---|
| `drainPendingImports` | `List<String>` | Return AND clear the platform queue. Values go straight into the durable `ShareInbox` before anything else touches them, so an app kill can't lose a share. |
| `takePresentOnOpen` | `bool` | One-shot read-and-clear: was the app (re)opened by a share that wants its progress UI surfaced? Consume it on EVERY drain — a stale flag left set pops UI for an unrelated job days later. |
| `drainNow` (native → Dart) | — | Cross-process ping: a share was queued while the app is already foreground with no lifecycle transition coming (iPad split view). Dart answers by draining. |

Drain triggers to wire on the Dart side (all through `DrainCoalescer` —
they overlap in practice and a double drain double-starts jobs): first
frame after launch, every foreground resume, `drainNow`, and any listener
that can raise the allowance mid-session (credits arriving, upgrade).

## iOS (`ShareViewController.swift`, `AppDelegate.swift`)

- Create a Share Extension target; give the app AND the extension the same
  App Group (`group.<bundle-id>`); set the group id in both files.
- The extension writes to `UserDefaults(suiteName: appGroup)` and posts a
  Darwin notification; the AppDelegate observes it and pokes `drainNow`.
- Extraction order matters: try the URL attachment first, then plain text.
  TikTok/Instagram share as text ("caption … https://vm.tiktok.com/…"), so
  the text path pulls the link out with NSDataDetector — prefer matches
  written with an explicit http(s) scheme and take the LAST one (captions
  mention bare domains like "recipe on myblog.com" that also detect as
  links, and the shared link trails the caption; first-match imported the
  wrong URL in production).
- Keep the extension's own UI minimal (queued confirmation + "Open app").
  Anything richer (inline processing, previews) is per-app custom work —
  Ladle's 1,100-line version is the reference, not the template.

## Android (`MainActivity.kt`)

- Declare an ACTION_SEND intent filter + `launchMode="singleTop"` in the
  manifest. The running Activity receives subsequent shares via
  `onNewIntent`; stash before Flutter resumes and the next drain wins the
  race for free.
- Android has no extension UI: picking the app in the share sheet always
  foregrounds it, so every share sets the present-on-open flag (iOS sets it
  only for an explicit "Open app").

## Rules that came from shipped bugs

- **Queue first, durable inbox second, THEN start work.** Every payload
  lands in `ShareInbox` before a job starts; entries leave only when the
  user has seen the job through (saved / discarded / dismissed failure).
- **Cancelling an in-flight job must also remove its inbox entry**, or the
  cold-start replay resurrects work the user explicitly killed.
- **Charge the meter once per entry across replays** — `ShareInbox`'s
  metered flag exists because a cold-start replay double-charged.
- **Cap failure retries** via `bumpFailures`; a permanently-failing share
  otherwise retries on every launch forever.
