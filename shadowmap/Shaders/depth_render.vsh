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

uniform mat4 modelViewProjectionMatrix;

void main()
{
  gl_Position = modelViewProjectionMatrix * position;
}
