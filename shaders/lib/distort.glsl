const float shadowmapBias = 0.85;

vec2 distortPosition(in vec2 position){
    float distortionFactor = length(position * 1.169) * shadowmapBias + (1.0 - shadowmapBias);
    return position / distortionFactor;
}