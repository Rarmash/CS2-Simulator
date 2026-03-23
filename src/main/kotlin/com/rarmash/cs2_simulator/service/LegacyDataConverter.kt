package com.rarmash.cs2_simulator.service

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.registerKotlinModule
import com.google.auth.oauth2.GoogleCredentials
import com.google.cloud.storage.BlobId
import com.google.cloud.storage.Storage
import com.google.cloud.storage.StorageOptions
import com.rarmash.cs2_simulator.model.dto.CaseContentDto
import com.rarmash.cs2_simulator.model.dto.CaseDto
import com.rarmash.cs2_simulator.model.dto.SkinDto
import java.io.File
import java.io.InputStream

@JsonIgnoreProperties(ignoreUnknown = true)
data class LegacySkinDto(
    val id: String,
    val name: String,
    val skinImage: String,
    val float_top: Double,
    val float_bottom: Double,
    val isSouvenir: Boolean,
    val rarity: String,
    val weaponType: String,
    val weapon: String? = null,
    val knife: String? = null,
    val gloves: String? = null
)

@JsonIgnoreProperties(ignoreUnknown = true)
data class LegacyCaseDto(
    val id: String,
    val name: String,
    val caseImage: String,
    val skins: List<String>
)

class LegacyDataConverter(
    private val inputDir: File = File("export"),
    private val outputDataDir: File = File("src/main/resources/data"),
    private val outputAssetsDir: File = File("src/main/resources/assets"),
    private val bucketName: String = "cs2-simulator.appspot.com"
) {
    private val mapper = jacksonObjectMapper().registerKotlinModule()
    private val failedDownloads = mutableListOf<String>()

    fun convertAll(downloadImages: Boolean = true) {
        failedDownloads.clear()

        val legacySkins = readList<LegacySkinDto>(File(inputDir, "skins.json"))
            .sortedWith(compareByNumericId { it.id })

        val legacyCases = readList<LegacyCaseDto>(File(inputDir, "cases.json"))
            .sortedWith(compareByNumericId { it.id })

        val newSkins = legacySkins
            .map { convertSkin(it) }
            .sortedWith(compareByNumericId { it.id })

        val newCases = legacyCases
            .map { convertCase(it) }
            .sortedWith(compareByNumericId { it.id })

        val caseContents = legacyCases
            .map { convertCaseContents(it) }
            .sortedWith(compareByNumericId { it.caseId })

        outputDataDir.mkdirs()
        writeJson(File(outputDataDir, "skins.json"), newSkins)
        writeJson(File(outputDataDir, "cases.json"), newCases)
        writeJson(File(outputDataDir, "case_contents.json"), caseContents)

        if (downloadImages) {
            downloadAllImagesAuthorized(legacySkins, legacyCases)
        }

        writeFailedDownloadsReport()

        println("Conversion finished.")
        println("Skins: ${newSkins.size}")
        println("Cases: ${newCases.size}")
        println("Case contents: ${caseContents.size}")
        println("Failed downloads: ${failedDownloads.size}")
    }

    private fun convertSkin(old: LegacySkinDto): SkinDto {
        val mappedWeaponType = mapWeaponType(old.weaponType)
        val mappedRarity = mapRarity(old.rarity)

        val itemKind: String
        val itemId: String

        when {
            old.weapon != null -> {
                itemKind = "WEAPON"
                itemId = mapWeapon(old.weapon)
            }
            old.knife != null -> {
                itemKind = "KNIFE"
                itemId = mapKnife(old.knife)
            }
            old.gloves != null -> {
                itemKind = "GLOVES"
                itemId = mapGloves(old.gloves)
            }
            else -> {
                throw IllegalArgumentException("Skin ${old.id} has no weapon/knife/gloves field")
            }
        }

        return SkinDto(
            id = old.id,
            name = old.name,
            skinImage = "assets/skins/${old.id}.png",
            floatTop = old.float_top,
            floatBottom = old.float_bottom,
            isSouvenir = old.isSouvenir,
            rarity = mappedRarity,
            weaponType = mappedWeaponType,
            itemKind = itemKind,
            itemId = itemId
        )
    }

    private fun convertCase(old: LegacyCaseDto): CaseDto {
        return CaseDto(
            id = old.id,
            name = old.name,
            caseImage = "assets/cases/${old.id}.png"
        )
    }

    private fun convertCaseContents(old: LegacyCaseDto): CaseContentDto {
        return CaseContentDto(
            caseId = old.id,
            skinIds = old.skins.sortedWith(compareByNumericString())
        )
    }

    private fun downloadAllImagesAuthorized(
        legacySkins: List<LegacySkinDto>,
        legacyCases: List<LegacyCaseDto>
    ) {
        val storage = buildAuthorizedStorage()

        val skinsDir = File(outputAssetsDir, "skins").apply { mkdirs() }
        val casesDir = File(outputAssetsDir, "cases").apply { mkdirs() }

        println("Downloading skin images via authorized GCS...")
        legacySkins.forEach { skin ->
            downloadBlobIfMissing(
                storage = storage,
                objectName = "skins/${skin.id}.png",
                target = File(skinsDir, "${skin.id}.png")
            )
        }

        println("Downloading case images via authorized GCS...")
        legacyCases.forEach { caseDto ->
            downloadBlobIfMissing(
                storage = storage,
                objectName = "cases/${caseDto.id}.png",
                target = File(casesDir, "${caseDto.id}.png")
            )
        }
    }

    private fun buildAuthorizedStorage(): Storage {
        val credentialsStream: InputStream =
            javaClass.classLoader.getResourceAsStream("firebaseConfig.json")
                ?: throw IllegalArgumentException("firebaseConfig.json not found in resources")

        val credentials = credentialsStream.use { GoogleCredentials.fromStream(it) }

        return StorageOptions.newBuilder()
            .setCredentials(credentials)
            .build()
            .service
    }

    private fun downloadBlobIfMissing(
        storage: Storage,
        objectName: String,
        target: File
    ) {
        if (target.exists()) return

        try {
            val blob = storage.get(BlobId.of(bucketName, objectName))
            if (blob == null || !blob.exists()) {
                val msg = "Missing blob: $objectName"
                println(msg)
                failedDownloads.add(msg)
                return
            }

            target.parentFile?.mkdirs()
            blob.downloadTo(target.toPath())
            println("Downloaded: ${target.path}")
        } catch (e: Exception) {
            val msg = "Failed authorized download $objectName -> ${target.path}: ${e.message}"
            println(msg)
            failedDownloads.add(msg)
        }
    }

    private fun writeFailedDownloadsReport() {
        val reportFile = File(outputDataDir, "failed_downloads.txt")
        reportFile.parentFile?.mkdirs()

        if (failedDownloads.isEmpty()) {
            reportFile.writeText("No failed downloads.")
        } else {
            reportFile.writeText(failedDownloads.joinToString(System.lineSeparator()))
        }

        println("Failed downloads report saved to: ${reportFile.absolutePath}")
    }

    private inline fun <reified T> readList(file: File): List<T> {
        if (!file.exists()) {
            throw IllegalArgumentException("Input file not found: ${file.absolutePath}")
        }
        return mapper.readValue(file, object : TypeReference<List<T>>() {})
    }

    private fun writeJson(file: File, value: Any) {
        file.parentFile?.mkdirs()
        mapper.writerWithDefaultPrettyPrinter().writeValue(file, value)
    }

    private fun compareByNumericString(): Comparator<String> =
        compareBy<String> { it.toIntOrNull() ?: Int.MAX_VALUE }
            .thenBy { it }

    private fun <T> compareByNumericId(idSelector: (T) -> String): Comparator<T> =
        compareBy<T> { idSelector(it).toIntOrNull() ?: Int.MAX_VALUE }
            .thenBy { idSelector(it) }

    private fun mapRarity(value: String): String = when (value.trim()) {
        "Contraband" -> "CONTRABAND"
        "Extraordinary" -> "EXTRAORDINARY"
        "Covert" -> "COVERT"
        "Classified" -> "CLASSIFIED"
        "Restricted" -> "RESTRICTED"
        "Mil-Spec Grade" -> "MIL_SPEC"
        "Industrial Grade" -> "INDUSTRIAL"
        "Consumer Grade" -> "CONSUMER"
        else -> throw IllegalArgumentException("Unknown rarity: $value")
    }

    private fun mapWeaponType(value: String): String = when (value.trim()) {
        "Pistol" -> "PISTOL"
        "SMG" -> "SMG"
        "Sniper Rifle" -> "SNIPER_RIFLE"
        "Rifle" -> "RIFLE"
        "Knife" -> "KNIFE"
        "Shotgun" -> "SHOTGUN"
        "Machine Gun" -> "MACHINE_GUN"
        "Gloves" -> "GLOVES"
        "Equipment" -> "EQUIPMENT"
        else -> throw IllegalArgumentException("Unknown weaponType: $value")
    }

    private fun mapWeapon(value: String): String = when (value.trim()) {
        "CZ75-Auto" -> "CZ75_AUTO"
        "Desert Eagle" -> "DESERT_EAGLE"
        "Dual Berettas" -> "DUAL_BERETTAS"
        "Five-SeveN" -> "FIVE_SEVEN"
        "Glock-18" -> "GLOCK_18"
        "P2000" -> "P2000"
        "P250" -> "P250"
        "R8 Revolver" -> "R8_REVOLVER"
        "Tec-9" -> "TEC_9"
        "USP-S" -> "USP_S"
        "MAC-10" -> "MAC_10"
        "MP5-SD" -> "MP5_SD"
        "MP7" -> "MP7"
        "MP9" -> "MP9"
        "PP-Bizon" -> "PP_BIZON"
        "P90" -> "P90"
        "UMP-45" -> "UMP_45"
        "MAG-7" -> "MAG_7"
        "Nova" -> "NOVA"
        "Sawed-Off" -> "SAWED_OFF"
        "XM1014" -> "XM1014"
        "M249" -> "M249"
        "Negev" -> "NEGEV"
        "FAMAS" -> "FAMAS"
        "Galil AR" -> "GALIL_AR"
        "M4A4" -> "M4A4"
        "M4A1-S" -> "M4A1_S"
        "AK-47" -> "AK_47"
        "AUG" -> "AUG"
        "SG 553" -> "SG_553"
        "SSG 08" -> "SSG_08"
        "AWP" -> "AWP"
        "SCAR-20" -> "SCAR_20"
        "G3SG1" -> "G3SG1"
        "Zeus x27" -> "ZEUS_X27"
        "Knife" -> "KNIFE"
        "Gloves" -> "GLOVES"
        else -> throw IllegalArgumentException("Unknown weapon: $value")
    }

    private fun mapKnife(value: String): String = when (value.trim()) {
        "Bayonet" -> "BAYONET"
        "Butterfly Knife" -> "BUTTERFLY"
        "Falchion Knife" -> "FALCHION"
        "Flip Knife" -> "FLIP"
        "Gut Knife" -> "GUT"
        "Huntsman Knife" -> "HUNTSMAN"
        "Karambit" -> "KARAMBIT"
        "M9 Bayonet" -> "M9_BAYONET"
        "Shadow Daggers" -> "SHADOW_DAGGERS"
        "Navaja Knife" -> "NAVAJA"
        "Stiletto Knife" -> "STILETTO"
        "Talon Knife" -> "TALON"
        "Ursus Knife" -> "URSUS"
        "Bowie Knife" -> "BOWIE"
        "Skeleton Knife" -> "SKELETON"
        "Paracord Knife" -> "PARACORD"
        "Survival Knife" -> "SURVIVAL"
        "Nomad Knife" -> "NOMAD"
        "Classic Knife" -> "CLASSIC"
        "Kukri Knife" -> "KUKRI"
        else -> throw IllegalArgumentException("Unknown knife: $value")
    }

    private fun mapGloves(value: String): String = when (value.trim()) {
        "Bloodhound Gloves" -> "BLOODHOUND"
        "Broken Fang Gloves" -> "BROKEN_FANG"
        "Driver Gloves" -> "DRIVER"
        "Hand Wraps" -> "HAND_WRAPS"
        "Hydra Gloves" -> "HYDRA"
        "Moto Gloves" -> "MOTO"
        "Specialist Gloves" -> "SPECIALIST"
        "Sport Gloves" -> "SPORT"
        else -> throw IllegalArgumentException("Unknown gloves: $value")
    }
}