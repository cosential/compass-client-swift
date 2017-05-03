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
}

public class CosentialCompassAPIClient {
    
    static var delegate: CosentialCompassAPIClientDelegate?
    
    static var SERVER_URL = ""
    static var API_KEY = ""
    static var AuthHeader = [String : String]()
    static var user = ""
    static var firmCode = ""
    static var logText = ""
    static var debugMode = false
    
    ////////////////////////////////
    
    class func callAPI(type: HTTPMethod, name: String, endPoint: String, parameters: [String : Any], headers: HTTPHeaders, userInfo: Any?) {
        
        let newHeader = headers
        
        Alamofire.request(endPoint, method: type, parameters: parameters, encoding: URLEncoding.default, headers: newHeader).validate().responseJSON { (response) in
            if (debugMode) {
                print(response)
            }
            
            if (name == "deleteContactTypes") {
                self.delegate!.onSuccess(apiName: name, data: "" as AnyObject, userInfo: userInfo)
                return
            }
            
            switch response.result {
            case.success(let value):
                self.delegate!.onSuccess(apiName: name, data: value as AnyObject, userInfo: userInfo)
                break
                
            case.failure(let error):
                let errorInfoString = "Error: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(parameters)\n\n"
                logText = logText + "Name: \(user), FirmID: \(firmCode)\n" + errorInfoString
                self.delegate!.onError(apiName: name, errorInfo: error as AnyObject, userInfo: userInfo)
                break
            }
        }
    }
    
    class func callAPIWithBodyData(type: String, name: String, endPoint: String, data: [[String : Any]], userInfo: Any?) {
        var request = URLRequest(url: URL.init(string: endPoint)!)
        request.httpMethod = type
        request.allHTTPHeaderFields = AuthHeader
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField:  "Accept")
        
