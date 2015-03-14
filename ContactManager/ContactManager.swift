//
//  ContactManager.swift
//  ContactManager
//
//  Created by 程巍巍 on 3/13/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//  
//  由程巍巍整理，引用请注明出处

import Foundation
import AddressBook

let ContactManagerRecordDidChangeNotification: String = "ContactManagerRecordDidChangeNotification"

final class ContactManager {
    
    // 应用启动后，第一次使用前必须先调用该方法
    // handler 不一定在调用者线程中执行，需要时，需同步到调用者线程，如：handler 中更新界面
    class func checkAccessStatus(#handler: ((authorizeSuccess: Bool, error: NSError?) ->Void)?)->Void{
        // 获取授权状态
        switch (ABAddressBookGetAuthorizationStatus()){
        case  .Authorized:
            if handler == nil {return}
            handler!(authorizeSuccess: true, error: nil)
        case  .NotDetermined :
            requestAccess(handler)
        case  .Denied ,.Restricted:
            if handler == nil {return}
            handler!(authorizeSuccess: true, error: NSError(domain: "Authroization denied !", code: 0, userInfo: nil))
        }
        
    }
    
    class func allRecord()->[Record]{
        var records = ABAddressBookCopyArrayOfAllPeople(Singleton.addressBook).takeRetainedValue()
        var persons = [Record]()
        for record in records as NSArray{
            persons.append(Record(record: record))
        }
        return persons
    }
    
    class func record(#name: String) -> [Record]{
        var records = ABAddressBookCopyPeopleWithName(Singleton.addressBook, name).takeRetainedValue()
        var persons = [Record]()
        for record in records as NSArray{
            persons.append(Record(record: record))
        }
        return persons
    }
    
    /**
    *   加载 lastRecord 后面的记录，可指定加载的个数，
    *   loadedCount 为已加载的个数， lastRecord 为已加载的最后一条记录
    *
    */
    class func record(#count: Int, loadedCount: Int, lastRecord: Record?) -> [Record]{
        var persons = [Record]()
        var remainCount = recordCount() - loadedCount
        var index = lastRecord != nil ? lastRecord!.id.toInt()! : 0
        var record: ABRecordRef?
        while(persons.count < count && persons.count < remainCount){
            index += 1
            record = ABAddressBookGetPersonWithRecordID(Singleton.addressBook, ABRecordID(index))?.takeRetainedValue()
            if record == nil {continue}
            persons.append(Record(record: record!))
        }
        return persons
    }
    
    class func record(#recordId: String) -> Record?{
        var id = recordId.toInt()
        if id == nil { return nil}
        var record = ABAddressBookGetPersonWithRecordID(Singleton.addressBook, ABRecordID(id!))
        if record == nil {return nil}
        return Record(record: record!.takeRetainedValue())
    }
    
    class func recordCount() -> Int{
        return ABAddressBookGetPersonCount(Singleton.addressBook)
    }
}

extension ContactManager{
    
    private struct Singleton {
        static let workLabel:           String = kABWorkLabel
        static let homeLabel:           String = kABHomeLabel
        static let otherLabel:          String = kABOtherLabel
        // phone label
        static let mobilePhoneLabel:    String = kABPersonPhoneMobileLabel
        static let ipPhoneLabel:        String = kABPersonPhoneIPhoneLabel
        static let mainPhoneLabel:      String = kABPersonPhoneMainLabel
        static let homeFAXLabel:        String = kABPersonPhoneHomeFAXLabel
        static let workFaxLabel:        String = kABPersonPhoneWorkFAXLabel
        static let otherFAXLabel:       String = kABPersonPhoneOtherFAXLabel
        static let pagerLabel:          String = kABPersonPhonePagerLabel
        // address label
        static let streetLabel:         String = kABPersonAddressStreetKey
        static let cityLabel:           String = kABPersonAddressCityKey
        static let stateLabel:          String = kABPersonAddressStateKey
        static let zipLabel:            String = kABPersonAddressZIPKey
        static let countryLabel:        String = kABPersonAddressCountryKey
        static let countryCodeLabel:    String = kABPersonAddressCountryCodeKey
        
