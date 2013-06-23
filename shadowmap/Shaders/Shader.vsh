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
varying lowp vec4 colorVarying;

uniform mat4 modelViewProjectionMatrix;
uniform mat3 normalMatrix;

void main()
{
  vec3 eyeNormal = normalize(normalMatrix * normal);
  vec3 lightPosition = vec3(4.0, 4.0, 5.0);
  vec4 diffuseColor = vec4(0.4, 0.4, 1.0, 1.0);
  
  float nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));
  
  colorVarying = diffuseColor * nDotVP;
  uvVarying = uv;
  gl_Position = modelViewProjectionMatrix * position;
}
