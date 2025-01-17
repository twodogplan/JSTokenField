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

#import "JSTokenField.h"
#import "JSTokenButton.h"
#import <QuartzCore/QuartzCore.h>

NSString *const JSTokenFieldFrameDidChangeNotification = @"JSTokenFieldFrameDidChangeNotification";
NSString *const JSTokenFieldNewFrameKey = @"JSTokenFieldNewFrameKey";
NSString *const JSTokenFieldOldFrameKey = @"JSTokenFieldOldFrameKey";
NSString *const JSDeletedTokenKey = @"JSDeletedTokenKey";

#define HEIGHT_PADDING 3
#define WIDTH_PADDING 3

#define DEFAULT_HEIGHT 31

#define ZERO_WIDTH_SPACE_STRING @"\u200B"

@interface JSTokenField ();
@property (nonatomic, assign, getter = isActivated)BOOL activated;

- (JSTokenButton *)tokenWithString:(NSString *)string representedObject:(id)obj;
- (void)deleteHighlightedToken;

- (void)commonSetup;
-(BOOL)isValidEmailAddress:(NSString *)possibleEmailAddress;
- (BOOL)addTokenFromContentsOfTextField:(UITextField *)textField;
-(BOOL)canAddTokenFromContentsOfTextField:(UITextField *)textField;

+(NSCharacterSet *)emailDelimiterCharacterSet;
@end


@implementation JSTokenField

@synthesize tokens = _tokens;
@synthesize textField = _textField;
@synthesize label = _label;
@synthesize summaryLabel;
@synthesize delegate = _delegate;
@synthesize activated;
@synthesize placeholderText;

+(NSCharacterSet *)emailDelimiterCharacterSet
{
	static NSCharacterSet *delimterCharacterSet = nil;
	if (delimterCharacterSet == nil) {
		NSMutableCharacterSet *temporaryCharacterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
		[temporaryCharacterSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
		delimterCharacterSet = temporaryCharacterSet;
	}
	return delimterCharacterSet;
}


- (id)initWithFrame:(CGRect)frame
{
	if (frame.size.height < DEFAULT_HEIGHT)
	{
		frame.size.height = DEFAULT_HEIGHT;
	}
	
    if ((self = [super initWithFrame:frame]))
	{
        [self commonSetup];
    }
	
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonSetup];
    }
    return self;
}

- (void)commonSetup {
    CGRect frame = self.frame;
	if (self.backgroundColor == nil) {
		[self setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
	}
    
    _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, frame.size.height)];
    [_label setBackgroundColor:[UIColor clearColor]];
    [_label setTextColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0]];
    [_label setFont:[UIFont fontWithName:@"Helvetica Neue" size:17.0]];
    
    [self addSubview:_label];
    
    //		self.layer.borderColor = [[UIColor blueColor] CGColor];
    //		self.layer.borderWidth = 1.0;
    
    _tokens = [[NSMutableArray alloc] init];
    
    frame.origin.y += HEIGHT_PADDING;
    frame.size.height -= HEIGHT_PADDING * 2;
    _textField = [[UITextField alloc] initWithFrame:frame];
    [_textField setDelegate:self];
    [_textField setBorderStyle:UITextBorderStyleNone];
    [_textField setBackground:nil];
    [_textField setBackgroundColor:[UIColor clearColor]];
    [_textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [_textField setFont:[UIFont fontWithName:@"Helvetica Neue" size:15.0]];
    
	CGRect summaryFrame = frame;
	summaryFrame.size.width -= 25.0;
	summaryFrame.origin = CGPointZero;
    summaryFrame.origin.y += HEIGHT_PADDING;
	self.summaryLabel = [[UILabel alloc] initWithFrame:summaryFrame];
	self.summaryLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
	self.summaryLabel.userInteractionEnabled = NO;
	self.summaryLabel.lineBreakMode = UILineBreakModeTailTruncation;
	self.summaryLabel.textAlignment = UITextAlignmentLeft;
	self.summaryLabel.numberOfLines = 1;
	self.summaryLabel.font = self.textField.font;
	self.summaryLabel.hidden = YES;
	self.summaryLabel.backgroundColor = [UIColor clearColor];
    //		[_textField.layer setBorderColor:[[UIColor redColor] CGColor]];
    //		[_textField.layer setBorderWidth:1.0];
    
    [_textField setText:ZERO_WIDTH_SPACE_STRING];
    
    [self addSubview:_textField];
	[self addSubview: self.summaryLabel];
    
	self.activated = YES;
	
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTextDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:_textField];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addTokenWithTitle:(NSString *)string representedObject:(id)obj
{
	NSString *aString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	if ([aString length])
	{
		JSTokenButton *token = [self tokenWithString:aString representedObject:obj];
        token.parentField = self;
		[_tokens addObject:token];
		token.alpha = 0.0;
		token.titleLabel.font = _textField.font;
		
		[UIView animateWithDuration:0.3 
						 animations:^{
							 token.alpha = 1.0;
							 _textField.alpha = 0.0;
						 }
						 completion:^(BOOL finished) {
							 [_textField setText:self.placeholderText];
							 _textField.alpha = 1.0;
							 [self setNeedsLayout];
						 }
		 ];
		if ([self.delegate respondsToSelector:@selector(tokenField:didAddToken:representedObject:)])
		{
			[self.delegate tokenField:self didAddToken:aString representedObject:obj];
		}
		[self setNeedsLayout];
		
	}
}

