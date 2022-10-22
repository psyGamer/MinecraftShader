#version 120

#include "settings.glsl"
#include "lib/color.glsl"
#include "lib/space_transform.glsl"

varying vec2 TexCoords;

// Direction of the sun (not normalized!)
uniform vec3 sunPosition;

/* DRAWBUFFERS:0 */

uniform sampler2D colortex0; // Color
uniform sampler2D colortex1; // Normal
uniform sampler2D colortex2; // Lightmap
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

const float sunPathRotation = 0; //[-90 -85 -80 -75 -70 -65 -60 -55 -50 -45 -40 -35 -30 -25 -20 -15 -10 -5 0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90]
const int shadowMapResolution = 1024; //[128 256 512 1024 1536 2048 2560 3072 3584 4096 6144 8192]

#ifdef DYNAMIC_SHADOWS
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
        vec3 clipPos = vec3(TexCoords, depth) * 2 - 1;
        vec3 viewPos = clip2view(clipPos);

        float distSquared = dot(viewPos, viewPos);
        if (distSquared > DYNAMIC_SHADOWS_MAX_DIST*DYNAMIC_SHADOWS_MAX_DIST)
            return vec3(1);

        float fade = clamp(1 - (distSquared) / (DYNAMIC_SHADOWS_MAX_DIST*DYNAMIC_SHADOWS_MAX_DIST), 0, 1);
        float sampleFade = clamp(1 - (distSquared - (DYNAMIC_SHADOWS_MAX_DIST*DYNAMIC_SHADOWS_MAX_DIST) * 0.05) / (DYNAMIC_SHADOWS_MAX_DIST*DYNAMIC_SHADOWS_MAX_DIST*0.8), 0, 1);

        vec3 shadowPos = clip2shadow(clipPos);
        vec3 shadowCoords = shadowPos * 0.5 + 0.5;

        float randomAngle = texture2D(noisetex, TexCoords * 20).r * 100;
        float cosTheta = cos(randomAngle);
        float sinTheta = sin(randomAngle);
        // We can move our division by the shadow map resolution here for a small speedup
        mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / 1024;
        vec3 shadowAccum = vec3(0);

        float fadedSampleCount = DYNAMIC_SHADOWS_SAMPLES * 0.5 * sampleFade;
        int totalSamples = 0;
        for(float x = -fadedSampleCount; x <= fadedSampleCount; x++){
            for(float y = -fadedSampleCount; y <= fadedSampleCount; y++){
                vec2 offset = rotation * vec2(x, y);
                vec3 offsetShadowCoords = vec3(shadowCoords.xy + offset, shadowCoords.z);
                shadowAccum += transparentShadow(offsetShadowCoords);
                totalSamples++;
            }
        }
        shadowAccum /= totalSamples;
        return shadowAccum;
    }
#endif // DYNAMIC_SHADOWS

void main() {
    vec3 albedo = texture2D(colortex0, TexCoords).rgb;
    albedo = srgb2linear(albedo);

    float depth = texture2D(depthtex0, TexCoords).r;
    
    // The sky is at depth = 1, so we can return early
    if (depth == 1) {
        gl_FragData[0] = vec4(albedo, 1);
        return;
    }

    #ifdef DIFFUSE_SHADOWS
        vec3 normal = world2screen(texture2D(colortex2, TexCoords).rgb * 2 - 1);
        // Compute cos theta between the normal and sun directions
        float diff = max(dot(normalize(normal), normalize(sunPosition)), 0);
    #else
        float diff = 0.86;
    #endif

    vec3 light = texture2D(colortex1, TexCoords).rgb;

    #ifdef DYNAMIC_SHADOWS
        vec3 final = albedo * (light + diff * getShadow(depth));
    #else
        vec3 final = albedo * (light + diff);
    #endif // DYNAMIC_SHADOWS

    final = linear2srgb(final);
    gl_FragData[0] = vec4(final, 1);
}