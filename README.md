# nearme-statistics-stub

A tiny, open-source, do-nothing Android stub app, created with AI assistance and inspired by this XDA Forums thread (CbIP, OnePlus 13 / OxygenOS 15), which first described the log-spam problem and the stub-app workaround.

**Current version: 1.6** (versionCode 7). See [BUILD_LOG.md](BUILD_LOG.md)
for what changed in v1.6 and its verification output.

## Why this exists

On OPPO / OnePlus phones running ColorOS / OxygenOS, many system apps
try to start the service

```
com.nearme.statistics.rom/.service.ReceiverService
```

That service used to be provided by the system statistics package
(`com.oplus.statistics.rom`, "Basic Data Services" / the User Experience
Program). If that package is disabled or uninstalled for a user
(for example with `pm disable-user --user 0 com.oplus.statistics.rom`
or `pm uninstall --user 0 com.oplus.statistics.rom`), every one of those
calls fails and logcat is spammed with lines like:

```
Unable to start service Intent { cmp=com.nearme.statistics.rom/.service.ReceiverService ... }: not found
```

This stub provides exactly that service name, so the calls resolve.
The service immediately stops itself and does nothing else.

## What it does

- Registers the service `com.nearme.statistics.rom.service.ReceiverService`
  (`exported=true`), so explicit `startService()` intents aimed at it
  no longer fail with "not found".
- `onStartCommand()` returns `START_NOT_STICKY` and stops itself at once.
- Ships a minimal launcher activity that only shows an explanatory text,
  so the app is visible and easy to uninstall from Settings > Apps.
- **v1.1:** adds a `BootReceiver` (see below) and two buttons in the
  launcher activity (see "ColorOS auto-start" below).
- **v1.2:** adds a third button, "Hide icon / 隐藏图标", which hides
  the launcher icon ACBridge-style (see "Hide the launcher icon"
  below). Hiding the icon does not uninstall the app and does not
  stop the stub service.
- **v1.3:** fixes button 2 ("Request ignore battery optimizations").
  If the app was already on the battery-optimization whitelist
  (e.g. allowed via Settings in step 1), the tap silently did
  nothing and looked broken. It now shows a Toast saying it is
  already whitelisted. If this ROM has no system dialog for the
  request, the failure is caught and a Toast plus on-screen text
  point at the manual path: Settings > Battery > Battery
  optimization. Nothing else changed.
- **v1.4:** fixes the layout bug that hid button 3. The three
  buttons used to sit below a very long text in a plain
  `LinearLayout` with no `ScrollView`, so on a phone screen buttons
  2 and 3 were pushed off the bottom and unreachable. The buttons
  now come first, at the top of the screen, the text is shortened
  to a few lines, and it lives in a `ScrollView` below the buttons.
  All three buttons are visible the moment the app opens. Button
  behaviours are unchanged.
- **v1.5:** fixes the hide-icon trap in v1.2-v1.4 (see below).
  The launcher filter now lives on an activity-alias
  `.LauncherAlias` instead of on `MainActivity`, button 3 disables
  ONLY that alias, and a new exported `.UnhideActivity` re-enables
  it. The way back after hiding is now
  `am start -n com.nearme.statistics.rom/.UnhideActivity` --
  no `pm enable` needed, and no reinstall needed.
- **v1.6:** fixes button 1. It used to open the single-app details
  page (`ACTION_APPLICATION_DETAILS_SETTINGS`), but on ColorOS 15 /
  OPPO A3 Pro that page has NO auto-start toggle, so the button was
  useless. Button 1 now tries the known ColorOS safecenter
  auto-start list activities in order (see below) and opens the
  global list directly: Settings > Apps > Auto-start
  (设置 > 应用 > 自启动). If none of them resolve on a build, it falls
  back to the app-details page and shows a Toast with the manual
  path instead of failing silently.

## What it does NOT do — read this first

- **It is NOT kept running. There is no foreground service, no
  notification, no `persistent` flag, and nothing that keeps it
  resident.** The stub only needs to be *startable on demand*: when
  another app calls `ReceiverService`, the service starts, stops
  itself immediately (`stopSelf()` + `START_NOT_STICKY`), and is gone.
  It is not forced to stay in the background.
- **Permissions in v1.1 (only these two):** `RECEIVE_BOOT_COMPLETED`
  and `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`. Still no `INTERNET`,
  no location, no phone state, no storage, nothing else.
- No network access, no data collection, no storage, no logging of the
  intents it receives (it does not even look at the `Intent` extras),
  no other components, no background work.
- It is **not** the real statistics service and does not replace its
  data collection. Disabling `com.oplus.statistics.rom` is what stops
  the reporting; this stub only stops the "not found" log spam that
  disabling it causes.

The whole app is about 315 lines of source. Read `MainActivity.java`,
`UnhideActivity.java`, `BootReceiver.java`, and `ReceiverService.java`
— there is nothing hidden in them.

## ColorOS auto-start: the "prevent start" problem (v1.1)

After installing v1.0, logcat showed a new line instead of
"not found":

