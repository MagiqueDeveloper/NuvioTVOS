# NuvioTV domain glossary

- A **title** is a user-visible movie or series identity represented by `MediaSummary`.
- A **stream** is a playable source selected for a title; it is represented as `MediaStream` so it cannot be confused with Foundation's `Stream` type.
- A **playback request** joins one title and one selected stream with an optional resume position.
- A **profile** scopes progress and library state. The active profile is selected by the profile store.
- **Progress** is a position/duration record for a title and profile. Continue Watching and Top Shelf are derived views of progress.
- A **repository** loads domain data. A **store** persists domain state. An **adapter** implements either seam for a concrete backend.
- The **composition root** is `NuvioTVApp` plus `AppDependencies`; feature and UI modules do not create storage, networking, or playback implementations.
