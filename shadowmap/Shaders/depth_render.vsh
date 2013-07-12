//
//  Shader.vsh
//  shadowmap
//
//  Created by Daniel Grigg on 21/06/13.
//  Copyright (c) 2013 Sliplane Software. All rights reserved.
//

attribute vec4 position;
uniform mat4 modelViewProjectionMatrix;

void main()
{
  gl_Position = modelViewProjectionMatrix * position;
}
