[Uploading README.md…]()
# nearme-statistics-stub

A tiny, open-source, do-nothing Android stub app, created with AI assistance and inspired by [this XDA Forums thread](https://xdaforums.com/t/solved-a-lot-of-apps-try-to-call-missing-com-nearme-statistics-rom-service.4743261/) (CbIP, OnePlus 13 / OxygenOS 15), which first described the log-spam problem and the stub-app workaround.

**Current version: 1.6** (versionCode 7).

## Why this exists

On OPPO / OnePlus phones running ColorOS / OxygenOS, many system apps try to start the service

```
com.nearme.statistics.rom/.service.ReceiverService
```

That service used to be provided by the system statistics package (`com.oplus.statistics.rom`, "Basic Data Services" / the User Experience Program). If that package is disabled or uninstalled for a user (for example with `pm disable-user --user 0 com.oplus.statistics.rom` or `pm uninstall --user 0 com.oplus.statistics.rom`), every one of those calls fails and logcat is spammed with lines like:

```
Unable to start service Intent { cmp=com.nearme.statistics.rom/.service.ReceiverService ... }: not found
```

This stub provides exactly that service name, so the calls resolve. The service immediately stops itself and does nothing else.

## What it does

- Registers the service `com.nearme.statistics.rom.service.ReceiverService` (`exported=true`), so explicit `startService()` intents aimed at it no longer fail with "not found".
- `onStartCommand()` returns `START_NOT_STICKY` and stops itself at once.
- It is **not** kept running. There is no foreground service, no notification, no `persistent` flag, and nothing that keeps it resident. It only needs to be startable on demand.
- Permissions: only `RECEIVE_BOOT_COMPLETED` and `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`. No `INTERNET`, no location, no phone state, no storage, nothing else.
- No network access, no data collection, no storage, no logging of the intents it receives (it does not even look at the `Intent` extras).
- It is **not** the real statistics service and does not replace its data collection. Disabling `com.oplus.statistics.rom` is what stops the reporting; this stub only stops the "not found" log spam that disabling it causes.

## Install

1. Download `app-debug.apk` from the [Releases](../../releases) page.
2. Tap it on the phone and allow installing from that source. Or: `adb install -r app-debug.apk`.
3. Launch it once, then do the two steps below.

## Usage

### 1. Allow auto-start

Tap **"1. Open auto-start management"** in the app. It opens the ColorOS auto-start list (Settings > Apps > Auto-start / 设置 > 应用 > 自启动). Find **Statistics Stub** there and turn it on.

If the button opens the wrong page, open that list manually: Settings > Apps > Auto-start, or Phone Manager > Privacy permissions > Auto-start management. Note ColorOS may cap the auto-start list at 5 apps — if it is full, turn one off first.

### 2. Ignore battery optimizations

Tap **"2. Request ignore battery optimizations"** in the app and confirm the system dialog. If it says the app is already whitelisted, nothing more to do.

### 3. Hide the icon (optional)

Tap **"3. Hide icon"** in the app, **only after steps 1 and 2 are done**. The launcher icon disappears; the app and its service keep working.

To get the icon back, run (from the phone shell, no `adb shell` prefix):

```
am start -n com.nearme.statistics.rom/.UnhideActivity
```

Or from a PC: `adb shell am start -n com.nearme.statistics.rom/.UnhideActivity`

### Verify it works

```
adb shell logcat -c
# wait a few minutes / toggle Wi-Fi once
adb shell logcat -d | grep -i "nearme.statistics.rom"
```

Both `Unable to start service … not found` and `OplusAppStartupManager: … prevent start` lines should stop appearing. The stub's own service produces no log lines, so a successful call is silent.

## Uninstall

Settings > Apps > Statistics Stub > Uninstall. Or:

```
adb uninstall com.nearme.statistics.rom
```

Removing it restores the previous behaviour (log spam returns, but so does nothing else — the real statistics package stays disabled unless you re-enable it with `pm enable com.oplus.statistics.rom`).

## Build it yourself

You need a JDK 17 and the Android SDK (platform `android-34`, build-tools `34.0.0`):

```sh
./build.sh
```

## Caveats

- This is a community workaround, not an official OPPO/OnePlus fix. A system update could change which service name system apps call.
- The APK is debug-signed. That is fine for a sideloaded stub; do not expect Play Store updates for it.
- If you re-enable `com.oplus.statistics.rom`, you do not need this stub any more — uninstall it.
