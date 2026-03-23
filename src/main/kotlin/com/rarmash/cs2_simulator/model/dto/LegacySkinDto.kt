package com.rarmash.cs2_simulator.model.dto

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