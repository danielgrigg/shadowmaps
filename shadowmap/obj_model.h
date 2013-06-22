//
//  obj_model.h
//  shadowmap
//
//  Created by Daniel Grigg on 21/06/13.
//  Copyright (c) 2013 Sliplane Software. All rights reserved.
//

#ifndef shadowmap_obj_model_h
#define shadowmap_obj_model_h

#include <vector>
#include "mesh_math.h"
#include <iterator>
#include <iostream>

namespace lap {

class ObjModel
{
public:
  
  std::string _name;
  std::vector<float3> _positions;
  std::vector<float2> _uvs;
  std::vector<float3> _normals;
};
    
  typedef std::unique_ptr<ObjModel> ObjModelPtr;

  ObjModelPtr obj_model(const std::string path);
}


#endif