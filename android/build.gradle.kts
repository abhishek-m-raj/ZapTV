allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureProject = {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            val android = extensions.findByName("android")
            if (android != null) {
                try {
                    val getCompileSdk = android.javaClass.getMethod("getCompileSdk")
                    val compileSdk = getCompileSdk.invoke(android) as? Int
                    if (compileSdk == null || compileSdk < 34) {
                        val setCompileSdk = android.javaClass.getMethod("setCompileSdk", java.lang.Integer::class.java)
                        setCompileSdk.invoke(android, 34)
                    }
                } catch (e: Exception) {
                    try {
                        val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", java.lang.Integer::class.java)
                        setCompileSdkVersion.invoke(android, 34)
                    } catch (e2: Exception) {
                        // Ignore
                    }
                }

                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val namespace = getNamespace.invoke(android) as? String
                    if (namespace.isNullOrEmpty()) {
                        val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                        val safePackageName = project.name.replace("-", "_").replace(".", "_")
                        setNamespace.invoke(android, "com.zaptv.$safePackageName")
                    }
                } catch (e: Exception) {
                    // Ignore
                }

                try {
                    val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                    val javaVersion11 = org.gradle.api.JavaVersion.VERSION_11
                    compileOptions.javaClass.getMethod("setSourceCompatibility", Object::class.java).invoke(compileOptions, javaVersion11)
                    compileOptions.javaClass.getMethod("setTargetCompatibility", Object::class.java).invoke(compileOptions, javaVersion11)
                } catch (e: Exception) {
                    // Ignore
                }
            }

            // Fix package attribute in AndroidManifest.xml for older plugins
            val manifestFile = project.file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                try {
                    var content = manifestFile.readText()
                    if (content.contains("package=")) {
                        content = content.replace(Regex("""package\s*=\s*"[^"]*""""), "")
                        manifestFile.writeText(content)
                    }
                } catch (e: Exception) {
                    // Ignore
                }
            }
        }
    }

    if (project.state.executed) {
        configureProject()
    } else {
        project.afterEvaluate { configureProject() }
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions.jvmTarget = "11"
    }
}





tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

