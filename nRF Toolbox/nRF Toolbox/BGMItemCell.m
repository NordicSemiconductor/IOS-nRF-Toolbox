//
//  BGMItemCell.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 17/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "BGMItemCell.h"

@implementation BGMItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
