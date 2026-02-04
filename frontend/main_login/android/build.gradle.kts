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

// Force Java 1.8, Kotlin 1.8, and SDK 34 for all Android subprojects (avoids requiring SDK 35)
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        android.javaClass.methods.find { it.name == "setCompileSdkVersion" && it.parameterCount == 1 }?.invoke(android, 34)
        val defaultConfig = android.javaClass.methods.find { it.name == "getDefaultConfig" }?.invoke(android)
        defaultConfig?.javaClass?.methods?.find { it.name == "setTargetSdkVersion" && it.parameterCount == 1 }?.invoke(defaultConfig, 34)
        val compileOptions = android.javaClass.methods.find { it.name == "getCompileOptions" }?.invoke(android) ?: return@afterEvaluate
        compileOptions.javaClass.methods
            .filter { it.name in listOf("setSourceCompatibility", "setTargetCompatibility") && it.parameterCount == 1 }
            .forEach { it.invoke(compileOptions, JavaVersion.VERSION_1_8) }
    }
}
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
        compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
