#include "distort.glsl"

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

vec3 clip2view(vec3 clip) {
    vec4 view = gbufferProjectionInverse * vec4(clip, 1);
    return view.xyz / view.w;
}

vec4 screen2view(vec2 texCoords, float depth) {
    vec4 ndc = vec4(vec3(texCoords, depth) * 2 - 1, 1);
    vec4 view = gbufferProjectionInverse * ndc;
    view.xyz /= view.w;
    return view;
}

vec4 clip2world(vec3 clip) {
    vec3 view = clip2view(clip);
    vec4 world = gbufferModelViewInverse * vec4(view, 1);
    return world;
}

vec4 clip2shadow(vec3 clip) {
    vec4 world = clip2world(clip);
    vec4 shadow = shadowProjection * shadowModelView * world;
    shadow.xy = distortPosition(shadow.xy);
    return shadow;
}

vec4 view2screen(vec3 view, vec2 screenSize) {
    vec4 screen = gbufferProjection * vec4(view, 1);
    screen.xyz /= screen.w;
    screen.xy   = screen.xy * 0.5 + 0.5;
    screen.xy  *= screenSize;
    return screen;
}

vec4 view2world(vec3 view) {
    vec4 world = gbufferModelViewInverse * vec4(view, 1);
    return world;
}

vec3 world2screen(vec3 world) {
   mat4 modelView = gbufferModelView;

   // clear transformations to stabilize conversions
   modelView[3] = vec4(0.0, 0.0, 0.0, 1.0);

   return (modelView * vec4(world, 1.0)).xyz;
}