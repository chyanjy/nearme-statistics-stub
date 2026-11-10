
[Uploading README.md…]()
# NearMe Statistics Stub · OPPO / 一加数据基础服务占位器

A tiny, open-source, do-nothing Android stub app, created with AI assistance and inspired by [this XDA Forums thread](https://xdaforums.com/t/solved-a-lot-of-apps-try-to-call-missing-com-nearme-statistics-rom-service.4743261/) (CbIP, OnePlus 13 / OxygenOS 15), which first described the log-spam problem and the stub-app workaround.

一个小巧、开源、什么也不做的安卓占位 App，由 AI 辅助创作，灵感来自 [XDA 论坛的这个帖子](https://xdaforums.com/t/solved-a-lot-of-apps-try-to-call-missing-com-nearme-statistics-rom-service.4743261/)（CbIP，OnePlus 13 / OxygenOS 15），那个帖子最早讲了日志刷屏的问题和占位 App 这个办法。

**Current version: 1.6** (versionCode 7). / **当前版本：1.6**（versionCode 7）。

## Why this exists / 为什么有这个东西

On OPPO / OnePlus phones running ColorOS / OxygenOS, many system apps try to start the service

在运行 ColorOS / OxygenOS 的 OPPO / 一加手机上，很多系统 App 都会去启动下面这个服务：

```
com.nearme.statistics.rom/.service.ReceiverService
```

That service used to be provided by the system statistics package (`com.oplus.statistics.rom`, "Basic Data Services" / the User Experience Program). If that package is disabled or uninstalled for a user (for example with `pm disable-user --user 0 com.oplus.statistics.rom` or `pm uninstall --user 0 com.oplus.statistics.rom`), every one of those calls fails and logcat is spammed with lines like:

这个服务以前是由系统统计包（`com.oplus.statistics.rom`，“数据基础服务” / 用户体验计划）提供的。要是把那个包给某个用户禁用或卸载了（比如 `pm disable-user --user 0 com.oplus.statistics.rom` 或 `pm uninstall --user 0 com.oplus.statistics.rom`），每次调用都会失败，logcat 里就会刷出这样的行：

```
Unable to start service Intent { cmp=com.nearme.statistics.rom/.service.ReceiverService ... }: not found
```

This stub provides exactly that service name, so the calls resolve. The service immediately stops itself and does nothing else.

这个占位 App 提供的就是 exactly 那个服务名，让调用能找到它。服务一启动就马上自己停掉，什么也不做。

## Why disabling `com.oplus.statistics.rom` matters / 为什么要禁用 `com.oplus.statistics.rom`

`com.oplus.statistics.rom` ("Basic Data Services", v5.9.1.00) is not a harmless counter. On the author's phone it had accumulated 653.22 MB of stored events/logs, and its manifest (verified with `dumpsys package`) shows:

`com.oplus.statistics.rom`（“数据基础服务”，5.9.1.00 版）不是一个无害的计数器。在作者的手机上，它已经攒了 653.22 MB 的事件 / 日志数据，用 `dumpsys package` 核实，它的清单里有：

- **Permissions / 权限**：`READ_PRIVILEGED_PHONE_STATE` (device identity / 设备身份), precise + background location (精确定位 + 后台定位), `PACKAGE_USAGE_STATS` + `QUERY_ALL_PACKAGES` (which apps you use, for how long, and the full installed-app list / 用了哪些 App、用了多久、装了哪些 App 的完整列表), plus `INTERNET` and exact alarms.
- **Triggers / 触发**：`BOOT_COMPLETED`, `CONNECTIVITY_CHANGE`, `BATTERY_OKAY` / `BATTERY_LOW`, `TIMEZONE_CHANGED` / `TIME_SET`, `ACTION_SHUTDOWN` — it wakes on boot, on every network change, on battery changes, and on shutdown. 开机、每次联网变化、电量变化、关机都会把它唤醒。
- **Upload paths / 上报通道**：services including `DCS_FILE_UPLOAD`, and providers named `TrackEventProvider`, `TrackCommonProvider`, `BalanceEventProvider`, `DccContentProvider`, plus Nearx (`nearx.track`) storage and `dcc.ml` inference/training providers. The community-documented endpoints include `*.dcs.oppo.com`, `*.stat.oppo.com`, `*.dcs.coloros.com`, `*.heytap.com` (dcs/stat), and `*.nearx.cn`.
- **Turning off the switch does not stop it / 关了开关也管不住它**：after turning off Settings > Privacy > User Experience Program, a PCAPdroid capture on the author's phone (2026-11-10, 21:22–21:23) still caught it making DNS lookups to `mdp-appconf-cn.heytapdownload.com` (2×) and `dc-dragate-cn.heytapmobi.com` (1×). Those three were DNS queries only — no data upload was captured in that short window — but they prove the switch alone does not stop it from reaching out to HeyTap upload domains.
  在作者的手机上，关掉“设置 > 隐私 > 用户体验计划”之后，用 PCAPdroid 抓包（2026-11-10 21:22–21:23），还是抓到它在查 `mdp-appconf-cn.heytapdownload.com`（2 次）和 `dc-dragate-cn.heytapmobi.com`（1 次）这两个 HeyTap 上报域名。那三条只是 DNS 查询，那次短时间抓包里没抓到数据上传，但已经证明了：只关开关，管不住它去找上报域名。
- **It runs as a privileged system app / 它是特权系统 App**：`PRIVILEGED` / `PRODUCT`, installed in the system partition, with its permissions granted by default and no user-facing way to remove it without ADB. It collects even with no Unicom SIM in the phone — the reporting targets are baked into the firmware.
  它是特权系统 App，装在系统分区里，权限默认就给了，不用 ADB 根本卸不掉。而且手机里就算没有联通卡它也照样报，上报目标是写死在固件里的。

In short: it watches device identity, location, app usage and feature usage, stores hundreds of megabytes of it, and periodically uploads it to the vendor's servers — and the visible "opt out" switch does not fully stop it. Disabling it (and using this stub to silence the log spam that disabling causes) is the only no-root way to stop the collection.

一句话：它盯着设备身份、位置、App 使用情况和功能使用情况，攒了几百 MB 的数据，定期往厂商的服务器上报，而且那个看得见的“退出体验计划”开关并不能完全拦住它。禁用它（再用这个占位 App 把禁用之后冒出来的日志刷屏压下去），是不用 Root 就能停掉这套收集的唯一办法。

The evidence above is from the author's own phone (`dumpsys package`, PCAPdroid, AYA). Your build may differ slightly; check `dumpsys package com.oplus.statistics.rom` on your own device before deciding.

上面这些证据都来自作者自己的手机（`dumpsys package`、PCAPdroid、AYA）。不同机型、不同版本可能略有不同，决定之前，您也可以在自己的手机上跑 `dumpsys package com.oplus.statistics.rom` 核实一下。

## What it does / 它是干什么的

- Registers the service `com.nearme.statistics.rom.service.ReceiverService` (`exported=true`), so explicit `startService()` intents aimed at it no longer fail with "not found".
  注册了 `com.nearme.statistics.rom.service.ReceiverService` 这个服务（`exported=true`），让那些指名道姓要启动它的调用不再报 "not found"。
- `onStartCommand()` returns `START_NOT_STICKY` and stops itself at once.
  `onStartCommand()` 返回 `START_NOT_STICKY`，然后马上自己停掉。
- It is **not** kept running. There is no foreground service, no notification, no `persistent` flag, and nothing that keeps it resident. It only needs to be startable on demand.
  它**不会一直挂着**。没有前台服务、没有通知、没有 `persistent` 标志，没有任何让它常驻的东西。它只需要在别的 App 叫它的时候能起来就行。
- Permissions: only `RECEIVE_BOOT_COMPLETED` and `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`. No `INTERNET`, no location, no phone state, no storage, nothing else.
  权限只有两个：`RECEIVE_BOOT_COMPLETED`（开机接收）和 `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`（请求忽略电池优化）。没有联网、没有位置、没有电话、没有存储，别的什么都没有。
- No network access, no data collection, no storage, no logging of the intents it receives (it does not even look at the `Intent` extras).
  不联网、不收集数据、不存数据、连收到的 Intent 它看都不看一眼。
- It is **not** the real statistics service and does not replace its data collection. Disabling `com.oplus.statistics.rom` is what stops the reporting; this stub only stops the "not found" log spam that disabling it causes.
  它**不是**真正的统计服务，也不代替那个统计服务去收集数据。真正停掉上报的是禁用 `com.oplus.statistics.rom` 那一步，这个占位 App 只是把禁用之后冒出来的 "not found" 日志刷屏压下去。

## Install / 怎么装

1. Download `app-debug.apk` from the [Releases](../../releases) page.
   从 [Releases](../../releases) 页面下载 `app-debug.apk`。
2. Tap it on the phone and allow installing from that source. Or: `adb install -r app-debug.apk`.
   在手机上点它，允许从这个来源安装。或者用：`adb install -r app-debug.apk`。
3. Launch it once, then do the two steps below.
   点开它一次，然后做下面两步。

## Usage / 用法

### 1. Allow auto-start / 开自启

Tap **"1. Open auto-start management"** in the app. It opens the ColorOS auto-start list (Settings > Apps > Auto-start / 设置 > 应用 > 自启动). Find **Statistics Stub** there and turn it on.

在 App 里点 **“1. Open auto-start management”**，它会打开 ColorOS 的自启列表（设置 > 应用 > 自启动）。在里面找到 **Statistics Stub**，把它打开。

If the button opens the wrong page, open that list manually: Settings > Apps > Auto-start, or Phone Manager > Privacy permissions > Auto-start management. Note ColorOS may cap the auto-start list at 5 apps — if it is full, turn one off first.

要是按钮跳错页面了，就手动打开那个列表：设置 > 应用 > 自启动，或者手机管家 > 权限隐私 > 自启动管理。注意 ColorOS 的自启列表好像最多只能放 5 个 App，要是已经满了，得先关掉一个不用的，再加它。

### 2. Ignore battery optimizations / 忽略电池优化

Tap **"2. Request ignore battery optimizations"** in the app and confirm the system dialog. If it says the app is already whitelisted, nothing more to do.

在 App 里点 **“2. Request ignore battery optimizations”**，确认系统弹出来的框就行。要是它说已经在白名单里了，那就不用再管了。

### 3. Hide the icon (optional) / 藏图标（可选）

Tap **"3. Hide icon"** in the app, **only after steps 1 and 2 are done**. The launcher icon disappears; the app and its service keep working.

在 App 里点 **“3. Hide icon”**，**只能在第 1、2 步都做完之后再点**。图标会从桌面和应用列表里消失，App 和服务照常工作。

To get the icon back, run (from the phone shell, no `adb shell` prefix):

想把图标叫回来，在手机终端里跑这条（不用加 `adb shell`）：

```
am start -n com.nearme.statistics.rom/.UnhideActivity
```

Or from a PC: `adb shell am start -n com.nearme.statistics.rom/.UnhideActivity`

或者在电脑上跑：`adb shell am start -n com.nearme.statistics.rom/.UnhideActivity`

### Verify it works / 怎么验它管不管用

```
adb shell logcat -c
# wait a few minutes / toggle Wi-Fi once
# 等几分钟，再开关一次 WiFi
adb shell logcat -d | grep -i "nearme.statistics.rom"
```

Both `Unable to start service … not found` and `OplusAppStartupManager: … prevent start` lines should stop appearing. The stub's own service produces no log lines, so a successful call is silent.

`Unable to start service … not found` 和 `OplusAppStartupManager: … prevent start` 这两行应该都不再出现了。这个占位 App 自己的服务不写日志，所以叫成功了就是静悄悄的，什么也没有。

## Uninstall / 怎么卸

Settings > Apps > Statistics Stub > Uninstall. Or:

设置 > 应用 > Statistics Stub > 卸载。或者：

```
adb uninstall com.nearme.statistics.rom
```

Removing it restores the previous behaviour (log spam returns, but so does nothing else — the real statistics package stays disabled unless you re-enable it with `pm enable com.oplus.statistics.rom`).

卸了它就回到以前那个样子（日志刷屏会回来，但别的什么也不会变——真正的统计包还是禁着的，除非您用 `pm enable com.oplus.statistics.rom` 再把它打开）。

## Build it yourself / 自己编译

You need a JDK 17 and the Android SDK (platform `android-34`, build-tools `34.0.0`):

需要 JDK 17 和 Android SDK（platform `android-34`，build-tools `34.0.0`）：

```sh
./build.sh
```

## Caveats / 注意事项

- This is a community workaround, not an official OPPO/OnePlus fix. A system update could change which service name system apps call.
  这只是一个社区的变通办法，不是 OPPO / 一加官方的修复。系统更新之后，系统 App 叫的服务名可能会变。
- The APK is debug-signed. That is fine for a sideloaded stub; do not expect Play Store updates for it.
  这个 APK 是 debug 签名的，侧载一个占位 App 没问题，别指望它能在 Play 商店里更新。
- If you re-enable `com.oplus.statistics.rom`, you do not need this stub any more — uninstall it.
  要是您又把 `com.oplus.statistics.rom` 打开了，就不需要这个占位 App 了，卸掉它就行。
