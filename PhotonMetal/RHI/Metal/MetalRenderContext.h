//
//  MetalRenderContext.h
//  PhotonMetal
//
//  Created by realxie on 2019/8/9.
//  Copyright © 2019 realxie. All rights reserved.
//

#pragma once

#include "RenderContext.h"

#import <MetalKit/MetalKit.h>

NS_RX_BEGIN

class MetalRenderContext : public IRenderContext
{
public:
    MetalRenderContext(void *initData);
    ~MetalRenderContext();
    
public:
    virtual void BeginRender() override;
    virtual void EndRender() override;
    
protected:
    MTKView                 *_mtkView   = nullptr;
    id<MTLDevice>           _device     = nil;
    id<MTLCommandQueue>     _queue      = nil;
    id<MTLCommandBuffer>    _buffer     = nil;
};

NS_RX_END
