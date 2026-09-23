allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Pins the native Firebase Android SDK BoM version for every FlutterFire
// plugin (firebase_core, firebase_auth, cloud_firestore, ...) — each plugin's
// own build.gradle reads this via getRootProjectExtOrDefaultProperty and
// otherwise falls back to its own bundled (older) default, independently of
// the BoM pinned in app/build.gradle.kts. Without this, plugin modules and
// the app module resolve different, out-of-sync Firebase SDK versions,
// causing runtime NoSuchMethodErrors like FirebaseOptions.getRecaptchaSiteKey.
// Keep this in sync with the firebase-bom version in app/build.gradle.kts.
rootProject.extra["FlutterFire"] = mapOf("FirebaseSDKVersion" to "34.19.0")

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
