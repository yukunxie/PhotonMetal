//
//  GameView.h
//  PhotonMetal
//
//  Created by realxie on 2019/8/9.
//  Copyright © 2019 realxie. All rights reserved.
//

#pragma once

#import <MetalKit/MetalKit.h>
#import <GLKit/GLKMath.h>

// Our platform independent renderer class
@interface RXGameView : NSObject<MTKViewDelegate>

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

@end
