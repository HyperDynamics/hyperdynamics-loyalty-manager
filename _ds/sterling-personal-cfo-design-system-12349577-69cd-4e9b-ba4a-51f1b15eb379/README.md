# Sterling — Personal CFO Design System

Sterling is a **personal CFO**: a premium personal-finance app that tracks your net worth, automates budgets, pays bills, and rewards good money habits. This design system captures Sterling's brand — a dark, luxe, confidently-lowercase fintech aesthetic with an **eye-catching 3D layer** (metallic payment cards, spinning reward coins, glass panels, colored glows).

The visual DNA is derived from a **CRED-style** premium fintech surface: near-black canvas, the **Gilroy** typeface, all-lowercase copy, huge display headings, white/mint pill buttons, and fanned 3D product objects.

## Sources
This system was built by reading one attached repository. Explore it to design against the product more faithfully:
- **kartikeysharmaks/Cred-Clone** — https://github.com/kartikeysharmaks/Cred-Clone (branch `master`). A React recreation of the CRED landing page. We lifted the Gilroy webfonts, the color variables (`--bg-black #0f0f0f`, `--bg-green #027757`, `--bg-red #ee2f4c`, `--link-blue #7ea2ec`, etc.), the pill-button and photo-section patterns, and the `slide-in` / `scale-in` reveal easing directly from its source.

> Note: "Sterling" is our name for the Personal CFO product; the source repo is an unbranded CRED clone. All product copy here is original and written in the CRED-inspired voice.

---

## CONTENT FUNDAMENTALS — how Sterling writes

**Voice:** a sharp, trustworthy friend who happens to be a brilliant CFO. Confident, warm, never stiff or corporate.

- **Case: lowercase almost everywhere.** Headlines, buttons, nav, labels — all lowercase. This is the single strongest verbal signal of the brand. `rewards for good money habits.` · `pay bill` · `become a member`. Uppercase is reserved only for tiny eyebrow/overline labels (letter-spaced) and acronyms (CFO, AES).
- **Person: "you" / "your".** Speak directly to the member. `your money, managed like a boss.` · `what's yours remains only yours.` We refer to ourselves as "we" sparingly, mostly in trust/story copy.
- **Punctuation:** headlines often end in a full stop for a declarative, weighty feel — `security first. and second.` Short fragments are welcome. Em-dashes and ampersands over "and" in tight UI.
- **Numbers:** always tabular; currency with grouping (`$48,210.75`). Deltas carry a sign and color (`+$1,240`, `−$328`). Percentages are terse (`+2.6%`).
- **Tone examples:**
  - Hero: *"your money, managed like a boss."*
  - Reassurance: *"you've spent $3,204 of your $4,700 budget. nice pace."*
  - Trust: *"there's no room for mistakes, because we didn't leave any."*
  - Reward: *"on sterling, good begets good."*
- **No emoji.** The premium tone carries the warmth; emoji would cheapen it. Iconography does the visual-accent job instead.
- **Length:** headlines are big and few words. Body copy is one or two tight sentences. Never a wall of text.

---

## VISUAL FOUNDATIONS

**Overall vibe:** dark-first, premium, tactile. Think brushed metal, deep obsidian glass, and a single luminous mint that reads as "money / growth / go". High contrast, generous negative space, big type, and real depth.