        private static var onceToken: dispatch_once_t = 0
        private static var addressBookRef: ABAddressBookRef!
        private static var addressBook: ABAddressBookRef{
            get{
                dispatch_once(&onceToken, { () -> Void in
                    self.addressBookRef = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
                    var context = UnsafeMutablePointer<Void>()
                    
                    // 监听外部修正
//                    let pointer = UnsafeMutablePointer<(ABAddressBook!, CFDictionary!, UnsafeMutablePointer<Void>) -> Void>.alloc(1)
//                    pointer.initialize(Singleton.externalChangeCallbackFunction)
//                    let cPointer = COpaquePointer(pointer)
//                    let functionPointer = ABExternalChangeCallback(cPointer)
//                    ABAddressBookRegisterExternalChangeCallback(Singleton.addressBookRef, functionPointer, context)
                })
                return addressBookRef
            }
        }
        
        private static func externalChangeCallbackFunction(addressBook: ABAddressBook!, userInfo: CFDictionary!, context: UnsafeMutablePointer<Void>) -> Void{
            NSNotificationCenter.defaultCenter().postNotificationName(ContactManagerRecordDidChangeNotification, object: nil, userInfo: userInfo)
        }
    }
    
    private class func requestAccess(handler: ((authorizeSuccess: Bool, error: NSError?) ->Void)?) ->Void {
        ABAddressBookRequestAccessWithCompletion(Singleton.addressBook, { (granted: Bool, error: CFError!) -> Void in
            if handler == nil {return}
            handler!(authorizeSuccess: granted, error:error == nil ? nil : NSError(domain: CFErrorGetDomain(error), code: CFErrorGetCode(error), userInfo: CFErrorCopyUserInfo(error)))
        })
    }
    
    
}

extension ContactManager {
    class Record {
        private var record: ABRecordRef!
        
        init(record: ABRecordRef){
            self.record = record
        }
        
        var id: String {
            get{
                return ABRecordGetRecordID(record).description
            }
        }
        
        var firstName: String?{
            get{
                return ABRecordCopyValue(record, kABPersonFirstNameProperty)?.takeRetainedValue() as? String
            }
        }
        var lastName: String?{
            get{
                return ABRecordCopyValue(record, kABPersonLastNameProperty)?.takeRetainedValue() as? String
            }
        }
        var middleName: String?{
            get{
                return ABRecordCopyValue(record, kABPersonMiddleNameProperty)?.takeRetainedValue() as? String
            }
        }
        var prefix: String?{
            get{
                return ABRecordCopyValue(record, kABPersonPrefixProperty)?.takeRetainedValue() as? String
            }
        }
        var suffix: String?{
            get{
                return ABRecordCopyValue(record, kABPersonSuffixProperty)?.takeRetainedValue() as? String
            }
        }
        var nickName: String?{
            get{
                return ABRecordCopyValue(record, kABPersonNicknameProperty)?.takeRetainedValue() as? String
            }
        }
        var organization: String?{
            get{
                return ABRecordCopyValue(record, kABPersonOrganizationProperty)?.takeRetainedValue() as? String
            }
        }
        var job: String?{
            get{
                return ABRecordCopyValue(record, kABPersonJobTitleProperty)?.takeRetainedValue() as? String
            }
        }
        var Department: String?{
            get{
                return ABRecordCopyValue(record, kABPersonDepartmentProperty)?.takeRetainedValue() as? String
            }
        }
        var email: Email{
            get{
                var value: ABMultiValueRef? = ABRecordCopyValue(record, kABPersonEmailProperty)?.takeRetainedValue()
                return Email(value: value)
            }
        }
        var birthday: NSDate?{
            get{
                return ABRecordCopyValue(record, kABPersonBirthdayProperty)?.takeRetainedValue() as? NSDate
            }
        }
        var note: String?{
            get{
                return ABRecordCopyValue(record, kABPersonNoteProperty)?.takeRetainedValue() as? String
            }
        }
        var address: Address{
            get{
                var value: ABMultiValueRef? = ABRecordCopyValue(record, kABPersonAddressProperty)?.takeRetainedValue()
                return Address(value: value)
            }
        }
        var phone: Phone{
            get{
                var value: ABMultiValueRef? = ABRecordCopyValue(record, kABPersonPhoneProperty)?.takeRetainedValue()
                return Phone(value: value)
            }
        }
        var avatar: NSData?{
            get{
                return ABPersonCopyImageData(self.record)?.takeRetainedValue()
            }
        }
    }
}

