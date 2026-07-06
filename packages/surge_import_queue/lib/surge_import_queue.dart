/// Surge import queue — share-sheet intake (Tier 3 System).
///
/// The pure-Dart half of "share a link/text INTO the app": the durable
/// inbox shared payloads land in, the drain plan that decides what starts
/// under a limited free-tier allowance, and the coalescer that stops
/// overlapping drain triggers from double-starting work.
///
/// The platform half (iOS share extension + app group, Android ACTION_SEND,
/// the method-channel contract) lives in `templates/share_extension/` at the
/// Daedalus repo root; this package's README documents the contract.
library;

export 'src/drain_coalescer.dart';
export 'src/drain_plan.dart';
export 'src/share_inbox.dart';
