//
//  SSViewController.m
//  shadowmap
//
//  Created by Daniel Grigg on 21/06/13.
//  Copyright (c) 2013 Sliplane Software. All rights reserved.
//

#import "SSViewController.h"
#include "obj_model.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

enum
{
  UNIFORM_PROGRAM_DIFFUSE_VIEW_MATRIX,
  UNIFORM_PROGRAM_DIFFUSE_MODEL_MATRIX,
  UNIFORM_PROGRAM_DIFFUSE_PROJ_MATRIX,
  UNIFORM_PROGRAM_DIFFUSE_MODELVIEWPROJECTION_MATRIX,
  UNIFORM_PROGRAM_DIFFUSE_NORMAL_MATRIX,
  UNIFORM_PROGRAM_DIFFUSE_COLOR_MAP,
  UNIFORM_PROGRAM_DIFFUSE_DEPTH_MAP,
  UNIFORM_PROGRAM_DIFFUSE_LIGHT_VIEW_PROJ,
  UNIFORM_PROGRAM_DIFFUSE_INV_CAMERA_VIEW_PROJ,
  UNIFORM_PROGRAM_DIFFUSE_INV_PROJ,
  UNIFORM_PROGRAM_DIFFUSE_VIEWPORT,
  UNIFORM_PROGRAM_DEPTH_MODELVIEWPROJECTION_MATRIX,
  UNIFORM_PROGRAM_DEPTH_NORMAL_MATRIX,
  UNIFORM_PROGRAM_DEPTH_COLOR_MAP,
  UNIFORM_PROGRAM_DIFFUSE_LIGHT_POSITION_WORLD,
  NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
  ATTRIB_VERTEX,
  ATTRIB_NORMAL,
  NUM_ATTRIBUTES
};
using lap::float3;
using lap::float2;
using lap::float4;

void export_framebuffer(int w, int h)
{
  std::vector<uint8_t> pixels(w * h * 4);
  glReadPixels(0, 0, w, h, GL_RGB, GL_UNSIGNED_BYTE, &pixels[0]);
}

struct PositionUVNormal {
  float3 _position;
  float2 _uv;
  float3 _normal;
};

