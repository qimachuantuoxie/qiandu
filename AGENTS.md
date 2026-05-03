# AGENTS.md — 千读阅界 (HarmonyOS)

## Quick facts

- **Platform**: HarmonyOS 6.1.0(23), Stage model, ArkUI
- **Language**: ArkTS (strict TypeScript — see "ArkTS strictness" below)
- **Build**: Hvigor (`hvigorw`), NOT npm/webpack
- **Packages**: `ohpm` (oh-package.json5), NOT npm
- **IDE**: DevEco Studio 5.0+ (not VS Code)
- **Single module**: `entry/` HAP, no monorepo

## Commands

```bash
ohpm install                    # install dependencies
hvigorw assembleHap            # build debug HAP
hvigorw assembleHap --mode release  # build release HAP
hvigorw run                    # deploy to device/emulator
```

No `npm test` / `npm run lint` — DevEco Studio handles lint, typecheck, and tests internally.

## ArkTS strictness (catches agents off-guard)

ArkTS is **not** standard TypeScript. The compiler rejects:

- `any` / `unknown` as escape hatches — declare real types
- Object spread `{ ...obj }` — use `Object.assign({}, obj)`
- `catch (error: Error)` type annotations — write `catch (error)` only
- Dynamic property add/delete on untyped objects
- `Function.prototype.bind` / `call` / `apply` with reshaped `this`

```ts
// ❌ Wrong (TS works, ArkTS fails)
let x: any = getData();
const y = { ...other };

// ✅ Correct
let x: string = getData();
const y = Object.assign({}, other);
```

## State management (V2)

All ViewModels use `@ObservedV2` + `@Trace` — NOT V1 decorators (`@Observed`/`@ObjectLink`).

```ts
@ObservedV2
class BookViewModel {
  @Trace books: BookInfo[] = [];
}
```

Entry point: `entry/src/main/ets/entryability/EntryAbility.ets`
ViewModels live in: `entry/src/main/ets/viewmodels/`

## Code layout

```
entry/src/main/ets/
├── entryability/     # UIAbility entry (EntryAbility.ets)
├── pages/            # 30 pages
├── viewmodels/       # 39 ViewModels (V2 @ObservedV2)
├── services/         # 44 services (13 categories)
├── features/         # feature modules (target V3 structure)
├── components/       # 18 UI components
├── core/             # core logic
├── models/           # 9 data models
├── store/            # global state
├── design/           # design system
├── managers/         # managers
└── utils/            # 20 utility files
```

## Testing

Framework: `@ohos/hypium` (Mocha-style). Test files in `entry/src/ohosTest/ets/test/`.

```ts
import { describe, it, expect } from '@ohos/hypium';
```

Run tests from DevEco Studio test runner (no CLI test command).

## Build notes

- Obfuscation is **disabled** in `entry/build-profile.json5` (`"enable": false`)
- Native C++ module: `entry/src/main/cpp/types/libentry` (linked in oh-package.json5)
- Signing config: debug cert in `C:\Users\mengj\.ohos\config\`
- `build-profile.json5` targets `compileSdkVersion: "6.1.0(23)"`

## Reference docs (in repo)

| Doc | Purpose |
|-----|---------|
| `ARCHITECTURE_PLAN.md` | Architecture design |
| `IMPLEMENTATION_PLAN.md` | Implementation roadmap |
| `V2_STATE_MANAGEMENT_UPGRADE.md` | V2 migration guide |
| `ARKTS_STRICT_STANDARD.md` | ArkTS coding rules |
| `README.md` | Project overview, all 39 ViewModels listed |
