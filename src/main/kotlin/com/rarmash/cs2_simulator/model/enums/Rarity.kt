package com.rarmash.cs2_simulator.model.enums

enum class Rarity(val rarityTitle: String) {
    CONTRABAND("Contraband"),
    EXTRAORDINARY("Extraordinary"),
    COVERT("Covert"),
    CLASSIFIED("Classified"),
    RESTRICTED("Restricted"),
    MIL_SPEC("Mil-Spec Grade"),
    INDUSTRIAL("Industrial Grade"),
    CONSUMER("Consumer Grade");

    companion object {
        private val map = entries.associateBy { it.rarityTitle.lowercase() }

        @JvmStatic
        fun fromString(rarityTitle: String): Rarity {
            return map[rarityTitle.lowercase()]
                ?: throw IllegalArgumentException("No enum constant for rarity title: $rarityTitle")
        }
    }

    override fun toString(): String = rarityTitle
}