std::ostream& operator<<(std::ostream& os, const PositionUVNormal& rhs) {
  os << "{:position " << rhs._position << " :uv " << rhs._uv
  << " :normal " << rhs._normal << "}";
  return os;
  }
  
  struct TriangleMesh { std::vector<PositionUVNormal> _vertices; };
  
  typedef std::shared_ptr<TriangleMesh> TriangleMeshPtr;
  TriangleMeshPtr make_triangle_mesh(const lap::ObjModelPtr& model) {
    
    auto mesh = TriangleMeshPtr(new TriangleMesh());
    mesh->_vertices.reserve(3 * model->_faces.size());
    for (int i =0; i < model->_faces.size(); ++i)  {
      for (int j = 0; j < 3; ++j) {
        auto& indices = model->_faces[i].vertex[j];
        
        if (!model->_uvs.empty()) {
          mesh->_vertices.push_back({
          model->_positions[indices[0]],
          model->_uvs[indices[1]],
          model->_normals[indices[2]]});
        }
      }
    }
    return mesh;
  }
  
  enum
  {
    MESH_PLANE,
    MESH_OBJECT,
    MESH_MAX
  };
  
  TriangleMeshPtr load_mesh(NSString* name)
  {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource: name ofType: @"obj"];
    if (path == nil) {
      std::cerr << "FAIL loading " << name.UTF8String << "\n";
      return TriangleMeshPtr();
    }
    auto model = lap::obj_model(path.UTF8String);
    std::cout << "Mesh " << name.UTF8String << "\n";
    std::cout << "#positions " << model->_positions.size() << "\n";
    std::cout << "#faces " << model->_faces.size() << "\n";
    return make_triangle_mesh(model);
  }
  
  struct VAO
  {
    GLuint name;
    GLuint vertex_buffer_name;
    float3 scale;
    float4 rotation;
    float3 translation;
    TriangleMeshPtr mesh;
    
    VAO():name(0), vertex_buffer_name(0) {
      scale = {1.0, 1.0, 1.0};
      rotation = {0.0, 1.0, 0.0, 0.0};
      translation = {0, 0, 0};
    }
  };
  
  enum
  {
    TEXTURE_STATIC,
    TEXTURE_LIGHT_COLOR,
    TEXTURE_LIGHT_DEPTH,
    TEXTURE_MAX
  };
  
  enum
  {
    PROGRAM_DEPTH,
    PROGRAM_SHADER,
    PROGRAM_MAX
  };
    
  GLuint g_textures[TEXTURE_MAX];
  GLuint g_fb_light;
  int g_fb_light_width = 1024;
  int g_fb_light_height = 1024;
  VAO g_vao[MESH_MAX];
  
  void light_framebuffer() {
    
    glGetError();
    
    GLint default_framebuffer;
    GLint default_renderbuffer;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &default_framebuffer);
    glGetIntegerv(GL_RENDERBUFFER_BINDING, &default_renderbuffer);
    
    glGenFramebuffers(1, &g_fb_light);
    glBindFramebuffer(GL_FRAMEBUFFER, g_fb_light);
    
    glGenTextures(1, &g_textures[TEXTURE_LIGHT_COLOR]);
    glBindTexture(GL_TEXTURE_2D, g_textures[TEXTURE_LIGHT_COLOR]);    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,  g_fb_light_width, g_fb_light_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, g_textures[TEXTURE_LIGHT_COLOR], 0);

    glGenTextures(1, &g_textures[TEXTURE_LIGHT_DEPTH]);
    glBindTexture(GL_TEXTURE_2D, g_textures[TEXTURE_LIGHT_DEPTH]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, g_fb_light_width, g_fb_light_height, 0,
                 GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, NULL);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, g_textures[TEXTURE_LIGHT_DEPTH], 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER) ;
    if(status != GL_FRAMEBUFFER_COMPLETE) {
      NSLog(@"failed to make complete framebuffer object %x", status);
    }
    glUseProgram(0);
    glBindVertexArrayOES(0);
    glClearColor(1.0, 0.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glBindFramebuffer(GL_FRAMEBUFFER, default_framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, default_renderbuffer);
    assert(glGetError() == GL_NO_ERROR);
  }
  
  float frand() {
    return (double)(random() % RAND_MAX) / (double)RAND_MAX;
  }
  
  std::vector<uint8_t> circle_texture(int w)
  {
    std::vector<uint8_t> c(w * w);
    int r = w / 2;
    for (int j = 0; j < w; ++j) {
      for (int i = 0; i < w; ++i) {
        int x = i - r;
        int y = j - r;
        
        float l = (sqrt(x*x + y*y) / r) + 0.005 * frand();
        l = std::min(1.0f, std::max(0.0f, l));
        l = cos(3.0 * sqrt(x*x + y*y) / r);
        l = std::min(1.0f, std::max(0.0f, l));
        c[j * w + i] = 255.0 * l;
      }
    }
    return c;
  }
  
  GLuint make_static_test_texture() {
    glGetError();
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    auto w = 1024;
    auto data3 = circle_texture(w);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, w, w, 0, GL_LUMINANCE,
                 GL_UNSIGNED_BYTE, &data3[0]);    
    glGenerateMipmap(GL_TEXTURE_2D);    
    assert(glGetError() == GL_NO_ERROR);
    return texture;
  }
  
  @interface SSViewController () {
    GLuint _programs[PROGRAM_MAX];
    float _time;
  }
  @property (strong, nonatomic) EAGLContext *context;
  
  - (void)setupGL;
  - (void)tearDownGL;
  
  - (BOOL)load_depth_render_shader;
  - (BOOL)load_diffuse_shader;
  - (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
  - (BOOL)linkProgram:(GLuint)prog;
  - (BOOL)validateProgram:(GLuint)prog;
  @end
  
  @implementation SSViewController
  
  - (void)viewDidLoad
  {
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context)
    {
      NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];    
  }
  
  - (void)dealloc
  {
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
      [EAGLContext setCurrentContext:nil];
    }
  }
  
  - (void)didReceiveMemoryWarning
  {
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
      self.view = nil;
      
      [self tearDownGL];
      
      if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
      }
      self.context = nil;
    }
  }  
  
  VAO make_vao(TriangleMeshPtr from_mesh, float3 scale, float4 rotation, float3 translation) {
    VAO v;
    v.scale = scale;
    v.rotation = rotation;
    v.translation = translation;
    v.mesh.swap(from_mesh);
    glGenVertexArraysOES(1, &v.name);
    glBindVertexArrayOES(v.name);
    
    glGenBuffers(1, &v.vertex_buffer_name);
    glBindBuffer(GL_ARRAY_BUFFER, v.vertex_buffer_name);
    
    glBufferData(GL_ARRAY_BUFFER, v.mesh->_vertices.size() * sizeof(PositionUVNormal),
                 &v.mesh->_vertices[0], GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE,
                          sizeof(PositionUVNormal), BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE,
                          sizeof(PositionUVNormal),
                          BUFFER_OFFSET(sizeof(float3) + sizeof(float2)));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE,
                          sizeof(PositionUVNormal), BUFFER_OFFSET(sizeof(float3)));    
    glBindVertexArrayOES(0);
    return v;
  }
  
  - (void)setupGL
  {
    [EAGLContext setCurrentContext:self.context];
    
    [self load_depth_render_shader];
    [self load_diffuse_shader];
        
    g_vao[MESH_PLANE] = make_vao(load_mesh(@"sphere"),
                                 {4.0, 0.40, 4.0},
                                 {0.0, 1.0, 0.0, 0.0},
                                 {0, -2.0, 0.0});
    
    g_vao[MESH_OBJECT] = make_vao(load_mesh(@"sphere"),
                                  {0.4, 1.0, 2.6},
                                  {20.0, 0.3, 1.0, 0.0},
                                  {0.0, 1.0, 0.0});
    
    g_textures[TEXTURE_STATIC] = make_static_test_texture();
    
    light_framebuffer();
    
    glEnable(GL_CULL_FACE);

    assert(glGetError() == GL_NO_ERROR);
  }
  
  - (void)tearDownGL
  {
    [EAGLContext setCurrentContext:self.context];
    
    for (int i = 0; i < MESH_MAX; ++i) {
      if (g_vao[i].vertex_buffer_name) glDeleteBuffers(1, &g_vao[i].vertex_buffer_name);
      if (g_vao[i].name) glDeleteVertexArraysOES(1, &g_vao[i].name);
    }
    
    for (auto x : _programs) {
      if (x) {
        glDeleteProgram(x);
      }
    }
  }
  
