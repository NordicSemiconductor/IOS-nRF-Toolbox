//
//  BGMItemCell.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 17/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BGMItemCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *type;
@property (weak, nonatomic) IBOutlet UILabel *value;

@end
