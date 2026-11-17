---
name: Workforce Clarity
colors:
  surface: '#f9f9ff'
  surface-dim: '#d3daea'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eefe'
  surface-container-high: '#e2e8f8'
  surface-container-highest: '#dce2f3'
  on-surface: '#151c27'
  on-surface-variant: '#444654'
  inverse-surface: '#2a313d'
  inverse-on-surface: '#ebf1ff'
  outline: '#747686'
  outline-variant: '#c4c5d7'
  surface-tint: '#2a52d3'
  primary: '#053dc0'
  on-primary: '#ffffff'
  primary-container: '#3158d9'
  on-primary-container: '#dbdfff'
  inverse-primary: '#b7c4ff'
  secondary: '#5b5f64'
  on-secondary: '#ffffff'
  secondary-container: '#dde0e7'
  on-secondary-container: '#5f6369'
  tertiary: '#843200'
  on-tertiary: '#ffffff'
  tertiary-container: '#ab4300'
  on-tertiary-container: '#ffd9ca'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dde1ff'
  primary-fixed-dim: '#b7c4ff'
  on-primary-fixed: '#001452'
  on-primary-fixed-variant: '#0038b7'
  secondary-fixed: '#e0e2e9'
  secondary-fixed-dim: '#c3c6cd'
  on-secondary-fixed: '#181c21'
  on-secondary-fixed-variant: '#43474d'
  tertiary-fixed: '#ffdbcc'
  tertiary-fixed-dim: '#ffb695'
  on-tertiary-fixed: '#351000'
  on-tertiary-fixed-variant: '#7c2e00'
  background: '#f9f9ff'
  on-background: '#151c27'
  surface-variant: '#dce2f3'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.005em
  title-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.03em
  caption:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system is engineered for small business owners, shift supervisors, and operational team leads who demand high-velocity scheduling without administrative friction. Built upon principles of operational clarity, speed, and functional transparency—reminiscent of Linear and native Apple productivity utilities—it treats software as an exact instrument rather than an expressive canvas.

The core aesthetic combines utilitarian minimalism with deliberate micro-craft:
- **Restraint Over Decoration:** Zero superfluous gradients, no skeuomorphic dimensionality, and absolute elimination of decorative visual noise.
- **Immediate Data Density:** High information legibility optimized for rapid scanning on mobile devices during busy shift handovers.
- **Slovenian Linguistic Precision:** Native UI copy crafted specifically for authentic operational contexts in Slovenia (e.g., *Urnik*, *Dodeljene izmene*, *Odsotnosti*, *Potrdi menjavo*), balancing conciseness with professional tone.

## Colors

The palette establishes an austere, high-contrast working surface where color conveys semantic meaning, never mere ornamentation.

- **Background & Canvas:** Crisp base at `#F8F9FA` pairs with `#FFFFFF` card surfaces and structural containers.
- **Text Hierarchies:** Near-black `#1C2025` provides authoritative readability for primary content, shift times, and employee names. Muted `#6B7280` handles secondary metadata, timestamps, and role labels.
- **Structural Boundaries:** Precise `#E5E7EB` 1px borders define interactive cards, segmented controls, and structural cell limits.
- **Primary Brand Accent:** Deep operational blue (`#3158D9`) acts as the focal anchor for primary actions, active navigational tabs, and confirmed states.
- **Strict Semantic Accents:**
  - **Success / Potrjeno:** Emerald `#16A34A` text/icon on `#DCFCE7` badge background for active shifts and approved leave.
  - **Warning / V čakanju:** Amber `#D97706` text/icon on `#FEF3C7` background for pending shift swaps, unassigned slots, or overtime warnings.
  - **Danger / Zavrnjeno / Nujno:** Crimson `#DC2626` text/icon on `#FEE2E2` background for conflicts, cancellations, and unfilled urgent shifts.

## Typography

The type system relies completely on Inter, configured with negative tracking at display scales and optical metrics across body copy to maximize clarity in condensed mobile rosters.

- **Numbers & Time Formats:** Use tabular numerals (`tnum`) across all shift hour displays (e.g., `07:00 – 15:30`), hourly wage summaries, and daily duration aggregations to maintain column alignment.
- **Slovenian Diacritics:** Line heights guarantee zero clipping on accented uppercase glyphs (`Č`, `Š`, `Ž`).
- **Data Densities:** Primary shift cards rely on `title-md` for worker designations, paired with `body-sm` in `#6B7280` for sub-labels and operational notes.

## Layout & Spacing

Designed against a baseline 390x844 mobile viewport, the system enforces a strict 8pt grid where every dimension, padding, and margin maps to an integer multiple of 8px (with 4px reserved strictly for tight micro-elements like tags and indicators).

