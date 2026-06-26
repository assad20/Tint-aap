# Tabby mobile setup for Tint Flutter app

## Dart defines

Run the app with:

```bash
flutter run \
  --dart-define=TINT_API_BASE_URL=http://10.0.2.2:3000/api \
  --dart-define=TINT_TABBY_PUBLIC_KEY=pk_live_or_test_xxx \
  --dart-define=TINT_TABBY_MERCHANT_CODE=ksa_code \
  --dart-define=TINT_TABBY_LANG=ar
```

## Android permissions

Add the following to `android/app/src/main/AndroidManifest.xml` once the native folders are generated:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.VIDEO_CAPTURE" />
<uses-permission android:name="android.permission.AUDIO_CAPTURE" />
```

## iOS permissions

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This allows Tabby to take a photo of an ID</string>
<key>NSMicrophoneUsageDescription</key>
<string>This allows Tabby to perform a live check during a KYC process</string>
```

Update `ios/Podfile` post_install with:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
      ]
    end
  end
end
```