#pragma mark - GLKView and GLKViewController delegate methods
  
  void light_position(float t, float pos[])
  {
    pos[0] = 10.0f;
    pos[1] = 7.0f + 6 * sin(t);
    pos[2] = 2.0 + 4.0 * cos(t);
    pos[3] = 1.0f;
  }
  
  GLKMatrix4 make_light_view_matrix(float t) {
    float pos[4];
    light_position(t, pos);
    return GLKMatrix4MakeLookAt(pos[0], pos[1], pos[2],
                                0.0f, 0.0f, 0.0f,
                                0.0f, 1.0f, 0.0f);
  }
  
  GLKMatrix4 make_camera_view_matrix(float t) {
    return GLKMatrix4MakeLookAt(2.0f, 8.0, 12.0,
                                0.0f, 0.0f, 0.0f,
                                0.0f, 1.0f, 0.0f);
  }
  
  GLKMatrix4 make_camera_projection_matrix(float aspect) {
    return GLKMatrix4MakePerspective(GLKMathDegreesToRadians(38), aspect, 9.0f, 20.0f);
  }
  
  GLKMatrix4 make_light_projection_matrix(float aspect) {
    return GLKMatrix4MakePerspective(GLKMathDegreesToRadians(38), aspect, 9.0f, 20.0f);
  }
  
  void upload_transformations(GLKMatrix4 projection,
                              GLKMatrix4 view,
                              GLKMatrix4 model,
                              GLuint uniform_model,
                              GLuint uniform_view,
                              GLuint uniform_proj,
                              GLuint uniform_mvp,
                              GLuint uniform_normal) {
    auto model_view = GLKMatrix4Multiply(view, model);
    auto normal = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(model_view), NULL);
    auto model_view_projection = GLKMatrix4Multiply(projection, model_view);
    
    if (uniform_model != -1) glUniformMatrix4fv(uniform_model, 1, 0, model.m);
    if (uniform_view != -1) glUniformMatrix4fv(uniform_view, 1, 0, view.m);
    if (uniform_proj != -1) glUniformMatrix4fv(uniform_proj, 1, 0, projection.m);
    if (uniform_mvp != -1) glUniformMatrix4fv(uniform_mvp, 1, 0, model_view_projection.m);
    if (uniform_normal != -1) glUniformMatrix3fv(uniform_normal, 1, 0, normal.m);
  }
  
  - (void)update
  {
    _time += self.timeSinceLastUpdate * 0.5f;
  }
  
  void draw_vao(GLKMatrix4 projection,
                GLKMatrix4 view,
                float t,
                GLuint uniform_model,
                GLuint uniform_view,
                GLuint uniform_proj,
                GLuint uniform_model_view_projection,
                GLuint uniform_normal) {
    for (int i = 0; i < MESH_MAX; ++i) {
      auto & v = g_vao[i];
      if (v.name) {
        assert(glGetError() == GL_NO_ERROR);
        auto model_matrix = GLKMatrix4Identity;
        model_matrix = GLKMatrix4RotateY(model_matrix, 0.4 * t);
        model_matrix = GLKMatrix4Rotate(model_matrix, GLKMathDegreesToRadians(v.rotation[0]),
                                        v.rotation[1], v.rotation[2], v.rotation[3]);
        model_matrix = GLKMatrix4Scale(model_matrix, v.scale[0], v.scale[1], v.scale[2]);
        model_matrix = GLKMatrix4Translate(model_matrix, v.translation[0], v.translation[1], v.translation[2]);
                
        upload_transformations(projection, view, model_matrix,
                               uniform_model,
                               uniform_view,
                               uniform_proj,
                               uniform_model_view_projection,
                               uniform_normal);
        glBindVertexArrayOES(g_vao[i].name);
        glDrawArrays(GL_TRIANGLES, 0, g_vao[i].mesh->_vertices.size());
      }
    }
  }
  
  float fb_light_aspect() {
    return (float)g_fb_light_width / (float)g_fb_light_height;
  }
  
  void draw_light_view(GLuint program, float t) {
    glBindFramebuffer(GL_FRAMEBUFFER, g_fb_light);
    glViewport(0, 0, g_fb_light_width, g_fb_light_height);
    
    glClearColor(1.0f, 0.0f, 1.0f, 1.0f);
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    glUseProgram(program);
    glEnable(GL_DEPTH_TEST);
    glCullFace(GL_FRONT);
    draw_vao(make_light_projection_matrix(fb_light_aspect()),
             make_light_view_matrix(t), t, -1, -1, -1,
             uniforms[UNIFORM_PROGRAM_DEPTH_MODELVIEWPROJECTION_MATRIX], -1);
    glCullFace(GL_BACK);
  }
    
  - (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
  {
    glGetError();
    GLint old_fbo;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &old_fbo);
    GLint old_viewport[4];
    glGetIntegerv(GL_VIEWPORT, old_viewport);
    draw_light_view(_programs[PROGRAM_DEPTH], _time);
    glBindFramebuffer(GL_FRAMEBUFFER, old_fbo);
    glViewport(old_viewport[0], old_viewport[1], old_viewport[2], old_viewport[3]);
    
    glClearColor(0.25f, 0.25f, 0.25f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(_programs[PROGRAM_SHADER]);
    
    glUniform4f(uniforms[UNIFORM_PROGRAM_DIFFUSE_VIEWPORT], old_viewport[0],
                old_viewport[1], old_viewport[2], old_viewport[3]);
    auto aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    auto proj = make_camera_projection_matrix(aspect);
    auto camera_view_proj = GLKMatrix4Multiply(proj, make_camera_view_matrix(_time));
    
    bool invertible;
    auto inv_camera_view_proj = GLKMatrix4Invert(camera_view_proj, &invertible);
    auto inv_proj = GLKMatrix4Invert(proj, &invertible);
    glUniformMatrix4fv(uniforms[UNIFORM_PROGRAM_DIFFUSE_INV_CAMERA_VIEW_PROJ], 1, 0, inv_camera_view_proj.m);
    glUniformMatrix4fv(uniforms[UNIFORM_PROGRAM_DIFFUSE_INV_PROJ], 1, 0, inv_proj.m);

    auto light_view_proj = GLKMatrix4Multiply(make_light_projection_matrix(fb_light_aspect()),
                                              make_light_view_matrix(_time));
    glUniformMatrix4fv(uniforms[UNIFORM_PROGRAM_DIFFUSE_LIGHT_VIEW_PROJ], 1, 0, light_view_proj.m);
    float pos[4]; light_position(_time, pos);
    glUniform4fv(uniforms[UNIFORM_PROGRAM_DIFFUSE_LIGHT_POSITION_WORLD], 1, pos);
    glEnable(GL_DEPTH_TEST);
    glActiveTexture(GL_TEXTURE0);
    glUniform1i(uniforms[UNIFORM_PROGRAM_DIFFUSE_COLOR_MAP], 0);
    glBindTexture(GL_TEXTURE_2D, g_textures[TEXTURE_STATIC]);
    glActiveTexture(GL_TEXTURE1);
    glUniform1i(uniforms[UNIFORM_PROGRAM_DIFFUSE_DEPTH_MAP], 1);
    glBindTexture(GL_TEXTURE_2D, g_textures[TEXTURE_LIGHT_DEPTH]);
//    glGenerateMipmap(GL_TEXTURE_2D);
    bool render_from_light = false;
    
    draw_vao(render_from_light ? make_light_projection_matrix(aspect) : make_camera_projection_matrix(aspect),
             render_from_light ? make_light_view_matrix(_time) : make_camera_view_matrix(_time),
             _time,
             uniforms[UNIFORM_PROGRAM_DIFFUSE_MODEL_MATRIX],
             uniforms[UNIFORM_PROGRAM_DIFFUSE_VIEW_MATRIX],
             uniforms[UNIFORM_PROGRAM_DIFFUSE_PROJ_MATRIX],
             uniforms[UNIFORM_PROGRAM_DIFFUSE_MODELVIEWPROJECTION_MATRIX],
             uniforms[UNIFORM_PROGRAM_DIFFUSE_NORMAL_MATRIX]);
    glBindTexture(GL_TEXTURE_2D, 0);
    assert(glGetError() == GL_NO_ERROR);
  }
  
#pragma mark -  OpenGL ES 2 shader compilation
  
  - (BOOL)load_diffuse_shader {
    GLuint vertShader, fragShader;
    
    _programs[PROGRAM_SHADER] = glCreateProgram();
    NSString *vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
      NSLog(@"Failed to compile vertex shader");
      return NO;
    }
    NSString* fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
      NSLog(@"Failed to compile fragment shader");
      return NO;
    }
    glAttachShader(_programs[PROGRAM_SHADER], vertShader);
    glAttachShader(_programs[PROGRAM_SHADER], fragShader);
    
    glBindAttribLocation(_programs[PROGRAM_SHADER], GLKVertexAttribPosition, "position");
    glBindAttribLocation(_programs[PROGRAM_SHADER], GLKVertexAttribNormal, "normal");
    glBindAttribLocation(_programs[PROGRAM_SHADER], GLKVertexAttribTexCoord0, "uv");
    
    if (![self linkProgram:_programs[PROGRAM_SHADER]]) {
      NSLog(@"Failed to link program: %d", _programs[PROGRAM_SHADER]);
      if (vertShader) { glDeleteShader(vertShader); }
      if (fragShader) { glDeleteShader(fragShader); }
      if (_programs[PROGRAM_SHADER]) { glDeleteProgram(_programs[PROGRAM_SHADER]); }
      return NO;
    }
    
    uniforms[UNIFORM_PROGRAM_DIFFUSE_INV_PROJ] = glGetUniformLocation(_programs[PROGRAM_SHADER], "inv_proj");
    uniforms[UNIFORM_PROGRAM_DIFFUSE_MODEL_MATRIX] = glGetUniformLocation(_programs[PROGRAM_SHADER], "modelMatrix");
    uniforms[UNIFORM_PROGRAM_DIFFUSE_VIEW_MATRIX] = glGetUniformLocation(_programs[PROGRAM_SHADER], "viewMatrix");
    uniforms[UNIFORM_PROGRAM_DIFFUSE_PROJ_MATRIX] = glGetUniformLocation(_programs[PROGRAM_SHADER], "projMatrix");
    uniforms[UNIFORM_PROGRAM_DIFFUSE_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_programs[PROGRAM_SHADER], "modelViewProjectionMatrix");
    uniforms[UNIFORM_PROGRAM_DIFFUSE_NORMAL_MATRIX] = glGetUniformLocation(_programs[PROGRAM_SHADER], "normalMatrix");
    uniforms[UNIFORM_PROGRAM_DIFFUSE_COLOR_MAP] = glGetUniformLocation(_programs[PROGRAM_SHADER], "colorMap");
    uniforms[UNIFORM_PROGRAM_DIFFUSE_DEPTH_MAP] = glGetUniformLocation(_programs[PROGRAM_SHADER], "depthMap");
    uniforms[UNIFORM_PROGRAM_DIFFUSE_LIGHT_VIEW_PROJ] = glGetUniformLocation(_programs[PROGRAM_SHADER], "light_view_proj");
    uniforms[UNIFORM_PROGRAM_DIFFUSE_INV_CAMERA_VIEW_PROJ] = glGetUniformLocation(_programs[PROGRAM_SHADER], "inv_camera_view_proj");
    uniforms[UNIFORM_PROGRAM_DIFFUSE_VIEWPORT] = glGetUniformLocation(_programs[PROGRAM_SHADER], "viewport");
    uniforms[UNIFORM_PROGRAM_DIFFUSE_LIGHT_POSITION_WORLD] = glGetUniformLocation(_programs[PROGRAM_SHADER], "light_pos_world");    
    
    if (vertShader) {
      glDetachShader(_programs[PROGRAM_SHADER], vertShader);
      glDeleteShader(vertShader);
    }
    if (fragShader) {
      glDetachShader(_programs[PROGRAM_SHADER], fragShader);
      glDeleteShader(fragShader);
    }
    return YES;
  }
  
  - (BOOL)load_depth_render_shader {
    GLuint vertShader, fragShader;
    
    _programs[PROGRAM_DEPTH] = glCreateProgram();
    NSString *vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"depth_render" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
      NSLog(@"Failed to compile vertex shader");
      return NO;
    }
    NSString* fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"depth_render" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
      NSLog(@"Failed to compile fragment shader");
      return NO;
    }
    glAttachShader(_programs[PROGRAM_DEPTH], vertShader);
    glAttachShader(_programs[PROGRAM_DEPTH], fragShader);
    
    glBindAttribLocation(_programs[PROGRAM_DEPTH], GLKVertexAttribPosition, "position");
    glBindAttribLocation(_programs[PROGRAM_DEPTH], GLKVertexAttribNormal, "normal");
    glBindAttribLocation(_programs[PROGRAM_DEPTH], GLKVertexAttribTexCoord0, "uv");
    
    if (![self linkProgram:_programs[PROGRAM_DEPTH]]) {
      NSLog(@"Failed to link program: %d", _programs[PROGRAM_DEPTH]);
      if (vertShader) { glDeleteShader(vertShader); }
      if (fragShader) { glDeleteShader(fragShader); }
      if (_programs[PROGRAM_DEPTH]) { glDeleteProgram(_programs[PROGRAM_DEPTH]); }
      return NO;
    }
    
    uniforms[UNIFORM_PROGRAM_DEPTH_MODELVIEWPROJECTION_MATRIX] =
    glGetUniformLocation(_programs[PROGRAM_DEPTH], "modelViewProjectionMatrix");
    
    if (vertShader) {
      glDetachShader(_programs[PROGRAM_DEPTH], vertShader);
      glDeleteShader(vertShader);
    }
    if (fragShader) {
      glDetachShader(_programs[PROGRAM_DEPTH], fragShader);
      glDeleteShader(fragShader);
    }
    return YES;
  }  
  
  - (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
  {
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file
                                                  encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
      NSLog(@"Failed to load vertex shader");
      return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
      GLchar *log = (GLchar *)malloc(logLength);
      glGetShaderInfoLog(*shader, logLength, &logLength, log);
      NSLog(@"Shader compile log:\n%s", log);
      free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
      glDeleteShader(*shader);
      return NO;
    }
    
    return YES;
  }
  
  - (BOOL)linkProgram:(GLuint)prog
  {
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
      GLchar *log = (GLchar *)malloc(logLength);
      glGetProgramInfoLog(prog, logLength, &logLength, log);
      NSLog(@"Program link log:\n%s", log);
      free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
      return NO;
    }
    
    return YES;
  }
  
  - (BOOL)validateProgram:(GLuint)prog
  {
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
      GLchar *log = (GLchar *)malloc(logLength);
      glGetProgramInfoLog(prog, logLength, &logLength, log);
      NSLog(@"Program validate log:\n%s", log);
      free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
      return NO;
    }
    
    return YES;
  }
  
  @end
