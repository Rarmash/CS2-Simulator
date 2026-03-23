package com.rarmash.cs2_simulator.repository

import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.registerKotlinModule
import com.rarmash.cs2_simulator.model.Case
import com.rarmash.cs2_simulator.model.dto.CaseContentDto
import com.rarmash.cs2_simulator.model.dto.CaseDto
import com.rarmash.cs2_simulator.model.dto.SkinDto
import com.rarmash.cs2_simulator.service.DataMapper

class LocalDataRepository {

    private val mapper = jacksonObjectMapper().registerKotlinModule()

    private val skinDtos: List<SkinDto> by lazy {
        readList("/data/skins.json")
    }

    private val caseDtos: List<CaseDto> by lazy {
        readList("/data/cases.json")
    }

    private val caseContentDtos: List<CaseContentDto> by lazy {
        readList("/data/case_contents.json")
    }

    fun getCases(): List<Case> {
        val skinsById = skinDtos.associateBy { it.id }
        val contentsByCaseId = caseContentDtos.associateBy { it.caseId }

        return caseDtos.map { caseDto ->
            val skinIds = contentsByCaseId[caseDto.id]?.skinIds ?: emptyList()

            val caseSkins = skinIds.map { skinId ->
                val skinDto = skinsById[skinId]
                    ?: throw IllegalArgumentException("Skin not found for id: $skinId")
                DataMapper.toJavaSkin(skinDto)
            }

            DataMapper.toCase(caseDto, caseSkins)
        }
    }

    fun getCaseById(caseId: String): Case? {
        val skinsById = skinDtos.associateBy { it.id }
        val caseDto = caseDtos.firstOrNull { it.id == caseId } ?: return null
        val skinIds = caseContentDtos.firstOrNull { it.caseId == caseId }?.skinIds ?: emptyList()

        val caseSkins = skinIds.map { skinId ->
            val skinDto = skinsById[skinId]
                ?: throw IllegalArgumentException("Skin not found for id: $skinId")
            DataMapper.toJavaSkin(skinDto)
        }

        return DataMapper.toCase(caseDto, caseSkins)
    }

    private inline fun <reified T> readList(path: String): List<T> {
        val stream = javaClass.getResourceAsStream(path)
            ?: throw IllegalArgumentException("Resource not found: $path")

        return stream.use {
            mapper.readValue(it, object : TypeReference<List<T>>() {})
        }
    }
}