- (BOOL)addTokenFromContentsOfTextField:(UITextField *)textField
{
	BOOL succeeded = YES;
	
	if (self.activated) {
		if ([self canAddTokenFromContentsOfTextField:textField]) {
			NSString *tokenString = [[textField text] stringByTrimmingCharactersInSet:[[self class] emailDelimiterCharacterSet]];
			id representedObject = tokenString;
			if ([self.delegate respondsToSelector:@selector(representedObjectForTokenField:title:)]) {
				representedObject = [self.delegate representedObjectForTokenField:self title:tokenString];
			}
			self.placeholderText = nil;
			[self addTokenWithTitle:tokenString representedObject:representedObject];
		} else {
			succeeded = NO;
		}
		
	} else {
		succeeded = NO;
	}
	

	return succeeded;
}

-(BOOL)canAddTokenFromContentsOfTextField:(UITextField *)textField
{
	NSString *tokenString = [[textField text] stringByTrimmingCharactersInSet:[[self class] emailDelimiterCharacterSet]];
	BOOL canAdd = [self isValidEmailAddress:tokenString];
	
	return canAdd;
}


- (void)removeTokenWithTest:(BOOL (^)(JSTokenButton *token))test {
    JSTokenButton *tokenToRemove = nil;
    for (JSTokenButton *token in [_tokens reverseObjectEnumerator]) {
        if (test(token)) {
            tokenToRemove = token;
            break;
        }
    }
    
    if (tokenToRemove) {
        if (tokenToRemove.isFirstResponder) {
            [_textField becomeFirstResponder];
        }
        [tokenToRemove removeFromSuperview];
		
		NSString *tokenName = [tokenToRemove titleForState:UIControlStateNormal];
        id representedObject = tokenToRemove.representedObject;

		[_tokens removeObject:tokenToRemove];
        
        if ([self.delegate respondsToSelector:@selector(tokenField:didRemoveToken:representedObject:)])
        {
				[self.delegate tokenField:self didRemoveToken:tokenName representedObject:representedObject];

        }
	}
	
	[self setNeedsLayout];
}

- (void)removeTokenForString:(NSString *)string
{
    [self removeTokenWithTest:^BOOL(JSTokenButton *token) {
        return [[token titleForState:UIControlStateNormal] isEqualToString:string];
    }];
}

- (void)removeTokenWithRepresentedObject:(id)representedObject {
    [self removeTokenWithTest:^BOOL(JSTokenButton *token) {
        return [[token representedObject] isEqual:representedObject];
    }];
}

- (BOOL)containsTokenForRepresentedObject:(id)representedObject
{
	BOOL containsToken = NO; 
    for (JSTokenButton *token in self.tokens) {
		if ([token.representedObject isEqual:representedObject]) {
			containsToken = YES;
			break;
		}
	}
	return containsToken;
}

