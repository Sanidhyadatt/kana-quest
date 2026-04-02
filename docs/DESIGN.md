# Stitch Design System (Synced)

Project: projects/3143519714084300888  
Design System: Sakura Zen (assets/c538308acc914b19869fff44aab700fc)

## Strategy Summary
- Visual north star: "Digital Washi" with editorial spacing and calm interfaces.
- Layout guidance: emphasize negative space ("Ma") and avoid dense, noisy composition.
- Shape guidance: rounded geometry throughout, with large radii for tactile cards and controls.
- Borders: avoid hard 1px separators; use tonal surface layering instead.

## Core UI Rules
- Do not use hard divider lines unless accessibility mode requires fallback.
- Prefer tonal elevation using `surface_*` variants over drop shadows.
- Use subtle gradient for primary CTA treatment: `primary -> primary_container`.
- Keep corner radii at 16dp+ baseline; larger radii for cards and primary actions.

## Typography
- Family: Plus Jakarta Sans
- Prioritize readable line height and generous spacing for Japanese glyph clarity.

## Flutter Implementation Guidance
- Use Material 3 `ColorScheme` seeded from primary token and override key surfaces.
- Define semantic spacing/radius tokens in a dedicated theme extension.
- Build reusable components for:
  - Soft-fill text fields
  - Pill-like character cards
  - Segmented "petal" progress indicator

## Do / Don't
- Do: asymmetrical editorial layouts, generous whitespace, muted contrast hierarchy.
- Don't: pure black text, sharp corners, neon status colors.
