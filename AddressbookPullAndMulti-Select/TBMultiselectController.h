//
//  MultiSelectViewController.h
//  MultiSelectUIXibVersion
//
//  Created by Aditya Narayan on 10/28/14.
//  Copyright (c) 2014 TurnToTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "Contact.h"
#import "TBContactsGrabber.h"

@interface TBMultiselectController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, TBContactsGrabberDelegate>

@property (strong, nonatomic) TBContactsGrabber *tbContactsGrabber;
@property (strong, nonatomic) IBOutlet UITableView *tableView;


- (IBAction)sendButton: (id) sender;
- (IBAction)customBackXButton:(id)sender;


@end
