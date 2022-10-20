#version 120

varying vec4 World;
varying vec2 TexCoords;
varying vec2 LmCoords;
varying vec3 Normal;
varying vec4 Color;
varying vec4 Material;

uniform sampler2D texture;
uniform sampler2D lightmap;

const vec3 Ambient = vec3(0.025);
// const vec3 TorchColor = vec3(1, 0.25, 0.08);
const vec3 TorchColor = vec3(1);
const vec3 SkyColor = vec3(0.05, 0.15, 0.3);

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

    /* DRAWBUFFERS:01234 */
    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(Normal * 0.5 + 0.5, 1);
    gl_FragData[2] = vec4(light + Ambient, albedo.a);
    gl_FragData[3] = World;
    gl_FragData[4] = Material;
}