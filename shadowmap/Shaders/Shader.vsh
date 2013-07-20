//
//  Shader.vsh
//  shadowmap
//
//  Created by Daniel Grigg on 21/06/13.
//  Copyright (c) 2013 Sliplane Software. All rights reserved.
//

attribute vec4 position;
attribute vec3 normal;
attribute vec2 uv;

//varying lowp vec2 uvVarying;
varying lowp vec3 normal_var;
varying lowp vec4 light_pos_var;
varying lowp vec4 colorVarying;
varying lowp vec4 eye_pos_var;
varying lowp vec3 vertex_light_ndc;

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projMatrix;
uniform mat4 modelViewProjectionMatrix;
uniform mat4 light_view_proj;

uniform vec4 viewport;
uniform mat3 normalMatrix;
uniform vec4 light_pos_world;

void main()
{
  vec4 vertex_light_clip = light_view_proj * modelMatrix * position;;
  vertex_light_ndc = vertex_light_clip.xyz / vertex_light_clip.w;
  
  normal_var = normalMatrix * normal;
  light_pos_var = viewMatrix * light_pos_world;
  eye_pos_var = viewMatrix * modelMatrix * position;
  gl_Position = modelViewProjectionMatrix * position;
}
