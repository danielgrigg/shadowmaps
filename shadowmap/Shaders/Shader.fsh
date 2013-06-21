//
//  Shader.fsh
//  shadowmap
//
//  Created by Daniel Grigg on 21/06/13.
//  Copyright (c) 2013 Sliplane Software. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