        if (type == "POST") {
            request.httpBody = try! JSONSerialization.data(withJSONObject: data)
        }
        else if (type == "PUT") {
            if (name == "updateContactAddresses" || name == "updateCompanyAddresses") {
                request.httpBody = try! JSONSerialization.data(withJSONObject: data)
            }
            else {
                request.httpBody = try! JSONSerialization.data(withJSONObject: data[0])
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
                    let errorInfoString = "Error: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(data)\n\n"
                    logText = logText + "Name: \(user), FirmID: \(firmCode)\n" + errorInfoString
                    self.delegate!.onError(apiName: name, errorInfo: error as AnyObject, userInfo: userInfo)
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
                    let errorInfoString = "Error: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(data)\n\n"
                    logText = logText + "Name: \(user), FirmID: \(firmCode)\n" + errorInfoString
                    self.delegate!.onError(apiName: name, errorInfo: error as AnyObject, userInfo: userInfo)
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
    
    public class func setDebugMode(_ isEnable: Bool) {
        self.debugMode = isEnable
    }
    
    public class func getLog() -> String {
        return logText
    }
    
    ////////////////////////////////
    
    public class func signIn(parameters: [String : String]) {
        let endPoint = SERVER_URL + "user"
        AuthHeader["x-compass-firm-id"] = parameters["firmCode"]
        AuthHeader["x-compass-api-key"] = API_KEY
        AuthHeader["Accept"] = "application/json"
        
        let user = parameters["user"]
        let password = parameters["password"]
        let loginString = user! + ":" + password!
        let credentialData = loginString.data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString()
        AuthHeader["Authorization"] = "Basic \(base64Credentials)"
        
        callAPI(type: .get, name: "signIn", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    ////////////////////////////////
    
    public class func getSchema(_ element: String, parameters: [String : Any]) {
        let endPoint = "\(SERVER_URL)/\(element)/schema"
        callAPI(type: .get, name: "getSchema", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: element)
    }
    
    ////////////////////////////////
    
    //  Contact
    
    public class func getContactTypes() {
        let endPoint = SERVER_URL + "contacts/types"
        callAPI(type: .get, name: "getContactTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func addContactTypes(_ contactId: Int, parameters: [[String : Any]]) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/types"
        callAPIWithBodyData(type: "POST", name: "addContactTypes", endPoint: endPoint, data: parameters, userInfo: "")
    }
    
    public class func deleteContactTypes(_ contactId: Int) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/types"
        callAPI(type: .delete, name: "deleteContactTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func getContacts(parameters: [String : Any], info: String) {
        let endPoint = SERVER_URL + "contacts"
        
        callAPI(type: .get, name: "getContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getContactDetail(_ contactId: Int) {
        let endPoint = SERVER_URL + "contacts/\(contactId)"
        
        callAPI(type: .get, name: "getContactDetail", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func searchContacts(parameters: [String : Any]) {
        let endPoint = SERVER_URL + "contacts/search"
        callAPI(type: .get, name: "searchContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: "")
    }
    
    public class func searchContactsWithKeyword(keyword: String) {
        let endPoint = SERVER_URL + "contacts/search"
        var parameters = [String : String]()
        parameters["q"] = keyword
        
        callAPI(type: .get, name: "searchContactsWithKeyword", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: "")
    }
    
    public class func addContact(parameters: [String : Any]) {
        let endPoint = SERVER_URL + "contacts"
        callAPIWithBodyData(type:"POST", name: "addContact", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    public class func updateContact(contactId: Int, parameters: [String : Any]) {
        let endPoint = SERVER_URL + "contacts/\(contactId)"
        callAPIWithBodyData(type:"PUT", name: "updateContact", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    public class func getContactAddresses(contactId: Int) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/addresses"
        callAPI(type: .get, name: "getContactAddresses", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func addContactAddresses(contactId: Int, parameters: [[String : Any]], type: String) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/addresses"
        callAPIWithBodyData(type: "POST", name: "addContactAddresses", endPoint: endPoint, data: parameters, userInfo: type)
    }
    
    public class func updateContactAddresses(contactId: Int, parameters: [[String : Any]], type: String) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/addresses"
        callAPIWithBodyData(type: "PUT", name: "updateContactAddresses", endPoint: endPoint, data: parameters, userInfo: type)
    }
    
    public class func getContactCardFrontImage(contactId: Int) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardfront"
        callAPI(type: .get, name: "getContactCardFrontImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func getContactCardBackImage(contactId: Int) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardback"
        callAPI(type: .get, name: "getContactCardBackImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func getContactProfilePicture(contactId: Int) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/profilepicture"
        callAPI(type: .get, name: "getContactProfilePicture", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func addContactCardFrontImage(contactId: Int, parameters: [String : Any]) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardfront"
        callAPIWithBodyData(type: "PUT", name: "addContactCardFrontImage", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    public class func addContactCardBackImage(contactId: Int, parameters: [String : Any]) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardback"
        callAPIWithBodyData(type: "PUT", name: "addContactCardBackImage", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    public class func addContactProfilePicture(contactId: Int, parameters: [String : Any]) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/profilepicture"
        callAPIWithBodyData(type: "PUT", name: "addContactProfilePicture", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    public class func deleteContactCardFrontImage(contactId: Int) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardfront"
        callAPI(type: .delete, name: "deleteContactCardFrontImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func deleteContactCardBackImage(contactId: Int) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardback"
        callAPI(type: .delete, name: "deleteContactCardBackImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func deleteContactProfilePicture(contactId: Int) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/profilepicture"
        callAPI(type: .delete, name: "deleteContactProfilePicture", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func addContactRelationships(_ contactId: Int, parameters: [[String : Any]]) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/relationships"
        callAPIWithBodyData(type: "POST", name: "addContactRelationships", endPoint: endPoint, data: parameters, userInfo: "")
    }
    
    ////////////////////////////////
    
    //  Company
    
    public class func getCompanyTypes() {
        let endPoint = SERVER_URL + "companies/companytypes"
        callAPI(type: .get, name: "getCompanyTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func addCompanyTypes(_ companyId: Int, parameters: [[String : Any]]) {
        let endPoint = SERVER_URL + "companies/\(companyId)/companytypes"
        callAPIWithBodyData(type: "POST", name: "addCompanyTypes", endPoint: endPoint, data: parameters, userInfo: "")
    }
    
    public class func deleteCompanyTypes(_ companyId: Int) {
        let endPoint = SERVER_URL + "companies/\(companyId)/companytypes"
        callAPI(type: .delete, name: "deleteCompanyTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func searchCompaniesWithKeyword(keyword: String) {
        let endPoint = SERVER_URL + "companies/search"
        var parameters = [String : String]()
        parameters["q"] = keyword
        
        callAPI(type: .get, name: "searchCompaniesWithKeyword", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: "")
    }
    
    public class func getCompanies(parameters: [String : Any], info: String) {
        let endPoint = SERVER_URL + "companies"

        callAPI(type: .get, name: "getCompanies", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getCompany(companyId: Int, parameters: [String : Any], info: String) {
        let endPoint = SERVER_URL + "companies/\(companyId)"
        
        callAPI(type: .get, name: "getCompany", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func addCompany(parameters: [String : Any]) {
        let endPoint = SERVER_URL + "companies"
        callAPIWithBodyData(type:"POST", name: "addCompany", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    public class func getCompanyAddresses(companyId: Int, parameters: [String : Any], userInfo: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/addresses"
        callAPI(type: .get, name: "getCompanyAddresses", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: userInfo)
    }
    
    public class func addCompanyAddresses(companyId: Int, parameters: [String : Any]) {
        let endPoint = SERVER_URL + "companies/\(companyId)/addresses"
        callAPIWithBodyData(type:"POST", name: "addCompanyAddresses", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    public class func updateCompanyAddresses(companyId: Int, parameters: [String : Any]) {
        let endPoint = SERVER_URL + "companies/\(companyId)/addresses"
        callAPIWithBodyData(type:"PUT", name: "updateCompanyAddresses", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    public class func updateCompany(companyId: Int, parameters: [String : Any]) {
        let endPoint = SERVER_URL + "companies/\(companyId)"
        callAPIWithBodyData(type:"PUT", name: "updateCompany", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    ////////////////////////////////
    
    public class func addLead(parameters: [String : Any]) {
        let endPoint = SERVER_URL + "leads"
        callAPIWithBodyData(type:"POST", name: "addLead", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    public class func getOpportunities(parameters: [String : Any], userInfo: Any?) {
        let endPoint = SERVER_URL + "opportunities"
        callAPI(type: .get, name: "getOpportunities", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: userInfo)
    }
    
    public class func getProjects(parameters: [String : Any], userInfo: Any?) {
        let endPoint = SERVER_URL + "projects"
        callAPI(type: .get, name: "getProjects", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: userInfo)
    }
    
    public class func getOffices(parameters: [String : Any], userInfo: Any?) {
        let endPoint = SERVER_URL + "contacts/offices"
        callAPI(type: .get, name: "getOffices", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: userInfo)
    }
    
    ////////////////////////////////
    
    public class func getProjectFirmOrg(_ firmOrgName: String, parameters: [String : Any]) {
        let endPoint = "\(SERVER_URL)/projects/\(firmOrgName)"
        callAPI(type: .get, name: "getProjectFirmOrg", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: firmOrgName)
    }
    
    ////////////////////////////////
}