- **Color.** Canvas is a deep near-black ink ramp (`--ink-900 #08090b` → `--ink-500 #1d2027`). The hero accent is **mint** (`--mint-400 #22e6a4`, gradient `--grad-mint`) — used for primary CTAs, positive figures, focus rings, active nav. **Gold** (`--gold-400 #e8c87e`) signals premium/metal/tiers and rewards. Supporting accents (blue, purple) come from the CRED palette and appear mainly on metallic card faces. Finance semantics: **gain = mint**, **loss = `--loss #ee2f4c`**, **warn = amber**, **info = blue**. Only ever 1–2 accent colors compete per screen.
- **Type.** One family: **Gilroy** (weights 200–900). Display is heavy (800–900), very tight tracking (`-0.03em`), line-height near 1. Body is 400–600. Financial figures use `font-variant-numeric: tabular-nums`. Marketing hero runs 90–106px; product headings 24–28px; body 16px; nothing below ~13px in UI.
- **Spacing & layout.** 4px base grid. Marketing sections breathe (110–120px vertical padding); product UI is tighter (12–20px). Content max-width ~1160px on marketing. The mobile app canvas is 390px.
- **Backgrounds.** Never flat when it can glow: radial **auras** behind hero content (`--grad-aura-mint`, `--grad-aura-gold`), metallic gradients on cards, and full-bleed colored feature bands (emerald, violet) echoing CRED's photo-sections. No stock photography; the 3D objects and gradients carry the imagery.
- **3D & depth (the signature).** Metallic payment cards that **parallax-tilt to the cursor** with a swept sheen and embossed chip; **reward coins** with raised rims and glows that can spin; glass panels with backdrop blur. Depth is built from layered `inset` highlight + ambient drop shadow (`--lift-card`, `--lift-raised`) plus **colored glows** (`--glow-mint`, `--glow-gold`).
- **Corner radii.** Soft and generous: cards `--radius-lg 20px`, sheets `--radius-xl 28px`, hero panels `--radius-2xl 36px`, and **pill (999px)** for every button and chip — the CRED signature. Card faces use 18px.
- **Cards.** Dark fill (`--surface-card`), 1px hairline border (`--border-subtle`), a top-edge white highlight and a soft drop shadow. `elevated` brightens the fill; `glass` swaps to frosted blur; `outline` is border-only.
- **Borders & hairlines.** Thin, low-opacity white (`rgba(255,255,255,0.06–0.16)`) on dark. Metallic edges use a bright top highlight + dark bottom line.
- **Shadows.** Two systems: neutral ambient elevation (`--shadow-sm…float`) and the branded **lift** (inset highlight + drop) used on cards. Colored glows are additive on accents only.
- **Transparency & blur.** Reserved for overlays that sit *over* content — the app's bottom tab bar, sheets, and nav — via `--glass-fill` + `backdrop-filter: blur()`. Not used as decoration on solid backgrounds.
- **Motion.** Confident, weighted. Reveals use CRED's easing `--ease-out cubic-bezier(.25,.46,.45,.94)` (`slide-in-right`, `scale-in-bottom`). Interactive springs use `--ease-spring` (overshoot) for toggles and segmented thumbs. 3D objects get a slow ambient `float-y` and a `sheen-sweep`; coins can `coin-spin`. Durations: `--dur-base 260ms` for UI, `--dur-reveal 1000ms` for section reveals. All decorative animation respects `prefers-reduced-motion`.
- **Hover / press.** Hover = lift (`translateY(-2px)`) + slight brighten (`brightness(1.06)`); primary buttons also intensify their glow. Press = shrink to `scale(0.97)`. Cards marked `interactive` lift `-4px`.

---

## ICONOGRAPHY

- **Set:** the source repo shipped **no icon font or SVG set** (it used remote CRED CDN PNGs, which we do not hotlink). We substitute **[Lucide](https://lucide.dev)** (MIT) — clean ~2px round-cap line icons that match the premium, minimal tone. **This is a flagged substitution; swap for a licensed/branded set in production.**
- **Usage:** icons are rendered as inline SVG (built from Lucide's icon data in `ui_kits/app/kit.jsx` — React-safe, no DOM mutation) so they inherit `color` / size cleanly. Stroke stays 2px; icons take `currentColor` and are sized 16–24px in UI.
- **Emoji:** never used as iconography (or anywhere) — see Content Fundamentals.
- **Unicode marks:** the minus sign `−` (U+2212, not hyphen) for negative amounts; arrows `▲ ▼` inside delta chips; `••••` for masked card digits.
- **Brand mark:** a Sterling **coin** (the `Coin` component, `symbol="S"`) paired with the lowercase `sterling` wordmark — no separate logo file is needed, the coin is generated.

---

## INDEX / MANIFEST

**Root**
- `styles.css` — the single entry point consumers link (imports everything below).
- `README.md` — this guide. · `SKILL.md` — Agent-Skills-compatible wrapper.

**tokens/** (all `@import`ed by `styles.css`)
- `fonts.css` — Gilroy `@font-face` (weights 200–900) → `assets/fonts/`
- `colors.css` · `typography.css` · `spacing.css` · `effects.css` (shadows/glows/glass/gradients) · `motion.css` · `base.css` (reset)

**components/core/** — `Button`, `Card`, `Badge`, `Avatar`, `Input`, `Toggle`, `SegmentedControl`, `ProgressRing`, `StatTile`, `ListRow`
**components/finance/** — `CreditCard3D` (signature), `Coin`
Each has `<Name>.jsx` + `.d.ts` + `.prompt.md`; each folder has a `@dsCard` showcase.
Reach them at `window.SterlingPersonalCFODesignSystem_123495.<Name>`.

**ui_kits/**
- `app/` — interactive Personal CFO **mobile app** (login → home · cards · spending · rewards). See `app/README.md`.
- `site/` — the **marketing landing page** (hero → 3D card showcase → feature bands → ratings → footer).

**guidelines/** — foundation specimen cards (Colors, Type, Spacing, Brand) shown in the Design System tab.

**assets/fonts/** — the seven Gilroy `.ttf` weights.
