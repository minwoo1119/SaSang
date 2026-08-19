# Visual Design Direction

Sasang must use a minimal, photo-first visual language inspired by:

- Apple's modern Liquid Glass design language
- Setlog's simple, playful, content-focused mobile UI

Reference:
- Apple Liquid Glass / Human Interface Guidelines
- https://apps.apple.com/us/app/setlog-friends-camera/id6587576438
- https://play.google.com/store/apps/details?id=com.newchat.setlog

These references are visual and interaction references only.
Do not reproduce Setlog's branding, logo, proprietary assets, or exact screen layouts.

## Core Design Principle

The map and the user's travel photos are the primary visual content.

UI controls must visually recede until the user needs them.

Use the following hierarchy:

Content
→ Map
→ Travel photos
→ Region boundaries

Controls
→ Navigation
→ Tabs
→ Buttons
→ Sheets

Do NOT make UI cards more visually prominent than the map or photos.


# Liquid Glass Direction

Use Apple's Liquid Glass philosophy rather than simply applying blur everywhere.

Glass is a functional UI layer floating above content.

Good candidates for glass treatment:

- bottom navigation
- floating navigation controls
- Korea / World map selector
- compact floating action buttons
- contextual map controls
- bottom-sheet control areas
- floating headers when appropriate

Do NOT apply glass indiscriminately to:

- every card
- every list item
- the map itself
- photo content
- large page backgrounds
- ordinary text containers

The application must never look like a collection of translucent glass cards.


## Glass Appearance

Glass surfaces should feel:

- translucent
- lightweight
- adaptive to background content
- softly separated from underlying content
- rounded
- physically layered
- visually calm

Avoid fake glass effects created from excessive:

- borders
- white gradients
- glow
- strong shadows
- high-opacity white backgrounds

Glass should primarily communicate depth and interaction hierarchy.


# Sasang Visual Language

Sasang should feel:

minimal
personal
warm
photo-centric
playful but restrained
native
lightweight

It should NOT feel:

enterprise
dashboard-like
material-heavy
card-heavy
over-designed
futuristic
neon
gaming-oriented


# Layout

Prefer edge-to-edge content.

The map should occupy most of the home screen.

Avoid wrapping the main map inside a large card.

Preferred:

┌─────────────────────────────┐
│                             │
│        MAP / PHOTOS         │
│                             │
│                             │
│      [ 한국 | 세계 ]         │ ← floating control
│                             │
│                             │
│                             │
│                             │
│      ╭──────────────╮       │
│      │ floating tab │       │ ← glass navigation
│      ╰──────────────╯       │
└─────────────────────────────┘

Avoid:

┌─────────────────────────────┐
│ ┌─────────────────────────┐ │
│ │       MAP CARD          │ │
│ │                         │ │
│ └─────────────────────────┘ │
│                             │
│ ┌────────┐  ┌────────┐     │
│ │ CARD   │  │ CARD   │     │
│ └────────┘  └────────┘     │
└─────────────────────────────┘


# Shape Language

Use generous continuous rounded corners.

Prefer:

- capsules for compact selectors
- circular icon buttons
- large continuous-radius bottom sheets
- rounded floating navigation

Avoid:

- rectangular buttons with small radius
- excessive outlined boxes
- nested cards
- unnecessary dividers


# Color

The user's photos should provide most of the screen's color.

Base UI should remain mostly neutral.

Prefer:

- white
- off-white
- near-black text
- subtle neutral gray
- translucent materials

Use one restrained Sasang accent color only where interaction state needs emphasis.

Do not introduce multiple decorative colors merely to make the UI look colorful.


# Typography

Typography should be simple and highly legible.

Prefer platform-native typography characteristics.

Use clear hierarchy through:

- size
- weight
- spacing

Do not rely on multiple fonts or decorative typography.

Keep labels short.

Avoid unnecessary explanatory text when the interaction is visually obvious.


# Navigation

Navigation should feel native to each platform.

On iOS, prefer native-feeling floating / glass navigation.

On Android, preserve the same Sasang visual identity while respecting Android interaction behavior.

Do not force pixel-identical iOS controls onto Android.


# Motion

Motion should reinforce physical layering.

Prefer:

- subtle spring animations
- smooth sheet transitions
- gentle scale feedback
- morphing / expanding controls
- map region selection transitions

Avoid:

- dramatic bounce
- long animations
- decorative motion
- excessive parallax

Interactions should normally complete quickly and feel responsive.


# Photo-First Rule

When deciding between a decorative UI element and giving more space to a travel photo:

choose the photo.

When deciding between a large UI container and giving more space to the map:

choose the map.

Photos and map geometry are Sasang's identity.


# Setlog Reference Rule

Use Setlog primarily as a reference for:

- low visual density
- simple navigation
- content-first composition
- playful but restrained interaction
- large touch targets
- minimal chrome

Do NOT copy:

- Setlog branding
- its logo
- exact colors
- exact screen layouts
- proprietary graphical elements

Sasang must develop its own visual identity.


# Platform Implementation

For React Native + Expo:

On supported iOS versions, prefer native Liquid Glass effects when practical.

Prefer:
- expo-glass-effect / GlassView for native iOS glass surfaces
- native navigation primitives where stable
- expo-blur as a fallback or for non-native blur requirements

On Android:

Do not attempt to emulate Apple's native optical effect pixel-for-pixel.

Use:
- translucent surfaces
- restrained BlurView usage
- subtle elevation
- equivalent rounded geometry

The goal is visual consistency, not identical rendering.


# Critical Design Constraints

Before implementing a screen, verify:

1. Is the map/photo still the most prominent element?
2. Are glass effects limited primarily to interactive controls?
3. Can any container or card be removed?
4. Is there unnecessary text?
5. Is there unnecessary color?
6. Is there unnecessary border or shadow?
7. Does this feel like a native mobile product rather than a web dashboard?

If the answer violates these principles, simplify the screen before proceeding.