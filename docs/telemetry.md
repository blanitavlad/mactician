# Telemetry and privacy

Mactician has two independent telemetry levels. The term "unlinkable" here
means that the JSON has no stable identifier with which to connect events. That
reduces privacy risk but does not by itself determine consent requirements in
every jurisdiction.

## Basic first-session event

After the first session that reached the runtime `ready` state has ended,
Mactician sends `first_game_session` once per retained macOS preferences domain:

```json
{
  "schema_version": 2,
  "event_id": "random-uuid",
  "event": "first_game_session",
  "occurred_on": "2026-08-09",
  "duration_bucket": "30_60m",
  "launcher_version": "1.0.0",
  "launcher_build": "33"
}
```

Allowed buckets are `under_5m`, `5_15m`, `15_30m`, `30_60m`, `60_120m`,
`120_240m`, and `over_240m`. The event does not contain an installation or
device identifier, exact duration/time, device properties, launcher settings,
language, identity, logs, or network addresses.

The pending event is written to `telemetry.firstSession.pending.v2` before the
request. A retry reuses its original `event_id`. HTTP 2xx or a duplicate
acknowledgement completes it; 408, 429, 5xx, and network failures retain it. An
unrecoverable 4xx is terminal. A pending event older than seven days is deleted
without replacement. Resetting Android/TFT data does not change this state.

The server aggregates the event immediately by received date, launcher
version/build, and duration bucket. The dashboard name is **Approximate
activated installations**. It is approximate because macOS accounts can count
separately, clearing preferences or reinstalling can count again, installs with
no completed session are absent, and an event can expire during extended
offline use. It must not be labelled `unique_users`, `people`, or `MAU`.

## Optional extended diagnostics

Extended diagnostics are created and sent only when
`telemetry.extendedConsent.state.v1` is `granted` for consent version 1.
`unknown` and `denied` both prohibit creation and transmission.

Each completed session then sends an independent event:

```json
{
  "schema_version": 2,
  "event_id": "random-uuid",
  "event": "game_session_diagnostics",
  "occurred_at": "2026-08-09T12:34:56Z",
  "duration_seconds": 2871,
  "launcher_version": "1.0.0",
  "launcher_build": "33",
  "consent_version": 1,
  "launcher_settings": {
    "profile_id": "quality",
    "effects_quality_id": "performance",
    "display_width": 2560,
    "display_height": 1440,
    "display_density": 416,
    "ui_scale_percent": 100,
    "guest_memory_mb": 8192,
    "guest_cpu_cores": 6
  },
  "device": {
    "model_identifier": "Mac16,1",
    "macos_version": "26.0.0",
    "physical_memory_mb": 32768,
    "logical_cpu_count": 10
  }
}
```

It never contains an installation ID, Mac name, serial number, MAC address,
Apple ID, macOS username, Riot ID, IP field, application list, or game logs.
Turning diagnostics off immediately stops event creation and deletes the entire
local diagnostic queue; it does not affect the pending basic event. A change to
the diagnostic field set increments `consent_version` and invalidates prior
consent.

## Server retention and processing

The API strictly rejects unknown fields and out-of-range values, bounds request
size, and deduplicates by `event_id`. It does not persist source IP or
User-Agent and never logs an invalid request body. Client addresses exist only
in the in-memory rate limiter with a short TTL.

Basic payloads are not retained as raw events. Their aggregates are retained;
only SHA-256 event-ID hashes remain for deduplication and expire after 14 days.
Raw extended diagnostic events are retained for 90 days. Longer-lived
aggregates must avoid small identifiable cohorts.

The release order is server compatibility, schema-v2 verification, public
privacy-policy publication, then the launcher update. No legacy event contract
is retained because the previous API and its data belonged only to the local
pre-release laboratory.
