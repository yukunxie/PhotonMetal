//
//  ViewController.m
//  PhotonMetal
//
//  Created by realxie on 2019/1/2.
//  Copyright © 2019 realxie. All rights reserved.
//

#import "ViewController.h"
#import "PMRenderer.h"

#import <Metal/MTLDefines.h>
#import <Metal/MTLTypes.h>
#import <Metal/MTLPixelFormat.h>
#import <Metal/MTLResource.h>
#import <Metal/MTLLibrary.h>
#import <Metal/MTLDevice.h>
#import <Metal/MTLCommandQueue.h>
#import <Metal/MTLCommandBuffer.h>
#import <Metal/MTLRenderPass.h>



@import MetalKit;


@interface ViewController ()

@end

@implementation ViewController
{
    MTKView *_view;
    id<MTLCommandQueue> _queue;
    PMRenderer *_render;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _view = (MTKView *)self.view;
    _view.device = MTLCreateSystemDefaultDevice();
    
    _render = [[PMRenderer alloc]initWithMetalKitView:_view];
    _view.delegate = _render;
    
//    id<MTLDevice> device = _view.device;
//    _queue = [device newCommandQueue];
//
//    id<MTLCommandBuffer> buffer = [_queue commandBuffer];
//
//    MTLRenderPassDescriptor *descriptor = [MTLRenderPassDescriptor alloc];
//    descriptor.colorAttachments[0].texture = _view.currentDrawable.texture;
//    descriptor.colorAttachments[0].loadAction =  MTLLoadActionClear;
//    descriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0, 0, 1);
//
//    id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:descriptor];
//    [encoder endEncoding];
//    [_queue commandBuffer];
}

@end
