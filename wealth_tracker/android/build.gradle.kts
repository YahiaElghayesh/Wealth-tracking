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
// Force every subproject — including third-party plugin modules — to the
// same JVM 17 target the app itself already uses, overriding whatever a
// plugin's own build.gradle set.
//
// Deliberately not using `afterEvaluate` here: the `evaluationDependsOn`
// block above makes Gradle evaluate `:app` before this block would run,
// and calling `afterEvaluate` on an already-evaluated project is a hard
// error ("Cannot run Project.afterEvaluate(Action) when the project is
// already evaluated"). `pluginManager.withPlugin` fires as soon as the
// Android plugin is applied, which is always safe regardless of
// evaluation order; `tasks.withType(...).configureEach` is lazy and has
// the same property.
subprojects {
    val forceJvm17 = {
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        Unit
    }
    pluginManager.withPlugin("com.android.application") { forceJvm17() }
    pluginManager.withPlugin("com.android.library") { forceJvm17() }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
