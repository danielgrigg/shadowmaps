//
//  Shader.fsh
//  shadowmap
//
//  Created by Daniel Grigg on 21/06/13.
//  Copyright (c) 2013 Sliplane Software. All rights reserved.
//
precision mediump float;

varying lowp vec4 colorVarying;
varying lowp vec2 uvVarying;
varying lowp vec4 world_pos_var;
varying lowp vec4 eye_pos_var;

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

vec2 compress(vec2 v)
{
  return 0.5 * v + vec2(0.5);
}

void main()
{
  vec4 frag_ndc = ndc_pos(viewport, gl_FragCoord, gl_DepthRange.near, gl_DepthRange.far);
  
  vec4 frag_eye = from_ndc(inv_proj, frag_ndc, gl_FragCoord.w);
  
  vec4 frag_world = from_ndc(inv_camera_view_proj, frag_ndc, gl_FragCoord.w);
  
  vec4 frag_light_clip = light_view_proj * frag_world;
  vec3 frag_light_ndc = frag_light_clip.xyz / frag_light_clip.w;
  
//  vec2 frag_uv = compress(frag_ndc.xy);
  vec4 depth_sample = texture2D(colorMap, compress(frag_light_ndc.xy));

//  gl_FragColor = vec4((0.5 * frag_light_ndc.xyz + vec3(0.5)) / 1.0, 1.0);

//  float d = depth_sample.x;
  gl_FragColor = vec4(depth_sample.xyz, 1.0);
 // gl_FragColor = vec4(frag_uv.xy, 0.0, 1.0);
//  if (d > 0.99) d = 0.0;
//  gl_FragColor = vec4(d,d,d, 1.0);
 
  //gl_FragColor = vec4(depth_sample.zzz, 1.0);
  //gl_FragColor = vec4(gl_FragCoord.zzz, 1.0);
  
//  gl_FragColor = colorVarying;
}
