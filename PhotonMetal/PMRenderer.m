//
//  PMRenderer.m
//  PhotonMetal
//
//  Created by realxie on 2019/1/2.
//  Copyright © 2019 realxie. All rights reserved.
//

@import simd;
@import MetalKit;
#import <GLKit/GLKMath.h>

#import "PMRenderer.h"
#import "Matrix4.h"

float vertices[] = {0, 0, 0, 0.5, 0.5, -1, -1, 0, 0, 0,  1, -1, 0, 1, 0};
float color [] = {0.0, 1.0, 1.0, 1.0};

float cubeVertices[] = {
    // front
    -1.0, -1.0,  1.0, 1.0, 0.0, 0.0,
    1.0, -1.0,  1.0, 0.0, 1.0, 0.0,
    1.0,  1.0,  1.0, 0.0, 0.0, 1.0,
    -1.0,  1.0,  1.0, 1.0, 1.0, 1.0,
    // back
    -1.0, -1.0, -1.0, 1.0, 0.0, 0.0,
    1.0, -1.0, -1.0, 0.0, 1.0, 0.0,
    1.0,  1.0, -1.0, 0.0, 0.0, 1.0,
    -1.0,  1.0, -1.0, 1.0, 1.0, 1.0
};

short cubeIndices[] = {
    // front
    0, 1, 2,
    2, 3, 0,
    // right
    1, 5, 6,
    6, 2, 1,
    // back
    7, 6, 5,
    5, 4, 7,
    // left
    4, 0, 3,
    3, 7, 4,
    // bottom
    4, 5, 1,
    1, 0, 4,
    // top
    3, 2, 6,
    6, 7, 3
};

int _width = 1080;
int _height = 1920;

@implementation PMRenderer
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _queue;
    id<MTLBuffer> _vBuffer;
    id<MTLLibrary> _library;
    id<MTLFunction> _vertexFunction;
    id<MTLFunction> _fragmentFunction;
    id<MTLBuffer> _vArgumentBuffer;
    id<MTLBuffer> _fArgumentBuffer;
    id<MTLTexture> _texture;
    id<MTLSamplerState> _sampler;
    
    id<MTLTexture> _renderTextureColor;
    id<MTLTexture> _renderTextureDepth;
    id<MTLTexture> _renderTextureStencil;
    
    // cube
    id<MTLBuffer> _cubeVerticeBuffer;
    id<MTLBuffer> _cubeIndiceBuffer;
    id<MTLFunction> _cubeVertexFunction;
    id<MTLFunction> _cubeFragmentFunction;
    id<MTLBuffer> _cubeVertexAB;
    GLKMatrix4 _mvMatrix;
    GLKMatrix4 _pMatrix;
    float _rotatedAngle;
}

-(id)init
{
    _rotatedAngle = 0;
    return self;
}

