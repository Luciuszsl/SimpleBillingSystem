# One-click Android build script for SimpleBillingSystem
# Usage: Open PowerShell in this repo and run: .\build_android.ps1

# === User configuration ===
$qtRoot = "C:\Qt\6.5.3"
$androidAbi = "armeabi-v7a"
$androidPlatform = "android-33"    # Use compile SDK 33 to avoid Android 36 aapt2 issue (still targets API 27 NDK)
$ndkRoot = "C:\Users\inku9\AppData\Local\Android\Sdk\ndk\25.1.8937393"
$sdkRoot = "C:\Users\inku9\AppData\Local\Android\Sdk"
$jdk17Root = "C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot"  # adjust to your JDK 17 path, or leave as default
$buildDir = "build\android_armv7"

# === Tools ===
$cmakeExe = "C:\Qt\Tools\CMake_64\bin\cmake.exe"
$ninjaExe = "C:\Qt\Tools\Ninja\ninja.exe"

# Fix JDK17 detection: prefer manual path, then JAVA_HOME, then Program Files\Java\jdk-17*
if (-not (Test-Path $jdk17Root)) {
    if ($env:JAVA_HOME -and (Test-Path $env:JAVA_HOME)) {
        $jdk17Root = $env:JAVA_HOME
    } else {
        $jdkRootCandidates = Get-ChildItem "C:\Program Files\Java" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "jdk-17*" }
        if ($jdkRootCandidates) {
            $jdk17Root = $jdkRootCandidates[0].FullName
        }
    }
}

if (-not (Test-Path $jdk17Root)) {
    Write-Error "Java 17 path not found. Please install JDK 17 and set JDK17 path in this script or JAVA_HOME."
    exit 1
}

if (-not (Test-Path $cmakeExe)) { Write-Error "CMake not found at $cmakeExe"; exit 1 }
if (-not (Test-Path $ninjaExe)) { Write-Error "Ninja not found at $ninjaExe"; exit 1 }
if (-not (Test-Path $ndkRoot)) { Write-Error "NDK root not found at $ndkRoot"; exit 1 }
if (-not (Test-Path $sdkRoot)) { Write-Error "Android SDK root not found at $sdkRoot"; exit 1 }

$env:ANDROID_SDK_ROOT = $sdkRoot
$env:ANDROID_NDK_ROOT = $ndkRoot
$env:JAVA_HOME = $jdk17Root
$env:Path = "$env:JAVA_HOME\bin;$env:Path"

$qtAndroidLibs = "${qtRoot}\android_armv7\lib\cmake"
$qt6Dir = "${qtAndroidLibs}\Qt6"

Write-Host "=== Building SimpleBillingSystem for Android ($androidAbi, $androidPlatform) ==="
Write-Host "CMake: $cmakeExe"
Write-Host "Ninja: $ninjaExe"
Write-Host "Qt6_DIR: $qt6Dir"
Write-Host "Android SDK: $env:ANDROID_SDK_ROOT"
Write-Host "Android NDK: $env:ANDROID_NDK_ROOT"
$javaVersionInfo = & "$env:JAVA_HOME\bin\java.exe" -version 2>&1
Write-Host "Java: $javaVersionInfo"
if ($javaVersionInfo -notmatch '17\.[0-9]+\.[0-9]+') {
    Write-Error "Java version is not 17. Androiddeployqt with this Qt version requires JDK 17. Install JDK 17 and update $jdk17Root."
    exit 1
}

# Configure
& $cmakeExe -S . -B $buildDir -G Ninja `
    -DCMAKE_MAKE_PROGRAM="$ninjaExe" `
    -DCMAKE_TOOLCHAIN_FILE="$ndkRoot\build\cmake\android.toolchain.cmake" `
    -DANDROID_ABI="$androidAbi" `
    -DANDROID_PLATFORM="$androidPlatform" `
    -DANDROID_COMPILE_SDK_VERSION=33 `
    -DANDROID_SDK_ROOT="$env:ANDROID_SDK_ROOT" `
    -DQt6_DIR="$qt6Dir" `
    -DCMAKE_PREFIX_PATH="$qtAndroidLibs" `
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=NEVER `
    -DCMAKE_BUILD_TYPE=Release

if ($LASTEXITCODE -ne 0) { Write-Error "CMake configure failed."; exit 1 }

# Fix Android compile SDK and build-tools for this Qt version.
$gradleProps = "$buildDir\android-build\gradle.properties"
if (Test-Path $gradleProps) {
    (Get-Content $gradleProps) -replace 'androidCompileSdkVersion=android-36', 'androidCompileSdkVersion=android-33' `
                                -replace 'androidBuildToolsVersion=36.1.0', 'androidBuildToolsVersion=33.0.0' | Set-Content $gradleProps
    Write-Host "Updated gradle.properties compile sdk/build-tools to 33"
}

# Build
& $ninjaExe -C $buildDir appLZ_SBS
if ($LASTEXITCODE -ne 0) { Write-Error "Ninja build failed."; exit 1 }

# Copy native libs into android-build libs folder (androiddeployqt expects this)
$abi = "armeabi-v7a"
$nativeLib = "$buildDir\libappLZ_SBS_${abi}.so"
$destLibDir = "$buildDir\android-build\libs\$abi"
New-Item -ItemType Directory -Force -Path $destLibDir | Out-Null
Copy-Item -Force $nativeLib $destLibDir

# Ensure products.json is in android assets for deployment
$assetDir = "$buildDir\android-build\assets"
New-Item -ItemType Directory -Force -Path $assetDir | Out-Null
Copy-Item -Force "products.json" "$assetDir\products.json"

# Deploy and package APK using androiddeployqt with explicit Android platform
$deploySettings = "$buildDir\android-appLZ_SBS-deployment-settings.json"
$outApk = "$buildDir\android-build\appLZ_SBS.apk"
& "$qtRoot\mingw_64\bin\androiddeployqt" --input $deploySettings --output "$buildDir\android-build" --android-platform android-33 --release --apk $outApk
if ($LASTEXITCODE -ne 0) { Write-Error "androiddeployqt packaging failed."; exit 1 }

# Sign and install APK
$unsignedApk = "$buildDir\android-build\build\outputs\apk\release\android-build-release-unsigned.apk"
$signedApk = "$buildDir\android-build\build\outputs\apk\release\android-build-release-signed.apk"
$debugKeystore = "$env:USERPROFILE\.android\debug.keystore"
if (-not (Test-Path $debugKeystore)) {
    Write-Host "Generating debug keystore at $debugKeystore"
    & "$jdk17Root\bin\keytool.exe" -genkeypair -alias androiddebugkey -keypass android -keystore $debugKeystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -keyalg RSA -validity 10000 | Out-Null
}

# Align, sign, install
$zipalignPath = "C:\Users\inku9\AppData\Local\Android\Sdk\build-tools\33.0.3\zipalign.exe"
if (-not (Test-Path $zipalignPath)) { Write-Error "zipalign not found at $zipalignPath"; exit 1 }
& $zipalignPath -v -p 4 $unsignedApk $signedApk
& "$jdk17Root\bin\jarsigner.exe" -sigalg SHA256withRSA -digestalg SHA-256 -keystore $debugKeystore -storepass android -keypass android $signedApk androiddebugkey

$adbPath = "C:\Users\inku9\AppData\Local\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) { Write-Error "adb not found at $adbPath"; exit 1 }
& $adbPath devices
& $adbPath install -r $signedApk
if ($LASTEXITCODE -ne 0) { Write-Error "APK install failed."; exit 1 }

Write-Host "=== Build, sign, and install completed! APK installed: $signedApk ==="