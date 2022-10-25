#version 120

#include "settings.glsl"

uniform int worldTime;

varying vec2 TexCoords;
varying vec2 LmCoords;
varying vec3 Normal;
varying vec4 Color;
varying vec4 Material;

/* DRAWBUFFERS:0124 */

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D colortex8; // Sky Color

float adjustLightmapTorch(in float torch) {
    const float K = 2;
    const float P = 5.06;
    return K * pow(torch, P);
}

float adjustLightmapSky(in float sky) {
    return pow(sky, 4);
}

vec2 adjustLightmap(in vec2 lightmap) {
    vec2 newLightMap;
    newLightMap.x = adjustLightmapTorch(lightmap.x);
    newLightMap.y = adjustLightmapSky(lightmap.y);
    return newLightMap;
}

void main() {
    vec4 albedo = texture2D(texture, TexCoords) * Color;
    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(Normal, 1);
    gl_FragData[2] = vec4(adjustLightmap(LmCoords), 0, albedo.a);
    gl_FragData[3] = Material;
}