-(nonnull instancetype) initWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    _device = mtkView.device;
    _queue = [_device newCommandQueue];
    _vBuffer = [_device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceCPUCacheModeDefaultCache];
    _library = [_device newDefaultLibrary];
    _vertexFunction = [_library newFunctionWithName:@"vertex_shader"];
    _fragmentFunction = [_library newFunctionWithName:@"fragment_shader"];
    
    id<MTLArgumentEncoder> vargumentEncoder = [_vertexFunction newArgumentEncoderWithBufferIndex:1];
    _vArgumentBuffer = [_device newBufferWithLength:vargumentEncoder.encodedLength options:0];
    
    id<MTLArgumentEncoder> fargumentEncoder = [_fragmentFunction newArgumentEncoderWithBufferIndex:10];
    _fArgumentBuffer = [_device newBufferWithLength:fargumentEncoder.encodedLength options:0];
    
    NSString *path = [[NSBundle mainBundle]pathForResource:@"texture" ofType:@"png"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:_device];
    _texture = [loader newTextureWithData:data options:@{MTKTextureLoaderOptionSRGB: [NSNumber numberWithInt:0]} error:nil];
    
    MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
    samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.mipFilter = MTLSamplerMipFilterNotMipmapped;
    samplerDesc.normalizedCoordinates = YES;
    samplerDesc.supportArgumentBuffers = YES;
    
    _sampler = [_device newSamplerStateWithDescriptor:samplerDesc];
    
    // init render target
    MTLTextureDescriptor *renderTextureColorDescriptor = [[MTLTextureDescriptor alloc] init];
    renderTextureColorDescriptor.usage = MTLTextureUsageRenderTarget;
    renderTextureColorDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    renderTextureColorDescriptor.height = 1024;
    renderTextureColorDescriptor.width  = 1024;
    _renderTextureColor = [_device newTextureWithDescriptor:renderTextureColorDescriptor];
    
    MTLTextureDescriptor *renderTextureDepthDescriptor = [[MTLTextureDescriptor alloc] init];
    renderTextureDepthDescriptor.usage = MTLTextureUsageRenderTarget;
    renderTextureDepthDescriptor.pixelFormat = MTLPixelFormatDepth32Float;
    _renderTextureDepth = [_device newTextureWithDescriptor:renderTextureDepthDescriptor];
    
    MTLTextureDescriptor *renderTextureStencilDescriptor = [[MTLTextureDescriptor alloc] init];
    renderTextureStencilDescriptor.usage = MTLTextureUsageRenderTarget;
    renderTextureStencilDescriptor.pixelFormat = MTLPixelFormatStencil8;
    _renderTextureStencil = [_device newTextureWithDescriptor:renderTextureStencilDescriptor];
    
    // cube
    {
        _cubeVerticeBuffer = [_device newBufferWithBytes:cubeVertices length:sizeof(cubeVertices) options:MTLResourceCPUCacheModeDefaultCache];
        _cubeIndiceBuffer = [_device newBufferWithBytes:cubeIndices length:sizeof(cubeIndices) options:MTLResourceCPUCacheModeDefaultCache];
        
        _mvMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -5);
        _pMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45), _height/_width, 1, 100);
        
        _cubeVertexFunction = [_library newFunctionWithName:@"cube_vertex_shader"];
        _cubeFragmentFunction = [_library newFunctionWithName:@"cube_fragment_shader"];
        
        id<MTLArgumentEncoder> vargumentEncoder = [_cubeVertexFunction newArgumentEncoderWithBufferIndex:1];
        _cubeVertexAB = [_device newBufferWithLength:vargumentEncoder.encodedLength options:0];
    }
    
    return self;
}

-(simd_float4x4) makeIdentModelViewMatrix
{
    simd_float4 col0 = simd_make_float4(1, 0, 0, 0);
    simd_float4 col1 = simd_make_float4(0, 1, 0, 0);
    simd_float4 col2 = simd_make_float4(0, 0, 1, 0);
    simd_float4 col3 = simd_make_float4(0, 0, 0, 1);
    return simd_matrix(col0, col1, col2, col3);
}



/// Called whenever view changes orientation or is resized
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}

/// Called whenever the view needs to render a frame
- (void)drawInMTKView:(nonnull MTKView *)view
{
    id<MTLCommandBuffer> buffer = [_queue commandBuffer];
    
    {
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].texture = view.currentDrawable.texture;
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.2, 0.2, 1.0);

        id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:passDescriptor];
        [encoder endEncoding];
    }
    
//    {
//        id<MTLArgumentEncoder> argumentEncoder = [_vertexFunction newArgumentEncoderWithBufferIndex:1];
//        [argumentEncoder setArgumentBuffer:_vArgumentBuffer offset:0];
//        void *numElementsAddress = [argumentEncoder constantDataAtIndex:0];
//        memcpy(numElementsAddress, color, sizeof(color));
//
//        id<MTLArgumentEncoder> fragArguEncoder = [_fragmentFunction newArgumentEncoderWithBufferIndex:10];
//        [fragArguEncoder setArgumentBuffer:_fArgumentBuffer offset:0];
//        [fragArguEncoder setTexture:_texture atIndex:0];
//        [fragArguEncoder setSamplerState:_sampler atIndex:1];
//
//
////        [argumentEncoder setBuffer:_colorBuffer offset:0 atIndex:0];
//
//
//        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
//        pipelineStateDescriptor.vertexFunction = _vertexFunction;
//        pipelineStateDescriptor.fragmentFunction = _fragmentFunction;
//        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
//
//        NSError *errors = nil;
//        id<MTLRenderPipelineState> pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&errors];
//
//        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
//        passDescriptor.colorAttachments[0].texture = view.currentDrawable.texture;
//        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
//        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
//        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 0.0, 1.0);
//
//        id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:passDescriptor];
//
//
//        [encoder setRenderPipelineState:pipelineState];
//        [encoder setVertexBuffer:_vBuffer offset:0 atIndex:0];
//        [encoder setVertexBuffer:_vArgumentBuffer offset:0 atIndex:1];
//        [encoder setFragmentBuffer:_fArgumentBuffer offset:0 atIndex:10];
//
////        // render triangle to the upper left corner.
////        MTLViewport viewport;
////        viewport.originX = 1080/2;
////        viewport.originY = 0;
////        viewport.height = 1920/2;
////        viewport.width = 1080/2;
////        viewport.zfar = 1;
////        [encoder setViewport:viewport];
//
//
//        // Encode Resources into an Argument Buffer
//        [encoder useResource:_texture usage:MTLResourceUsageSample];
//
//        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
//        [encoder endEncoding];
//    }
    
