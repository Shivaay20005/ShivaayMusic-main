package com.shivaay20005.shivaaymusic.di

import com.shivaay20005.shivaaymusic.utils.gamification.GamificationIntegration
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@EntryPoint
@InstallIn(SingletonComponent::class)
interface GamificationEntryPoint {
    fun gamificationIntegration(): GamificationIntegration
}
