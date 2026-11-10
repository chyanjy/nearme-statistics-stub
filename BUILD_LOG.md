# Build log — nearme-statistics-stub

Built 2026-11-10 (UTC) on this VM. The APK was **not** installed on any
phone and was **not** pushed to GitHub.

## v1.6 (2026-11-10, seventh build) — button 1 jumps to ColorOS auto-start management

### Bug reported by the user

On OPPO A3 Pro / ColorOS 15, button 1 ("Open app settings
(allow auto-start)") opened Settings > Apps > Statistics Stub,
the single-app details page — which has NO auto-start toggle on
ColorOS 15. The switch lives in the global list: Settings > App
Management > Auto-start and associated startup (or Phone Manager
> Privacy permissions > Auto-start management). So button 1 was
useless, and the user asked for it to jump straight to that list.

**Correction (user, same evening):** the manual path on this
phone is Settings > Apps > Auto-start (设置 > 应用 > 自启动),
NOT Settings > App Management > Auto-start and associated
startup. The v1.6 text (button label, on-screen text, Toast and
README) was corrected to that path before delivery. The jump
target is unchanged: the StartupAppListActivity candidates above
are that Settings > 应用 > 自启动 page. The candidate list was
not changed, only the wording / manual fallback path.

### Fix (v1.6, MainActivity.java + AndroidManifest.xml only)

- **Button 1 (`MainActivity.java`):** renamed to
  "1. Open auto-start management (自启动)" and now
  calls `openAutoStartManagement()`, which tries the known
  ColorOS safecenter auto-start activities in order, taking the
  first one that resolves, and falls back to the app-details
  page only if none resolve:
  1. `ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")`
  2. `ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")`
  3. `ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")`
  4. `ComponentName("com.oplus.safecenter", "com.oplus.safecenter.permission.startup.StartupAppListActivity")`
     (extra candidate, after the com.coloros.safecenter ones and
     before the fallback, in case ColorOS 15 renamed the package)
  5. `Intent` with action
     `"com.coloros.safecenter.startupapp.permission.STARTUP_APP_LIST"`,
     `setPackage("com.coloros.safecenter")`
  6. Fallback: the old `ACTION_APPLICATION_DETAILS_SETTINGS`
     Intent for this package, plus a Toast giving the manual path
     (Settings > Apps > Auto-start, 设置 > 应用 > 自启动) if even
     the fallback cannot be started.
  Each explicit-component candidate also carries
  `putExtra("packageName", getPackageName())` — some builds use
  it to jump to the app's row; it is harmless where ignored.
  Each candidate is checked with `resolveActivity()` first and
  the `startActivity()` call is wrapped in try/catch
  (`ActivityNotFoundException` and generic `Exception`), so a
  missing activity just means "try the next one" — the button
  never crashes.
- **Duplicate note:** candidates 2 and 5 in the task brief were
  the identical component string
  (`com.coloros.safecenter` /
  `com.coloros.safecenter.startupapp.StartupAppListActivity`),
  so it is tried once (candidate 2 above), not twice.
- **Manifest (`AndroidManifest.xml`):** added a `<queries>` block
  for `com.coloros.safecenter`, `com.oppo.safe` and
  `com.oplus.safecenter`, so `resolveActivity()` can see those
  packages on Android 11+ package visibility. **No new
  permissions** — still only `RECEIVE_BOOT_COMPLETED` and
  `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
- Buttons 2 and 3, `UnhideActivity`, `.LauncherAlias`,
  `ReceiverService`, `BootReceiver` and permissions are
  **unchanged**. On-screen label updated to "Statistics Stub
  v1.6" and the short text now explains that button 1 opens the
  global auto-start list and what to do if it opens the
  app-details page instead.
- Version bump: `versionCode 6 -> 7`, `versionName 1.5 -> 1.6`
  (in `build.sh` aapt2 link args and in both `build.gradle` files).
- Source size v1.6: `MainActivity.java` 303 lines,
  `UnhideActivity.java` 54 lines, `BootReceiver.java` 28 lines,
  `ReceiverService.java` 30 lines, `AndroidManifest.xml` 92 lines
  — 507 lines total.

### Signing key — v1.1/v1.2/v1.3/v1.4/v1.5 key REUSED, v1.6 updates v1.5 in place

The `debug.keystore` still exists in the project directory (SHA-256
`de2d0be3fc1c28db78921a9c990bb7e65c8b4e50268642753e6a8c0f4a8a48a5`,
unchanged before and after the build — `build.sh` only generates a
keystore when none exists). v1.6 was signed with that same keystore.

**Consequence: v1.6 CAN update v1.5 in place** (plain install over
it, or `adb install -r app-debug.apk`). Verified: the v1.6 signer
certificate SHA-256 (`22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b`)
is identical to the v1.1/v1.2/v1.3/v1.4/v1.5 signer digest. v1.0 still
cannot be updated in place (different key) — uninstall v1.0 first,
as before.

### v1.6 output

- `app-debug.apk` — 16,885 bytes
- SHA-256: `2a9f7a46392009c22113de4a8025a5e6159fb8823a39f7a94cb9d747b9fd52ef`
  (rebuilt after the wording correction above; the first v1.6 build
  with the old "应用管理 > 自启动和关联启动" wording was
  `89b36dbb82070832e5acc5f9e9aee77b6d95e2193426131d45856fdbdb981505`
  and was superseded before delivery — same versionCode 7 /
  versionName 1.6, same signing key, only the manual-path strings
  differ)
- Signer SHA-256 digest: `22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b`
  (1 signer, APK Signature Scheme v3) — identical to v1.1/v1.2/v1.3/v1.4/v1.5.

### v1.6 verification (all run on the built APK)

```
$ apksigner verify --verbose --print-certs app-debug.apk
Verifies
Verified using v3 scheme (APK Signature Scheme v3): true
Number of signers: 1
Signer #1 certificate SHA-256 digest: 22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b

$ aapt2 dump badging app-debug.apk
package: name='com.nearme.statistics.rom' versionCode='7' versionName='1.6'
sdkVersion:'29' targetSdkVersion:'34'
uses-permission: name='android.permission.RECEIVE_BOOT_COMPLETED'
uses-permission: name='android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS'
NOTE: aapt2 dump badging lists NO launchable-activity line, as in
v1.5 — an aapt2 quirk for activity-alias launchers, not a missing
launcher; the xmltree dump below shows the MAIN/LAUNCHER filter on
.LauncherAlias.

$ aapt2 dump xmltree app-debug.apk --file AndroidManifest.xml (excerpt)
  E: manifest  package="com.nearme.statistics.rom" versionCode=7 versionName="1.6"
    E: uses-permission  name="android.permission.RECEIVE_BOOT_COMPLETED"
    E: uses-permission  name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"
    E: queries
        E: package  name="com.coloros.safecenter"
        E: package  name="com.oppo.safe"
        E: package  name="com.oplus.safecenter"
    E: activity   name=".MainActivity" exported=true
    E: activity-alias  name=".LauncherAlias" enabled=true exported=true
        targetActivity=".MainActivity"
        E: intent-filter  action MAIN / category LAUNCHER
    E: activity   name=".UnhideActivity" enabled=true exported=true
    E: service    name=".service.ReceiverService" exported=true
    E: receiver   name=".BootReceiver" exported=true
        action "android.intent.action.BOOT_COMPLETED"

$ dexdump build/classes.dex — Class descriptors:
  Lcom/nearme/statistics/rom/BootReceiver;
  Lcom/nearme/statistics/rom/MainActivity;  (+ 3 lambda classes)
  Lcom/nearme/statistics/rom/UnhideActivity;
  Lcom/nearme/statistics/rom/service/ReceiverService;

$ grep -ri "foreground|persistent|startForeground" app/src/main/
  (no hits at all) — no foreground service, no persistent flag anywhere.
```

### Still not verified on a device

As with v1.0–v1.5, the APK was verified by static inspection only.
It was not installed on a phone in this session. The on-device
checks still to be done on the phone: install v1.6 over v1.5, tap
button 1 and confirm it opens the ColorOS auto-start list (not the
app-details page), find Statistics Stub in that list and turn it
on, and confirm that after that step the logcat `not found` /
`prevent start` lines stop. Which of the five candidates actually
resolved on the user's ColorOS 15 build is unknown until that tap
— if button 1 still opens the app-details page, none of them
resolved and the manual path in the Toast/README applies.

---

## v1.5 (2026-11-10, sixth build) — fix the hide-icon trap

### Bug reported by the user

In v1.2-v1.4, tapping button 3 ("Hide icon") disabled `MainActivity`
itself via `PackageManager.setComponentEnabledSetting()`. After that,
the icon disappeared as intended — but the way back did not work:

```
adb shell pm enable com.nearme.statistics.rom/.MainActivity
  -> java.lang.SecurityException: Shell cannot change component state
     for ComponentInfo{com.nearme.statistics.rom/
     com.nearme.statistics.rom.MainActivity} to 1
am start -n com.nearme.statistics.rom/.MainActivity
  -> Error type 3
     Error: Activity class {com.nearme.statistics.rom/
     com.nearme.statistics.rom.MainActivity} does not exist.
```

Shell cannot re-enable a component the app itself disabled, and a
disabled activity cannot be started at all. The only way back was
reinstalling the APK. The user reinstalled v1.4 and asked for the
trap to be fixed properly.

### Fix (v1.5)

- **Manifest (`AndroidManifest.xml`):** the `MAIN` / `LAUNCHER`
  intent-filter moved OFF `MainActivity` and onto a new
  **activity-alias `.LauncherAlias`**
  (`android:targetActivity=".MainActivity"`, enabled=true,
  exported=true). `MainActivity` itself stays exported=true but
  has no launcher filter.
- **Hide button (`MainActivity.java`):** now disables ONLY the
  `.LauncherAlias` component (`COMPONENT_ENABLED_STATE_DISABLED`,
  `DONT_KILL_APP`), never `MainActivity`. Toast and on-screen text
  now point at the new way back instead of `pm enable`.
- **New activity `.UnhideActivity` (`UnhideActivity.java`, 54
  lines):** exported=true, enabled=true, no launcher filter. Its
  `onCreate()` re-enables `.LauncherAlias` (and `MainActivity`,
  for safety, in case v1.2-v1.4 had disabled it) via the app's own
  `PackageManager` — the app itself IS allowed to change its own
  components, unlike shell `pm enable` — shows Toast "Icon
  restored / 图标已恢复" and finishes. It starts nothing else,
  reads nothing, and has no permissions beyond the two in the
  manifest.
- **Way back after hiding (v1.5):**
  ```
  am start -n com.nearme.statistics.rom/.UnhideActivity
  ```
  (from the phone shell, e.g. AYA terminal — no `adb shell`
  prefix, you are already inside the phone; from a PC:
  `adb shell am start -n com.nearme.statistics.rom/.UnhideActivity`).
  No `pm enable`, no reinstall. README.md documents this and warns
  explicitly against `pm enable` on a self-disabled component.
- Buttons 1 and 2 behaviours are **unchanged** (including the v1.3
  button-2 Toast fix), buttons-at-top + ScrollView text layout
  (v1.4) unchanged, `ReceiverService` unchanged
  (`stopSelf()` + `START_NOT_STICKY`, no foreground / persistent /
  notification — grep over `app/src/main/` finds no
  `foreground` / `persistent` / `startForeground` hits at all),
  `BootReceiver` unchanged, permissions unchanged (still only
  `RECEIVE_BOOT_COMPLETED` and
  `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`).
- Version bump: `versionCode 5 -> 6`, `versionName 1.4 -> 1.5`
  (in `build.sh` aapt2 link args and in both `build.gradle` files).
  On-screen label updated to "Statistics Stub v1.5".
- Source size v1.5: `MainActivity.java` 200 lines,
  `UnhideActivity.java` 54 lines, `BootReceiver.java` 28 lines,
  `ReceiverService.java` 30 lines, `AndroidManifest.xml` 83 lines
  — 395 lines total.

### Signing key — v1.1/v1.2/v1.3/v1.4 key REUSED, v1.5 updates v1.4 in place

The `debug.keystore` still exists in the project directory (SHA-256
`de2d0be3fc1c28db78921a9c990bb7e65c8b4e50268642753e6a8c0f4a8a48a5`,
unchanged before and after the build — `build.sh` only generates a
keystore when none exists). v1.5 was signed with that same keystore.

**Consequence: v1.5 CAN update v1.4 in place** (plain install over
it, or `adb install -r app-debug.apk`). Verified: the v1.5 signer
certificate SHA-256 (`22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b`)
is identical to the v1.1/v1.2/v1.3/v1.4 signer digest. v1.0 still
cannot be updated in place (different key) — uninstall v1.0 first,
as before.

### v1.5 output

- `app-debug.apk` — 16,885 bytes
- SHA-256: `e904bd125f08000ea8a19672029e70f6048a4a7143aa9a3c76659eab8dfd1e71`
- Signer SHA-256 digest: `22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b`
  (1 signer, APK Signature Scheme v3) — identical to v1.1/v1.2/v1.3/v1.4.

### v1.5 verification (all run on the built APK)

```
$ apksigner verify --verbose --print-certs app-debug.apk
Verifies
Verified using v3 scheme (APK Signature Scheme v3): true
Number of signers: 1
Signer #1 certificate SHA-256 digest: 22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b

$ aapt2 dump badging app-debug.apk
package: name='com.nearme.statistics.rom' versionCode='6' versionName='1.5'
sdkVersion:'29' targetSdkVersion:'34'
uses-permission: name='android.permission.RECEIVE_BOOT_COMPLETED'
uses-permission: name='android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS'
NOTE: aapt2 dump badging lists NO launchable-activity line for this
build. That is an aapt2 quirk for activity-alias launchers, not a
missing launcher: the xmltree dump below shows the MAIN/LAUNCHER
intent-filter on .LauncherAlias, and the launcher resolves an alias
with that filter exactly like an activity with it.

$ aapt2 dump xmltree app-debug.apk --file AndroidManifest.xml (excerpt)
  E: manifest  package="com.nearme.statistics.rom" versionCode=6 versionName="1.5"
    E: uses-permission  name="android.permission.RECEIVE_BOOT_COMPLETED"
    E: uses-permission  name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"
    E: activity   name=".MainActivity" exported=true
        (no intent-filter — launcher filter moved to the alias)
    E: activity-alias  name=".LauncherAlias" enabled=true exported=true
        targetActivity=".MainActivity"
        E: intent-filter  action MAIN / category LAUNCHER
    E: activity   name=".UnhideActivity" enabled=true exported=true
    E: service    name=".service.ReceiverService" exported=true
    E: receiver   name=".BootReceiver" exported=true
        action "android.intent.action.BOOT_COMPLETED"

$ dexdump build/classes.dex — Class descriptors:
  Lcom/nearme/statistics/rom/BootReceiver;
  Lcom/nearme/statistics/rom/MainActivity;  (+ 3 lambda classes)
  Lcom/nearme/statistics/rom/UnhideActivity;
  Lcom/nearme/statistics/rom/service/ReceiverService;

$ grep -ri "foreground|persistent|startForeground" app/src/main/
  (no hits at all) — no foreground service, no persistent flag anywhere.
```

### Still not verified on a device

As with v1.0–v1.4, the APK was verified by static inspection only.
It was not installed on a phone in this session. The on-device
checks still to be done on the phone:
install v1.5 over v1.4, confirm the launcher icon is present,
tap button 3 and confirm the icon disappears, then WITHOUT
reinstalling run `am start -n
com.nearme.statistics.rom/.UnhideActivity` and confirm the icon
comes back (Toast "Icon restored"), and confirm the logcat
`not found` / `prevent start` lines stay gone.

---

## v1.4 (2026-11-10, fifth build) — fix layout bug hiding button 3

### Bug reported by the user

The user could not find button 3 ("Hide icon") in the app.

### Root cause

In `MainActivity.java`, the layout was a plain vertical `LinearLayout`
with the very long explanatory `TextView` added first, followed by
the three buttons, and **no `ScrollView` anywhere**. On a phone
screen the text filled the whole viewport and pushed buttons 2 and
3 off the bottom, unreachable — there was no way to scroll to them.
Button 1 worked only because it happened to sit just below the
fold, or the text happened to fit on that screen; button 3 never
did.

### Fix (MainActivity.java only)

- **Both causes fixed:** the three buttons now come FIRST, at the
  top of the root `LinearLayout`, so all three are visible the
  moment the app opens with no scrolling needed at all.
- The explanatory text was shortened to a few lines (title, one
  sentence of purpose, one sentence of order-of-steps; the full
  explanation stays in `README.md`), and it now lives inside a
  `ScrollView` below the buttons — so even if the text grows again
  later, it can never push the buttons off screen.
- Button 1/2/3 behaviours are **unchanged**, including the v1.3
  button-2 fix (Toast when already whitelisted, try/catch with a
  manual-path fallback when the ROM has no battery dialog).
  `ReceiverService`, `BootReceiver`, manifest and permissions are
  unchanged (still only `RECEIVE_BOOT_COMPLETED` and
  `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`).
- Version bump: `versionCode 4 -> 5`, `versionName 1.3 -> 1.4`
  (in `build.sh` aapt2 link args and in both `build.gradle` files).
  On-screen label updated to "Statistics Stub v1.4".

### Signing key — v1.1/v1.2/v1.3 key REUSED, v1.4 updates v1.3 in place

The `debug.keystore` still exists in the project directory (SHA-256
`de2d0be3fc1c28db78921a9c990bb7e65c8b4e50268642753e6a8c0f4a8a48a5`,
unchanged before and after the build — `build.sh` only generates a
keystore when none exists). v1.4 was signed with that same keystore.

**Consequence: v1.4 CAN update v1.3 in place** (plain install over
it, or `adb install -r app-debug.apk`). Verified: the v1.4 signer
certificate SHA-256 (`22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b`)
is identical to the v1.1/v1.2/v1.3 signer digest. v1.0 still cannot
be updated in place (different key) — uninstall v1.0 first, as before.

### v1.4 output

- `app-debug.apk` — 12,789 bytes
- SHA-256: `41c43ed93816bc4cba3f01c07e99cb9d36dc6871d406b31bd1e4c72da57d3963`
- Signer SHA-256 digest: `22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b`
  (1 signer, APK Signature Scheme v3) — identical to v1.1/v1.2/v1.3.

### v1.4 verification (all run on the built APK)

```
$ apksigner verify --verbose --print-certs app-debug.apk
Verifies
Verified using v3 scheme (APK Signature Scheme v3): true
Number of signers: 1
Signer #1 certificate SHA-256 digest: 22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b

$ aapt2 dump badging app-debug.apk
package: name='com.nearme.statistics.rom' versionCode='5' versionName='1.4'
sdkVersion:'29' targetSdkVersion:'34'
uses-permission: name='android.permission.RECEIVE_BOOT_COMPLETED'
uses-permission: name='android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS'
launchable-activity: name='com.nearme.statistics.rom.MainActivity'

$ aapt2 dump xmltree app-debug.apk --file AndroidManifest.xml (excerpt)
  E: manifest  package="com.nearme.statistics.rom" versionCode=5 versionName="1.4"
    E: uses-permission  name="android.permission.RECEIVE_BOOT_COMPLETED"
    E: uses-permission  name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"
    E: activity   name=".MainActivity" exported=true  (MAIN/LAUNCHER)
    E: service    name=".service.ReceiverService" exported=true
    E: receiver   name=".BootReceiver" exported=true
        action "android.intent.action.BOOT_COMPLETED"

$ dexdump build/classes.dex — Class descriptors:
  Lcom/nearme/statistics/rom/BootReceiver;
  Lcom/nearme/statistics/rom/MainActivity;  (+ 3 lambda classes)
  Lcom/nearme/statistics/rom/service/ReceiverService;

$ grep ScrollView app/src/main/java/com/nearme/statistics/rom/MainActivity.java
  (6 hits — ScrollView imported, instantiated, and the text added to it;
   buttons are added to the root layout before the ScrollView)
```

### Still not verified on a device

As with v1.0–v1.3, the APK was verified by static inspection only.
It was not installed on a phone in this session. The on-device
check — install v1.4 over v1.3, confirm all three buttons are
visible on opening the app with no scrolling, tap button 3 and
confirm the launcher icon disappears while the logcat `not found` /
`prevent start` lines stay gone — still needs to be done on the phone.

---

## v1.3 (2026-11-10, fourth build) — fix button 2 silent no-op

### Bug reported by the user

Button 1 ("Open app settings") worked, but button 2 ("Request ignore
battery optimizations") did nothing when tapped.

### Root cause

In `MainActivity.java`, button 2's onClick only called
`startActivity()` when `!pm.isIgnoringBatteryOptimizations(pkg)`.
If the app was ALREADY on the battery-optimization whitelist (e.g.
already allowed via Settings in step 1), the tap fell through both
branches and silently did nothing — no Toast, no dialog, no
feedback — so it looked broken. A second failure mode existed too:
on some ColorOS builds no activity handles
`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, so `startActivity()`
can throw `ActivityNotFoundException`.

### Fix (MainActivity.java only)

- Button 2: if `pm.isIgnoringBatteryOptimizations(pkg)` is true,
  show a Toast "Already ignoring battery optimizations - nothing
  to do / 已忽略电池优化，无需操作" and do not start the intent.
- Else, wrap `startActivity(intent)` in try/catch
  (`ActivityNotFoundException` and generic `Exception`): on
  failure show a Toast "System dialog not available on this ROM -
  please allow it manually in Settings > Battery / 系统没有这个
  弹窗，请在设置 > 电池里手动允许" and replace the on-screen text
  with the manual path (Settings > Battery > Battery optimization
  > Statistics Stub > Don't optimize) plus the ADB check command
  `adb shell dumpsys deviceidle whitelist | grep nearme`.
- Buttons 1 and 3 unchanged. `ReceiverService`, `BootReceiver`,
  manifest and permissions unchanged (still only
  `RECEIVE_BOOT_COMPLETED` and
  `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`).
- Version bump: `versionCode 3 -> 4`, `versionName 1.2 -> 1.3`
  (in `build.sh` aapt2 link args and in both `build.gradle` files).
  On-screen label updated to "Statistics Stub v1.3".

### Signing key — v1.1/v1.2 key REUSED, v1.3 updates v1.2 in place

The `debug.keystore` still exists in the project directory
(SHA-256 `de2d0be3fc1c28db78921a9c990bb7e65c8b4e50268642753e6a8c0f4a8a48a5`,
unchanged before and after the build — `build.sh` only generates a
keystore when none exists). v1.3 was signed with that same keystore.

**Consequence: v1.3 CAN update v1.2 in place** (plain install over
it, or `adb install -r app-debug.apk`). Verified: the v1.3 signer
certificate SHA-256 (`22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b`)
is identical to the v1.1/v1.2 signer digest recorded below. v1.0
still cannot be updated in place (different key) — uninstall v1.0
first, as before.

### v1.3 output

- `app-debug.apk` — 12,789 bytes (same size as v1.2; the fix is a few
  dozen lines of handler code)
- SHA-256: `a5425b952302642ed74409d82d45722f17b9523c8ddd948e6b7799cd35e45b94`
- Signer SHA-256 digest: `22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b`
  (1 signer, APK Signature Scheme v3) — identical to v1.1/v1.2.

### v1.3 verification (all run on the built APK)

```
$ apksigner verify --verbose --print-certs app-debug.apk
Verifies
Verified using v3 scheme (APK Signature Scheme v3): true
Number of signers: 1
Signer #1 certificate SHA-256 digest: 22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b

$ aapt2 dump badging app-debug.apk
package: name='com.nearme.statistics.rom' versionCode='4' versionName='1.3'
sdkVersion:'29' targetSdkVersion:'34'
uses-permission: name='android.permission.RECEIVE_BOOT_COMPLETED'
uses-permission: name='android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS'
launchable-activity: name='com.nearme.statistics.rom.MainActivity'

$ aapt2 dump xmltree app-debug.apk --file AndroidManifest.xml (excerpt)
  E: manifest  package="com.nearme.statistics.rom" versionCode=4 versionName="1.3"
    E: uses-permission  name="android.permission.RECEIVE_BOOT_COMPLETED"
    E: uses-permission  name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"
    E: activity   name=".MainActivity" exported=true  (MAIN/LAUNCHER)
    E: service    name=".service.ReceiverService" exported=true
    E: receiver   name=".BootReceiver" exported=true
        action "android.intent.action.BOOT_COMPLETED"

$ dexdump classes.dex — Class descriptors:
  Lcom/nearme/statistics/rom/BootReceiver;
  Lcom/nearme/statistics/rom/MainActivity;  (+ 3 lambda classes)
  Lcom/nearme/statistics/rom/service/ReceiverService;
```

### ADB check for the battery-whitelist status (suggested, not run here)

No phone was attached to this VM, so this was not run against the
user's device — it is the standard check, confirmed against Android
docs / community references:

```
adb shell dumpsys deviceidle whitelist | grep nearme
```

If `com.nearme.statistics.rom` appears in that output, the app is
already whitelisted — which is exactly the case in which the old
button 2 silently did nothing, and the case v1.3 now reports with
a Toast. (Equivalent list form: `adb shell cmd deviceidle
whitelist`.) To whitelist from ADB directly:
`adb shell dumpsys deviceidle whitelist +com.nearme.statistics.rom`.

### Still not verified on a device

As with v1.0–v1.2, the APK was verified by static inspection only.
It was not installed on a phone in this session. The on-device
check — install v1.3 over v1.2, tap button 2 while already
whitelisted and confirm the "already ignoring" Toast appears, and
confirm the logcat `not found` / `prevent start` lines stay gone —
still needs to be done on the phone.

---

## v1.2 (2026-11-10, third build) — hide the launcher icon, ACBridge-style

### What changed

- `MainActivity.java` (83 -> 137 lines): a third button,
  **"3. Hide icon / 隐藏图标"**. On tap it calls
  `PackageManager.setComponentEnabledSetting()` on this app's own
  `MainActivity` component (`COMPONENT_ENABLED_STATE_DISABLED`,
  `DONT_KILL_APP`), shows a Toast, and swaps the on-screen text to
  the unhide / uninstall instructions. That is the whole mechanism:
  the launcher icon disappears because the launcher component is
  disabled; the package, the service and the receiver are untouched.
- The `MAIN` / `LAUNCHER` intent-filter is deliberately **kept** in
  the manifest. Deleting it would make the app unlaunchable — the
  user could never launch it once to exit the stopped state, and
  there would be no screen from which to hide the icon. Hiding is
  runtime-only and user-triggered, never automatic: the button must
  be tapped by the user, and only after the two manual steps
  (launch once + allow auto-start) — the activity text and README
  both warn about this, because hiding first would leave the app in
  the stopped state and background starts could still be blocked.
- `ReceiverService`: **unchanged** — still `stopSelf(startId)` +
  `START_NOT_STICKY`, never reads intent extras, still start-on-
  demand only. `BootReceiver`: **unchanged**.
- Manifest: **no permission changes** — still only
  `RECEIVE_BOOT_COMPLETED` and `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`;
  still no `INTERNET`, location, phone state, or storage. Only a
  comment was added explaining the kept LAUNCHER filter and the
  runtime hide mechanism.
- Version bump: `versionCode 2 -> 3`, `versionName 1.1 -> 1.2`
  (in `build.sh` aapt2 link args and in both `build.gradle` files).
- One build failure hit and fixed: the first v1.2 build failed in
  `aapt2 link` with `AndroidManifest.xml:26: error: not well-formed
  (invalid token)` — the new manifest comment contained `--`, which
  is illegal inside an XML comment. That line was reworded to use a
  colon instead; no other change was needed.

### Signing key — v1.1 key REUSED, v1.2 updates v1.1 in place

The v1.1 `debug.keystore` still exists in the project directory
(`debug.keystore`, 2,666 bytes, SHA-256
`de2d0be3fc1c28db78921a9c990bb7e65c8b4e50268642753e6a8c0f4a8a48a5`,
unchanged before and after the build — `build.sh` only generates a
keystore when none exists). v1.2 was signed with that same keystore.

**Consequence: v1.2 CAN update v1.1 in place** (plain install over
it, or `adb install -r app-debug.apk`). Verified: the v1.2 signer
certificate SHA-256 (`22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b`)
is identical to the v1.1 signer digest recorded in the v1.1 section
below. v1.0 still cannot be updated in place (different key) —
uninstall v1.0 first, as before.

### v1.2 output

- `app-debug.apk` — 12,789 bytes
- SHA-256: `1c53f71e9f8b57d0d8138940113e7e2b159425845d7a64e15041249a0bcf29bf`
- Signer SHA-256 digest: `22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b`
  (1 signer, APK Signature Scheme v3) — identical to v1.1.

### v1.2 verification (all run on the built APK)

```
$ apksigner verify --verbose --print-certs app-debug.apk
Verifies
Verified using v3 scheme (APK Signature Scheme v3): true
Number of signers: 1
Signer #1 certificate SHA-256 digest: 22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b

$ aapt2 dump badging app-debug.apk
package: name='com.nearme.statistics.rom' versionCode='3' versionName='1.2'
sdkVersion:'29' targetSdkVersion:'34'
uses-permission: name='android.permission.RECEIVE_BOOT_COMPLETED'
uses-permission: name='android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS'
launchable-activity: name='com.nearme.statistics.rom.MainActivity'

$ aapt2 dump xmltree app-debug.apk --file AndroidManifest.xml (excerpt)
  E: manifest  package="com.nearme.statistics.rom" versionCode=3 versionName="1.2"
    E: uses-permission  name="android.permission.RECEIVE_BOOT_COMPLETED"
    E: uses-permission  name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"
    E: activity   name=".MainActivity" exported=true  (MAIN/LAUNCHER)
    E: service    name=".service.ReceiverService" exported=true
    E: receiver   name=".BootReceiver" exported=true
        action "android.intent.action.BOOT_COMPLETED"

$ dexdump classes.dex — Class descriptors:
  Lcom/nearme/statistics/rom/BootReceiver;
  Lcom/nearme/statistics/rom/MainActivity;  (+ 3 lambda classes)
  Lcom/nearme/statistics/rom/service/ReceiverService;

$ grep -ri "foreground|persistent|startForeground" app/src/main/
  (no hits at all) — no foreground service, no persistent flag anywhere.
```

### Still not verified on a device

As with v1.0/v1.1, the APK was verified by static inspection only.
It was not installed on a phone in this session. The on-device
checks — install v1.2 over v1.1, do the two manual steps, tap
"Hide icon" and confirm the launcher icon disappears while the
logcat `not found` / `prevent start` lines stay gone, then confirm
`adb shell pm enable com.nearme.statistics.rom/.MainActivity`
brings the icon back — still need to be done on the phone.
[Superseded by v1.5: that `pm enable` way back was proven to fail
with SecurityException on the user's phone; the v1.5 way back is
`am start -n com.nearme.statistics.rom/.UnhideActivity`. Do not
use the `pm enable` check above.]

---

## v1.1 (2026-11-10, second build)

### What changed (and what did NOT change — per user correction)

- **Correction honoured:** the stub must NOT be forced to stay in the
  background and must NOT be made persistent / foreground /
  always-running. **No foreground service, no notification, no
  `persistent` flag, and nothing resident was added in v1.1** — and
  none existed in v1.0 either. Verified by grep over all sources:
  the only "sticky" hit is `START_NOT_STICKY` in
  `ReceiverService.onStartCommand()`, which means the system will
  *not* restart it. The stub is startable on demand only: it starts,
  stops itself immediately, and is gone.
- `MainActivity`: now a vertical layout with the explanatory text
  plus two buttons — (1) open this app's system Settings page
  (`ACTION_APPLICATION_DETAILS_SETTINGS`, where ColorOS puts the
  auto-start / allow-background switches; there is no reliable
  public Intent for ColorOS's own auto-start page), (2) request
  ignoring battery optimizations
  (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, only opened if
  `PowerManager.isIgnoringBatteryOptimizations()` is false).
- `BootReceiver` (new file): exported, `BOOT_COMPLETED` filter, starts
  `ReceiverService` explicitly on boot. It reads nothing and starts
  nothing else.
- `ReceiverService`: **unchanged** — still `stopSelf(startId)` +
  `START_NOT_STICKY`, never reads intent extras.
- Manifest: added **only** `RECEIVE_BOOT_COMPLETED` and
  `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`. Still no `INTERNET`,
  location, phone state, or storage permission.
- Version bump: `versionCode 1 -> 2`, `versionName 1.0 -> 1.1`
  (in `build.sh` aapt2 link args and in both `build.gradle` files).
- `build.sh`: added `-encoding UTF-8` to `javac` (the first v1.1
  build failed on em-dashes in comments under javac's default
  US-ASCII encoding; the source files were also changed to ASCII
  `--` / `'` for safety).
- Source size v1.1: `MainActivity.java` 83 lines,
  `BootReceiver.java` 28 lines, `ReceiverService.java` 30 lines,
  `AndroidManifest.xml` 59 lines — 200 lines total.

### Signing key — v1.0 key LOST, v1.1 uses a NEW key

The v1.0 debug keystore was **not** preserved: a search of
`~/workspace` found no `*.keystore` file at all, and the keystore
was `.gitignore`d out of the repo. `build.sh` therefore generated a
fresh debug keystore on the v1.1 build (RSA 2048, 10000 days,
`CN=Android Debug,O=Android,C=US`).

**Consequence: v1.1 CANNOT update v1.0 in place.** The user must
uninstall v1.0 first (`adb uninstall com.nearme.statistics.rom`)
and then install v1.1. This is stated in README.md. The new
`debug.keystore` now exists in the project directory (still
`.gitignore`d, not committed) — keeping it is what would let a
future rebuild update v1.1 in place; losing it again means another
uninstall-first cycle.

### v1.1 output

- `app-debug.apk` — 12,789 bytes
- SHA-256: `6f19f43fc3ad4ff55f8b473d4e16e4d3c7d9ddebdc83bdc56a1d758178b9b422`
- Signer SHA-256 digest: `22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b`
  (1 signer, APK Signature Scheme v3)

### v1.1 verification (all run on the built APK)

```
$ apksigner verify --verbose --print-certs app-debug.apk
Verifies
Verified using v3 scheme (APK Signature Scheme v3): true
Number of signers: 1
Signer #1 certificate SHA-256 digest: 22dd4876c8fab003e6ac7152f146855d077bf5607d108c6e926a68a897165e9b

$ aapt2 dump badging app-debug.apk
package: name='com.nearme.statistics.rom' versionCode='2' versionName='1.1'
sdkVersion:'29'  targetSdkVersion:'34'
uses-permission: name='android.permission.RECEIVE_BOOT_COMPLETED'
uses-permission: name='android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS'
launchable-activity: name='com.nearme.statistics.rom.MainActivity'

$ aapt2 dump xmltree app-debug.apk --file AndroidManifest.xml (excerpt)
  E: manifest  package="com.nearme.statistics.rom" versionCode=2 versionName="1.1"
    E: uses-permission  name="android.permission.RECEIVE_BOOT_COMPLETED"
    E: uses-permission  name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"
    E: activity   name=".MainActivity" exported=true  (MAIN/LAUNCHER)
    E: service    name=".service.ReceiverService" exported=true
    E: receiver   name=".BootReceiver" exported=true
        action "android.intent.action.BOOT_COMPLETED"

$ dexdump classes.dex — Class descriptors:
  Lcom/nearme/statistics/rom/BootReceiver;
  Lcom/nearme/statistics/rom/MainActivity;
  Lcom/nearme/statistics/rom/service/ReceiverService;
  (+ MainActivity lambda classes, R / R$layout / R$string)

$ grep -ri "foreground|persistent|startForeground" app/src/main/
  only hit: START_NOT_STICKY (ReceiverService + its comment) — no
  foreground service, no persistent flag anywhere.
```

### Still not verified on a device

As with v1.0, the APK was verified by static inspection only. It was
not installed on a phone in this session. The on-device check — that
after installing v1.1 and doing the two manual steps (launch once,
allow auto-start), both the `Unable to start service … not found`
lines *and* the `OplusAppStartupManager: … prevent start` lines stop
— still needs to be done on the phone (see README.md).

---

## v1.0 (original build — kept for reference)

## Toolchain installed for this build (all under ~/workspace, persistent)

- JDK: Eclipse Temurin OpenJDK 17.0.21+9
  (`~/workspace/jdk-17.0.21+9`, downloaded from
  `https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse`)
- Android SDK: `~/workspace/android-sdk`
  - cmdline-tools 11076708 (`commandlinetools-linux-11076708_latest.zip`)
  - platform android-34 — `platform-34-ext7_r03.zip`
    SHA1 `1f2e9478d6a7601425ceaa553311dc43191f103d` (matches repository2-1.xml)
  - build-tools 34.0.0 — `build-tools_r34-linux.zip`
    SHA1 `d6d58e0c6925a9e4d9a541e84cd1f405c2f9d2a9` (matches repository2-1.xml)
    aapt2 2.19-10229193, d8/R8 8.2.2-dev

### sdkmanager did not work — workaround used

`sdkmanager` fails on this VM: its Java HTTP client crashes in
`HttpURLConnection.doTunneling` against the VM's authenticated egress
proxy (`hatch-egress-proxy:3128`), with
`java.util.NoSuchElementException` in `StringTokenizer.nextToken`.
Workaround: the platform and build-tools ZIPs were downloaded directly
with `curl` (which handles the proxy fine), SHA1-verified against
`repository2-1.xml`, and unzipped into the SDK layout by hand.
The ZIPs contain a one-level-deep `android-34` / `android-14`
subdirectory that had to be moved up one level. No Gradle was used:
Gradle would have needed the same proxy path to download its
distribution and dependencies.

## Build

```
./build.sh        # with JAVA_HOME=<Temurin 17> ANDROID_HOME=~/workspace/android-sdk
```

Steps in `build.sh`: `aapt2 compile` (res) → `aapt2 link`
(manifest, `--version-code 1 --version-name 1.0 --min-sdk-version 29
--target-sdk-version 34`) → `javac` (sources + generated `R.java`,
`-source/-target 17`) → `d8` (DEX) → `zip` classes.dex in →
`zipalign -f 4` → `apksigner sign` with a freshly generated debug
keystore (`androiddebugkey`, RSA 2048, 10000 days).

One build failure was hit and fixed: `d8` 8.2 rejects a bare classes
directory (`Unsupported source file type`); `build.sh` now passes the
`.class` files to `d8` explicitly.

The debug keystore is **not** included in this repo (it is in
`.gitignore`). A rebuild generates a new one, so a rebuilt APK has a
different signing key — uninstall the old APK before installing a
rebuilt one instead of updating over it.
[Update, v1.2: this changed — the v1.1 `debug.keystore` was in fact
preserved in the project directory and v1.2 reused it, so v1.2
updates v1.1 in place. See the v1.2 section at the top.]

## Output

- `app-debug.apk` — 12,789 bytes
- SHA-256: `4c92d1afc09c911f9e83dd30505d6669c3a4a2aeb29ebd8410a5fa8f81730b29`

## Verification (all run on the built APK)

```
$ apksigner verify --verbose app-debug.apk
Verifies
Verified using v3 scheme (APK Signature Scheme v3): true
Number of signers: 1

$ aapt2 dump badging app-debug.apk
package: name='com.nearme.statistics.rom' versionCode='1' versionName='1.0'
  platformBuildVersionName='14' platformBuildVersionCode='34'
  compileSdkVersion='34' compileSdkVersionCodename='14'
sdkVersion:'29'
targetSdkVersion:'34'
application-label:'Statistics Stub'
launchable-activity: name='com.nearme.statistics.rom.MainActivity'
feature-group: ...
  uses-feature: name='android.hardware.faketouch'   (default, implied)
  # NOTE: no uses-permission line at all — see below

$ aapt2 dump xmltree app-debug.apk --file AndroidManifest.xml
  E: manifest  package="com.nearme.statistics.rom" versionCode=1 versionName="1.0"
  E: uses-sdk  minSdkVersion=29 targetSdkVersion=34
  E: application label="Statistics Stub"
    E: activity  name=".MainActivity" exported=true
      E: intent-filter  action MAIN / category LAUNCHER
    E: service   name=".service.ReceiverService" exported=true

$ aapt2 dump badging app-debug.apk | grep -i permission
  (none found)   <- requested-permissions list is EMPTY

$ unzip -l app-debug.apk
  AndroidManifest.xml, res/layout/activity_main.xml, resources.arsc,
  classes.dex (2896 bytes), META-INF/*

$ dexdump build/classes.dex  (before the build/ dir was cleaned)
  Class descriptor: 'Lcom/nearme/statistics/rom/MainActivity;'
  Class descriptor: 'Lcom/nearme/statistics/rom/service/ReceiverService;'
  (+ generated R, R$layout, R$string)
```

Source size: `MainActivity.java` 26 lines, `ReceiverService.java`
30 lines, `AndroidManifest.xml` 32 lines — 88 lines total.

## Not verified on a device

The APK was built and verified by static inspection only (aapt2 /
apksigner / dexdump). It was **not** installed on a phone in this
session, so the on-device behaviour — that
`startService(com.nearme.statistics.rom/.service.ReceiverService)`
resolves and that the logcat "not found" lines stop — still needs a
one-time check on the phone after installing (see README.md).
