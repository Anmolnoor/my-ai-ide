---
name: react-bits
description: Use when adding animated or visual UI components (text effects, backgrounds, hover/scroll animations, cursors, 3D) to a React/Next.js frontend, or when the user mentions React Bits / reactbits.dev. Always installs the TypeScript + Tailwind variant via the shadcn CLI.
---

# React Bits (TypeScript + Tailwind)

Source: https://reactbits.dev. Components come from the `@react-bits` namespace in the shadcn registry and are copied into the repo, so we own the code.

## Variant rule

Always use the `-TS-TW` suffix (TypeScript + Tailwind). Never `-JS-*` or `-*-CSS` unless the user asks.

```
npx shadcn@latest view @react-bits/<Name>-TS-TW   # inspect files + npm deps first
npx shadcn@latest add  @react-bits/<Name>-TS-TW
```

`<Name>` is the PascalCase name from the site URL/title, e.g. `SplitText`, `BlurText`, `Aurora`, `SpotlightCard`.

## Prerequisites (check before the first add)

1. **Tailwind v4** in the project. If it's missing, for Next.js:
   - `npm i -D tailwindcss @tailwindcss/postcss`
   - `postcss.config.mjs`: `export default { plugins: { "@tailwindcss/postcss": {} } };`
   - Top of the global CSS file: `@import "tailwindcss";`
2. **`components.json`**. If it's missing, run `npx shadcn@latest init`. It records where components go (`aliases.components`).

Adding Tailwind to a project that styles with plain CSS changes its global styles (preflight reset). Say so and confirm before you add it to an existing repo.

## Before adding a component

- Run `view` and list its npm `dependencies` (often `gsap`, `motion`, `three`, `ogl`, `@react-three/fiber`). Heavy 3D/WebGL deps → mention the bundle cost and pick a lighter component if one fits.
- The components start with `'use client'`, so in Next.js App Router use them from a client boundary, not inside server-only code.
- Keep the project's existing design (colors, fonts, design files) as the source of truth. Pass colors/text through props instead of editing the component internals.
- Check `prefers-reduced-motion` handling. If the component has none, gate the animation.

## After adding

Run the project's typecheck/build, and render the page to confirm the effect works.
