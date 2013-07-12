//
//  Shader.fsh
//  shadowmap
//
//  Created by Daniel Grigg on 21/06/13.
//  Copyright (c) 2013 Sliplane Software. All rights reserved.
//
precision highp float;

varying lowp vec4 colorVarying;
varying lowp vec2 uvVarying;
varying lowp vec4 world_pos_var;
varying lowp vec4 eye_pos_var;
varying lowp vec3 normal_var;
varying lowp vec4 light_pos_var;

uniform sampler2D colorMap;
uniform sampler2D depthMap;

uniform mat4 light_view_proj;
uniform mat4 inv_camera_view_proj;
uniform mat4 inv_proj;
uniform vec4 viewport;

// Transform a Window position to NDC space.
vec4 ndc_pos(vec4 viewport,
             vec4 window_pos,
             float near,
             float far)
{
  vec4 ndc_pos;
  ndc_pos.xy = ((2.0 * window_pos.xy) - (2.0 * viewport.xy)) / (viewport.zw) - vec2(1.0);
  ndc_pos.z = (2.0 * window_pos.z - near - far) / (far - near);
  ndc_pos.w = 1.0;
  return ndc_pos;
}

// Inverse-transform a NDC position to some space (eye, world, etc).
vec4 from_ndc(mat4 inv_transform,
             vec4 ndc_pos,
             float inv_clip_w)
{
  // Reverse division-by-w using the (1/Wc) stored in window_pos.w .
  vec4 clip_pos = ndc_pos / inv_clip_w;
  return inv_transform * clip_pos;
}

vec2 compress(vec2 v) { return 0.5 * v + vec2(0.5); }
vec3 compress(vec3 v) { return 0.5 * v + vec3(0.5); }

void main()
{
  vec4 frag_ndc = ndc_pos(viewport, gl_FragCoord, gl_DepthRange.near, gl_DepthRange.far);
  
  vec4 frag_eye = from_ndc(inv_proj, frag_ndc, gl_FragCoord.w);
  
  vec4 frag_world = from_ndc(inv_camera_view_proj, frag_ndc, gl_FragCoord.w);
  
  vec4 frag_light_clip = light_view_proj * frag_world;
  vec3 frag_light_ndc = frag_light_clip.xyz / frag_light_clip.w;
  
  vec4 depth_sample = texture2D(depthMap, compress(frag_light_ndc.xy));
  vec4 color_sample = texture2D(colorMap, compress(frag_light_ndc.xy));
  
  float depth_light = depth_sample.x;
  float depth_eye = 0.5 * frag_light_ndc.z + 0.5;
  float s = step( depth_eye, depth_light);
  vec3 l = normalize(light_pos_var - eye_pos_var).xyz;
  float n_dot_l = max(0.0, dot(normalize(normal_var), l));

  vec3 C = max(0.05, s * n_dot_l) * vec3(1.0, 0.3, 0.2);  
  gl_FragColor = vec4(pow(C, vec3(1.0/2.2)), 1.0);

}
