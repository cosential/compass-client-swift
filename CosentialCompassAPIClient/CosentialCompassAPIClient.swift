//
//  CosentialCompassAPIClient.swift
//  CosentialCompassAPIClient
//
//  Created by SoftDev on 2/13/17.
//
//

import Alamofire

public protocol CosentialCompassAPIClientDelegate {
    func onSuccess(apiName: String, data: AnyObject, userInfo: Any)
    func onError(apiName: String, errorInfo: AnyObject, userInfo: Any)
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
    
    class func callAPI(type: HTTPMethod, name: String, endPoint: String, parameters: [String : Any], headers: HTTPHeaders, userInfo: Any) {
        
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
    
    class func callAPIWithBodyData(type: String, name: String, endPoint: String, data: [[String : Any]], userInfo: Any) {
        var request = URLRequest(url: URL.init(string: endPoint)!)
        request.httpMethod = type
        request.allHTTPHeaderFields = AuthHeader
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField:  "Accept")
        
        if (type == "POST") {
            request.httpBody = try! JSONSerialization.data(withJSONObject: data)
        }
        else if (type == "PUT") {
            if (name != "updateContactAddress") {
                request.httpBody = try! JSONSerialization.data(withJSONObject: data[0])
            }
            else {
                request.httpBody = try! JSONSerialization.data(withJSONObject: data)
            }
        }
        
        if (name == "addContactFrontImage" || name == "addContactBackImage") {
            Alamofire.request(request).responseString { response in
                if (debugMode) {
                    print(response)
                }
                switch response.result {
                case .success(let value):
                    self.delegate!.onSuccess(apiName: name, data: value as AnyObject, userInfo: userInfo)
                case .failure(let error):
                    let errorInfoString = "Error: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(data)\n\n"
                    logText = logText + "Name: \(user), FirmID: \(firmCode)\n" + errorInfoString
                    self.delegate!.onError(apiName: name, errorInfo: error as AnyObject, userInfo: userInfo)
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
                case .failure(let error):
                    let errorInfoString = "Error: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(data)\n\n"
                    logText = logText + "Name: \(user), FirmID: \(firmCode)\n" + errorInfoString
                    self.delegate!.onError(apiName: name, errorInfo: error as AnyObject, userInfo: userInfo)
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
        
        callAPI(type: HTTPMethod.get, name: "signIn", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
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
        
        callAPI(type: HTTPMethod.get, name: "getContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: info)
    }
    
    public class func getContactDetail(_ contactId: Int) {
        let endPoint = SERVER_URL + "contacts/\(contactId)"
        
        callAPI(type: HTTPMethod.get, name: "getContactDetail", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func searchContacts(parameters: [String : Any]) {
        let endPoint = SERVER_URL + "contacts/search"
        callAPI(type: HTTPMethod.get, name: "searchContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: "")
    }
    
    public class func searchContactsWithKeyword(keyword: String) {
        let endPoint = SERVER_URL + "contacts/search"
        var parameters = [String : String]()
        parameters["q"] = keyword
        
        callAPI(type: HTTPMethod.get, name: "searchContactsWithKeyword", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: "")
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
        callAPI(type: HTTPMethod.get, name: "getContactAddresses", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func addContactAddresses(contactId: Int, parameters: [[String : Any]], type: String) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/addresses"
        callAPIWithBodyData(type: "POST", name: "addContactAddresses", endPoint: endPoint, data: parameters, userInfo: type)
    }
    
    public class func updateContactAddress(contactId: Int, parameters: [[String : Any]], type: String) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/addresses"
        callAPIWithBodyData(type: "PUT", name: "updateContactAddress", endPoint: endPoint, data: parameters, userInfo: type)
    }
    
    public class func getContactFrontImage(contactId: Int) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardfront"
        callAPI(type: HTTPMethod.get, name: "getContactFrontImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: "")
    }
    
    public class func addContactFrontImage(contactId: Int, parameters: [String : Any]) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardfront"
        callAPIWithBodyData(type: "PUT", name: "addContactFrontImage", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    public class func addContactBackImage(contactId: Int, parameters: [String : Any]) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardback"
        callAPIWithBodyData(type: "PUT", name: "addContactBackImage", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    public class func deleteContact(contactId: Int) {
        let endPoint = SERVER_URL + "contacts/\(contactId)"
        callAPI(type: .delete, name: "deleteContact", endPoint: endPoint, parameters: [:], headers: AuthHeader, userInfo: contactId)
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
        
        callAPI(type: HTTPMethod.get, name: "searchCompaniesWithKeyword", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: "")
    }
    
    public class func addCompany(parameters: [String : Any]) {
        let endPoint = SERVER_URL + "companies"
        callAPIWithBodyData(type:"POST", name: "addCompany", endPoint: endPoint, data: [parameters], userInfo: "")
    }
    
    public class func addCompanyAddresses(companyId: Int, parameters: [String : Any]) {
        let endPoint = SERVER_URL + "companies/\(companyId)/addresses"
        callAPIWithBodyData(type:"POST", name: "addCompanyAddresses", endPoint: endPoint, data: [parameters], userInfo: "")
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
    
    public class func getOpportunities(parameters: [String : Any], userInfo: Any) {
        let endPoint = SERVER_URL + "opportunities"
        callAPI(type: .get, name: "getOpportunities", endPoint: endPoint, parameters: parameters, headers: AuthHeader, userInfo: userInfo)
    }
    
    ////////////////////////////////
}
