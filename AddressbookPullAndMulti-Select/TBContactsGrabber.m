//
//  TBContactsGrabber.m
//  MultiSelectUIXibVersion
//
//  Created by Terry Bu on 10/28/14.
//  Copyright (c) 2014 TurnToTech. All rights reserved.
//

#import "TBContactsGrabber.h"

@implementation TBContactsGrabber

#pragma mark Grabbing from Addressbook

- (void) checkForABAuthorizationAndStartRun {
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
        ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted){
        //1
        NSLog(@"you must allow app permissions to access your contacts from this app");
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){
        //2
        NSLog(@"Authorized");
        [self runGrabContactsOnBackgroundQueue];
    } else { //case of ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined
        //3
        NSLog(@"Not determined");
        ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
            if (!granted){
                //4
                NSLog(@"you must allow app permissions to access your contacts from this app");
                return;
            }
            //5
            NSLog(@"Authorized");
            [self runGrabContactsOnBackgroundQueue];
        });
    }
}

- (void) runGrabContactsOnBackgroundQueue {
    NSOperationQueue *queue = [NSOperationQueue new];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                            selector:@selector(grabContactsWithAPhoneNumber)
                                                                              object:nil];
    [queue addOperation:operation];
}


- (void) grabContactsWithAPhoneNumber {
    NSMutableArray *resultsArray = [[NSMutableArray alloc]init];
    
    CFErrorRef error = nil;
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
    if (!addressBookRef)
    {
        NSLog(@"error: %@", error);
        return; // bail
    }
    NSArray *allContacts = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    
    for (id record in allContacts){
        ABRecordRef thisContact = (__bridge ABRecordRef)record;
        ABMultiValueRef mvr = ABRecordCopyValue(thisContact, kABPersonPhoneProperty);
        
        //check for phone number existence - if the record does have a phone number, push to our array
        int phoneNumbersCount = (int) ABMultiValueGetCount(mvr);
        if (phoneNumbersCount > 0) {
            Contact *myNewContactObject = [self createContactObjectBasedOnAddressBookRecord:thisContact];
            
            if ([self validatePhoneNumber:myNewContactObject.mobileNumber])
                [resultsArray addObject:myNewContactObject];
            else
                NSLog(@"top phone number listed for the contact didn't have a valid number");
        }
        else {
            //            NSLog(@"found a contact without any phone number at %@", personFullName);
        }
    }
    
    self.savedArrayOfContactsWithPhoneNumbers = resultsArray;
    
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:true];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sorter];
    [self.savedArrayOfContactsWithPhoneNumbers sortUsingDescriptors:sortDescriptors];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didFinishGrabbingContactsFromAddressBook];
    });
    
}




- (Contact *) createContactObjectBasedOnAddressBookRecord: (ABRecordRef) myABRecordRef {
    Contact *myContactObject = [[Contact alloc]init];
    myContactObject.firstName = (__bridge NSString *)(ABRecordCopyValue(myABRecordRef, kABPersonFirstNameProperty));
    myContactObject.lastName = (__bridge NSString *)(ABRecordCopyValue(myABRecordRef, kABPersonLastNameProperty));
    myContactObject.checkmarkFlag = NO;
    ABMultiValueRef mvr = ABRecordCopyValue(myABRecordRef, kABPersonPhoneProperty);
    
    return [self phoneNumberPrioritizationLogic:myContactObject ABmultivalueref:mvr];
}

