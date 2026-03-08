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

subprojects {
    val forceSdk = { p: Project ->
        if (p.hasProperty("android")) {
            val android = p.extensions.findByName("android")
            if (android != null) {
                val methods = android.javaClass.methods
                for (m in methods) {
                    if (m.name == "compileSdkVersion" && m.parameterTypes.size == 1) {
                        val typeName = m.parameterTypes[0].name
                        try {
                            if (typeName == "int" || typeName == "java.lang.Integer") {
                                m.invoke(android, 36)
                            } else if (typeName == "java.lang.String") {
                                m.invoke(android, "android-36")
                            }
                        } catch (e: Exception) {}
                    }
                }
                
                try {
                    val defaultConfig = android.javaClass.getMethod("getDefaultConfig").invoke(android)
                    if (defaultConfig != null) {
                        val dcMethods = defaultConfig.javaClass.methods
                        for (m in dcMethods) {
                            if (m.name == "targetSdkVersion" && m.parameterTypes.size == 1) {
                                val typeName = m.parameterTypes[0].name
                                try {
                                    if (typeName == "int" || typeName == "java.lang.Integer") {
                                        m.invoke(defaultConfig, 36)
                                    } else if (typeName == "java.lang.String") {
                                        m.invoke(defaultConfig, "android-36")
                                    }
                                } catch (e: Exception) {}
                            }
                        }
                    }
                } catch (e: Exception) {}
            }
        }
    }

    if (project.state.executed) {
        forceSdk(project)
    } else {
        project.afterEvaluate {
            forceSdk(this)
        }
    }
}

// Disable lint tasks for all projects to avoid the SDK 36 deserialization crash
subprojects {
    val disableLint = { p: Project ->
        p.tasks.configureEach {
            if (name.contains("lintVital") || name.contains("lintAnalyze")) {
                enabled = false
            }
        }
    }

    if (project.state.executed) {
        disableLint(project)
    } else {
        project.afterEvaluate {
            disableLint(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
