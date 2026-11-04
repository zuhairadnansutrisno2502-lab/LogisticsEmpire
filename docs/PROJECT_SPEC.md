# LOGISTICS EMPIRE — Visual & Gameplay Source of Truth

**Genre:** UI-first Roblox logistics management tycoon. No avatar-driving, no buses, no PvP. Four fleet types ONLY: courier motorcycle, cargo truck, cargo aircraft, container ship.

**Visual target:** light gray/white content background, navy left sidebar, restrained blue accents, rounded cards, generous spacing, crisp type, clear hierarchy. Do not make a dense dark-mode dashboard. Mobile responsive. 3D elements support the UI: isometric HQ diorama, rotating vehicle previews, delivery cinematics, evolving warehouse. Optimize asset complexity and animation.

**Dashboard:** company identity, cash, level, reputation, revenue indicators, active deliveries/routes, 3D HQ, live delivery preview, contract list, fleet cards, warehouse quick upgrades. Screens: Dashboard, Contracts, Fleet, Route Planner, Warehouse, Research, Expansion, Events, Robux Shop.

**Core loop:** browse contract → accept → select valid fleet and route → dispatch (server validates and deducts costs) → delivery timestamps → client-side 3D preview → server completes and awards exactly once → upgrade → repeat. All UI actions connect to real state. Mock adapters are temporary and visibly flagged in development; do not label mock as integrated.

**Four visual delivery scenes:** motor urban, truck highway, aircraft airport/flight, ship container port/ocean. Preview is cosmetic only. Server remains authoritative.

**Monetization:** VIP pass, vehicle skins, cinematic preview, dashboard themes, optional cash packs. No invented product IDs, live purchase activation, or publication without authorization.

**Release acceptance:** new-player end-to-end loop, persistence, duplicate-reward prevention, multi-player isolation, responsive UI, visual parity with approved preview, no critical errors. Validate in Roblox Studio, not only by inspecting files.
