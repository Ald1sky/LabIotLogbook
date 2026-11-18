

import com.android.build.gradle.BaseExtension
import org.gradle.api.Project
import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

import com.android.build.gradle.LibraryExtension
57a3c58 (Update fitur)

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
    val newSubprojectBuildDir: Directory =
        newBuildDir.dir(project.name)

    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Pastikan seluruh modul Android menggunakan compileSdk 36
    afterEvaluate {
        extensions.findByType(BaseExtension::class.java)?.let {
            it.compileSdkVersion(36)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Samakan compileSdk modul Coinbase Wallet SDK dengan API 36.
subprojects {
    if (name == "coinbase_wallet_sdk") {
        afterEvaluate {
            extensions.configure<LibraryExtension> {
                compileSdk = 36
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
