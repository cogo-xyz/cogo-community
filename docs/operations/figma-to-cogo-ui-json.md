## Figma MCP → Cogo UI JSON Mapping Runbook

Purpose: Standardize conversion from Figma (MCP) nodes to Cogo UI JSON and persistence into Supabase tables (`projects/pages/components/...`).

### Sources
- Figma MCP servers: `mcp-servers/figma-context`
- Reference spec: `docs/references/figma/page-doc.md`

### JSON Shapes
- Page JSON
```
{
  "id": "page:home",
  "name": "Home",
  "width": 1440,
  "height": 1024,
  "bg_clr": "#FFFFFF",
  "components": [ Component ]
}
```
- Component JSON
```
{
  "id": "cmp:btn-1",
  "name": "CTA Button",
  "type": "button",
  "dx": 120,
  "dy": 80,
  "width": 200,
  "height": 48,
  "options": { "text": "Get Started" }
}
```

### Mapping
- Figma Frame → `pages` row
  - `name` → `pages.name`
  - `width/height` → `pages.width/height`
  - `fills` → `pages.bg_clr` (solid only)
- Figma Node (TEXT/RECT/IMAGE/FRAME) → `components` row
  - `absoluteBoundingBox.{x,y}` → `dx,dy`
  - `absoluteBoundingBox.{width,height}` → `width,height`
  - `type` → `type` (normalize: TEXT→`text`, RECTANGLE→`container`, IMAGE→`image`)
  - `characters`(TEXT) → `options.text`
  - `fills`/`strokes` → `options.style`
  - `cornerRadius` → `options.radius`
- Hierarchy
  - Parent frame id → `page_id`
  - Z-order → `index_in_page`

### Persistence
- Insert order: `projects` → `pages` → `components`
- Upsert keys
  - `pages`: `(id)` or `(name, width, height)` if id absent
  - `components`: `(page_id, id)` or `(page_id, index_in_page)`

### Validations
- Required fields per table (see schema verifier)
- Coordinate sanity: `dx,dy >= 0`, `width,height > 0`
- Type whitelist: `button,text,image,container,list,grid,wrap`

### Import Flow (dry-run)
1) Parse Figma export JSON
2) Map to Cogo UI JSON using rules above
3) Validate with JSON Schema
4) Upsert into Supabase (dry-run → print SQL via REST selects)

### CLI
- Verify DB schema: `npm run -s verify:cogo-ui:schema`
- (TBD) Validate JSON: `npm run -s validate:cogo-ui:json FILE=...`
- (TBD) Import dry-run: `npm run -s import:cogo-ui:dry FILE=... PROJECT_ID=...`
