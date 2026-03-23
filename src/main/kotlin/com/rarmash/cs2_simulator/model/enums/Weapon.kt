package com.rarmash.cs2_simulator.model.enums

enum class Weapon(val weaponTitle: String) {
    // Pistols
    CZ75_AUTO ("CZ75-Auto"),
    DESERT_EAGLE ("Desert Eagle"),
    DUAL_BERETTAS ("Dual Berettas"),
    FIVE_SEVEN ("Five-SeveN"),
    GLOCK_18 ("Glock-18"),
    P2000 ("P2000"),
    P250 ("P250"),
    R8_REVOLVER ("R8 Revolver"),
    TEC_9 ("Tec-9"),
    USP_S ("USP-S"),
    // SMGs
    MAC_10 ("MAC-10"),
    MP5_SD ("MP5-SD"),
    MP7 ("MP7"),
    MP9 ("MP9"),
    PP_BIZON ("PP-Bizon"),
    P90 ("P90"),
    UMP_45 ("UMP-45"),
    // Shotguns
    MAG_7 ("MAG-7"),
    NOVA ("Nova"),
    SAWED_OFF ("Sawed-Off"),
    XM1014 ("XM1014"),
    // Machine guns
    M249 ("M249"),
    NEGEV ("Negev"),
    // Rifles
    FAMAS ("FAMAS"),
    GALIL_AR ("Galil AR"),
    M4A4 ("M4A4"),
    M4A1_S ("M4A1-S"),
    AK_47 ("AK-47"),
    AUG ("AUG"),
    SG_553 ("SG 553"),
    // Sniper rifles
    SSG_08 ("SSG 08"),
    AWP ("AWP"),
    SCAR_20 ("SCAR-20"),
    G3SG1 ("G3SG1"),
    // Equipment
    ZEUS_X27 ("Zeus x27"),
    // Knife
    KNIFE ("Knife"),
    // Gloves
    GLOVES ("Gloves");

    companion object {
        private val map = entries.associateBy { it.weaponTitle.lowercase() }

        @JvmStatic
        fun fromString(weaponTitle: String): Weapon {
            return map[weaponTitle.lowercase()]
                ?: throw IllegalArgumentException("No enum constant for weapon title: $weaponTitle")
        }
    }

    override fun toString(): String = weaponTitle
}