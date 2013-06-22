//
//  obj_model.cpp
//  shadowmap
//
//  Created by Daniel Grigg on 21/06/13.
//  Copyright (c) 2013 Sliplane Software. All rights reserved.
//

#include "obj_model.h"
#include <unordered_map>
#include <string>
#include <fstream>
#include <functional>
#include <map>
#include <regex>
#include <iterator>

using std::string;
using std::sregex_token_iterator;
using std::function;

namespace lap {
  
  std::ostream& operator<<(std::ostream& os, const ObjModel& m) {
    
    os << "positions: ";
    std::copy(m._positions.begin(), m._positions.end(), std::ostream_iterator<lap::float3>(os, " "));
    os << "\nnormals: ";
    std::copy(m._normals.begin(), m._normals.end(), std::ostream_iterator<lap::float3>(os, " "));
    os << "\nuvs: ";
    std::copy(m._uvs.begin(), m._uvs.end(), std::ostream_iterator<lap::float2>(os, " "));
    os << "\n";
    return os;
  }
  
  const string COMMENT="#";
  const string POSITION = "v";
  const string NORMAL = "vn";
  const string UV = "vt";
  const string GROUP = "g";
  const string MTL = "mtllib";
  const string USE_MTL = "usemtl";
  const string FACE = "f";
  
  typedef std::map<string, function<ObjModelPtr&(ObjModelPtr&, sregex_token_iterator args)>> ParserMap;
  
  const std::regex ws_re("\\s+");
  
  ObjModelPtr& debug_parse(ObjModelPtr& m, sregex_token_iterator iter)
  {
    std::cout << "debug_parse: ";
    std::copy(iter, sregex_token_iterator(), std::ostream_iterator<string>(std::cout, " "));
    std::cout << "\n";
    return m;
  }
  
  ObjModelPtr& identity_parse(ObjModelPtr& m, sregex_token_iterator iter)
  {
    return m;
  }
  
  template <int N>
  vec<float, N> parse_vec(std::__1::sregex_token_iterator iter) {
    vec<float, N> v;
    for (int i = 0; i < N; ++i) {
      if (iter != sregex_token_iterator()) {
        v[i] = std::stof(*iter);
        ++iter;
      }
    }
    return v;
  }
  
  ObjModelPtr& parse_position(ObjModelPtr& m, sregex_token_iterator iter) {
    m->_positions.push_back(parse_vec<3>(++iter));
    return m;
  }
  
  ObjModelPtr& parse_uv(ObjModelPtr& m, sregex_token_iterator iter) {
    m->_uvs.push_back(parse_vec<2>(++iter));
    return m;
  }
  ObjModelPtr& parse_normal(ObjModelPtr& m, sregex_token_iterator iter) {
    m->_normals.push_back(parse_vec<3>(++iter));
    return m;
  }
  
  void parse_line(const ParserMap& parsers, ObjModelPtr& model, const string& line) {
    auto word_iter = std::sregex_token_iterator(line.begin(), line.end(), ws_re, -1);
    if (word_iter == std::sregex_token_iterator() ) return;
    
    const string command = *word_iter;
    
    auto fiter = parsers.find(command);
    if (fiter != parsers.end()) {
      fiter->second(model, word_iter);
    }
    else {
      debug_parse(model, word_iter);
    }
  }
  
  
  ObjModelPtr obj_model(const std::string path) {
    
    const std::map<string, std::function<ObjModelPtr&(ObjModelPtr&, std::sregex_token_iterator args)>> parser_fns =
    {{ COMMENT, identity_parse },
      { POSITION, parse_position},
      { NORMAL, parse_normal },
      { UV, parse_uv }};
    
    std::fstream fs (path.c_str(), std::fstream::in);
    if (!fs.is_open()) return ObjModelPtr();
    
    ObjModelPtr model = ObjModelPtr(new ObjModel());
    
    std::string line;
    while (getline(fs, line)) {
      if (!line.empty()) parse_line(parser_fns, model, line);
    }
    fs.close();
    
    const ObjModel& mr = *model;
    std::cout << "Model:\n" << mr << std::endl;
    
    return model;
  }
}

