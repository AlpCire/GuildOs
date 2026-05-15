# Changelog

## 0.7.2
- Implemented real, navigable content for all sidebar categories (Chat, Actividad, Eventos, Perfiles, Comunidades, Info, Logros, Banco, Reclutamiento, Ajustes).
- Added data-driven section rendering helpers (guild stats aggregation and top-lists by class/zone/rank).
- Replaced generic placeholder sections with operational views and safe Blizzard frame actions where APIs are protected.

## 0.7.1
- Reworked the main GuildOS layout to closely match the provided mockup (larger canvas, adjusted columns/panels, roster tabs, and pager/footer alignment).
- Updated roster section visuals and spacing for a more faithful AAA dashboard appearance.

## 0.7.0
- Added secure optional J key override (`/gos replace on|off`) that opens GuildOS without requiring reload.
- Added combat-safe delayed binding apply logic (`PLAYER_REGEN_ENABLED`) to avoid protected action issues.
- Updated addon metadata and docs for the new behavior.

## 0.6.0
- Fixed initial section activation in UI navigation.
- Hardened class color formatting in chat lines.
- Improved roster refresh scheduler with trailing refresh.
- Added sync peer TTL cleanup ticker.
- Added repository README and changelog docs.