//    // render to texture
//    {
//        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
//        passDescriptor.colorAttachments[0].texture = _renderTextureColor;
//        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
//        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
//        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 0.0, 1.0);
//
//        id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:passDescriptor];
//        [encoder insertDebugSignpost:@"render to target"];
//        [encoder endEncoding];
//
//    }
    
    // render cube
    {
        id<MTLArgumentEncoder> argumentEncoder = [_cubeVertexFunction newArgumentEncoderWithBufferIndex:1];
        [argumentEncoder setArgumentBuffer:_cubeVertexAB offset:0];
        void *numElementsAddress = [argumentEncoder constantDataAtIndex:0];
        memcpy(numElementsAddress, _pMatrix.m, sizeof(_pMatrix));
        
        _rotatedAngle += 1.0f / view.preferredFramesPerSecond;
        
        _mvMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -(7.5 + sinf(_rotatedAngle*3) * 2.5));
        _mvMatrix = GLKMatrix4Rotate(_mvMatrix, _rotatedAngle, 0, 1, 0);
        numElementsAddress = [argumentEncoder constantDataAtIndex:1];
        memcpy(numElementsAddress, _mvMatrix.m, sizeof(_mvMatrix));
//
//        id<MTLArgumentEncoder> fragArguEncoder = [_fragmentFunction newArgumentEncoderWithBufferIndex:10];
//        [fragArguEncoder setArgumentBuffer:_fArgumentBuffer offset:0];
//        [fragArguEncoder setTexture:_texture atIndex:0];
//        [fragArguEncoder setSamplerState:_sampler atIndex:1];
        
        
        //        [argumentEncoder setBuffer:_colorBuffer offset:0 atIndex:0];
        
        
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.vertexFunction = _cubeVertexFunction;
        pipelineStateDescriptor.fragmentFunction = _cubeFragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        
        
        NSError *errors = nil;
        id<MTLRenderPipelineState> pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&errors];
        
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].texture = view.currentDrawable.texture;
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 0.0, 1.0);
        
        id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:passDescriptor];
        
        
        [encoder setRenderPipelineState:pipelineState];
        [encoder setVertexBuffer:_cubeVerticeBuffer offset:0 atIndex:0];
        [encoder setVertexBuffer:_cubeVertexAB offset:0 atIndex:1];
        [encoder setCullMode:MTLCullModeBack];
        [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
//        [encoder setFragmentBuffer:_fArgumentBuffer offset:0 atIndex:10];
        
        //        // render triangle to the upper left corner.
        //        MTLViewport viewport;
        //        viewport.originX = 1080/2;
        //        viewport.originY = 0;
        //        viewport.height = 1920/2;
        //        viewport.width = 1080/2;
        //        viewport.zfar = 1;
        //        [encoder setViewport:viewport];
        
        
        // Encode Resources into an Argument Buffer
//        [encoder useResource:_texture usage:MTLResourceUsageSample];
        
//        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [encoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:24 indexType:MTLIndexTypeUInt16 indexBuffer:_cubeIndiceBuffer indexBufferOffset:0];
        [encoder endEncoding];
    }
    
    [buffer presentDrawable:view.currentDrawable];
    [buffer commit];
}

@end
