package com.shivaay20005.shivaaymusic.models

data class Reward(
    val key: String,
    val name: String,
    val description: String,
    val requiredLevel: Int,
    val type: RewardType
)

enum class RewardType {
    THEME,
    ANIMATION,
    PROFILE_FRAME,
    BADGE,
    UI_ACCENT,
    ICON
}

object RewardDefinitions {
    val allRewards = listOf(
        Reward(
            key = "gradient_theme",
            name = "Mini Gradient Theme",
            description = "A beautiful gradient theme for your player",
            requiredLevel = 5,
            type = RewardType.THEME
        ),
        Reward(
            key = "custom_like_animation",
            name = "Custom Like Animation",
            description = "Special animation when you like a song",
            requiredLevel = 5,
            type = RewardType.ANIMATION
        ),
        Reward(
            key = "rare_profile_frame",
            name = "Rare Profile Frame",
            description = "An exclusive profile frame",
            requiredLevel = 10,
            type = RewardType.PROFILE_FRAME
        ),
        Reward(
            key = "ui_accent_new",
            name = "New UI Accent",
            description = "Fresh new color accent for UI elements",
            requiredLevel = 10,
            type = RewardType.UI_ACCENT
        ),
        Reward(
            key = "glassmorphic_player",
            name = "Glassmorphic Player Theme",
            description = "Modern glassmorphic design for player",
            requiredLevel = 15,
            type = RewardType.THEME
        ),
        Reward(
            key = "vip_badge",
            name = "VIP Badge",
            description = "Show off your VIP status",
            requiredLevel = 20,
            type = RewardType.BADGE
        ),
        Reward(
            key = "hologram_animation",
            name = "Hologram Animation",
            description = "Futuristic hologram effect in player",
            requiredLevel = 30,
            type = RewardType.ANIMATION
        ),
        Reward(
            key = "rare_icons_pack",
            name = "Rare Profile Icons",
            description = "Collection of exclusive profile icons",
            requiredLevel = 40,
            type = RewardType.ICON
        ),
        Reward(
            key = "surprise_animation",
            name = "Surprise Animation Pack",
            description = "Bundle of exclusive animations",
            requiredLevel = 40,
            type = RewardType.ANIMATION
        )
    )
}
