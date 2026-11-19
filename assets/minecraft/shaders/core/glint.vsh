#version 330
#extension GL_ARB_separate_shader_objects : require

// Classic enchantment glint (1.0 - 1.2.5): two layers that cross each other.
// The game only builds one texture matrix (rotated 10 degrees, scrolling).
// Layer 1 uses it as-is (old second pass: 10 degrees); layer 2 turns the UVs
// -60 degrees first, giving the old first pass angle of -50 degrees, so the
// streaks run in a different direction and the layers cross like before.

#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec2 UV0;

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;
layout(location = 2) out vec2 texCoord0;
layout(location = 3) out vec2 texCoord1;
layout(location = 4) flat out float guiBoost;

const float C60 = 0.5;
const float S60 = 0.8660254;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);

    texCoord0 = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
    vec2 turned = vec2(C60 * UV0.x + S60 * UV0.y, -S60 * UV0.x + C60 * UV0.y);
    // +0.37: offset so both layers don't line up at the same spot
    texCoord1 = (TextureMat * vec4(turned, 0.0, 1.0)).xy + vec2(0.37, 0.61);

    // Inventory/GUI uses an orthographic projection (no perspective divide).
    // There the old glint skipped the * 0.76 dimming: undo it, squared by the blend.
    guiBoost = ProjMat[2][3] == 0.0 ? 1.0 / (0.76 * 0.76) : 1.0;
}
