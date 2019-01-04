//
//  PMRenderer.m
//  PhotonMetal
//
//  Created by realxie on 2019/1/2.
//  Copyright © 2019 realxie. All rights reserved.
//

@import simd;
@import MetalKit;

#import "PMRenderer.h"

float vertices[] = {0, 0, 0, 0.5, 0.5, -1, -1, 0, 0, 0,  1, -1, 0, 1, 0};
float color [] = {0.0, 1.0, 1.0, 1.0};

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
    
    return self;
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
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);

        id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:passDescriptor];
        [encoder endEncoding];
    }
    
    {
        id<MTLArgumentEncoder> argumentEncoder = [_vertexFunction newArgumentEncoderWithBufferIndex:1];
        [argumentEncoder setArgumentBuffer:_vArgumentBuffer offset:0];
        void *numElementsAddress = [argumentEncoder constantDataAtIndex:0];
        memcpy(numElementsAddress, color, sizeof(color));
        
        id<MTLArgumentEncoder> fragArguEncoder = [_fragmentFunction newArgumentEncoderWithBufferIndex:10];
        [fragArguEncoder setArgumentBuffer:_fArgumentBuffer offset:0];
        [fragArguEncoder setTexture:_texture atIndex:0];
        [fragArguEncoder setSamplerState:_sampler atIndex:1];
        
        
//        [argumentEncoder setBuffer:_colorBuffer offset:0 atIndex:0];
        
        
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.vertexFunction = _vertexFunction;
        pipelineStateDescriptor.fragmentFunction = _fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        
        NSError *errors = nil;
        id<MTLRenderPipelineState> pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&errors];
        
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].texture = view.currentDrawable.texture;
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:passDescriptor];
        
        
        [encoder setRenderPipelineState:pipelineState];
        [encoder setVertexBuffer:_vBuffer offset:0 atIndex:0];
        [encoder setVertexBuffer:_vArgumentBuffer offset:0 atIndex:1];
        [encoder setFragmentBuffer:_fArgumentBuffer offset:0 atIndex:10];
        
        // Encode Resources into an Argument Buffer
        [encoder useResource:_texture usage:MTLResourceUsageSample];
        
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [encoder endEncoding];
    }
    
    [buffer presentDrawable:view.currentDrawable];
    [buffer commit];
}

@end
