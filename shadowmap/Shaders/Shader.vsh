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
varying lowp vec2 uvVarying;
varying lowp vec3 normal_var;
varying lowp vec4 light_pos_var;
varying lowp vec4 colorVarying;
varying lowp vec4 world_pos_var;
varying lowp vec4 eye_pos_var;

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projMatrix;
uniform mat4 modelViewProjectionMatrix;
uniform mat3 normalMatrix;

void main()
{
  normal_var = normalMatrix * normal;
  light_pos_var = viewMatrix * vec4(10.0, 3.0, 0.0, 1.0);
//  vec4 diffuseColor = vec4(1.0, 1.0, 1.0, 1.0);
  
  uvVarying = uv;
  world_pos_var = modelMatrix * position;
  eye_pos_var = viewMatrix * modelMatrix * position;
  gl_Position = modelViewProjectionMatrix * position;
}
