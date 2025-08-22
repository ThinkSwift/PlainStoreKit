# PlainStoreKit

Minimal shared storage for text-first apps (iOS 17+, SwiftData).
Define your own per-app **format** once, feed localized raw text, and store.

## Why
- Stop re-inventing SwiftData models in every app.
- One model (`Record`), one store (`RecordStore`), and a tiny format registry (`Formats`).
- Apps register a parser for their format; the kit normalizes to JSON.

## Requirements
- iOS 17+
- Swift 5.9+

## Installation
Add the package via Xcode:
