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

// Uniform index.
enum
{
  UNIFORM_MODELVIEWPROJECTION_MATRIX,
  UNIFORM_NORMAL_MATRIX,
  UNIFORM_COLOR_MAP,
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

#if 0
struct PositionNormal {
  float3 _position;
  float3 _normal;
};
std::ostream& operator<<(std::ostream& os, const PositionNormal& rhs) {
  os << "{:position " << rhs._position
  << " :normal " << rhs._normal << "}";
  return os;
}
#endif
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


//struct TriangleMesh {
//  std::vector<PositionNormal> _vertices;
//};
struct TriangleMesh {
    std::vector<PositionUVNormal> _vertices;
  };

typedef std::unique_ptr<TriangleMesh> TriangleMeshPtr;
TriangleMeshPtr make_triangle_mesh(const lap::ObjModelPtr& model) {
  
  auto mesh = TriangleMeshPtr(new TriangleMesh());
  mesh->_vertices.reserve(3 * model->_faces.size());
  for (int i =0; i < model->_faces.size(); ++i)  {
    for (int j = 0; j < 3; ++j) {
      auto& indices = model->_faces[i].vertex[j];
      
      if (model->_uvs.empty()) {
      //mesh->_vertices.push_back({ model->_positions[indices[0]], model->_normals[indices[2]]});
      }
      else {
        mesh->_vertices.push_back({
        model->_positions[indices[0]],
        model->_uvs[indices[1]],
        model->_normals[indices[2]]});
      }
    }

  }
  return mesh;
}

TriangleMeshPtr gMesh;

void load_mesh() {
  NSBundle *mainBundle = [NSBundle mainBundle];
  NSString *myFile = [mainBundle pathForResource: @"quad_pnt" ofType: @"obj"];
  if (myFile == nil) return;
  
  NSLog(@"Main bundle path: %@", mainBundle);
  NSLog(@"myFile path: %@", myFile);
  auto model = lap::obj_model(myFile.UTF8String);
  
  std::cout << "#positions " << model->_positions.size() << "\n";
  std::cout << "#faces " << model->_faces.size() << "\n";
  
  gMesh = make_triangle_mesh(model);
}

GLuint g_fb_light;
GLuint g_fb_light_texture;
int g_fb_light_width = 512;
int g_fb_light_height = 512;

void light_framebuffer() {

  glGetError();
  
  GLint default_framebuffer;
  GLint default_renderbuffer;
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &default_framebuffer);
  glGetIntegerv(GL_RENDERBUFFER_BINDING, &default_renderbuffer);

  glGenFramebuffers(1, &g_fb_light);
  glBindFramebuffer(GL_FRAMEBUFFER, g_fb_light);
  
  // create the texture
  glGenTextures(1, &g_fb_light_texture);
  glBindTexture(GL_TEXTURE_2D, g_fb_light_texture);
  
  GLint min_filter, mag_filter, wrap_s, wrap_t;
  glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, &min_filter);
  glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, &mag_filter);
  glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, &wrap_s);
  glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, &wrap_t);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR_MIPMAP_LINEAR);

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,  g_fb_light_width, g_fb_light_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
  glGenerateMipmap(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, 0);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, g_fb_light_texture, 0);
  
  GLuint depthRenderbuffer;
  glGenRenderbuffers(1, &depthRenderbuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, g_fb_light_width, g_fb_light_height);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
  
  GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER) ;
  if(status != GL_FRAMEBUFFER_COMPLETE) {
    NSLog(@"failed to make complete framebuffer object %x", status);
  }
  assert(glGetError() == GL_NO_ERROR);
  
  glUseProgram(0);
  glBindVertexArrayOES(0);
  glClearColor(1.0f, 0.5f, 0.0f, 0.0f);
  glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
  glClear(GL_COLOR_BUFFER_BIT);
  glBindFramebuffer(GL_FRAMEBUFFER, default_framebuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, default_renderbuffer);
  
  glBindTexture(GL_TEXTURE_2D, g_fb_light_texture);
  glGenerateMipmap(GL_TEXTURE_2D);
  assert(glGetError() == GL_NO_ERROR);
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
  
  uint8_t texture_data[] = { 0, 255, 0, 255,
    0, 0, 255, 255,
    255, 0, 0, 255,
    255, 255, 0, 255 };  

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, 0,
               GL_RGBA, GL_UNSIGNED_BYTE, &texture_data[0]);
  glGenerateMipmap(GL_TEXTURE_2D);

  assert(glGetError() == GL_NO_ERROR);
  return texture;
}

