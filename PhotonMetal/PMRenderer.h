//
//  PMRenderer.h
//  PhotonMetal
//
//  Created by realxie on 2019/1/2.
//  Copyright © 2019 realxie. All rights reserved.
//

@import MetalKit;

// Our platform independent renderer class
@interface PMRenderer : NSObject<MTKViewDelegate>

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

@end
