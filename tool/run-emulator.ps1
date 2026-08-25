# تشغيل محاكي أندرويد لتِنت — بإعداداتٍ لا تُترك للصدفة.
#
# الاستعمال:  pwsh tool\run-emulator.ps1            (الجهاز الافتراضيّ: tint)
#             pwsh tool\run-emulator.ps1 -Avd tint_pro
#
# ‼️ **لماذا سكربتٌ بدل أمرٍ يُكتب يدويّاً؟** لأنّ العَلَمين أدناه ليسا تفضيلاً
#    بل إصلاحان لعطلين رُصدا فعلاً، ونسيانُ أحدهما يُعيد العطل كما هو.

param(
  [string]$Avd = 'tint',
  # إقلاعٌ بارد يتجاهل اللقطة المحفوظة — يُستعمل حين تعلق حالة الجهاز.
  [switch]$ColdBoot
)

$ErrorActionPreference = 'Stop'
$emulator = 'C:\Android\emulator\emulator.exe'
if (-not (Test-Path $emulator)) { throw "لم أجد المحاكي: $emulator" }

$emuArgs = @('-avd', $Avd)

# ── ① الذاكرة ────────────────────────────────────────────────────────────────
# ‼️ **`hw.ramSize` في `config.ini` يُتجاهَل** (قِيس 2026-08-23: الملفّ يقول
#    4096 والجهاز يُقلع بـ2.5 غيغا). والتمرير من سطر الأوامر هو الذي يسري
#    فعلاً — تحقّقنا بـ`/proc/meminfo`: 4013932 kB.
#
#    وأثر نقص الذاكرة ليس بطئاً بل «Process system isn't responding» و
#    «Pixel Launcher isn't responding» — تبدو أعطال تطبيقٍ وهي خنق ذاكرة.
$emuArgs += @('-memory', '4096')

# ── ② مُحلّلات الأسماء ───────────────────────────────────────────────────────
# ‼️ **بلا هذا العَلَم يفشل نصف الاستعلامات — والتطبيق يبدو معطّلاً وهو سليم.**
#
#    المحاكي يأخذ قائمة مُحلّلات ويندوز كما هي. وجهاز التطوير هنا يُعلن ثلاثة:
#      · 192.168.8.1        (IPv4 — الراوتر، يعمل)
#      · fe80::…            (IPv6 محلّيّ الرابط — **لا يُبلَغ من شبكة المحاكي**)
#      · fe80::…            (المِثل)
#    فالاستعلام الذي يقع على أحد عنواني `fe80::` ينتظر حتّى تنتهي مهلته،
#    والذي يقع على الراوتر ينجح — أي فشلٌ متقطّعٌ لا يُشخَّص بسهولة.
#
#    رُصد 2026-08-25: شاشة الدفع قالت «لا توجد وسيلة دفع متاحة حالياً»
#    و«تعذّر جلب طرق التوصيل»، والسجلّ يُظهر في اللحظة نفسها
#    `PROBE_HTTP … ret=204` ناجحاً و`PROBE_DNS … 10023ms FAIL` فاشلاً.
#    وبعد تثبيت المُحلّلات: صفر إخفاقات.
#
#    وعناوين `fe80::` تتغيّر بإعلانات الراوتر، فالعطل يظهر ويختفي بلا سبب
#    ظاهر — ولذلك يُنزع الاختيار من المحاكي بدل انتظار تكرّره.
$emuArgs += @('-dns-server', '8.8.8.8,1.1.1.1')

if ($ColdBoot) { $emuArgs += '-no-snapshot-load' }

Write-Host "تشغيل $Avd …" -ForegroundColor Cyan
Start-Process -FilePath $emulator -ArgumentList $emuArgs -WindowStyle Normal

# ── التحقّق: لا نكتفي بالإطلاق ───────────────────────────────────────────────
# ‼️ **يُقاس ما أُصلح، لا يُفترَض.** الإقلاع وحده لا يعني أنّ الأسماء تُترجَم.
$adb = 'C:\Android\platform-tools\adb.exe'
& $adb wait-for-device
Write-Host 'الجهاز متّصل — بانتظار اكتمال الإقلاع …' -ForegroundColor DarkGray
do {
  Start-Sleep -Seconds 3
  $booted = (& $adb shell getprop sys.boot_completed) -replace '\s', ''
} while ($booted -ne '1')

$mem = (& $adb shell cat /proc/meminfo | Select-Object -First 1)
Write-Host "أقلع. $mem" -ForegroundColor Green
Write-Host 'إن ظهرت «لا توجد وسيلة دفع متاحة» فافحص أوّلاً:' -ForegroundColor DarkGray
Write-Host '  adb logcat -d | Select-String "PROBE_DNS"' -ForegroundColor DarkGray
