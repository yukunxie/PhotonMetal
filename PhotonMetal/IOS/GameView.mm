//
//  GameView.m
//  PhotonMetal
//
//  Created by realxie on 2019/8/9.
//  Copyright © 2019 realxie. All rights reserved.
//


#import "GameView.h"

#import <MetalKit/MetalKit.h>
#import <GLKit/GLKMath.h>

#include "Runtime/Engine.h"

@implementation RXGameView
{
    RX::Engine* _gameEngine;
}

-(nonnull instancetype) initWithMetalKitView:(MTKView *)mtkView
{
    _gameEngine = new RX::Engine();
    return self;
}

/// Called whenever view changes orientation or is resized
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}

/// Called whenever the view needs to render a frame
- (void)drawInMTKView:(nonnull MTKView *)view
{
    _gameEngine->MainLoop(0);
}

@end
