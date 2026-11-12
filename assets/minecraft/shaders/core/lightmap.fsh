#version 330
#extension GL_ARB_separate_shader_objects : require

// Modern Classics: Alpha/Beta-style lighting.
// Based on the vanilla 26.3 lightmap shader; only main() differs.
//  - sky light and block light are combined with max() instead of being added
//  - light is neutral grey (no warm torch tint, no blue night tint, no torch flicker)
//  - Beta brightness table with a 0.05 minimum
//  - at night the sky drops 11 light levels (15 -> 4), like Beta

layout(std140) uniform LightmapInfo {
    float SkyFactor;
    float BlockFactor;
    float NightVisionFactor;
    float DarknessScale;
    float BossOverlayWorldDarkeningFactor;
    float BrightnessFactor;
    vec3 BlockLightTint;
    vec3 SkyLightColor;
    vec3 AmbientColor;
    vec3 NightVisionColor;
} lightmapInfo;

layout(location = 0) in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

float get_brightness(float level) {
    return level / (4.0 - 3.0 * level);
}

vec3 notGamma(vec3 color) {
    float maxComponent = max(max(color.x, color.y), color.z);
    float maxInverted = 1.0f - maxComponent;
    float maxScaled = 1.0f - maxInverted * maxInverted * maxInverted * maxInverted;
    return color * (maxScaled / maxComponent);
}

void main() {
    // Light levels 0..15 as 0..1, same as vanilla
    float block_level = floor(texCoord.x * 16) / 15;
    float sky_level = floor(texCoord.y * 16) / 15;

    // Beta night: the sky loses up to 11 light levels (vanilla sky factor goes 1.0 by day -> 0.24 at night)
    float darken = clamp((1.0 - lightmapInfo.SkyFactor) / 0.76, 0.0, 1.0) * 11.0;
    float sky_eff = max(sky_level * 15.0 - darken, 0.0) / 15.0;

    // Beta: brightest of sky and block light, looked up in the old table (minimum 0.05), neutral grey
    float level = max(block_level, sky_eff);
    vec3 color = vec3(0.05 + 0.95 * get_brightness(level));

    // Keep each dimension's ambient floor (Nether/End) but without its colour cast
    vec3 ambient = lightmapInfo.AmbientColor;
    float ambientGrey = max(max(ambient.r, ambient.g), ambient.b);
    color = max(color, vec3(ambientGrey));

    // Night vision, same as vanilla
    color = max(color, lightmapInfo.NightVisionColor * lightmapInfo.NightVisionFactor);

    // Boss overlay darkening, same as vanilla
    color = mix(color, color * vec3(0.7, 0.6, 0.6), lightmapInfo.BossOverlayWorldDarkeningFactor);

    // Darkness effect (warden), same as vanilla
    color = color - vec3(lightmapInfo.DarknessScale);

    // Brightness slider, same as vanilla (set it to "Moody" for the Beta look)
    color = clamp(color, 0.0, 1.0);
    vec3 notGamma = notGamma(color);
    color = mix(color, notGamma, lightmapInfo.BrightnessFactor);

    fragColor = vec4(color, 1.0);
}
