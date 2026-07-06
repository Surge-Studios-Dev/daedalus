# Ember · Spec §6 + §8 draft (for merge into design/spec.md after stamping)

Drafted from INTAKE 2026-07-06. Streak rule (referenced throughout): a group's
streak ticks +1 when EVERY non-away member answers before midnight group-local;
prompt drops 9:00 AM group time (adjustable). Answers reveal only after you
answer. Restore: pro, 1 per group per calendar month, within 72h of the break.

## 6. Screen-by-screen specification

### Factory screens (deltas)

- **ONB-01 · Onboarding.** Steps: (1) welcome - "your people, on your home
  screen"; (2) value moment - mock widget filling with a crew's sky photos;
  (3) create-or-join fork (join deep-links skip to GRO-04); (4) widget install
  walkthrough (platform add-widget flow, skippable, re-entry from SET-01);
  (5) notification pre-permission framed as "know when the prompt drops."
  The aha moment is the first group created/joined - onboarding ends on
  TOD-01 with today's prompt live.
- **AUTH-01/02.** Providers: email, apple, google; no guest mode (identity is
  the product). Copy only.
- **PAY-01 · Paywall.** One lifetime unlock. Contextual headlines:
  `unlimited_groups` -> "One fire per person is free. Light more." ·
  `premium_packs` -> "Fresh sparks for your crew." ·
  `streak_restore` -> "Bring the fire back."
- **SET-01 deltas.** Rows: "Add the widget" (re-runs walkthrough), "Vacation
  mode" (per-group away toggle), "Notification times", cross-promo slot.

### WID-01 · Home-screen widget [P0] - THE quality bar

- **Purpose:** your crew's day, always fresh, on the home screen.
- **Layout:** small = latest friend answer (or prompt card if you haven't
  answered); medium = latest answer + answered-avatars row + streak flame
  count. One widget instance = one group (multi-group users add multiple
  widgets; group picked in the widget config sheet).
- **Refresh:** push-driven - every new answer in the group triggers a silent
  push -> widget timeline reload. Budget guard: coalesce to <= 1 reload per
  5 min per group. Opening the app always reconciles.
