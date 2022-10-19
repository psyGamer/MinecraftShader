#include "distort.glsl"

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

vec4 clip2world(vec3 clipSpace) {
    vec4 viewW = gbufferProjectionInverse * vec4(clipSpace, 1);
    vec3 view = viewW.xyz / viewW.w;
    vec4 world = gbufferModelViewInverse * vec4(view, 1);
    return world;
}

vec4 clip2shadow(vec3 clipSpace) {
    vec4 world = clip2world(clipSpace);
    vec4 shadowSpace = shadowProjection * shadowModelView * world;
    shadowSpace.xy = distortPosition(shadowSpace.xy);
    return shadowSpace;
}