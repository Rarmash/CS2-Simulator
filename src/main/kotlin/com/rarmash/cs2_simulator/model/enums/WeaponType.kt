package com.rarmash.cs2_simulator.model.enums

enum class WeaponType(val weaponType: String) {
    PISTOL("Pistol"),
    SMG("SMG"),
    SNIPER_RIFLE("Sniper Rifle"),
    RIFLE("Rifle"),
    KNIFE("Knife"),
    SHOTGUN("Shotgun"),
    MACHINE_GUN("Machine Gun"),
    GLOVES("Gloves"),
    EQUIPMENT("Equipment");

    companion object {
        private val map = entries.associateBy { it.weaponType.lowercase() }

        @JvmStatic
        fun fromString(weaponTypeString: String): WeaponType {
            return map[weaponTypeString.lowercase()]
                ?: throw IllegalArgumentException("No enum constant for weapon type title: $weaponTypeString")
        }
    }

    override fun toString(): String = weaponType
}