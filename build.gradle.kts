plugins {
    id("java")
}

group = "com.rarmash.cs2_simulator"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    testImplementation(platform("org.junit:junit-bom:5.10.0"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    implementation("com.google.cloud:google-cloud-firestore:3.0.0")
}

tasks.test {
    useJUnitPlatform()
}