extension ContactManager.Record {
    class Phone {
        var value = [String: String]()
        init(value: ABMultiValueRef?){
            if value == nil {return}
            var count = ABMultiValueGetCount(value)
            var label: String
            var property: String
            for index in 0..<count{
                label = ABMultiValueCopyLabelAtIndex(value, index).takeRetainedValue()
                property = ABMultiValueCopyValueAtIndex(value, index).takeRetainedValue() as String
                self.value[label] = property
            }
        }
        var mobile: String?{
            get{
                return self.value[ContactManager.Singleton.mobilePhoneLabel]
            }
        }
        var ip: String?{
            get{
                return self.value[ContactManager.Singleton.ipPhoneLabel]
            }
        }
        var main: String?{
            get{
                return self.value[ContactManager.Singleton.mainPhoneLabel]
            }
        }
        var homeFAX: String?{
            get{
                return self.value[ContactManager.Singleton.homeFAXLabel]
            }
        }
        var workFAX: String?{
            get{
                return self.value[ContactManager.Singleton.workFaxLabel]
            }
        }
        var otherFax: String?{
            get{
                return self.value[ContactManager.Singleton.otherFAXLabel]
            }
        }
        var pager: String?{
            get{
                return self.value[ContactManager.Singleton.pagerLabel]
            }
        }
    }
}
extension ContactManager.Record {
    class Email {
        private var value = [String: String]()
        init(value: ABMultiValueRef?){
            if value == nil {return}
            var count = ABMultiValueGetCount(value)
            var label: String
            var property: String
            for index in 0..<count{
                label = ABMultiValueCopyLabelAtIndex(value, index).takeRetainedValue()
                property = ABMultiValueCopyValueAtIndex(value, index).takeRetainedValue() as String
                self.value[label] = property
            }
        }
        
        var work: String?{
            get{
                return value[ContactManager.Singleton.workLabel]
            }
        }
        var home: String?{
            get{
                return value[ContactManager.Singleton.homeLabel]
            }
        }
        var other: String?{
            get{
                return value[ContactManager.Singleton.otherLabel]
            }
        }
    }
}

extension ContactManager.Record {
    class Address {
        private var value: [String: AddressItem]!
        
        init(value: ABMultiValueRef?){
            if value == nil {return}
            var count = ABMultiValueGetCount(value)
            self.value = [String: AddressItem]()
            for index in 0..<count{
                var label: String = ABMultiValueCopyLabelAtIndex(value, index).takeRetainedValue()
                var property = ABMultiValueCopyValueAtIndex(value, index).takeRetainedValue() as [String: String]
                self.value[label] = AddressItem(value: property)
            }
        }
        
        var work: AddressItem?{
            get{
                return value[ContactManager.Singleton.workLabel]
            }
        }
        var home: AddressItem?{
            get{
                return value[ContactManager.Singleton.homeLabel]
            }
        }
        var other: AddressItem?{
            get{
                return value[ContactManager.Singleton.otherLabel]
            }
        }
        
        class AddressItem {
            var value = [String: String]()
            init(value: [String: String]){
                self.value = value
            }
            var street: String?{
                get{
                    return self.value[ContactManager.Singleton.streetLabel]
                }
            }
            var city: String?{
                get{
                    return self.value[ContactManager.Singleton.cityLabel]
                }
            }
            var state: String?{
                get{
                   return self.value[ContactManager.Singleton.stateLabel]
                }
            }
            var zip: String?{
                get{
                    return self.value[ContactManager.Singleton.zipLabel]
                }
            }
            var country: String?{
                get{
                    return self.value[ContactManager.Singleton.countryCodeLabel]
                }
            }
            var countryCode: String?{
                get{
                    return self.value[ContactManager.Singleton.countryCodeLabel]
                }
            }
        }
    }
}