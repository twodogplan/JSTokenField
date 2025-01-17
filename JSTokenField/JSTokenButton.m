//
//	Copyright 2011 James Addyman (JamSoft). All rights reserved.
//	
//	Redistribution and use in source and binary forms, with or without modification, are
//	permitted provided that the following conditions are met:
//	
//		1. Redistributions of source code must retain the above copyright notice, this list of
//			conditions and the following disclaimer.
//
//		2. Redistributions in binary form must reproduce the above copyright notice, this list
//			of conditions and the following disclaimer in the documentation and/or other materials
//			provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY JAMES ADDYMAN (JAMSOFT) ``AS IS'' AND ANY EXPRESS OR IMPLIED
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//	FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JAMES ADDYMAN (JAMSOFT) OR
//	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//	ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//	ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//	The views and conclusions contained in the software and documentation are those of the
//	authors and should not be interpreted as representing official policies, either expressed
//	or implied, of James Addyman (JamSoft).
//

#import "JSTokenButton.h"
#import "JSTokenField.h"
#import <QuartzCore/QuartzCore.h>

@interface JSTokenButton ()
-(void)resetPadding;

@end

@implementation JSTokenButton

@synthesize toggled = _toggled;
@synthesize normalBg = _normalBg;
@synthesize highlightedBg = _highlightedBg;
@synthesize representedObject = _representedObject;
@synthesize parentField = _parentField;

+ (JSTokenButton *)tokenWithString:(NSString *)string representedObject:(id)obj
{
	JSTokenButton *button = (JSTokenButton *)[self buttonWithType:UIButtonTypeCustom];
	[[button titleLabel] setLineBreakMode:UILineBreakModeTailTruncation];
	[button setTitleEdgeInsets:UIEdgeInsetsMake(2, 10, 0, 10)];
	
	[button setTitle:string forState:UIControlStateNormal];
	
	[button setToggled:NO];
	
	[button setRepresentedObject:obj];
	
	return button;
}

-(void)resetPadding
{
	[self sizeToFit];
	CGRect selfFrame = self.frame;
	selfFrame.size.width += 20;
	selfFrame.size.height = 25;
	self.frame = selfFrame;

}

-(void)setTitle:(NSString *)title forState:(UIControlState)state
{
	[super setTitle:title forState:state];
	[self resetPadding];
}

- (BOOL)becomeFirstResponder {
    BOOL superReturn = [super becomeFirstResponder];
    if (superReturn) {
        self.toggled = YES;
    }
    return superReturn;
}

- (BOOL)resignFirstResponder {
    BOOL superReturn = [super resignFirstResponder];
    if (superReturn) {
        self.toggled = NO;
    }
    return superReturn;
}

#pragma mark - UIKeyInput
- (void)deleteBackward {
    [_parentField removeTokenForString:[self titleForState:UIControlStateNormal]];
}

- (BOOL)hasText {
    return NO;
}
- (void)insertText:(NSString *)text {
    return;
}


- (BOOL)canBecomeFirstResponder {
    return YES;
}

@end
