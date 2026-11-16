rootProject.name = "max-patches"

pluginManagement {
    repositories {
        // Maven Central first: the plugin portal's artifact CDN is refused outright by some
        // networks, and everything this build needs is published to Central as well.
        mavenCentral()
        gradlePluginPortal()
        google()
        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/MorpheApp/registry")
            credentials {
                username = providers.gradleProperty("gpr.user").getOrElse(System.getenv("GITHUB_ACTOR"))
                password = providers.gradleProperty("gpr.key").getOrElse(System.getenv("GITHUB_TOKEN"))
            }
        }
    }
}

plugins {
    // The patch Gradle plugin is published only to the Morphe registry, so this build needs a
    // token with read:packages. The version follows the tree the collection was imported from;
    // 2.1.0 is not published there and resolves to nothing, which reads as "plugin not found".
    // Vendoring or replacing the plugin is tracked in docs/REGISTRY_TOKEN.md.
    id("app.morphe.patches") version "2.1.1"
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

settings {
    extensions {
        defaultNamespace = "app.morphe.extension"
        proguardFiles(rootProject.projectDir.resolve("extensions/proguard-rules.pro").toString())
    }
}

include(":patches:stub")
