/*
 * Copyright (c) 2015, Nordic Semiconductor
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "LogItemCell.h"

@implementation LogItem

@end

@interface LogItemCell ()

@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *message;

@end

@implementation LogItemCell

-(void)set:(LogItem*)item
{
    self.timestamp.text = item.timestamp;
    self.message.text = item.message;
    
    // Use the color based on the log level
    UIColor *color = nil;
    switch (item.level) {
        case Debug:
            color = [UIColor colorWithRed:0x00/255.0 green:0x9C/255.0 blue:0xDE/255.0 alpha:1];
            break;
            
        case Verbose:
            color = [UIColor colorWithRed:0xB8/255.0 green:0xB0/255.0 blue:0x56/255.0 alpha:1];
            break;
            
        case Info:
            color = [UIColor blackColor];
            break;
            
        case App:
            color = [UIColor colorWithRed:0x23/255.0 green:0x8C/255.0 blue:0x0F/255.0 alpha:1];
            break;
            
        case Warning:
            color = [UIColor colorWithRed:0xD7/255.0 green:0x79/255.0 blue:0x26/255.0 alpha:1];
            break;
            
        case Error:
            color = [UIColor redColor];
            break;
    }
    self.message.textColor = color;
}

@end
