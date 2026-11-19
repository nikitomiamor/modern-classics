#version 330
#extension GL_ARB_separate_shader_objects : require

// Classic enchantment glint (1.0 - 1.2.5).
// The textures already carry the old tint (0.5, 0.25, 0.8) * 0.76.
// The glint blend is (SRC_COLOR, ONE): the screen gets color * color added.
// Old versions drew two passes, so the screen got c1*c1 + c2*c2; output the
// square root of that so the blend gives the same sum in one pass.
// Old versions had no "Glint Strength" option: the default 75% looks like
// the old glint, and lower values still dim it.

#include <minecraft:fog.glsl>
#include <minecraft:globals.glsl>
#include <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
layout(location = 2) in vec2 texCoord0;
layout(location = 3) in vec2 texCoord1;
layout(location = 4) flat in float guiBoost;

layout(location = 0) out vec4 fragColor;

void main() {
    vec4 c1 = texture(Sampler0, texCoord0) * ColorModulator;
    vec4 c2 = texture(Sampler0, texCoord1) * ColorModulator;
    if (c1.a < 0.1 && c2.a < 0.1) {
        discard;
    }
    float fog = 1.0 - total_fog_value(sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd);
    float strength = clamp(GlintAlpha / 0.75, 0.0, 1.0);
    vec3 sum = (c1.rgb * c1.rgb + c2.rgb * c2.rgb) * guiBoost;
    fragColor = vec4(sqrt(sum * fog * strength), 1.0);
}
