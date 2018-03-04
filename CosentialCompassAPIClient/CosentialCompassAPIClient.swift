//
//  CosentialCompassAPIClient.swift
//  CosentialCompassAPIClient
//
//  Created by SoftDev on 2/13/17.
//
//

import Alamofire

public protocol CosentialCompassAPIClientDelegate {
    func onSuccess(apiName: String, data: AnyObject, userInfo: Any?)
    func onError(apiName: String, errorInfo: AnyObject, userInfo: Any?)
    func onNoInternet(apiName: String, errorInfo: AnyObject, userInfo: Any?)
}

public class CosentialCompassAPIClient {
    
    static var delegate: CosentialCompassAPIClientDelegate?
    
    static var SERVER_URL = ""
    static var API_KEY = ""
    static var AuthHeader = ["Accept" : "application/json", "Content-Type" : "application/json"]
    static var user = ""
    static var firmCode = ""
    static var logText = ""
    static var debugMode = false
    
    ////////////////////////////////
    
    class func callAPI(type: HTTPMethod, name: String, endPoint: String, parameters: [String : Any], headers: HTTPHeaders, userInfo: Any?) {
        
        Alamofire.request(endPoint, method: type, parameters: parameters, encoding: URLEncoding.default, headers: headers).validate().responseJSON { (response) in
            if (debugMode) {
                print(response)
            }
            
            if (type == .delete) {
                self.delegate!.onSuccess(apiName: name, data: "" as AnyObject, userInfo: userInfo)
                return
            }
            
            switch response.result {
            case.success(let value):
                self.delegate!.onSuccess(apiName: name, data: value as AnyObject, userInfo: userInfo)
                break
                
            case.failure(let error):
                let errorInfoString = "Name: \(user), FirmID: \(firmCode)\nError: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(parameters)\n\n"
                logText = logText + errorInfoString
                
                if error is URLError {
                    self.delegate!.onNoInternet(apiName: name, errorInfo: errorInfoString as AnyObject, userInfo: userInfo)
                }
                else {
                    self.delegate!.onError(apiName: name, errorInfo: errorInfoString as AnyObject, userInfo: userInfo)
                }
                break
            }
        }
    }
    
    class func callAPIWithBlock(type: HTTPMethod, endPoint: String, parameters: [String : Any], headers: HTTPHeaders, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        
        Alamofire.request(endPoint, method: type, parameters: parameters, encoding: URLEncoding.default, headers: headers).validate().responseJSON { (response) in
            if (debugMode) {
                print(response)
            }
            
            if (type == .delete) {
                success("" as AnyObject)
                return
            }
            
            switch response.result {
            case.success(let value):
                success(value as AnyObject)
                break
                
            case.failure(let error):
                let errorInfoString = "Error: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(parameters)\n\n"
                logText = logText + "Name: \(user), FirmID: \(firmCode)\n" + errorInfoString
                
                if error is URLError {
                    failure(error as AnyObject)
                }
                else {
                    failure(error as AnyObject)
                }
                break
            }
        }
    }
    
    class func callAPIWithBodyData(type: String, name: String, endPoint: String, data: [[String : Any]], userInfo: Any?) {
        var request = URLRequest(url: URL.init(string: endPoint)!)
        request.httpMethod = type
        request.allHTTPHeaderFields = AuthHeader
        
        if (type == "POST") {
            request.httpBody = try! JSONSerialization.data(withJSONObject: data)
        }
        else if (type == "PUT") {
            if (name == "updateContactAddresses" || name == "updateCompanyAddresses") {
                request.httpBody = try! JSONSerialization.data(withJSONObject: data)
            }
            else {
                if (data.count > 0) {
                    request.httpBody = try! JSONSerialization.data(withJSONObject: data[0])
                }
            }
        }
        
        if (name == "addContactCardFrontImage" || name == "addContactCardBackImage" || name == "addContactProfilePicture") {
            Alamofire.request(request).responseString { response in
                if (debugMode) {
                    print(response)
                }
                switch response.result {
                case .success(let value):
                    self.delegate!.onSuccess(apiName: name, data: value as AnyObject, userInfo: userInfo)
                    break
                    
                case .failure(let error):
                    let errorInfoString = "Name: \(user), FirmID: \(firmCode)\nError: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(data)\n\n"
                    logText = logText + errorInfoString
                    
                    if error is URLError {
                        self.delegate!.onNoInternet(apiName: name, errorInfo: errorInfoString as AnyObject, userInfo: userInfo)
                    }
                    else {
                        self.delegate!.onError(apiName: name, errorInfo: errorInfoString as AnyObject, userInfo: userInfo)
                    }
                    break
                }
            }
        }
        else
        {
            Alamofire.request(request).responseJSON { response in
                if (debugMode) {
                    print(response)
                }
                switch response.result {
                case .success(let value):
                    self.delegate!.onSuccess(apiName: name, data: value as AnyObject, userInfo: userInfo)
                    break
                    
                case .failure(let error):
                    let errorInfoString = "Name: \(user), FirmID: \(firmCode)\nError: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(data)\n\n"
                    logText = logText + errorInfoString
                    
                    if error is URLError {
                        self.delegate!.onNoInternet(apiName: name, errorInfo: errorInfoString as AnyObject, userInfo: userInfo)
                    }
                    else {
                        self.delegate!.onError(apiName: name, errorInfo: errorInfoString as AnyObject, userInfo: userInfo)
                    }
                    break
                }
            }
        }
    }
    
