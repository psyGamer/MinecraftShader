#version 120

#include "settings.glsl"
#include "lib/space_transform.glsl"

/* DRAWBUFFERS:0 */

uniform sampler2D colortex0; // Color
uniform sampler2D colortex2; // Normal
uniform sampler2D colortex4; // Material
uniform sampler2D depthtex0;

varying vec2 TexCoords;

#ifdef SSR
    const int   maxRaySteps         = 15;
    const int   maxRefinements      = 4;
    const float rayMultiplier       = 2;
    const float refinmentMultiplier = 0.1;

    vec4 screenSpaceReflection(vec3 position, vec3 reflection) {
        /*
        Author: mateusak (https://github.com/mateusak)
        Source: https://github.com/mateusak/minecraft-miniature-shader/blob/cfdd7eb4bf8a520485699ff1ac0db8ec8fb36c63/shaders/final.fsh#L59-L100

        The code of this function is licensed under:

        MIT License

        Copyright (c) 2022 Mateus A. Kreuch

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
        */

        vec3 curPos = position + reflection;
        vec3 oldPos = position;

        int j = 0;
        for (int _ = 0; _ < maxRaySteps; _++) {
            vec3 curUV = screen2uv(curPos);

            if (curUV.x < 0.0 || curUV.x > 1.0 || 
                curUV.y < 0.0 || curUV.y > 1.0 || 
                curUV.z < 0.0 || curUV.z > 1.0) break;
            
            vec3 sample = uv2screen(curUV.st, texture2D(depthtex0, curUV.st).x);
            float dist  = abs(curPos.z - sample.z);
            float len   = dot(reflection, reflection);

            // check if distance between last and current depth is
            // smaller than the current length of the reflection vector
            // the numbers are trial and error to produce less distortion
            if (dist * dist < 2 * len * exp(0.029 * len) && texture2D(colortex4, curUV.st).r <= 0.001) {
                j++;

                if (j >= maxRefinements) {
                    // fade reflection with vignette
                    vec2 vignette = curUV.st * (1.0 - curUV.st);

                    return vec4(
                        texture2D(colortex0, curUV.st).rgb,
                        clamp(pow(15.0*vignette.s*vignette.t, 1.5), 0.0, 1.0)
                    );
                }

                curPos = oldPos;
                reflection *= refinmentMultiplier;
            }

            reflection *= rayMultiplier;
            oldPos = curPos;
            curPos += reflection;
        }
        
        return vec4(0, 0, 0, 1);
    }
#endif // SSR

void main() {
    vec4 color = texture2D(colortex0, TexCoords);

    #ifdef SSR
        // (r) Reflectivness, (g) none, (b) none, (a) none
        float reflectivness = texture2D(colortex4, TexCoords).r;
        if (reflectivness <= 0.001) {
            gl_FragData[0] = color;
            return;
        }

        float depth = texture2D(depthtex0, TexCoords).r;

        vec3 position = uv2screen(TexCoords, depth).xyz;
        vec3 normal = normalize(world2screen(texture2D(colortex2, TexCoords).xyz * 2 - 1));

        vec3 reflection = normalize(reflect(position, normal));
        vec4 ssr = screenSpaceReflection(position, reflection);

        // The flatter the viewing angle the more should the reflection be visible
        reflectivness *= clamp(1 - dot(normal, -normalize(position)), 0, 1);

        // gl_FragData[0] = ssr;
        gl_FragData[0] = ssr.xyz == vec3(0)
            ? color
            : vec4(mix(color.rgb, ssr.rgb, reflectivness * ssr.a), color.a);
    #else
        gl_FragData[0] = color;
    #endif // SSR
}