- (void)deleteHighlightedToken
{
	for (int i = 0; i < [_tokens count]; i++)
	{
		_deletedToken = [_tokens objectAtIndex:i];
		if ([_deletedToken isToggled])
		{
			[_deletedToken removeFromSuperview];
			[_tokens removeObject:_deletedToken];
			
			if ([self.delegate respondsToSelector:@selector(tokenField:didRemoveTokenAtIndex:)])
			{
				NSString *tokenName = [_deletedToken titleForState:UIControlStateNormal];
				[self.delegate tokenField:self didRemoveToken:tokenName representedObject:_deletedToken.representedObject];
			}
			
			[self setNeedsLayout];	
		}
	}
}

- (JSTokenButton *)tokenWithString:(NSString *)string representedObject:(id)obj
{
	JSTokenButton *token = [JSTokenButton tokenWithString:string representedObject:obj];
	CGRect frame = [token frame];
	
	if (frame.size.width > self.frame.size.width)
	{
		frame.size.width = self.frame.size.width - (WIDTH_PADDING * 2);
	}
	
	[token setFrame:frame];
	
	[token addTarget:self
			  action:@selector(toggle:)
	forControlEvents:UIControlEventTouchUpInside];
	
	return token;
}
- (void)inactivateAndShowSummary:(NSString *)summary
{
	self.activated = NO;
	
	self.summaryLabel.text = summary;
	self.summaryLabel.hidden = NO;
	
	//hide all the tokens
	[self.tokens enumerateObjectsUsingBlock:^(JSTokenButton *tokenButton, NSUInteger idx, BOOL *stop) {
		tokenButton.hidden = YES;
	}];
	
	[self setNeedsLayout];
	
}
- (void)activate
{
	self.activated = YES;
	self.summaryLabel.text = @"";
	self.summaryLabel.hidden = YES;
	
	//show all the tokens
	[self.tokens enumerateObjectsUsingBlock:^(JSTokenButton *tokenButton, NSUInteger idx, BOOL *stop) {
		tokenButton.hidden = NO;
	}];
	
	[self.textField becomeFirstResponder];
	
	[self setNeedsLayout];

}

- (void)layoutSubviews
{
	CGRect currentRect = CGRectZero;
	CGRect selfFrame = [self frame];

	[_label sizeToFit];
	[_label setFrame:CGRectMake(WIDTH_PADDING, HEIGHT_PADDING, [_label frame].size.width, [_label frame].size.height + 3)];
	
	currentRect.origin.x += _label.frame.size.width + _label.frame.origin.x + WIDTH_PADDING;
	
	if (self.activated) {
		for (UIButton *token in _tokens)
		{
			CGRect frame = [token frame];
			
			if ((currentRect.origin.x + frame.size.width) > self.frame.size.width)
			{
				currentRect.origin = CGPointMake(WIDTH_PADDING, (currentRect.origin.y + frame.size.height + HEIGHT_PADDING));
			}
			
			frame.origin.x = currentRect.origin.x;
			frame.origin.y = currentRect.origin.y + HEIGHT_PADDING;
			
			[token setFrame:frame];
			
			if (![token superview])
			{
				[self addSubview:token];
			}
			
			currentRect.origin.x += frame.size.width + WIDTH_PADDING;
			currentRect.size = frame.size;
		}
		
		CGRect textFieldFrame = [_textField frame];
		if (_textField.alpha > 0.0) {
			
			textFieldFrame.origin = currentRect.origin;
			textFieldFrame.origin.x += 10.0;
			
			if ((self.frame.size.width - textFieldFrame.origin.x) >= 60)
			{
				textFieldFrame.size.width = self.frame.size.width - textFieldFrame.origin.x;
			}
			else
			{
				textFieldFrame.size.width = self.frame.size.width;
				textFieldFrame.origin = CGPointMake(WIDTH_PADDING * 2, 
													(currentRect.origin.y + currentRect.size.height + HEIGHT_PADDING));
			}
			
			textFieldFrame.origin.y += (HEIGHT_PADDING + 2.0); //fudge by two points to get the button label to line up with the UILabel's text
			[_textField setFrame:textFieldFrame];
			
		}
		selfFrame.size.height = textFieldFrame.origin.y + textFieldFrame.size.height + HEIGHT_PADDING;		
	} else {
		selfFrame.size.height = self.summaryLabel.bounds.size.height;		
	}
	

	
	[UIView animateWithDuration:0.3
					 animations:^{
						 [self setFrame:selfFrame];
					 }
					 completion:nil];
}
- (void)toggle:(id)sender
{
	for (JSTokenButton *token in _tokens)
	{
		[token setToggled:NO];
	}
	
	JSTokenButton *token = (JSTokenButton *)sender;
	[token setToggled:YES];
    [token becomeFirstResponder];
}

