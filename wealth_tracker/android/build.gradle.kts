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

// another_telephony's own build.gradle pins Kotlin to JVM 1.8 but leaves
// Java at AGP's default of 11 — a mismatch within the plugin itself that
// Gradle treats as a hard error ("Inconsistent JVM Target Compatibility
// Between Java and Kotlin Tasks").
//
// This is scoped to that ONE plugin, deliberately not applied to every
// subproject: an earlier, broader version of this fix forced every
// plugin's Kotlin tasks to JVM 17, which broke home_widget — it was
// building fine before (its own build.gradle pins Java to 1.8, and
// evaluates *after* plugin application, so a `pluginManager.withPlugin`
// hook forcing its Java side to 17 gets silently overwritten by its own
// later-executing script; only the always-lazy KotlinCompile task
// override actually stuck, creating a NEW mismatch: Java 1.8 vs Kotlin
// 17). Every other plugin already has consistent Java/Kotlin targets on
// its own and must be left alone.
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
//   has been finalized". `:app` doesn't need this fix anyway.
subprojects {
    if (project.name == "another_telephony") {
        pluginManager.withPlugin("com.android.library") {
            extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
