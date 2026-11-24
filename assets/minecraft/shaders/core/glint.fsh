#version 330
#extension GL_ARB_separate_shader_objects : require

// Classic enchantment glint (1.0 - 1.2.5).
// Since 26.x most glints (items, armor, entities) are drawn inside item.fsh and
// entity.fsh as one layer: (GlintAlpha * texture)^2. The textures are the old
// tint (0.5, 0.25, 0.8) * 0.76 brightened by K = sqrt(2) / 0.75, so that one
// layer at the default 75% matches the old two passes.
// This shader is the remaining "glint" pipeline: it undoes K and adds the two
// old crossing layers instead. The blend is (SRC_COLOR, ONE), which squares
// the output, so output the square root of the old sum c1*c1 + c2*c2.
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
    const float K2 = 2.0 / (0.75 * 0.75); // K squared
    vec3 sum = (c1.rgb * c1.rgb + c2.rgb * c2.rgb) / K2 * guiBoost;
    fragColor = vec4(sqrt(sum * fog * strength), 1.0);
}