- (Contact *) phoneNumberPrioritizationLogic: (Contact *) myContactObject ABmultivalueref: (ABMultiValueRef) mvr{
    // You need to loop through every phone number reference in the multievaluereference
    // along with its label string
    // then you compare the label string to an actual string ... to see what kind of reference that number is
    // iPhone label should be useds first, mobile second, home third, and all else just defaults to first number on top
    
    NSString *iphoneNumber;
    NSString *mobileNumber;
    NSString *homeNumber;
    
    for(CFIndex numberIndex = 0; numberIndex < ABMultiValueGetCount(mvr); numberIndex++)
    {
        CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(mvr, numberIndex);
        NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
        CFStringRef locLabel = ABMultiValueCopyLabelAtIndex(mvr, numberIndex);
        NSString *phoneLabel =(__bridge NSString*) ABAddressBookCopyLocalizedLabel(locLabel);
        
        if ([phoneLabel isEqualToString:@"iPhone"])// iPhone number saving.
        {
            iphoneNumber = phoneNumber;
        }
        else if ([phoneLabel isEqualToString:@"mobile"])// mobile number saving.
        {
            mobileNumber = phoneNumber;
        }
        else if ([phoneLabel isEqualToString:@"home"])// home number saving.
        {
            homeNumber = phoneNumber;
        }
    }
    
    if ([self validatePhoneNumber:iphoneNumber]) {
        myContactObject.mobileNumber =  iphoneNumber;
        return myContactObject;
    }
    else if ([self validatePhoneNumber:mobileNumber]) {
        myContactObject.mobileNumber =  mobileNumber;
        return myContactObject;
    }
    else if ([self validatePhoneNumber:homeNumber]) {
        myContactObject.mobileNumber =  homeNumber;
        return myContactObject;
    }
    
    //if all else fails, then just return the top-most phone number registered to the contact
    myContactObject.mobileNumber =  (__bridge NSString *)(ABMultiValueCopyValueAtIndex(mvr, 0));
    return myContactObject;
}




- (void) startListeningForABChanges {
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil); // indirection
    ABAddressBookRegisterExternalChangeCallback(addressBookRef, addressBookChanged, (__bridge void *)(self));
}



void ABAddressBookRegisterExternalChangeCallback (
                                                  ABAddressBookRef addressBook,
                                                  ABExternalChangeCallback callback,
                                                  void *context
                                                  );


void addressBookChanged(ABAddressBookRef abRef, CFDictionaryRef dicRef, void *context) {
    
    NSLog(@"Some Address Book Change Detected");
    //Gets triggered on any change: delete contact, add contact, edit contact phone
    
    //C function would not let me use [self] so had to do a funky
    TBContactsGrabber *mytbcb = (__bridge TBContactsGrabber *)(context);
    [mytbcb addNewContactsIntoCustomArray];
}




- (void) addNewContactsIntoCustomArray {
    CFErrorRef error = nil;
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error); // indirection
    NSArray *allContacts = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    
    //iterate through your existing array and create a new array with just the phone number from each contact
    NSMutableArray *allNamesFromSavedArray = [[NSMutableArray alloc]init];
    for (int i=0; i < self.savedArrayOfContactsWithPhoneNumbers.count; i++) {
        Contact *selectedContact = self.savedArrayOfContactsWithPhoneNumbers[i];
        [allNamesFromSavedArray addObject:[NSString stringWithFormat:@"%@ %@", selectedContact.firstName, selectedContact.lastName]];
    }
    
    //this above array has all the names, Kate Bell, Daniel Higgins
    //now, go through all the addressbook, and find contact refs that are NOT THOSE NAMES
    
    for (id record in allContacts){
        ABRecordRef thisContact = (__bridge ABRecordRef)record;
        NSString* firstName = (__bridge NSString *)(ABRecordCopyValue(thisContact, kABPersonFirstNameProperty));
        NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(thisContact, kABPersonLastNameProperty));
        NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        
        if (![allNamesFromSavedArray containsObject:fullName]) {
            Contact *newContact = [self createContactObjectBasedOnAddressBookRecord:thisContact];
            [self.savedArrayOfContactsWithPhoneNumbers addObject:newContact];
            NSLog(@"Added new contact: %@", fullName);
            
            NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:true];
            NSArray *sortDescriptors = [NSArray arrayWithObject:sorter];
            [self.savedArrayOfContactsWithPhoneNumbers sortUsingDescriptors:sortDescriptors];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate didFinishGrabbingContactsFromAddressBook];
            });
        }
    }
}


- (void) logOutSavedArray {
    for (int i=0; i < self.savedArrayOfContactsWithPhoneNumbers.count; i++) {
        Contact *contact = self.savedArrayOfContactsWithPhoneNumbers[i];
        NSLog(@"%@ %@: %@", contact.firstName, contact.lastName, contact.mobileNumber);
    }
}

- (BOOL) validatePhoneNumber: (NSString *) somePhoneNumber {
    if (somePhoneNumber == nil && [somePhoneNumber length] < 10)
        return NO;
    
    return YES;
}


@end
