// Ensure plugin can pick up site-packages from env or repo folder
import java.io.File

val spEnv: String? = System.getenv("SERIOUS_PYTHON_SITE_PACKAGES")
if (!spEnv.isNullOrBlank()) {
    extra["SERIOUS_PYTHON_SITE_PACKAGES"] = spEnv
} else {
    val spDir = rootProject.file("site-packages")
    if (spDir.exists() && spDir.isDirectory) {
        extra["SERIOUS_PYTHON_SITE_PACKAGES"] = spDir.absolutePath
    }
}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
