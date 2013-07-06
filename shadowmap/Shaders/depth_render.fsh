//
//  Shader.fsh
//  shadowmap
//
//  Created by Daniel Grigg on 21/06/13.
//  Copyright (c) 2013 Sliplane Software. All rights reserved.
//
 precision lowp float;

void main()
{
  gl_FragColor = vec4(gl_FragCoord.zzz, 1.0);
//  gl_FragColor = vec4(0.0, 0.0, 1.0, 1.0);
}