    ////////////////////////////////
    
    public class func setDelegate(_ delegate: CosentialCompassAPIClientDelegate) {
        self.delegate = delegate
    }
    
    public class func setConfiguration(_ url: String, key: String) {
        self.SERVER_URL = url
        self.API_KEY = key
    }
    
    public class func setUserInfo(parameters: [String : String]) {
        AuthHeader["x-compass-firm-id"] = parameters["firmCode"]
        AuthHeader["x-compass-api-key"] = API_KEY
        
        let user = parameters["user"]
        let password = parameters["password"]
        let loginString = user! + ":" + password!
        let credentialData = loginString.data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString()
        AuthHeader["Authorization"] = "Basic \(base64Credentials)"
    }
    
    public class func setDebugMode(_ isEnable: Bool) {
        self.debugMode = isEnable
    }
    
    public class func getLog() -> String {
        return logText
    }
    
    public class func deleteLog() {
        logText = ""
    }
    
    ////////////////////////////////
    
    public class func signIn(parameters: [String : String]) {
        let endPoint = SERVER_URL + "user"
        
        setUserInfo(parameters: parameters)
        
        callAPI(type: .get, name: "signIn", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    ////////////////////////////////
    
    public class func getSchema(_ element: String, parameters: [String : Any]) {
        let endPoint = "\(SERVER_URL)/\(element)/schema"
        callAPI(type: .get, name: "getSchema", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: element)
    }
    
    ////////////////////////////////
    
    //  Company
    
    public class func getCompanies(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "companies"
        
        callAPI(type: .get, name: "getCompanies", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func searchCompanies(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "companies/search"
        
        callAPI(type: .get, name: "searchCompanies", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getChangedCompanies(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "companies/changes"
        
        callAPI(type: .get, name: "getChangedCompanies", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getCompany(companyId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)"
        
        callAPI(type: .get, name: "getCompany", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func addCompany(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "companies"
        
        callAPIWithBodyData(type: "POST", name: "addCompany", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    public class func updateCompany(companyId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)"
        
        callAPIWithBodyData(type: "PUT", name: "updateCompany", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    public class func getCompanyContacts(companyId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/contacts"
        
        callAPI(type: .get, name: "getCompanyContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getCompanyTypes() {
        let endPoint = SERVER_URL + "companies/companytypes"
        
        callAPI(type: .get, name: "getCompanyTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func getCompanyCompanyTypes(_ companyId: Int, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/companytypes"
        
        callAPI(type: .get, name: "getCompanyCompanyTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func addCompanyTypes(_ companyId: Int, parameters: [[String : Any]], info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/companytypes"
        
        callAPIWithBodyData(type: "POST", name: "addCompanyTypes", endPoint: endPoint, data: parameters, userInfo: info)
    }
    
    public class func deleteCompanyTypes(_ companyId: Int, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/companytypes"
        
        callAPI(type: .delete, name: "deleteCompanyTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func getCompanyAddresses(companyId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/addresses"
        
        callAPI(type: .get, name: "getCompanyAddresses", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func addCompanyAddresses(companyId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/addresses"
        
        callAPIWithBodyData(type: "POST", name: "addCompanyAddresses", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    public class func updateCompanyAddresses(companyId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/addresses"
        
        callAPIWithBodyData(type: "PUT", name: "updateCompanyAddresses", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    ////////////////////////////////
    
    //  Contact
    
    public class func getContacts(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "contacts"
        
        callAPI(type: .get, name: "getContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func searchContacts(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "contacts/search"
        
        callAPI(type: .get, name: "searchContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getChangedContacts(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "contacts/changes"
        
        callAPI(type: .get, name: "getChangedContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func addContact(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "contacts"
        
        callAPIWithBodyData(type: "POST", name: "addContact", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    public class func updateContact(contactId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)"
        
        callAPIWithBodyData(type: "PUT", name: "updateContact", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    public class func getContactDetail(_ contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)"
        
        callAPI(type: .get, name: "getContactDetail", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func deleteContact(_ contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)"
        
        callAPI(type: .delete, name: "deleteContact", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func getContactCardFrontImage(contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardfront"
        
        callAPI(type: .get, name: "getContactCardFrontImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func addContactCardFrontImage(contactId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardfront"
        
        callAPIWithBodyData(type: "PUT", name: "addContactCardFrontImage", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    public class func deleteContactCardFrontImage(contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardfront"
        
        callAPI(type: .delete, name: "deleteContactCardFrontImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func getContactCardBackImage(contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardback"
        
        callAPI(type: .get, name: "getContactCardBackImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func addContactCardBackImage(contactId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardback"
        
        callAPIWithBodyData(type: "PUT", name: "addContactCardBackImage", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    public class func deleteContactCardBackImage(contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardback"
        
        callAPI(type: .delete, name: "deleteContactCardBackImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func getContactProfilePicture(contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/profilepicture"
        
        callAPI(type: .get, name: "getContactProfilePicture", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func addContactProfilePicture(contactId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/profilepicture"
        
        callAPIWithBodyData(type: "PUT", name: "addContactProfilePicture", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    public class func addContactProfilePictureWithUrl(contactId: Int, url: String, info: Any?) {
        var endPoint = SERVER_URL + "images/contact/\(contactId)/profilepicture"
        endPoint = "\(endPoint)?url=\(url)"
        
        callAPIWithBodyData(type: "PUT", name: "addContactProfilePicture", endPoint: endPoint, data: [], userInfo: info)
    }
    
    public class func deleteContactProfilePicture(contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/profilepicture"
        
        callAPI(type: .delete, name: "deleteContactProfilePicture", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func getContactTypes() {
        let endPoint = SERVER_URL + "contacts/types"
        
        callAPI(type: .get, name: "getContactTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func getContactContactTypes(contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/types"
        
        callAPI(type: .get, name: "getContactContactTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func addContactTypes(_ contactId: Int, parameters: [[String : Any]], info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/types"
        
        callAPIWithBodyData(type: "POST", name: "addContactTypes", endPoint: endPoint, data: parameters, userInfo: info)
    }
    
    public class func deleteContactTypes(_ contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/types"
        
        callAPI(type: .delete, name: "deleteContactTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func getContactAddresses(contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/addresses"
        
        callAPI(type: .get, name: "getContactAddresses", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func addContactAddresses(contactId: Int, parameters: [[String : Any]], info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/addresses"
        
        callAPIWithBodyData(type: "POST", name: "addContactAddresses", endPoint: endPoint, data: parameters, userInfo: info)
    }
    
    public class func updateContactAddresses(contactId: Int, parameters: [[String : Any]], info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/addresses"
        
        callAPIWithBodyData(type: "PUT", name: "updateContactAddresses", endPoint: endPoint, data: parameters, userInfo: info)
    }
    
    public class func addContactRelationships(_ contactId: Int, parameters: [[String : Any]], info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/relationships"
        
        callAPIWithBodyData(type: "POST", name: "addContactRelationships", endPoint: endPoint, data: parameters, userInfo: info)
    }
    
    public class func getContactOpportunities(contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/opportunities"
        
        callAPI(type: .get, name: "getContactOpportunities", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func getContactProjects(contactId: Int, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/projects"
        
        callAPI(type: .get, name: "getContactProjects", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    ////////////////////////////////
    
    //  CallLog
    
    public class func getCallLogCallTypes() {
        let endPoint = SERVER_URL + "calllogs/calltype"
        
        callAPI(type: .get, name: "getCallLogCallTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: nil)
    }
    
    public class func getCallLogs(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "calllogs"
        
        callAPI(type: .get, name: "getCallLogs", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getCallLogContacts(callLogId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/contacts"
        
        callAPI(type: .get, name: "getCallLogContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getCallLogCompanies(callLogId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/companies"
        
        callAPI(type: .get, name: "getCallLogCompanies", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getCallLogLeads(callLogId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/leads"
        
        callAPI(type: .get, name: "getCallLogLeads", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getCallLogOpportunities(callLogId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/opportunities"
        
        callAPI(type: .get, name: "getCallLogOpportunities", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getCallLogProjects(callLogId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/projects"
        
        callAPI(type: .get, name: "getCallLogProjects", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func searchCallLogs(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "calllogs/search"
        callAPI(type: .get, name: "searchCallLogs", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getContactCallLogs(contactId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "calllogs/search"
        var searchParameters = parameters
        searchParameters["q"] = "Contacts.ContactId:\(contactId)"
        
        callAPI(type: .get, name: "getContactCallLogs", endPoint: endPoint, parameters: searchParameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func addCallLog(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "calllogs"
        
        callAPIWithBodyData(type: "POST", name: "addCallLog", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    public class func updateCallLog(callLogId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)"
        
        callAPIWithBodyData(type: "PUT", name: "updateCallLog", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    public class func deleteCallLog(_ callLogId: Int, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)"
        
        callAPI(type: .delete, name: "deleteCallLog", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func addContactInfoToCallLog(callLogId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/contacts"
        
        callAPIWithBodyData(type: "POST", name: "addContactInfoToCallLog", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    public class func addCompanyInfoToCallLog(callLogId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/companies"
        
        callAPIWithBodyData(type: "POST", name: "addCompanyInfoToCallLog", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    ////////////////////////////////
    
    public class func addLead(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "leads"
        
        callAPIWithBodyData(type: "POST", name: "addLead", endPoint: endPoint, data: [parameters], userInfo: nil)
    }
    
    public class func addContactInfoToLead(leadId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "leads/\(leadId)/associatedcontacts"
        
        callAPIWithBodyData(type: "POST", name: "addContactInfoToLead", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    public class func addCompanyInfoToLead(leadId: Int, parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "leads/\(leadId)/potentialclient"
        
        callAPIWithBodyData(type: "POST", name: "addCompanyInfoToLead", endPoint: endPoint, data: [parameters], userInfo: info)
    }
    
    ////////////////////////////////
    
    public class func getOpportunities(parameters: [String : Any]) {
        let endPoint = SERVER_URL + "opportunities"
        
        callAPI(type: .get, name: "getOpportunities", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: nil)
    }
    
    public class func searchOpportunities(parameters: [String : Any]) {
        let endPoint = SERVER_URL + "opportunities/search"
        
        callAPI(type: .get, name: "searchOpportunities", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: nil)
    }
    
    public class func getProjects(parameters: [String : Any]) {
        let endPoint = SERVER_URL + "projects"
        
        callAPI(type: .get, name: "getProjects", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: nil)
    }
    
    public class func searchProjects(parameters: [String : Any]) {
        let endPoint = SERVER_URL + "projects/search"
        
        callAPI(type: .get, name: "searchProjects", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: nil)
    }
    
    public class func getOffices(parameters: [String : Any]) {
        let endPoint = SERVER_URL + "contacts/offices"
        
        callAPI(type: .get, name: "getOffices", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: nil)
    }
    
    ////////////////////////////////
    
    public class func getProjectFirmOrg(_ firmOrgName: String, parameters: [String : Any]) {
        let endPoint = "\(SERVER_URL)/projects/\(firmOrgName)"
        
        callAPI(type: .get, name: "getProjectFirmOrg", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: firmOrgName)
    }
    
    ////////////////////////////////
    
    //  Personnel
    
    public class func getPersonnel(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "personnel"
        
        callAPI(type: .get, name: "getPersonnel", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func searchPersonnel(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "personnel/search"
        
        callAPI(type: .get, name: "searchPersonnel", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getChangedPersonnel(parameters: [String : Any], info: Any?) {
        let endPoint = SERVER_URL + "personnel/changes"
        
        callAPI(type: .get, name: "getChangedPersonnel", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getPersonnelProfilePictures(personnelId: Int, info: Any?) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/images"
        
        callAPI(type: .get, name: "getPersonnelProfilePictures", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func getPersonnelProfilePictures(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/images"
        
        callAPIWithBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelProfilePicture(personnelId: Int, imageId: Int, info: Any?) {
        let endPoint = SERVER_URL + "images/personnel/\(personnelId)/\(imageId)"
        
        callAPI(type: .get, name: "getPersonnelProfilePicture", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func getPersonnelProfileThumbPicture(personnelId: Int, imageId: Int, info: Any?) {
        let endPoint = SERVER_URL + "images/personnel/\(personnelId)/\(imageId)/thumb"
        
        callAPI(type: .get, name: "getPersonnelProfileThumbPicture", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func getPersonnelProfileThumbPicture(personnelId: Int, imageId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "images/personnel/\(personnelId)/\(imageId)/thumb"
        
        callAPIWithBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelOpportunities(personnelId: Int, info: Any?) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/opportunities"
        
        callAPI(type: .get, name: "getPersonnelOpportunities", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func getPersonnelProjects(personnelId: Int, info: Any?) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/projects"
        
        callAPI(type: .get, name: "getPersonnelProjects", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: info)
    }
    
    public class func getPersonnelOffices(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/offices"
        
        callAPIWithBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelDivisions(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/divisions"
        
        callAPIWithBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelStudios(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/studios"
        
        callAPIWithBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelPracticeAreas(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/practiceareas"
        
        callAPIWithBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelTerritories(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/territories"
        
        callAPIWithBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelStaffRoles(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/staffroles"
        
        callAPIWithBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    ////////////////////////////////
}