```
OplusAppStartupManager: isAllowStartFromStartService: prevent start com.nearme.statistics.rom
```

The service was now found, but ColorOS blocked the background start:
the stub had never been launched manually, and it was not on the
auto-start allowlist. **A manifest alone cannot grant that allowlist
entry — it is a system setting, and only the user can allow it.**
v1.1 therefore adds:

1. A `BootReceiver` (`exported=true`, `BOOT_COMPLETED`) that starts
   `ReceiverService` explicitly after a reboot, so the stub can exit
   the stopped state on boot. Note a newly installed app does not
   receive `BOOT_COMPLETED` until it has been launched manually once.
2. Two buttons in the launcher activity:
   - **"1. Open auto-start management (自启动)"** —
     **v1.6:** opens the GLOBAL auto-start list directly, not the
     single-app details page. It tries, in order:
     `com.coloros.safecenter` /
     `com.coloros.safecenter.permission.startup.StartupAppListActivity`;
     `com.coloros.safecenter` /
     `com.coloros.safecenter.startupapp.StartupAppListActivity`;
     `com.oppo.safe` /
     `com.oppo.safe.permission.startup.StartupAppListActivity`;
     `com.oplus.safecenter` /
     `com.oplus.safecenter.permission.startup.StartupAppListActivity`
     (in case ColorOS 15 renamed the package); then the action
     Intent
     `com.coloros.safecenter.startupapp.permission.STARTUP_APP_LIST`
     targeted at `com.coloros.safecenter`. Each candidate is checked
     with `resolveActivity()` first and wrapped in try/catch, so a
     missing activity just means "try the next one". If none
     resolve, it falls back to the app-details page and shows a
     Toast with the manual path. Find **Statistics Stub** in that
     list and turn it on. Manual fallback, if the button ever opens
     the wrong page: Settings > Apps > Auto-start
     (设置 > 应用 > 自启动), or Phone Manager > Privacy permissions >
     Auto-start management. Note ColorOS may cap the auto-start
     list at 5 apps — if it is full, turn one off first.
     (Before v1.6, button 1 opened the app-details page, which on
     ColorOS 15 has no auto-start toggle at all.)
   - **"2. Request ignore battery optimizations"** — opens the system
     dialog asking to exempt this app from battery optimization
     (the user still has to confirm it). **v1.3:** if the app is
     already whitelisted, tapping it now says so with a Toast
     instead of silently doing nothing; if the ROM has no such
     dialog, it says so and shows the manual Settings > Battery
     path.

### The two manual steps the user still has to do on the phone

After installing v1.1, do both of these, in order:

