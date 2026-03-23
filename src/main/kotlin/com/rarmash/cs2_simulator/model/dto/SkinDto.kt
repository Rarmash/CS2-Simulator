package com.rarmash.cs2_simulator.model.dto

data class SkinDto(
    val id: String,
    val name: String,
    val skinImage: String,
    val floatTop: Double,
    val floatBottom: Double,
    val isSouvenir: Boolean,
    val rarity: String,
    val weaponType: String,
    val itemKind: String,
    val itemId: String
)