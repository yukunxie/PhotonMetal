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

float vertices[] = {0, 0, 0, -1, -1, 0, 1, -1, 0};

@implementation PMRenderer
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _queue;
    id<MTLBuffer> _vBuffer;
    id<MTLLibrary> _library;
    id<MTLFunction> _vertexFunction;
    id<MTLFunction> _fragmentFunction;
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
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [encoder endEncoding];
    }
    
    [buffer presentDrawable:view.currentDrawable];
    [buffer commit];
}

@end