- (void)setFrame:(CGRect)frame
{
    CGRect oldFrame = self.frame;
    
	[super setFrame:frame];
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGRect:frame] forKey:JSTokenFieldNewFrameKey];
    [userInfo setObject:[NSValue valueWithCGRect:oldFrame] forKey:JSTokenFieldOldFrameKey];
	if (_deletedToken)
	{
		[userInfo setObject:_deletedToken forKey:JSDeletedTokenKey]; 
		_deletedToken = nil;
	}
	
	if (CGRectEqualToRect(oldFrame, frame) == NO) {
		[[NSNotificationCenter defaultCenter] postNotificationName:JSTokenFieldFrameDidChangeNotification object:self userInfo:[userInfo copy]];
	}
}

#pragma mark utility
-(BOOL)isValidEmailAddress:(NSString *)possibleEmailAddress
{
	static NSPredicate *regularExpressionPredicate = nil;
	if (regularExpressionPredicate == nil) {
		//with thanks to Matt Gallagher: http://cocoawithlove.com/2009/06/verifying-that-string-is-email-address.html
		NSString *emailRegularExpression =
		@"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
		@"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
		@"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
		@"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
		@"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
		@"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
		@"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
		
		regularExpressionPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegularExpression];
	}

	BOOL isValidEmailAddress = [regularExpressionPredicate evaluateWithObject:possibleEmailAddress];
	
	return isValidEmailAddress;
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (void)handleTextDidChange:(NSNotification *)note
{
	// ensure there's always a space at the beginning
	NSMutableString *text = [[_textField text] mutableCopy];
	if (![text hasPrefix:ZERO_WIDTH_SPACE_STRING])
	{
		[text insertString:ZERO_WIDTH_SPACE_STRING atIndex:0];
		[_textField setText:text];
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	static NSCharacterSet *delimterCharacterSet = nil;
	if (delimterCharacterSet == nil) {
		NSMutableCharacterSet *temporaryCharacterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
		[temporaryCharacterSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
		delimterCharacterSet = temporaryCharacterSet;
	}
    if ([string isEqualToString:@""] &&
        (NSEqualRanges(range, NSMakeRange(0, 0)) || [[textField text] isEqualToString:ZERO_WIDTH_SPACE_STRING]))
	{
        JSTokenButton *token = [_tokens lastObject];
        [token becomeFirstResponder];		
		return NO;
	} else if ([string rangeOfCharacterFromSet:delimterCharacterSet].location != NSNotFound) {
		//end the current token
		BOOL added = [self addTokenFromContentsOfTextField:textField];
		return added;

	}
	
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (_textField == textField) {
		BOOL shouldReturn = [self addTokenFromContentsOfTextField:textField];
		self.activated = NO;	
		if (shouldReturn && [self.delegate respondsToSelector:@selector(tokenFieldShouldReturn:)]) {
            return [self.delegate tokenFieldShouldReturn:self];
        }
    }
	
	return NO;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(tokenFieldDidBeginEditing:)]) {
        [self.delegate tokenFieldDidBeginEditing:self];
    }
	
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(tokenFieldDidEndEditing:)]) {
        [self.delegate tokenFieldDidEndEditing:self];
        return;
    }
    else if ([[textField text] length] > 1)
    {
		BOOL added = [self addTokenFromContentsOfTextField:textField];
		if (added) {
			[textField setText:ZERO_WIDTH_SPACE_STRING];
		}
    }
}

#pragma mark UIView overrides
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//this turns the entire JSTokenView into a touch target to start typing an email address
	[self activate];
}

@end
