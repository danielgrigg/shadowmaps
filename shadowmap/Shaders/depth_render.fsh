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
uniform sampler2D colorMap;

void main()
{
  gl_FragColor = colorVarying * texture2D(colorMap, uvVarying);
}