1. **Launch the stub once** — tap its launcher icon ("Statistics
   Stub"). This takes it out of the stopped state; until then Android
   will not deliver `BOOT_COMPLETED` to it and other apps' calls to
   it can be blocked.
2. **Allow auto-start** — in the stub app tap button 1, which opens
   the global auto-start list (Settings > Apps > Auto-start,
   设置 > 应用 > 自启动); find Statistics Stub there
   and turn it on. If button 1 opens the app-details page instead,
   none of the ColorOS auto-start activities resolved on this build
   — open that list manually (same path, or Phone Manager >
   Privacy permissions > Auto-start management). Then tap button 2
   and confirm ignoring battery optimizations.

Then clear logcat and check again:

```
adb shell logcat -c
# wait a few minutes / toggle Wi-Fi once
adb shell logcat -d | grep -i "nearme.statistics.rom"
```

Both `Unable to start service … not found` **and**
`OplusAppStartupManager: … prevent start` lines should stop
appearing. The stub's own service produces no log lines, so a
successful call is silent.

## Hide the launcher icon (v1.2, ACBridge-style; v1.5 fixes the trap)

Like ACBridge, this stub does not need to sit on the desktop: once it
is set up, nothing in it needs opening again. v1.2 therefore adds a
third button in the launcher activity: **"3. Hide icon / 隐藏图标"**.

How it works in v1.5: tapping the button calls
`PackageManager.setComponentEnabledSetting()` on this app's own
**launcher alias** (`.LauncherAlias`, `COMPONENT_ENABLED_STATE_DISABLED`,
`DONT_KILL_APP`). The launcher then no longer shows an icon for it.
**This only hides the icon — it does not uninstall the app, it does
not disable the package, and it does not stop `ReceiverService` or
`BootReceiver`.** The stub keeps working exactly as before; it is
still a normal installed app in Settings > Apps.

The `MAIN` / `LAUNCHER` intent-filter lives on `.LauncherAlias`
(`targetActivity=".MainActivity"`), not on `MainActivity` itself.
`MainActivity` and the new `.UnhideActivity` stay enabled and
exported, so they can still be started directly.

### Warning: do the two manual steps FIRST, then hide

**Do not hide the icon before you have launched the app once and
allowed auto-start** (the two steps above). If the icon is hidden
first, the app stays in the stopped state, Android will not deliver
`BOOT_COMPLETED` to it, and ColorOS can still block other apps'
background starts of the stub service — the log spam comes back.
The correct order is: install -> launch once -> allow auto-start
-> tap "Hide icon".

### The v1.2-v1.4 trap, and the v1.5 fix — read this

In v1.2-v1.4, button 3 disabled `MainActivity` itself. After that,
the way back did **not** work on this phone:

```
adb shell pm enable com.nearme.statistics.rom/.MainActivity
  -> SecurityException: Shell cannot change component state ...
am start -n com.nearme.statistics.rom/.MainActivity
  -> Error type 3, Activity class ... does not exist.
```

Shell cannot re-enable a component the app itself disabled, and a
disabled activity cannot be started. The only way back was
reinstalling the APK. **Do not use `pm enable` on a self-disabled
component.**

v1.5 fixes this by disabling only the alias. The way back is a
separate, always-enabled, exported activity, `.UnhideActivity`,
which the app itself can start and which re-enables the alias (and
`MainActivity`, for safety) from inside the app — the app *is*
allowed to change its own components, unlike shell `pm enable`.

### How to get the icon back (v1.5)

From the phone shell (AYA terminal — you are already inside the
phone, so no `adb shell` prefix):

```
am start -n com.nearme.statistics.rom/.UnhideActivity
```

From a PC over ADB:

```
adb shell am start -n com.nearme.statistics.rom/.UnhideActivity
```

It shows a Toast "Icon restored / 图标已恢复" and finishes; the
launcher icon reappears. No `pm enable`, no reinstall. You can
also still find the app in Settings > Apps > Statistics Stub.

### How to uninstall a hidden app

Settings > Apps > Statistics Stub > Uninstall. Or:
```
adb uninstall com.nearme.statistics.rom
```

## Install

1. Download `app-debug.apk` from the
   [Releases](../../releases) page (or build it yourself, below).
2. **v1.6 updates v1.5 in place — no uninstall needed.** v1.6 was
   signed with the *same* debug key as v1.1/v1.2/v1.3/v1.4/v1.5 (the
   `debug.keystore` was preserved in the project directory, so the
   signer certificate is identical), so just tap `app-debug.apk`
   and install over the old version (or:
   `adb install -r app-debug.apk`).
   **If v1.0 is still installed, uninstall it first** — v1.1 was
   signed with a *new* debug key (the v1.0 keystore was not saved
   and could not be recovered), so v1.1/v1.2/v1.3/v1.4/v1.5/v1.6 cannot update v1.0:
   ```
   adb uninstall com.nearme.statistics.rom
   ```
   then tap `app-debug.apk` on the phone and allow installing from
   that source.
3. Do the two manual steps above (launch once, allow auto-start).
4. Optionally tap "3. Hide icon" — only after step 3.
5. Verify it stops the spam (see the logcat check above).

Installing this package is allowed while `com.oplus.statistics.rom` is
disabled, because the package name `com.nearme.statistics.rom` is a
*different* package name and is not currently installed on the phone.
Android only blocks installing a package whose name is already
installed for that user.

## Uninstall

Settings > Apps > Statistics Stub > Uninstall. Or:

```
adb uninstall com.nearme.statistics.rom
```

Removing it restores the previous behaviour (log spam returns, but so
does nothing else — the real statistics package stays disabled unless
you re-enable it with `pm enable com.oplus.statistics.rom`).

## Build it yourself

No Gradle download is needed. You need a JDK 17 and the Android SDK
(platform `android-34`, build-tools `34.0.0`):

```sh
./build.sh
```

`build.sh` runs `aapt2 compile/link`, `javac`, `d8`, `zipalign` and
`apksigner` (debug keystore, generated on first run), and writes
`app-debug.apk` next to it. See `BUILD_LOG.md` for the exact versions
used to build the released APK, and the verification output.

## Caveats

- This is a community workaround, not an official OPPO/OnePlus fix.
  A system update could change which service name system apps call.
- The APK is debug-signed. That is fine for a sideloaded stub; do not
  expect Play Store updates for it.
- **Signing-key note:** the debug keystore is deliberately *not* in
  this repo (`.gitignore`). The v1.1 APK was signed with a new key
  because the v1.0 key was lost, so v1.1 cannot update v1.0 in place.
  **v1.2 reuses the v1.1 key** — the v1.1 `debug.keystore` was
  preserved in the project directory, and v1.2 was verified to have
  the identical signer certificate, so v1.2 updates v1.1 in place.
  **v1.3 reuses the same key again**, so v1.3 updates v1.2 in place.
  **v1.4 reuses the same key yet again**, so v1.4 updates v1.3 in
  place.
  **v1.5 reuses the same key yet again**, so v1.5 updates v1.4 in
  place.
  **v1.6 reuses the same key yet again**, so v1.6 updates v1.5 in
  place.
  If you rebuild from source later without that keystore, the same
  uninstall-first rule applies again — keep the generated
  `debug.keystore` file somewhere safe and rebuild with it to keep
  in-place updates working.
- If you re-enable `com.oplus.statistics.rom`, you do not need this
  stub any more — uninstall it.
