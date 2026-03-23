package com.rarmash.cs2_simulator.service

import com.rarmash.cs2_simulator.Skin
import com.rarmash.cs2_simulator.enums.Gloves
import com.rarmash.cs2_simulator.enums.Knife
import com.rarmash.cs2_simulator.model.Case
import com.rarmash.cs2_simulator.model.dto.CaseDto
import com.rarmash.cs2_simulator.model.dto.SkinDto
import com.rarmash.cs2_simulator.model.enums.Rarity
import com.rarmash.cs2_simulator.model.enums.Weapon
import com.rarmash.cs2_simulator.model.enums.WeaponType

object DataMapper {

    @JvmStatic
    fun toJavaSkin(dto: SkinDto): Skin {
        val rarity = Rarity.valueOf(dto.rarity.uppercase())
        val weaponType = WeaponType.valueOf(dto.weaponType.uppercase())

        return when (dto.itemKind.uppercase()) {
            "WEAPON" -> Skin(
                dto.name,
                dto.skinImage,
                dto.floatTop,
                dto.floatBottom,
                dto.isSouvenir,
                rarity,
                weaponType,
                Weapon.valueOf(dto.itemId.uppercase())
            )

            "KNIFE" -> Skin(
                dto.name,
                dto.skinImage,
                dto.floatTop,
                dto.floatBottom,
                dto.isSouvenir,
                rarity,
                weaponType,
                Knife.valueOf(dto.itemId.uppercase())
            )

            "GLOVES" -> Skin(
                dto.name,
                dto.skinImage,
                dto.floatTop,
                dto.floatBottom,
                dto.isSouvenir,
                rarity,
                weaponType,
                Gloves.valueOf(dto.itemId.uppercase())
            )

            else -> throw IllegalArgumentException("Unknown itemKind: ${dto.itemKind}")
        }
    }

    @JvmStatic
    fun toCase(caseDto: CaseDto, skins: List<Skin>): Case {
        return Case(
            caseDto.name,
            caseDto.caseImage,
            skins
        )
    }
}