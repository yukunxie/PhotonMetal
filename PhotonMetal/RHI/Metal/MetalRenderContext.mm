//
//  MetalRenderContext.mm
//  PhotonMetal
//
//  Created by realxie on 2019/8/9.
//  Copyright © 2019 realxie. All rights reserved.
//

#include "MetalRenderContext.h"

NS_RX_BEGIN

MetalRenderContext::MetalRenderContext(void *initData)
{
    _mtkView =(__bridge MTKView*)initData;
    _device  = _mtkView.device;
    _queue   = [_device newCommandQueue];
}

MetalRenderContext::~MetalRenderContext()
{
    _mtkView = nullptr;
}

void MetalRenderContext::BeginRender()
{
    assert(_buffer == nil);
    _buffer = [_queue commandBuffer];
}

void MetalRenderContext::EndRender()
{
    assert(_buffer != nil);
    [_buffer presentDrawable: _mtkView.currentDrawable];
    [_buffer commit];
}

NS_RX_END
