package com.rarmash.cs2_simulator.model.enums

enum class Exterior(
    val exteriorTitle: String,
    val min: Double,
    val max: Double
) {
    FACTORY_NEW("Factory New", 0.00, 0.07),
    MINIMAL_WEAR("Minimal Wear", 0.07, 0.15),
    FIELD_TESTED("Field-Tested", 0.15, 0.37),
    WELL_WORN("Well-Worn", 0.37, 0.44),
    BATTLE_SCARRED("Battle-Scarred", 0.44, 1.00);

    companion object {

        @JvmStatic
        fun fromFloat(value: Double): Exterior {
            return entries.firstOrNull { value in it.min..it.max }
                ?: throw IllegalArgumentException("Float value out of range: $value")
        }
    }

    override fun toString(): String = exteriorTitle
}