- **Screen Canvas:** Mobile screens maintain 16px (`1rem`) horizontal outer margins.
- **Vertical Rhythm:**
  - Content sections divide by 24px (`space-lg`).
  - Related form controls and list entries space at 8px (`space-sm`) or 12px intervals.
  - Card interior padding strictly adheres to 16px (`space-md`) on all edges, or 12px vertical by 16px horizontal for compact schedule views.
- **Touch Target Assurance:** Every actionable component provides an explicit minimum hit zone of 44x44px (expanding to 48px for top-level navigation and FAB triggers), implemented via Flutter `TapTargetSize.padded` or surrounding constraints.

## Elevation & Depth

Visual hierarchy does not rely on heavy drop shadows or blurred glass layers. Instead, depth is established through physical separation, flat surfaces, and hairline structural borders.

- **Border-Driven Separation:** Layer transitions utilize 1px solid `#E5E7EB` hairline borders around cards, dividers, bottom sheets, and segmented filters.
- **Layer Stacking:**
  - **Ground (0dp):** Canvas canvas at `#F8F9FA`.
  - **Surface (1dp):** Shift cards, table rows, and panel units at `#FFFFFF` with `#E5E7EB` containment.
  - **Floating Overlay (2dp):** Modals, bottom action sheets (*Dodelitev izmene*), and date picker overlays feature `#FFFFFF` background with an ambient shadow: `box-shadow: 0px 4px 16px rgba(28, 32, 37, 0.08)`.
  - **Navigation Bars:** Fixed bottom and top navigation utilize an opaque `#FFFFFF` background with a crisp border separator on the bounding edge: `border-top: 1px solid #E5E7EB`.

## Shapes

The geometric approach embraces controlled, functional roundedness that matches modern system interfaces without turning playful or juvenile.

- **Base Components (0.5rem / 8px):** Input fields, standard buttons, shift status badges, dropdowns, and schedule timeline items.
- **Container Elements (0.75rem / 12px):** Roster summary cards, employee overview cards, and modal dialog containers.
- **Interactive Micro-Pills:** Status badges and timeline date badges use subtle rounded corners (4px to 6px) to maintain structured data-sheet alignment.

## Components

### Buttons & Actions
- **Primary Button (*Glavni gumb*):** Height 48px, background `#3158D9`, foreground `#FFFFFF`, `title-sm` font, 8px radius. Active tap state: `#2545B8`.
- **Secondary Button (*Sekundarni gumb*):** Height 48px, background `#FFFFFF`, border 1px solid `#E5E7EB`, text `#1C2025`. Active state: background `#F3F4F6`.
- **Destructive Button (*Zavrnitev / Odstranitev*):** Background `#FEE2E2`, text `#DC2626`, 8px radius.
- **Floating Add Button (*Dodaj izmeno*):** 52x52px container, `#3158D9` fill, white vector plus icon, anchored at bottom-right with 16px padding.

### Chips & Semantic Status Badges
- **Structure:** Height 24px, horizontal padding 8px, 4px corner radius.
- **States:**
  - *Potrjeno* (Confirmed): Background `#DCFCE7`, text `#16A34A`, label-sm font.
  - *V čakanju* (Pending): Background `#FEF3C7`, text `#D97706`, label-sm font.
  - *Nezasedeno* (Unassigned): Background `#FEE2E2`, text `#DC2626`, label-sm font.
  - *Filter Chips:* Inactive `#FFFFFF` with `#E5E7EB` border; active `#1C2025` text on `#1C2025` fill with white text.

### Schedule Lists & Table Rows
- **Shift Row Item (*Vrstica izmene*):** `#FFFFFF` surface, min-height 68px, horizontal padding 16px, vertical 12px. Hairline border `#E5E7EB` bottom. Left-hand 3px vertical accent strip indicates employee role or department (e.g., Strežba, Kuhinja, Šank).
- **Time Block:** Left-aligned `title-md` font (e.g., `07:00 – 15:30`), stacked above `body-sm` total duration (`8 ur 30 min`).
- **Employee Info:** Right-aligned name in `title-sm` with optional circular avatar (28px) displaying clean initials.

### Form Inputs & Selectors
- **Text Field (*Vnosno polje*):** 48px height, `#FFFFFF` fill, 1px `#E5E7EB` border, 8px corner radius. Focus state: 1.5px `#3158D9` border with zero colored halo. Label text in `label-sm` placed 6px above input in `#1C2025`.
- **Time & Employee Pickers:** Custom bottom-sheet presentation with standard 48px selectable cell lists, native drag handle (36x4px, `#E5E7EB`), and immediate confirmation buttons (*Uveljavi*).

### Checkboxes & Toggle Controls
- **Checkbox:** 20x20px square with 4px border radius. Inactive: 1.5px `#D1D5DB` border. Active: `#3158D9` background with white checkmark. Minimum tap area: 44x44px.
- **Switch Toggle:** Native iOS/Material hybrid style, 44x26px pill container, 22px white circular thumb, `#3158D9` when enabled, `#E5E7EB` when disabled.