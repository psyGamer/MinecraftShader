#version 120

#include "settings.glsl"

varying vec2 TexCoords;
varying vec2 LmCoords;
varying vec3 Normal;
varying vec4 Color;
varying vec4 Material;

/* DRAWBUFFERS:0124 */

uniform sampler2D texture;
uniform sampler2D lightmap;

const vec3 Ambient = vec3(AMBIENT_R, AMBIENT_G, AMBIENT_B);
const vec3 TorchColor = vec3(TORCH_R, TORCH_G, TORCH_B);
const vec3 SkyColor = vec3(SKY_R, SKY_G, SKY_B);

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

vec3 getLightmapColor(in vec2 lightmap){
    lightmap = adjustLightmap(lightmap);
    
    vec3 torchLighting = lightmap.x * TorchColor;
    vec3 skyLighting = lightmap.y * SkyColor;
    
    return torchLighting + skyLighting;
}

void main() {
    vec4 albedo = texture2D(texture, TexCoords) * Color;
    vec3 light = getLightmapColor(LmCoords);

    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(light + Ambient, albedo.a);
    gl_FragData[2] = vec4(Normal, 1);
    gl_FragData[3] = Material;
}