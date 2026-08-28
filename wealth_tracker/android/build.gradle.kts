allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

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

// Some plugins (another_telephony pins Kotlin to JVM 1.8 but leaves Java at
// AGP's default of 11) declare Java and Kotlin JVM targets that disagree
// with each other, which Gradle now treats as a hard error
// ("Inconsistent JVM Target Compatibility Between Java and Kotlin Tasks").
// Force every third-party plugin module (all "com.android.library",
// never ":app" itself) to the same JVM 17 target ":app"'s own
// build.gradle.kts already sets for itself, overriding whatever a
// plugin's own build.gradle set.
//
// Two things this deliberately avoids, both hit while getting this
// working:
// - `afterEvaluate`: the `evaluationDependsOn` block above makes Gradle
//   evaluate `:app` before a later `subprojects { afterEvaluate {...} }`
//   block would run, and calling `afterEvaluate` on an already-evaluated
//   project is a hard error. `pluginManager.withPlugin` fires as soon as
//   the plugin is applied instead, which is safe regardless of
//   evaluation order.
// - Touching `:app` here at all: by the time this block's
//   `pluginManager.withPlugin` callback would fire for `:app`, AGP has
//   already finalized its `sourceCompatibility` (it's set correctly in
//   :app's own build.gradle.kts, evaluated earlier via
//   evaluationDependsOn) — setting it again throws "sourceCompatibility
//   has been finalized". `:app` doesn't need this fix anyway, only the
//   plugin modules do.
subprojects {
    if (project.path != ":app") {
        pluginManager.withPlugin("com.android.library") {
            extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
