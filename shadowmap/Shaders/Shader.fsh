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
uniform sampler2D colorMap;
uniform sampler2D depthMap;

uniform mat4 light_view_proj;
uniform mat4 inv_camera_view_proj;
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
vec4 eye_pos(mat4 inv_transform,
             vec4 ndc_pos,
             float inv_clip_w,
             float near,
             float far)
{
  // Reverse division-by-w using the (1/Wc) stored in window_pos.w .
  vec4 clip_pos = ndc_pos / inv_clip_w;
  return inv_transform * clip_pos;
}

void main()
{
//    gl_FragColor =  texture2D(colorMap, uvVarying * vec2(1.0, 1.0)) ;
  vec4 kd = max(vec4(0.0), colorVarying);
  
//  gl_FragColor = kd * texture2D(depthMap, uvVarying);
  
  // First transform the depth-map position to NDC
  vec4 frag_ndc = ndc_pos(viewport, gl_FragCoord, gl_DepthRange.near, gl_DepthRange.far);
  vec4 frag_world = eye_pos(inv_camera_view_proj,
                             frag_ndc,
                             gl_FragCoord.w,
                             gl_DepthRange.near,
                             gl_DepthRange.far);
  vec4 frag_light_clip = light_view_proj * frag_world;
  vec4 frag_light_ndc = frag_light_clip / frag_light_clip.w;
  
  gl_FragColor = vec4(frag_light_ndc.zzz, 1.0);
}
