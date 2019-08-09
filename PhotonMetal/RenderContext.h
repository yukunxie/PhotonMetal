//
//  RenderContext.h
//  PhotonMetal
//
//  Created by realxie on 2019/8/9.
//  Copyright © 2019 realxie. All rights reserved.
//

#pragma once

#include "GlobalDefines.h"

NS_RX_BEGIN

class IRenderContext
{
public:
    virtual void BeginRender() = 0;
    virtual void EndRender() = 0;
    
public:
    ~IRenderContext(){}
};


NS_RX_END




