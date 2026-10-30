#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uProgress;
uniform float uRadiusScale;
uniform float uPixel;
uniform vec4 uColor;

out vec4 fragColor;

const float PI = 3.14159265358979;
const float BUMPS = 8.0;

void main() {
  vec2 p = FlutterFragCoord().xy - uSize * 0.5;
  float halfExtent = min(uSize.x, uSize.y) * 0.5;
  float baseR = halfExtent * 0.82 * uRadiusScale;
  float peakR = halfExtent * 1.02 * uRadiusScale;
  float circleR = (baseR + peakR) / 2.3;
  float mid = (baseR + peakR) * 0.5;
  float amp = (peakR - baseR) * 0.5;

  float len = max(length(p), 1e-3);
  float theta = atan(p.y, p.x) + PI * 0.5;
  float burstR = mid + amp * cos(BUMPS * theta);
  float burstSlope = -amp * BUMPS * sin(BUMPS * theta);

  float radius = mix(circleR, burstR, uProgress);
  float slope = uProgress * burstSlope;
  float dist = (len - radius) / sqrt(1.0 + (slope * slope) / (len * len));

  float coverage = clamp(0.5 - dist / uPixel, 0.0, 1.0);
  fragColor = vec4(uColor.rgb * uColor.a, uColor.a) * coverage;
}
