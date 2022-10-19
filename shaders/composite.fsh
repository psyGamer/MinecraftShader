#version 120

#define composite
#include "shader.h"

#include "lib/space_transform.glsl"

varying vec2 TexCoords;

// Direction of the sun (not normalized!)
uniform vec3 sunPosition;

uniform sampler2D colortex0; // Color
uniform sampler2D colortex1; // Normal
uniform sampler2D colortex2; // Lightmap
uniform sampler2D colortex4;

/*
const int colortex0Format = RGBA16;
*/

uniform sampler2D depthtex0;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform sampler2D noisetex;

#ifdef SUN_ROTATION
const float sunPathRotation = SUN_ROTATION;
#else
const float sunPathRotation = 0;
#endif // SUN_ROTATION

const int shadowMapResolution = 1024;
const int noiseTextureResolution = 128; // Default value is 64

const float Ambient = 0.025;
const vec3 TorchColor = vec3(1, 0.25, 0.08);
const vec3 SkyColor = vec3(0.05, 0.15, 0.3);

#ifdef DYNAMIC_SHADOWS
const int ShadowSamples = 2;
const int ShadowSamplesPerSize = 2 * ShadowSamples + 1;
const int TotalSamples = ShadowSamplesPerSize * ShadowSamplesPerSize;

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

float visibility(in sampler2D shadowMap, in vec3 sampleCoords) {
    return step(sampleCoords.z - 0.001, texture2D(shadowMap, sampleCoords.xy).r);
}

vec3 transparentShadow(in vec3 sampleCoords) {
    float shadowVisibility0 = visibility(shadowtex0, sampleCoords);
    float shadowVisibility1 = visibility(shadowtex1, sampleCoords);
    vec4 shadowColor0 = texture2D(shadowcolor0, sampleCoords.xy);
    vec3 transmittedColor = shadowColor0.rgb * (1 - shadowColor0.a); // Perform a blend operation with the sun color
    return mix(transmittedColor * shadowVisibility1, vec3(1), shadowVisibility0);
}

vec3 getShadow(float depth) {
    vec3 clipSpace = vec3(TexCoords, depth) * 2 - 1;
    vec4 shadowSpace = clip2Shadow(clipSpace);
    vec3 sampleCoords = shadowSpace.xyz * 0.5 + 0.5;

    float randomAngle = texture2D(noisetex, TexCoords * 20).r * 100;
    float cosTheta = cos(randomAngle);
    float sinTheta = sin(randomAngle);
    // We can move our division by the shadow map resolution here for a small speedup
    mat2 rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution;

    vec3 shadowAccum = vec3(0);
    for(int x = -ShadowSamples; x <= ShadowSamples; x++){
        for(int y = -ShadowSamples; y <= ShadowSamples; y++){
            vec2 offset = rotation * vec2(x, y);
            vec3 currentSampleCoordinate = vec3(sampleCoords.xy + offset, sampleCoords.z);
            shadowAccum += transparentShadow(currentSampleCoordinate);
        }
    }
    shadowAccum /= TotalSamples;
    return shadowAccum;
}
#endif // DYNAMIC_SHADOWS

void main() {
    vec3 albedo = texture2D(colortex0, TexCoords).rgb;

    // Account for gamma correction
    albedo = pow(albedo, vec3(2.2));

    float depth = texture2D(depthtex0, TexCoords).r;
    // The sky is at depth = 1, so we can return early
    if (depth == 1) {
        gl_FragData[0] = vec4(albedo, 1);
        return;
    }

    vec2 lightmap = texture2D(colortex2, TexCoords).rg;

#ifdef DIFFUSE_SHADOWS
    vec3 normal = normalize(texture2D(colortex1, TexCoords).rgb * 2 - 1);
    // Compute cos theta between the normal and sun directions
    float diff = max(dot(normal, normalize(sunPosition)), 0);
#else
    float diff = 1;
#endif

#ifdef DYNAMIC_SHADOWS
    vec3 lightmapColor = getLightmapColor(lightmap);
    vec3 final = albedo * (lightmapColor + diff * getShadow(depth) + Ambient);
#else
    vec3 final = albedo * lightmap + Ambient;
#endif // DYNAMIC_SHADOWS

    gl_FragData[0] = vec4(final, 1);
}