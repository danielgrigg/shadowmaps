//
//  Shader.fsh
//  shadowmap
//
//  Created by Daniel Grigg on 21/06/13.
//  Copyright (c) 2013 Sliplane Software. All rights reserved.
//
precision lowp float;

varying lowp vec4 colorVarying;
varying lowp vec2 uvVarying;
varying lowp vec4 eye_pos_var;
varying lowp vec3 normal_var;
varying lowp vec4 light_pos_var;
varying lowp vec3 vertex_light_ndc;

uniform sampler2D colorMap;
uniform sampler2D depthMap;

vec2 compress(vec2 v) { return 0.5 * v + vec2(0.5); }

float shadow_test(float depth_light, float depth_eye) {
  return step( depth_eye, depth_light);
}

void main()
{
  vec2 vertex_light_ndc_compressed = compress(vertex_light_ndc.xy);
  vec4 depth_sample = texture2D(depthMap, vertex_light_ndc_compressed);
  vec4 color_sample = texture2D(colorMap, vertex_light_ndc_compressed);
  
  float depth_light = depth_sample.x;
  float depth_eye = 0.5 * vertex_light_ndc.z + 0.5;
  float s = shadow_test(depth_light, depth_eye);
  
  vec3 l = normalize(light_pos_var - eye_pos_var).xyz;
  float n_dot_l = max(0.0, dot(normalize(normal_var), l));

  vec3 C = max(0.05, s * n_dot_l) * vec3(1.0, 0.3, 0.2);  
  gl_FragColor = vec4(pow(C, vec3(1.0/2.2)), 1.0);

}
