### CreateGo → UUIS Mapping Table (Working Draft)

- Canonical source: `creatego-ide/Documents/component-doc.md`
- Purpose: Provide an at-a-glance mapping for migration and rule authoring.

#### Type Mapping

| CreateGo Type | UUIS `type`     | Notes |
| --- | --- | --- |
| Button        | `cogo:button`   | Variants: primary/secondary/ghost; props: label, variant |
| Text          | `cogo:text`     | props: text, style tokens |
| TextField     | `cogo:textfield`| props: label, placeholder, value |
| Icon          | `cogo:icon`     | props: name, size |
| Image         | `cogo:image`    | props: src, alt |
| Card          | `cogo:card`     | props: header/body/footer slots |
| List          | `cogo:list`     | props: items, itemTemplate |
| Container     | `cogo:stack`    | props.layout: direction, gap, padding, align/justify |

#### Props Mapping (Selected)

- Visuals → Tokens: color, spacing, radius, font → W3C DTCG token refs `{tokens.*}`
- Button: `text` → `props.label`; `style` → `props.variant`
- TextField: `placeholder` → `props.placeholder`; `label` → `props.label`
- Icon: `iconName` → `props.name`; `size` → token alias or scalar

#### Events Mapping (Standardized)

- `onClick` → `events[{ on: "click", action: { type: "DISPATCH_EVENT"|"NAVIGATE" }}]`
- `onChange` → `events[{ on: "change", action: { type: "UPDATE_STATE" }}]`
- Validation → `events[{ on: "submit", action: { type: "VALIDATE" }}]`

#### Layout Mapping

- Auto Layout → `props.layout`
  - `horizontal/vertical` → `direction: row|column`
  - `itemSpacing` → `gap`
  - `padding*` → `padding`
  - `align/justify` → `alignItems/justifyContent`

#### Notes

- Preserve semantics; store legacy-only fields under `$legacy` if needed
- Use subtree hash `props.__hash` for idempotent upserts
- Record applied rules version in `props.__rules_v`

#### Extended Component Mapping (Draft)

| Figma Name Pattern | Figma Types | UUI Type     | Notes |
|--------------------|-------------|--------------|-------|
| button/submit/cta  | TEXT        | `cogo:button`  | label from `$text|$name` |
| card               | FRAME/GROUP | `cogo:card`    | header from `$name` |
| list/items/grid    | FRAME       | `cogo:list`    | itemTemplate `$name` |
| tabs/tabbar        | FRAME/GROUP | `cogo:tabs`    | variant default |
| modal/dialog       | FRAME/GROUP | `cogo:modal`   | open false |
| navbar/navigation  | FRAME/GROUP | `cogo:navbar`  | title `$name` |
| header             | FRAME/GROUP | `cogo:header`  | title `$name` |
| footer             | FRAME/GROUP | `cogo:footer`  |  |
| link/anchor        | TEXT/VECTOR | `cogo:text`    | Preserve as text (no auto-link). Links are inferred at runtime or via explicit props.href |
| badge              | FRAME/GROUP | `cogo:badge`   | label `$name`, variant info |
| chip/pill          | FRAME/GROUP | `cogo:chip`    | label `$name` |
| avatar/profile     | FRAME/ELLIPSE| `cogo:avatar` | alt `$name` |
| table/datagrid     | FRAME/GROUP | `cogo:table`   | variant basic |