GLuint g_static_texture;

@interface SSViewController () {
  GLuint _program;
  
  GLKMatrix4 _modelViewProjectionMatrix;
  GLKMatrix3 _normalMatrix;
  float _rotation;
  
  GLuint _vertexArray;
  GLuint _vertexBuffer;
}
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation SSViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  
  if (!self.context) {
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
  
  // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
  [EAGLContext setCurrentContext:self.context];
  
  [self loadShaders];
  
  glEnable(GL_DEPTH_TEST);
  
  load_mesh();
  
  glGenVertexArraysOES(1, &_vertexArray);
  glBindVertexArrayOES(_vertexArray);
  
  glGenBuffers(1, &_vertexBuffer);
  glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
  glBufferData(GL_ARRAY_BUFFER, gMesh->_vertices.size() * sizeof(PositionUVNormal),
               &gMesh->_vertices[0], GL_STATIC_DRAW);
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE,
                        sizeof(PositionUVNormal), BUFFER_OFFSET(0));
  glEnableVertexAttribArray(GLKVertexAttribNormal);
  glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE,
                        sizeof(PositionUVNormal),  BUFFER_OFFSET(sizeof(float3) + sizeof(float2)));

  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE,
                        sizeof(PositionUVNormal), BUFFER_OFFSET(sizeof(float3)));

  glBindVertexArrayOES(0);
  
  g_static_texture = make_static_test_texture();
  
  light_framebuffer();
  
  assert(glGetError() == GL_NO_ERROR);

}

- (void)tearDownGL
{
  [EAGLContext setCurrentContext:self.context];
  
  glDeleteBuffers(1, &_vertexBuffer);
  glDeleteVertexArraysOES(1, &_vertexArray);
  
  if (_program) {
    glDeleteProgram(_program);
    _program = 0;
  }
}

#pragma mark - GLKView and GLKViewController delegate methods

GLKMatrix4 make_light_view_matrix() {
    return GLKMatrix4MakeLookAt(10.0f, 10, 8.0, 0.0f, -0.5f, -0.5f, 0.0f, 1.0f, 0.0f);
}

GLKMatrix4 make_camera_view_matrix() {
  return GLKMatrix4MakeLookAt(2.0f, 13, 13, 0.0f, 0.0f, -0.5f, -0.5f, 1.0f, 0.0f);
}

GLKMatrix4 make_model_matrix(float rotation) {
  auto modelMatrix = GLKMatrix4MakeScale(8.0, 8.0, 8.0);
//  modelMatrix = GLKMatrix4Rotate(modelMatrix, GLKMathDegreesToRadians(-90.0), 0.0f, 0.0f, 0.0f);
  modelMatrix = GLKMatrix4Rotate(modelMatrix, rotation, 0.0f, 0.0f, 1.0f);
  modelMatrix = GLKMatrix4Translate(modelMatrix, -0.5, -0.5, 0.0);
  return modelMatrix;
}

void upload_transformations(GLKMatrix4 projection, GLKMatrix4 view, GLKMatrix4 model) {
  auto model_view = GLKMatrix4Multiply(view, model);
  auto normal = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(model_view), NULL);
  auto model_view_projection = GLKMatrix4Multiply(projection, model_view);
  
  glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, model_view_projection.m);
  glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, normal.m);
}

- (void)update
{  
  _rotation += self.timeSinceLastUpdate * 0.5f;
}

