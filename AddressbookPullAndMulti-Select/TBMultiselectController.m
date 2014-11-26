//
//  MultiSelectViewController.m
//  MultiSelectUIXibVersion
//`
//  Created by Aditya Narayan on 10/28/14.
//  Copyright (c) 2014 TurnToTech. All rights reserved.
//

#import "TBMultiselectController.h"


@interface TBMultiselectController ()

@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *selectedContacts;

@end




@implementation TBMultiselectController




- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    //Hooking up TBContactsGrabber for Multiselect Contacts view
    self.tbContactsGrabber = [[TBContactsGrabber alloc]init];
    self.tbContactsGrabber.delegate = self;
    [self.tbContactsGrabber checkForABAuthorizationAndStartRun];
    [self.tbContactsGrabber startListeningForABChanges];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.title = @"Invite Friends";
    
    UIBarButtonItem *rightButtonSend = [[UIBarButtonItem alloc]initWithTitle:@"SEND" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItem = rightButtonSend;
    UIBarButtonItem *leftButtonBack = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(customBackXButton:)];
    self.navigationItem.leftBarButtonItem = leftButtonBack;
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    
    //Setting up searchbar filter functionality 
    self.searchResults = [NSMutableArray arrayWithCapacity:[self.tbContactsGrabber.savedArrayOfContactsWithPhoneNumbers count]];
    self.selectedContacts = [[NSMutableArray array]init];
    self.searchDisplayController.searchResultsTableView.allowsMultipleSelection = YES;
}

- (void) viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark Search Bar Methods

- (void)filterContentForSearchText:(NSString*)searchText scope: (NSString *) scope
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"firstName BEGINSWITH[c] %@", searchText];
    self.searchResults = [[self.tbContactsGrabber.savedArrayOfContactsWithPhoneNumbers filteredArrayUsingPredicate:resultPredicate]mutableCopy];
}


- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar scopeButtonTitles]objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    [tableView reloadData];
    [self.tableView reloadData]; //these two lines make sure that both Filterview and Tableview data are refreshed - without it, it doesn't work
    
}



#pragma mark Tableview Delegate Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.searchResults count];
    }
    else {
        return (self.tbContactsGrabber.savedArrayOfContactsWithPhoneNumbers.count);
    }
}


- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if(!cell){
        cell =
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    Contact *selectedContact;
    if (tableView == self.searchDisplayController.searchResultsTableView){
    //if we are in filter search results view
        selectedContact = [self.searchResults objectAtIndex:indexPath.row];
        if (selectedContact.checkmarkFlag == YES) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else if (selectedContact.checkmarkFlag == NO) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else {
    //if we are in regular table view
        selectedContact = [self.tbContactsGrabber.savedArrayOfContactsWithPhoneNumbers objectAtIndex:indexPath.row];
        if (selectedContact.checkmarkFlag == YES) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        else if (selectedContact.checkmarkFlag == NO) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    //to make sure there's no gray highlighting when it's clicked - important
    
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", selectedContact.firstName, selectedContact.lastName];
    cell.textLabel.text = fullName;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    Contact *selectedContact;
    
    //if its filterview mode
    if (tableView == self.searchDisplayController.searchResultsTableView){
        
        selectedContact = [self.searchResults objectAtIndex:indexPath.row];
            if (selectedContact.checkmarkFlag == YES) {
            selectedContact.checkmarkFlag = NO;
            cell.accessoryType = UITableViewCellAccessoryNone;
            [self.selectedContacts removeObject:selectedContact];
        }
        else {
            selectedContact.checkmarkFlag = YES;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [self.selectedContacts addObject:selectedContact];
        }
    }
    
    //if its just regular tableview mode, and you selected something
    else {
        selectedContact = [self.tbContactsGrabber.savedArrayOfContactsWithPhoneNumbers objectAtIndex:indexPath.row];
        selectedContact.checkmarkFlag = YES;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.selectedContacts addObject:selectedContact];
    }
    
    NSLog(self.selectedContacts.description);
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    Contact *selectedContact = [self.tbContactsGrabber.savedArrayOfContactsWithPhoneNumbers objectAtIndex:indexPath.row];
    selectedContact.checkmarkFlag = NO;
    cell.accessoryType = UITableViewCellAccessoryNone;
    [self.selectedContacts removeObject:selectedContact];
    
    NSLog(self.selectedContacts.description);
}




#pragma mark IBActions and custom methods


- (IBAction)customBackXButton:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
    
}


- (void) didFinishGrabbingContactsFromAddressBook {
    [self.tableView reloadData];
}

@end