- **States:** unanswered (prompt + avatars of who's answered, own answer
  blurred-out slot), answered (rotating friends' answers), day complete
  (recap frame + flame tick animation on next reload), stale/no network
  (last content + subtle "as of" timestamp, never blank), signed-out /
  no group (single CTA frame). NEVER an empty white box.
- **Navigation:** tap unanswered -> answer flow (TOD-02/03); tap answered ->
  TOD-04 for that group.

### TOD-01 · Today home [P0]

- **Purpose:** every group's prompt and progress for today, one glance.
- **Layout:** header (date, no clutter); one card per group: group name +
  emoji, streak flame count, today's prompt text, answered-avatars row,
  primary state area (your camera/vote CTA if unanswered; latest answers
  strip if answered). Single-group users: card expands to full-bleed.
- **Interactions:** card CTA -> answer flow for that group's prompt type;
  answers strip -> TOD-04; avatars row -> TOD-04; long-press card -> GRO-02.
- **States:** loading (skeleton cards); empty (no groups - invite-a-crew
  hero, CTA to GRO-03/GRO-04; this is first-run); pre-drop (card shows
  "prompt drops at 9:00" countdown); all-answered (card celebrates quietly -
  flame tick, no confetti spam); error (banner per 4.5, cached cards stay).
- **Navigation:** in - tab, widget tap, NTF deep links (`ember://today`);
  out - answer sheets, TOD-04, GRO-02.

### TOD-02 · Answer: photo / challenge proof [P0]

- **Purpose:** live camera capture, under 10 seconds, no library, no filters.
- **Layout:** full-screen camera; prompt text pinned top ("post your sky" /
  challenge task framing); shutter, flip-camera, flash; caption field
  (optional, 80 chars) post-capture with Retake / Send It.
- **Interactions:** shutter -> preview; Send -> upload + return to TOD-01
  with the card now answered; Retake unlimited; close (x) confirms nothing
  ("your crew is waiting" NOT used - just closes; no guilt copy).
- **States:** camera permission denied (inline explainer + Settings link);
  offline/upload-fail (answer queues locally, card shows "sending...",
  streak credit granted at capture time, not upload time); challenge
  variant adds a task checklist line above the shutter.
- **Navigation:** in - TOD-01 CTA, widget, center Answer button; out - back
  to origin. Center Answer button with multiple unanswered groups opens a
  chooser sheet first; when all answered it shows a check and opens TOD-01.

### TOD-03 · Answer: poll vote [P0]

- **Purpose:** one-tap positive vote.
- **Layout:** sheet: prompt ("who's the best hype person"); options = member
  avatars+names (member polls) or pack-provided text options; vote button.
- **Interactions:** tap option -> selected; Vote -> recorded, sheet flips to
  live results (bars, warm framing - "everyone's somebody's hype person"
  footer on member polls). Results visible only after voting.
- **States:** self-vote allowed (it's funny); tie - all leaders highlighted;
  voted-for member has left group - name shows as "(left the fire)";
  offline - vote queues like TOD-02.
- **Navigation:** in - TOD-01/widget/Answer button; out - dismiss to origin.

### TOD-04 · Day detail [P0]

- **Purpose:** the full day for one group - everyone's answers + reactions.
- **Layout:** prompt header + date + flame; answer grid/list (photos
  full-width, poll results card); per-answer emoji-reaction row (6 fixed
  warm emoji, tap toggles, tiny avatar cluster shows who reacted - no
  counts leaderboard); missing members shown as unlit slots ("waiting on
  Sam"), never shame copy.
- **Interactions:** react; tap photo -> full-screen viewer; report/hide on
  long-press (UGC: report content, block member -> confirmation, hides
  their content locally pending review).
- **States:** you haven't answered (whole grid blurred + "answer to reveal"
  CTA); partial day; complete day (recap ribbon); past days read-only
  except reactions.
- **Navigation:** in - TOD-01, widget, GRO-06 archive; out - viewer, back.

### GRO-01 · Groups home [P0]

- **Purpose:** all your fires in one place.
- **Layout:** group cards (name, emoji, flame count, member avatars, today
  answered/total); footer actions: Start a group / Join with code.
- **Interactions:** card -> GRO-02; Start -> GRO-03 (2nd+ group on free ->
  gate `unlimited_groups`); Join -> GRO-04 (same gate on free).
- **States:** empty (first-run hero, same CTAs); one group (card + gentle
  "your other crews belong here too" secondary slot, chip-marked pro).
- **Navigation:** in - tab; out - GRO-02/03/04, PAY-01.

### GRO-02 · Group detail [P0]

- **Purpose:** the group's hearth - streak, members, archive door, health.
- **Layout:** flame hero (streak count, longest-streak subline); today
  status row; members list (avatar, name, answered-today dot, away badge);
  archive calendar preview (GRO-06); settings gear (GRO-05).
- **Interactions:** member long-press (self) -> vacation-mode toggle; invite
  button -> share sheet with invite link (`ember://join/{code}`); broken
  streak state shows Restore button -> pro gate `streak_restore`, then
  restore confirm (names the streak: "Relight the 34-day fire?").
- **States:** streak alive / broken (flame dims to ember, 72h restore
  window countdown) / restored (relight animation - THE signature motion
  moment); member count at cap (12) hides invite.
- **Navigation:** in - GRO-01, TOD-01 long-press; out - GRO-05/06, TOD-04,
  share sheet.

### GRO-03 · Create group [P0]

- **Purpose:** name the crew, pick the vibe, invite.
- **Layout:** name field, emoji pick, prompt-pack pick (starter packs free;
  premium packs chip-marked -> gate `premium_packs`), timezone (defaults to
  creator's, shown explicitly - it anchors the day), drop-time pick
  (default 9:00).
- **Interactions:** Create -> group live immediately with today's prompt if
  before drop-time cutoff, else starts tomorrow (say which, explicitly);
  lands on invite share sheet.
- **States:** name collision fine (groups aren't global); free user
  creating 2nd group -> PAY-01 `unlimited_groups` before this screen.
- **Navigation:** in - GRO-01, ONB fork; out - GRO-02.

### GRO-04 · Join group [P0]

- **Purpose:** invite link -> inside the fire in two taps.
- **Layout:** group preview card (name, emoji, member avatars, flame count),
  Join button, decline link.
- **Interactions:** Join -> member added, lands TOD-01 with today's prompt;
  joining today never counts against today's streak (you owe answers from
  tomorrow).
- **States:** expired/invalid code (friendly dead-end + "ask for a fresh
  link"); already a member (opens GRO-02); group at cap (12) - explains,
  no join; free user with an existing group -> PAY-01 `unlimited_groups`
  (link preserved through purchase/dismiss); signed-out -> AUTH-01 first,
  link survives auth.
- **Navigation:** in - deep link `ember://join/{code}`, GRO-01; out -
  TOD-01, PAY-01, AUTH-01.

### GRO-05 · Group settings [P0]

- **Purpose:** tune or leave one group.
- **Layout:** rows - name/emoji edit, prompt pack, drop time, timezone
  (creator only), mute notifications for this group, vacation mode,
  members (kick - creator only), invite link reset, Leave group.
- **Interactions:** Leave names the object ("Leave Sunday Crew? The streak
  needs everyone."); creator leaving hands creator role to oldest member
  or deletes if last out; kick confirms and removes from streak math from
  tomorrow.
- **States:** last member leaving -> delete confirm (archive gone - named
  plainly).
- **Navigation:** in - GRO-02 gear; out - back, AUTH flows unaffected.

### GRO-06 · Archive [P1]

- **Purpose:** the compounding asset - every day the fire has burned.
- **Layout:** month calendar, days as thumbnails (photo days) / icons
  (poll/challenge); streak runs visually connected.
- **Interactions:** day -> TOD-04 (read-only); recap share (day_recap card
  export) [P1, sharing rail].
- **States:** gaps render as unlit days without comment; 200+ days paginate
  by month.
- **Navigation:** in - GRO-02 preview; out - TOD-04.

## 8. Edge-case master list (QA checklist) - domain edges

- **Today:** midnight rollover while answer sheet is open (submit counts for
  the day the capture started - capture-time credit) · upload queued offline
  then app killed (queue survives restart, retries on launch) · two devices
  same account answer simultaneously (first write wins, second sees "already
  answered") · prompt-drop push arrives but content fetch fails (card shows
  prompt from push payload cache) · poll target leaves group mid-day (votes
  stand, name marked left) · reaction to answer whose author was kicked
  (content hidden, reactions orphaned silently) · member joins at 11:58 PM
  (owes nothing until tomorrow) · center Answer with 3 unanswered groups
  (chooser sheet order = closest deadline first) · delete own answer before
  midnight (allowed once, streak credit revoked, re-answer allowed; after
  midnight immutable) · group timezone vs member timezone (all deadlines
  render in MEMBER local time with group-day labeling).
- **Groups:** free user taps invite while already in one group (gate, link
  survives paywall round-trip AND auth round-trip) · restore meter: broken
  twice in one calendar month (second restore unavailable, copy says when it
  resets) · restore attempted at hour 73 (window closed, flame stays out,
  streak restarts at 1 - no cliff surprise: countdown was visible) · away
  member returns early and answers (counts normally, away flag clears) ·
  ALL members away simultaneously (day is a freebie, streak holds, archive
  marks "everyone away") · creator account deleted (role hands off, deleted
  member's answers show "removed" placeholder per privacy delete) · 12/12
  members and one leaves then a stale invite link is used (join works,
  cap re-checked at join time) · group with 400-day archive cold-loads
  GRO-02 in <1s (calendar preview lazy).
- **Widget (quality bar):** silent-push throttled by OS (widget falls back
  to scheduled timeline refresh every 30 min - staleness ceiling, "as of"
  shown past 60 min) · push arrives while device offline (reload no-ops,
  reconciles on connectivity) · user answers in-app (own widget updates
  same reconcile, never shows you as unanswered after answering) · group
  deleted while widget pinned to it (CTA frame "this fire is out - pick a
  group") · signed out from app (widget flips to sign-in frame on next
  reload, never shows another account's photos) · iOS widget-budget
  exhaustion day-long soak test (content is never >30 min behind an
  answer).
- **System:** Dynamic Type AX sizes on TOD-04 (densest) · VoiceOver full
  pass on the core loop (prompt -> capture -> reveal -> react) · Reduce
  Motion alternates for flame tick + relight · offline behavior per 4.4
  (Today/answers queue-and-sync; Groups read-only offline; widget per
  above).
