#version 120

#include "lib/distort.glsl"

varying vec2 TexCoords;

// Direction of the sun (not normalized!)
uniform vec3 sunPosition;

// The color textures which we wrote to
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex4;

uniform sampler2D depthtex0;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform sampler2D noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

/*
const int colortex0Format = RGBA16;
const int colortex1Format = RGB16;
const int colortex2Format = RGB16;
*/

const float sunPathRotation = 0;

const int shadowMapResolution = 1024;
const int noiseTextureResolution = 128; // Default value is 64

const float Ambient = 0.025;

const int ShadowSamples = 2;
const int ShadowSamplesPerSize = 2 * ShadowSamples + 1;
const int TotalSamples = ShadowSamplesPerSize * ShadowSamplesPerSize;

vec3 GetLightmapColor(in vec2 Lightmap);
vec3 GetShadow(float depth);

void main(){
    // Account for gamma correction
    vec3 Albedo = pow(texture2D(colortex0, TexCoords).rgb, vec3(2.2));
	float Depth = texture2D(depthtex0, TexCoords).r;

	// if (Depth == 1) {
    // 	gl_FragData[0] = vec4(Albedo, 1);
    // 	return;
	// }
    // Get the normal
    vec3 Normal = normalize(texture2D(colortex1, TexCoords).rgb * 2 - 1);
	
	vec2 Lightmap = texture2D(colortex2, TexCoords).rg;
	// Get the lightmap color
	vec3 LightmapColor = GetLightmapColor(Lightmap);
	if (LightmapColor.s <= 0 && LightmapColor.t <= 0) {
		gl_FragData[0] = vec4(Albedo, 1);
    	return;
	}
    // Compute cos theta between the normal and sun directions
    float NdotL = max(dot(Normal, normalize(sunPosition)), 0);
    // Do the lighting calculations
    vec3 Diffuse = Albedo * (LightmapColor + NdotL * GetShadow(Depth) + Ambient);
    // vec3 Diffuse = Albedo * (LightmapColor + Ambient);

    /* DRAWBUFFERS:0 */
    // Finally write the diffuse color
    gl_FragData[0] = vec4(Diffuse, 1);
}

float AdjustLightmapTorch(in float torch) {
    const float K = 2;
    const float P = 5.06;
    return K * pow(torch, P);
}

float AdjustLightmapSky(in float sky) {
    float sky_2 = sky * sky;
    return sky_2 * sky_2;
}

vec2 AdjustLightmap(in vec2 Lightmap) {
    vec2 NewLightMap;
    NewLightMap.x = AdjustLightmapTorch(Lightmap.x);
    NewLightMap.y = AdjustLightmapSky(Lightmap.y);
    return NewLightMap;
}

// Input is not adjusted lightmap coordinates
vec3 GetLightmapColor(in vec2 Lightmap){
    // First adjust the lightmap
    Lightmap = AdjustLightmap(Lightmap);
    // Color of the torch and sky. The sky color changes depending on time of day but I will ignore that for simplicity
    const vec3 TorchColor = vec3(1, 0.25, 0.08);
    const vec3 SkyColor = vec3(0.05, 0.15, 0.3);
    // Multiply each part of the light map with it's color
    vec3 TorchLighting = Lightmap.x * TorchColor;
    vec3 SkyLighting = Lightmap.y * SkyColor;
    // Add the lighting togther to get the total contribution of the lightmap the final color.
    vec3 LightmapLighting = TorchLighting + SkyLighting;
    // Return the value
    return LightmapLighting;
}

float Visibility(in sampler2D ShadowMap, in vec3 SampleCoords) {
    return step(SampleCoords.z - 0.001, texture2D(ShadowMap, SampleCoords.xy).r);
}

vec3 TransparentShadow(in vec3 SampleCoords) {
    float ShadowVisibility0 = Visibility(shadowtex0, SampleCoords);
    float ShadowVisibility1 = Visibility(shadowtex1, SampleCoords);
    vec4 ShadowColor0 = texture2D(shadowcolor0, SampleCoords.xy);
    vec3 TransmittedColor = ShadowColor0.rgb * (1 - ShadowColor0.a); // Perform a blend operation with the sun color
    return mix(TransmittedColor * ShadowVisibility1, vec3(1), ShadowVisibility0);
}

vec3 GetShadow(float depth) {
	vec3 ClipSpace = vec3(TexCoords, depth) * 2 - 1;

	vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1);
	vec3 View = ViewW.xyz / ViewW.w;

	vec4 World = gbufferModelViewInverse * vec4(View, 1);

	vec4 ShadowSpace = shadowProjection * shadowModelView * World;
	ShadowSpace.xy = DistortPosition(ShadowSpace.xy);
	vec3 SampleCoords = ShadowSpace.xyz * 0.5 + 0.5;


	float RandomAngle = texture2D(noisetex, TexCoords * 20).r * 100;
	float cosTheta = cos(RandomAngle);
	float sinTheta = sin(RandomAngle);
	// We can move our division by the shadow map resolution here for a small speedup
	mat2 Rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution;

	vec3 ShadowAccum = vec3(0);
    for(int x = -ShadowSamples; x <= ShadowSamples; x++){
        for(int y = -ShadowSamples; y <= ShadowSamples; y++){
            vec2 Offset = Rotation * vec2(x, y);
            vec3 CurrentSampleCoordinate = vec3(SampleCoords.xy + Offset, SampleCoords.z);
            ShadowAccum += TransparentShadow(CurrentSampleCoordinate);
        }
    }
    ShadowAccum /= TotalSamples;
    return ShadowAccum;
}