void draw_light_view(GLuint program, GLuint vao, float rotation) {
  
  glBindFramebuffer(GL_FRAMEBUFFER, g_fb_light);
  glViewport(0, 0, g_fb_light_width, g_fb_light_height);
  
  glClearColor(1.0f, 0.2f, 1.0f, 0.0f);
  glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
  glUseProgram(program);
  glBindVertexArrayOES(vao);
  glEnable(GL_DEPTH_TEST);

  glUniform1i(uniforms[UNIFORM_COLOR_MAP], 0);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, g_static_texture);

  float aspect = 1.0;

  upload_transformations(GLKMatrix4MakePerspective(GLKMathDegreesToRadians(38), aspect, 1.0f, 1000.0f),
                         make_light_view_matrix(),
                         make_model_matrix(rotation));

  glDrawArrays(GL_TRIANGLES, 0, gMesh->_vertices.size());

  assert(glGetError() == GL_NO_ERROR);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
  glGetError();

  GLint old_fbo;
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &old_fbo);
  GLint old_viewport[4];
  glGetIntegerv(GL_VIEWPORT, old_viewport);
  draw_light_view(_program, _vertexArray, _rotation);
  glBindFramebuffer(GL_FRAMEBUFFER, old_fbo);
  glViewport(old_viewport[0], old_viewport[1], old_viewport[2], old_viewport[3]);
  
  glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
  glBindVertexArrayOES(_vertexArray);
  
  glUseProgram(_program);
  glUniform1i(uniforms[UNIFORM_COLOR_MAP], 0);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, g_fb_light_texture);
  
  bool render_from_light = false;
  if (render_from_light) {
    glBindTexture(GL_TEXTURE_2D, g_static_texture);
  }
  glGenerateMipmap(GL_TEXTURE_2D);

  float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
  upload_transformations(GLKMatrix4MakePerspective(GLKMathDegreesToRadians(38), aspect, 1.0f, 1000.0f),
                         render_from_light ? make_light_view_matrix() : make_camera_view_matrix(),
                         make_model_matrix(_rotation));
  
  glDrawArrays(GL_TRIANGLES, 0, gMesh->_vertices.size());
  glBindTexture(GL_TEXTURE_2D, 0);
  
  assert(glGetError() == GL_NO_ERROR);
  
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
  glGetError();
  GLuint vertShader, fragShader;
  NSString *vertShaderPathname, *fragShaderPathname;
  
  // Create shader program.
  _program = glCreateProgram();
  
  // Create and compile vertex shader.
  vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
  if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
    NSLog(@"Failed to compile vertex shader");
    return NO;
  }
  
  // Create and compile fragment shader.
  fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
  if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
    NSLog(@"Failed to compile fragment shader");
    return NO;
  }
  
  // Attach vertex shader to program.
  glAttachShader(_program, vertShader);
  
  // Attach fragment shader to program.
  glAttachShader(_program, fragShader);
  
  // Bind attribute locations.
  // This needs to be done prior to linking.
  glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
  glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    glBindAttribLocation(_program, GLKVertexAttribTexCoord0, "uv");
    assert(glGetError() == GL_NO_ERROR);
  // Link program.
  if (![self linkProgram:_program]) {
    NSLog(@"Failed to link program: %d", _program);
    
    if (vertShader) {
      glDeleteShader(vertShader);
      vertShader = 0;
    }
    if (fragShader) {
      glDeleteShader(fragShader);
      fragShader = 0;
    }
    if (_program) {
      glDeleteProgram(_program);
      _program = 0;
    }
    
    return NO;
  }
  
  // Get uniform locations.
  uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
  uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
  uniforms[UNIFORM_COLOR_MAP] = glGetUniformLocation(_program, "colorMap");
  
  // Release vertex and fragment shaders.
  if (vertShader) {
    glDetachShader(_program, vertShader);
    glDeleteShader(vertShader);
  }
  if (fragShader) {
    glDetachShader(_program, fragShader);
    glDeleteShader(fragShader);
  }
    assert(glGetError() == GL_NO_ERROR);
  return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
  GLint status;
  const GLchar *source;
  
  source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
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
