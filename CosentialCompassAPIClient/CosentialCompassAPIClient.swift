//
//  CosentialCompassAPIClient.swift
//  CosentialCompassAPIClient
//
//  Created by SoftDev on 2/13/17.
//
//

import Alamofire

public protocol CosentialCompassAPIClientDelegate {
    func onSuccess(apiName: String, data: AnyObject, owner: String, userInfo: Any?)
    func onError(apiName: String, status: Int, errorInfo: AnyObject, owner: String, userInfo: Any?)
    func onNoInternet(apiName: String, errorInfo: AnyObject, owner: String, userInfo: Any?)
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
    
    class func callAPI(type: HTTPMethod, name: String, endPoint: String, parameters: [String : Any], headers: HTTPHeaders, owner: String, userInfo: Any?) {
        
        Alamofire.request(endPoint, method: type, parameters: parameters, encoding: URLEncoding.default, headers: headers).validate().responseJSON { (response) in
            if (debugMode) {
                print(response)
            }
            
            var info = userInfo
            if (name == "getContacts" || name == "getCompanies" || name == "getPersonnel") {
                var infoObject = userInfo as! [String : AnyObject]
                if let responseHeader = response.response?.allHeaderFields {
                    infoObject["totalCount"] = responseHeader["x-compass-count"] as AnyObject
                }
                info = infoObject
            }
            
            if (type == .delete) {
                self.delegate!.onSuccess(apiName: name, data: "" as AnyObject, owner: owner, userInfo: info)
                return
            }
            
            switch response.result {
            case.success(let value):
                self.delegate!.onSuccess(apiName: name, data: value as AnyObject, owner: owner, userInfo: info)
                break
                
            case.failure(let error):
                let errorInfoString = "Name: \(user), FirmID: \(firmCode)\nError: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(parameters)\n\n"
                logText = logText + errorInfoString
                
                if error is URLError {
                    self.delegate!.onNoInternet(apiName: name, errorInfo: errorInfoString as AnyObject, owner: owner, userInfo: info)
                }
                else {
                    let status = response.response?.statusCode ?? 0
                    self.delegate!.onError(apiName: name, status: status, errorInfo: errorInfoString as AnyObject, owner: owner, userInfo: info)
                }
                break
            }
        }
    }
    
    class func callAPIInBlock(type: HTTPMethod, endPoint: String, parameters: [String : Any], headers: HTTPHeaders, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        
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
    
    class func callAPIWithBodyData(type: String, name: String, endPoint: String, data: [[String : Any]], owner: String, userInfo: Any?) {
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
        
        if (name == "addContactCardFrontImage" || name == "addContactCardBackImage" || name == "addContactProfilePicture" || name == "addCompanyLogo") {
            Alamofire.request(request).responseString { response in
                if (debugMode) {
                    print(response)
                }
                switch response.result {
                case .success(let value):
                    self.delegate!.onSuccess(apiName: name, data: value as AnyObject, owner: owner, userInfo: userInfo)
                    break
                    
                case .failure(let error):
                    let errorInfoString = "Name: \(user), FirmID: \(firmCode)\nError: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(data)\n\n"
                    logText = logText + errorInfoString
                    
                    if error is URLError {
                        self.delegate!.onNoInternet(apiName: name, errorInfo: errorInfoString as AnyObject, owner: owner, userInfo: userInfo)
                    }
                    else {
                        let status = response.response?.statusCode ?? 0
                        self.delegate!.onError(apiName: name, status: status, errorInfo: errorInfoString as AnyObject, owner: owner, userInfo: userInfo)
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
                    self.delegate!.onSuccess(apiName: name, data: value as AnyObject, owner: owner, userInfo: userInfo)
                    break
                    
                case .failure(let error):
                    let errorInfoString = "Name: \(user), FirmID: \(firmCode)\nError: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(data)\n\n"
                    logText = logText + errorInfoString
                    
                    if error is URLError {
                        self.delegate!.onNoInternet(apiName: name, errorInfo: errorInfoString as AnyObject, owner: owner, userInfo: userInfo)
                    }
                    else {
                        let status = response.response?.statusCode ?? 0
                        self.delegate!.onError(apiName: name, status: status, errorInfo: errorInfoString as AnyObject, owner: owner, userInfo: userInfo)
                    }
                    break
                }
            }
        }
    }
    
    class func callAPIWithBodyDataInBlock(type: String, name: String, endPoint: String, data: [[String : Any]], success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
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
        
        if (name == "addContactCardFrontImage" || name == "addContactCardBackImage" || name == "addContactProfilePicture" || name == "addCompanyLogo" || name == "addProjectImageContent") {
            Alamofire.request(request).responseString { response in
                if (debugMode) {
                    print(response)
                }
                switch response.result {
                case .success(let value):
                    success(value as AnyObject)
                    break
                    
                case .failure(let error):
                    let errorInfoString = "Name: \(user), FirmID: \(firmCode)\nError: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(data)\n\n"
                    logText = logText + errorInfoString
                    
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
        else
        {
            Alamofire.request(request).responseJSON { response in
                if (debugMode) {
                    print(response)
                }
                switch response.result {
                case .success(let value):
                    success(value as AnyObject)
                    break
                    
                case .failure(let error):
                    let errorInfoString = "Name: \(user), FirmID: \(firmCode)\nError: \(error)\nCall Type: \(type)\nAPI Endpoint: \(endPoint)\nParameters: \(data)\n\n"
                    logText = logText + errorInfoString
                    
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
    
    public class func signIn(parameters: [String : String], owner: String) {
        let endPoint = SERVER_URL + "user"
        
        setUserInfo(parameters: parameters)
        
        callAPI(type: .get, name: "signIn", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: "")
    }
    
    ////////////////////////////////
    
    public class func getSchema(_ element: String, parameters: [String : Any], owner: String) {
        let endPoint = "\(SERVER_URL)/\(element)/schema"
        callAPI(type: .get, name: "getSchema", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: element)
    }
    
    public class func getSchema(_ element: String, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = "\(SERVER_URL)/\(element)/schema"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    ////////////////////////////////
    
    //  Company
    
    public class func getCompanies(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies"
        
        callAPI(type: .get, name: "getCompanies", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func searchCompanies(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/search"
        
        callAPI(type: .get, name: "searchCompanies", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getChangedCompanies(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/changes"
        
        callAPI(type: .get, name: "getChangedCompanies", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getCompany(companyId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)"
        
        callAPI(type: .get, name: "getCompany", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addCompany(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies"
        
        callAPIWithBodyData(type: "POST", name: "addCompany", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func updateCompany(companyId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)"
        
        callAPIWithBodyData(type: "PUT", name: "updateCompany", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func getCompanyContacts(companyId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/contacts"
        
        callAPI(type: .get, name: "getCompanyContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getCompanySubData(companyId: Int, subPath: String, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/\(subPath)"
        
        callAPI(type: .get, name: "getCompanySubData", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    //  Company Types
    
    public class func getCompanyTypes(owner: String) {
        let endPoint = SERVER_URL + "companies/companytypes"
        
        callAPI(type: .get, name: "getCompanyTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: "")
    }
    
    public class func getCompanyTypes(success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "companies/companytypes"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getCompanyCompanyTypes(_ companyId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/companytypes"
        
        callAPI(type: .get, name: "getCompanyCompanyTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: "")
    }
    
    public class func addCompanyTypes(_ companyId: Int, parameters: [[String : Any]], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/companytypes"
        
        callAPIWithBodyData(type: "POST", name: "addCompanyTypes", endPoint: endPoint, data: parameters, owner: owner, userInfo: info)
    }
    
    public class func deleteCompanyTypes(_ companyId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/companytypes"
        
        callAPI(type: .delete, name: "deleteCompanyTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    //  Firm Organization
    
    public class func getCompanyOffices(companyId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "companies/\(companyId)/offices"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getCompanyDivisions(companyId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "companies/\(companyId)/divisions"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getCompanyStudios(companyId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "companies/\(companyId)/studios"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getCompanyPracticeAreas(companyId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "companies/\(companyId)/practiceareas"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getCompanyTerritories(companyId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "companies/\(companyId)/territories"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    //  Address
    
    public class func getCompanyAddresses(companyId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/addresses"
        
        callAPI(type: .get, name: "getCompanyAddresses", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addCompanyAddresses(companyId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/addresses"
        
        callAPIWithBodyData(type: "POST", name: "addCompanyAddresses", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func updateCompanyAddresses(companyId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/addresses"
        
        callAPIWithBodyData(type: "PUT", name: "updateCompanyAddresses", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    //  Logo
    
    public class func getCompanyLogoThumbnail(companyId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "/images/companies/\(companyId)/thumb"
        
        callAPI(type: .get, name: "getCompanyLogoThumbnail", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addCompanyLogo(companyId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/companies/\(companyId)"
        
        callAPIWithBodyData(type: "PUT", name: "addCompanyLogo", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    //  Social
    
    public class func getCompanySocials(_ companyId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/social"
        
        callAPI(type: .get, name: "getCompanySocials", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: "")
    }
    
    //  Prequalification
    
    public class func getCompanyPrequalifications(_ companyId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/prequalifications"
        
        callAPI(type: .get, name: "getCompanyPrequalifications", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addCompanyPrequalifications(_ companyId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/prequalifications"
        
        callAPIWithBodyData(type: "POST", name: "addCompanyPrequalifications", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func updateCompanyPrequalifications(_ companyId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/prequalifications"
        
        callAPIWithBodyData(type: "PUT", name: "updateCompanyPrequalifications", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func deleteCompanyPrequalification(_ companyId: Int, prequalificationId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/prequalifications/\(prequalificationId)"
        
        callAPI(type: .delete, name: "deleteCompanyPrequalification", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func deleteAllCompanyPrequalifications(_ companyId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/prequalifications"
        
        callAPI(type: .delete, name: "deleteAllCompanyPrequalifications", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    //  LegalStructure
    
    public class func getLegalStructures(_ owner: String) {
        let endPoint = SERVER_URL + "companies/legalstructure"
        
        callAPI(type: .get, name: "getLegalStructures", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: nil)
    }
    
    public class func addLegalStructure(_ parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/legalstructure"
        
        callAPIWithBodyData(type: "POST", name: "addLegalStructure", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func updateLegalStructure(_ parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/legalstructure"
        
        callAPIWithBodyData(type: "PUT", name: "updateLegalStructure", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func deleteLegalStructure(_ legalStructureId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/legalstructure/\(legalStructureId)"
        
        callAPI(type: .delete, name: "deleteLegalStructure", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getCompanyLegalStructures(_ companyId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/legalstructure"
        
        callAPI(type: .get, name: "getCompanyLegalStructures", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addCompanyLegalStructure(_ companyId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/legalstructure"
        
        callAPIWithBodyData(type: "POST", name: "addCompanyLegalStructure", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func deleteCompanyLegalStructure(_ companyId: Int, legalStructureId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/legalstructure/\(legalStructureId)"
        
        callAPI(type: .delete, name: "deleteCompanyLegalStructure", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func deleteAllCompanyLegalStructures(_ companyId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/legalstructure"
        
        callAPI(type: .delete, name: "deleteAllCompanyLegalStructures", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    //  Users
    
    public class func getCompanyUserRoles(_ owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/users/role"
        
        callAPI(type: .get, name: "getCompanyUserRoles", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getCompanyUsers(_ companyId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/users"
        
        callAPI(type: .get, name: "getCompanyUsers", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addCompanyUsers(_ companyId: Int, parameters: [[String : Any]], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/users"
        
        callAPIWithBodyData(type: "POST", name: "addCompanyUsers", endPoint: endPoint, data: parameters, owner: owner, userInfo: info)
    }
    
    public class func deleteCompanyUser(_ companyId: Int, userId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "companies/\(companyId)/users/\(userId)"
        
        callAPI(type: .delete, name: "deleteCompanyUser", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    ////////////////////////////////
    
    //  Contact
    
    public class func getContacts(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts"
        
        callAPI(type: .get, name: "getContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func searchContacts(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/search"
        
        callAPI(type: .get, name: "searchContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getChangedContacts(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/changes"
        
        callAPI(type: .get, name: "getChangedContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addContact(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts"
        
        callAPIWithBodyData(type: "POST", name: "addContact", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func updateContact(contactId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)"
        
        callAPIWithBodyData(type: "PUT", name: "updateContact", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func getContactDetail(_ contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)"
        
        callAPI(type: .get, name: "getContactDetail", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func deleteContact(_ contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)"
        
        callAPI(type: .delete, name: "deleteContact", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getContactCardFrontImage(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardfront"
        
        callAPI(type: .get, name: "getContactCardFrontImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addContactCardFrontImage(contactId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardfront"
        
        callAPIWithBodyData(type: "PUT", name: "addContactCardFrontImage", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func deleteContactCardFrontImage(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardfront"
        
        callAPI(type: .delete, name: "deleteContactCardFrontImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getContactCardBackImage(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardback"
        
        callAPI(type: .get, name: "getContactCardBackImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addContactCardBackImage(contactId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardback"
        
        callAPIWithBodyData(type: "PUT", name: "addContactCardBackImage", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func deleteContactCardBackImage(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/cardback"
        
        callAPI(type: .delete, name: "deleteContactCardBackImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getContactProfilePicture(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/profilepicture"
        
        callAPI(type: .get, name: "getContactProfilePicture", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getContactProfilePicture(contactId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/profilepicture"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func addContactProfilePicture(contactId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/profilepicture"
        
        callAPIWithBodyData(type: "PUT", name: "addContactProfilePicture", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func addContactProfilePictureWithUrl(contactId: Int, url: String, owner: String, info: Any?) {
        var endPoint = SERVER_URL + "images/contact/\(contactId)/profilepicture"
        endPoint = "\(endPoint)?url=\(url)"
        
        callAPIWithBodyData(type: "PUT", name: "addContactProfilePicture", endPoint: endPoint, data: [], owner: owner, userInfo: info)
    }
    
    public class func deleteContactProfilePicture(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/contact/\(contactId)/profilepicture"
        
        callAPI(type: .delete, name: "deleteContactProfilePicture", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    //  Contact Types
    
    public class func getContactTypes(owner: String) {
        let endPoint = SERVER_URL + "contacts/types"
        
        callAPI(type: .get, name: "getContactTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: "")
    }
    
    public class func getContactTypes(success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "contacts/types"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getContactContactTypes(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/types"
        
        callAPI(type: .get, name: "getContactContactTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: "")
    }
    
    public class func addContactTypes(_ contactId: Int, parameters: [[String : Any]], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/types"
        
        callAPIWithBodyData(type: "POST", name: "addContactTypes", endPoint: endPoint, data: parameters, owner: owner, userInfo: info)
    }
    
    public class func deleteContactTypes(_ contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/types"
        
        callAPI(type: .delete, name: "deleteContactTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getContactAddresses(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/addresses"
        
        callAPI(type: .get, name: "getContactAddresses", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addContactAddresses(contactId: Int, parameters: [[String : Any]], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/addresses"
        
        callAPIWithBodyData(type: "POST", name: "addContactAddresses", endPoint: endPoint, data: parameters, owner: owner, userInfo: info)
    }
    
    public class func updateContactAddresses(contactId: Int, parameters: [[String : Any]], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/addresses"
        
        callAPIWithBodyData(type: "PUT", name: "updateContactAddresses", endPoint: endPoint, data: parameters, owner: owner, userInfo: info)
    }
    
    //  Contact Relationship
    
    public class func getRelationships(owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/relationships/relationship"
        
        callAPI(type: .get, name: "getRelationships", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getRelationshipStrengths(owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/relationships/relationshipstrength"
        
        callAPI(type: .get, name: "getRelationshipStrengths", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getContactRelationships(_ contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/relationships"
        
        callAPI(type: .get, name: "getContactRelationships", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addContactRelationships(_ contactId: Int, parameters: [[String : Any]], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/relationships"
        
        callAPIWithBodyData(type: "POST", name: "addContactRelationships", endPoint: endPoint, data: parameters, owner: owner, userInfo: info)
    }
    
    public class func updateContactRelationships(_ contactId: Int, relationshipId: Int, parameters: [[String : Any]], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/relationships/\(relationshipId)"
        
        callAPIWithBodyData(type: "PUT", name: "updateContactRelationships", endPoint: endPoint, data: parameters, owner: owner, userInfo: info)
    }
    
    public class func deleteContactRelationship(_ contactId: Int, relationshipId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/relationships/\(relationshipId)"
        
        callAPI(type: .delete, name: "deleteContactRelationship", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    //  Contact Mailing List
    
    public class func getContactMailingList(owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/Contact_MailingList"
        
        callAPI(type: .get, name: "getContactMailingList", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getContactContactMailingList(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/Contact_MailingList"
        
        callAPI(type: .get, name: "getContactContactMailingList", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addContactContactMailingList(contactId: Int, parameters: [[String : Any]], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/Contact_MailingList"
        
        callAPIWithBodyData(type: "POST", name: "addContactContactMailingList", endPoint: endPoint, data: parameters, owner: owner, userInfo: info)
    }
    
    //  Other
    
    public class func getContactOpportunities(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/opportunities"
        
        callAPI(type: .get, name: "getContactOpportunities", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getContactProjects(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/projects"
        
        callAPI(type: .get, name: "getContactProjects", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getContactSocials(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/social"
        
        callAPI(type: .get, name: "getContactSocials", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    //  Influence Level
    
    public class func getContactInfluenceLevels(owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/influencelevel"
        
        callAPI(type: .get, name: "getContactInfluenceLevels", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getContactContactInfluenceLevels(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/influencelevel"
        
        callAPI(type: .get, name: "getContactContactInfluenceLevels", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    //  Category
    
    public class func getContactCategories(owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/contact_category"
        
        callAPI(type: .get, name: "getContactCategories", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getContactContactCategories(contactId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/contact_category"
        
        callAPI(type: .get, name: "getContactContactCategories", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    //  Firm Organization
    
    public class func getContactFirmOrgs(_ firmOrg: String, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "contacts/\(firmOrg)"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getContactContactFirmOrgs(_ contactId: Int, firmOrg: String, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/\(firmOrg)"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func addContactContactFirmOrgs(_ contactId: Int, firmOrg: String, parameters: [[String : Any]], success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "contacts/\(contactId)/\(firmOrg)"
        
        callAPIWithBodyDataInBlock(type: "POST", name: "addContactContactFirmOrgs", endPoint: endPoint, data: parameters, success: success, failure: failure)
    }
    
    ////////////////////////////////
    
    //  CallLog
    
    public class func getCallLogCallTypes(owner: String) {
        let endPoint = SERVER_URL + "calllogs/calltype"
        
        callAPI(type: .get, name: "getCallLogCallTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: nil)
    }
    
    public class func getCallLogCallDispositions(owner: String) {
        let endPoint = SERVER_URL + "calllogs/calldisposition"
        
        callAPI(type: .get, name: "getCallLogCallDispositions", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: nil)
    }
    
    public class func getCallLogs(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs"
        
        callAPI(type: .get, name: "getCallLogs", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getCallLogContacts(callLogId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/contacts"
        
        callAPI(type: .get, name: "getCallLogContacts", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getCallLogCompanies(callLogId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/companies"
        
        callAPI(type: .get, name: "getCallLogCompanies", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getCallLogPersonnel(callLogId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/personnel"
        
        callAPI(type: .get, name: "getCallLogPersonnel", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getCallLogLeads(callLogId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/leads"
        
        callAPI(type: .get, name: "getCallLogLeads", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getCallLogOpportunities(callLogId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/opportunities"
        
        callAPI(type: .get, name: "getCallLogOpportunities", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getCallLogProjects(callLogId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/projects"
        
        callAPI(type: .get, name: "getCallLogProjects", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func searchCallLogs(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/search"
        callAPI(type: .get, name: "searchCallLogs", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getContactCallLogs(contactId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/search"
        var searchParameters = parameters
        searchParameters["q"] = "Contacts.ContactId:\(contactId)"
        
        callAPI(type: .get, name: "getContactCallLogs", endPoint: endPoint, parameters: searchParameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addCallLog(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs"
        
        callAPIWithBodyData(type: "POST", name: "addCallLog", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func updateCallLog(callLogId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)"
        
        callAPIWithBodyData(type: "PUT", name: "updateCallLog", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func deleteCallLog(_ callLogId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)"
        
        callAPI(type: .delete, name: "deleteCallLog", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addContactInfoToCallLog(callLogId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/contacts"
        
        callAPIWithBodyData(type: "POST", name: "addContactInfoToCallLog", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func addCompanyInfoToCallLog(callLogId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/companies"
        
        callAPIWithBodyData(type: "POST", name: "addCompanyInfoToCallLog", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func addPersonnelInfoToCallLog(callLogId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/personnel"
        
        callAPIWithBodyData(type: "POST", name: "addPersonnelInfoToCallLog", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func getCallLogMeetingPlan(callLogId: Int, owner: String) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/meetingplan"
        
        callAPI(type: .get, name: "getCallLogMeetingPlan", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: nil)
    }
    
    public class func updateCallLogMeetingPlan(callLogId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/meetingplan"
        
        callAPIWithBodyData(type: "PUT", name: "updateCallLogMeetingPlan", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func addCallLogOpportunities(callLogId: Int, parameters: [[String : Any]], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/opportunities"
        
        callAPIWithBodyData(type: "POST", name: "addCallLogOpportunities", endPoint: endPoint, data: parameters, owner: owner, userInfo: info)
    }
    
    public class func addCallLogLeads(callLogId: Int, parameters: [[String : Any]], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/leads"
        
        callAPIWithBodyData(type: "POST", name: "addCallLogLeads", endPoint: endPoint, data: parameters, owner: owner, userInfo: info)
    }
    
    public class func addCallLogProjects(callLogId: Int, parameters: [[String : Any]], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/projects"
        
        callAPIWithBodyData(type: "POST", name: "addCallLogProjects", endPoint: endPoint, data: parameters, owner: owner, userInfo: info)
    }
    
    public class func deleteCallLogCompany(callLogId: Int, companyId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/companies/\(companyId)"
        
        callAPI(type: .delete, name: "deleteCallLogCompany", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func deleteCallLogLead(callLogId: Int, leadId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/leads/\(leadId)"
        
        callAPI(type: .delete, name: "deleteCallLogLead", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func deleteCallLogOpportunity(callLogId: Int, opportunityId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/opportunities/\(opportunityId)"
        
        callAPI(type: .delete, name: "deleteCallLogOpportunity", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func deleteCallLogProject(callLogId: Int, projectId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "calllogs/\(callLogId)/projects/\(projectId)"
        
        callAPI(type: .delete, name: "deleteCallLogProject", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    ////////////////////////////////
    
    //  Lead
    
    public class func getLeads(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "leads"
        
        callAPI(type: .get, name: "getLeads", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getChangedLeads(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "leads/changes"
        
        callAPI(type: .get, name: "getChangedLeads", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func searchLeads(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "leads/search"
        
        callAPI(type: .get, name: "searchLeads", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addLead(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "leads"
        
        callAPIWithBodyData(type: "POST", name: "addLead", endPoint: endPoint, data: [parameters], owner: owner, userInfo: nil)
    }
    
    public class func addContactInfoToLead(leadId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "leads/\(leadId)/associatedcontacts"
        
        callAPIWithBodyData(type: "POST", name: "addContactInfoToLead", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    //  Company
    
    public class func getLeadCompanies(leadId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "leads/\(leadId)/potentialclient"
        
        callAPI(type: .get, name: "getLeadCompanies", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addCompanyInfoToLead(leadId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "leads/\(leadId)/potentialclient"
        
        callAPIWithBodyData(type: "POST", name: "addCompanyInfoToLead", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    ////////////////////////////////
    
    public class func getOffices(parameters: [String : Any], owner: String) {
        let endPoint = SERVER_URL + "contacts/offices"
        
        callAPI(type: .get, name: "getOffices", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: nil)
    }
    
    ////////////////////////////////
    
    //  Personnel
    
    public class func getPersonnelDetail(personnelId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)"
        
        callAPI(type: .get, name: "getPersonnelDetail", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getPersonnel(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "personnel"
        
        callAPI(type: .get, name: "getPersonnel", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func updatePersonnel(personnelId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)"
        
        callAPIWithBodyData(type: "PUT", name: "updatePersonnel", endPoint: endPoint, data: [parameters], owner: owner, userInfo: info)
    }
    
    public class func searchPersonnel(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "personnel/search"
        
        callAPI(type: .get, name: "searchPersonnel", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getChangedPersonnel(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "personnel/changes"
        
        callAPI(type: .get, name: "getChangedPersonnel", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    //  Image
    
    public class func getPersonnelProfilePictures(personnelId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/images"
        
        callAPI(type: .get, name: "getPersonnelProfilePictures", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getPersonnelProfilePictures(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/images"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelProfilePicture(personnelId: Int, imageId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/personnel/\(personnelId)/\(imageId)"
        
        callAPI(type: .get, name: "getPersonnelProfilePicture", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getPersonnelProfileThumbPicture(personnelId: Int, imageId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/personnel/\(personnelId)/\(imageId)/thumb"
        
        callAPI(type: .get, name: "getPersonnelProfileThumbPicture", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getPersonnelProfileThumbPicture(personnelId: Int, imageId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "images/personnel/\(personnelId)/\(imageId)/thumb"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    //  Firm Organization
    
    public class func getPersonnelOffices(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/offices"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelDivisions(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/divisions"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelStudios(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/studios"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelPracticeAreas(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/practiceareas"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelTerritories(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/territories"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    //  Extra Info
    
    public class func getPersonnelOpportunities(personnelId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/opportunities"
        
        callAPI(type: .get, name: "getPersonnelOpportunities", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getPersonnelProjects(personnelId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/projects"
        
        callAPI(type: .get, name: "getPersonnelProjects", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getPersonnelStaffRoles(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/staffroles"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelEducation(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/education"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelRegistrations(personnelId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/registrations"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getPersonnelSocials(personnelId: Int, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "personnel/\(personnelId)/social"
        
        callAPI(type: .get, name: "getPersonnelSocials", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getPersonnelSchema(owner: String, info: Any?) {
        let endPoint = SERVER_URL + "personnel/schema"
        
        callAPI(type: .get, name: "getPersonnelSchema", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getPersonnelSchema(success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "personnel/schema"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    ////////////////////////////////
    
    //  Opportunity
    
    public class func getOpportunities(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "opportunities"
        
        callAPI(type: .get, name: "getOpportunities", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: nil)
    }
    
    public class func searchOpportunities(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "opportunities/search"
        
        callAPI(type: .get, name: "searchOpportunities", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getChangedOpportunities(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "opportunities/changes"
        
        callAPI(type: .get, name: "getChangedOpportunities", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getOpportunity(opportunityId: Int, owner: String) {
        let endPoint = SERVER_URL + "opportunities/\(opportunityId)"
        
        callAPI(type: .get, name: "getOpportunity", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: nil)
    }
    
    public class func getOpportunityProspectTypes(opportunitylId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "opportunities/\(opportunitylId)/prospecttype"
        
        callAPI(type: .get, name: "getOpportunityProspectTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getOpportunityProspectTypes(opportunitylId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "opportunities/\(opportunitylId)/prospecttype"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getOpportunityStaffTeams(opportunitylId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "opportunities/\(opportunitylId)/staffteam"
        
        callAPI(type: .get, name: "getOpportunityStaffTeams", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getOpportunityStaffTeams(opportunitylId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "opportunities/\(opportunitylId)/staffteam"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getOpportunityEmails(opportunitylId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "opportunities/\(opportunitylId)/emails"
        
        callAPI(type: .get, name: "getOpportunityEmails", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getOpportunityDocuments(opportunitylId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "opportunities/\(opportunitylId)/documents"
        
        callAPI(type: .get, name: "getOpportunityDocuments", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getAllOpportunityFirmOrgData(_ firmOrgName: String, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "opportunities/\(firmOrgName)"
        
        callAPI(type: .get, name: "getAllOpportunityFirmOrgData", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getOpportunityFirmOrgData(_ firmOrgName: String, opportunitylId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "opportunities/\(opportunitylId)/\(firmOrgName)"
        
        callAPI(type: .get, name: "getOpportunityFirmOrgData", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    ////////////////////////////////
    
    //  Project
    
    public class func getProjects(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "projects"
        
        callAPI(type: .get, name: "getProjects", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func searchProjects(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "projects/search"
        
        callAPI(type: .get, name: "searchProjects", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getChangedProjects(parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "projects/changes"
        
        callAPI(type: .get, name: "getChangedProjects", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getProject(projectId: Int, owner: String) {
        let endPoint = SERVER_URL + "projects/\(projectId)"
        
        callAPI(type: .get, name: "getProject", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: nil)
    }
    
    public class func updateProject(projectId: Int, parameters: [String : Any], owner: String) {
        let endPoint = SERVER_URL + "projects/\(projectId)"
        
        callAPIWithBodyData(type: "PUT", name: "updateProject", endPoint: endPoint, data: [parameters], owner: owner, userInfo: nil)
    }
    
    public class func getProjectStatuses(owner: String, info: Any?) {
        let endPoint = SERVER_URL + "projects/status"
        
        callAPI(type: .get, name: "getProjectStatuses", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getProjectContractTypes(owner: String, info: Any?) {
        let endPoint = SERVER_URL + "projects/contracttype"
        
        callAPI(type: .get, name: "getProjectContractTypes", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getProjectRoles(owner: String, info: Any?) {
        let endPoint = SERVER_URL + "projects/role"
        
        callAPI(type: .get, name: "getProjectRoles", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getProjectSubData(projectId: Int, path: String, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "projects/\(projectId)/\(path)"
        
        callAPI(type: .get, name: "getProjectSubData", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func addProjectSubData(projectId: Int, path: String, parameters: [[String : Any]], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "projects/\(projectId)/\(path)"
        
        callAPIWithBodyData(type: "POST", name: "addProjectSubData", endPoint: endPoint, data: parameters, owner: owner, userInfo: info)
    }
    
    public class func deleteProjectSubData(projectId: Int, path: String, dataId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "projects/\(projectId)/\(path)/\(dataId)"
        
        callAPI(type: .delete, name: "deleteProjectSubData", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func deleteProjectSubData(projectId: Int, path: String, dataId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "projects/\(projectId)/\(path)/\(dataId)"
        
        callAPIInBlock(type: .delete, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    //  Firm Organization
    
    public class func getProjectFirmOrgData(_ firmOrgName: String, parameters: [String : Any], success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "projects/\(firmOrgName)"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: parameters, headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getProjectFirmOrgData(_ firmOrgName: String, parameters: [String : Any], owner: String, info: Any?) {
        let endPoint = SERVER_URL + "projects/\(firmOrgName)"
        
        callAPI(type: .get, name: "getProjectFirmOrgData", endPoint: endPoint, parameters: parameters, headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    //  Category
    
    public class func getProjectPrimaryCategories(projectId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "projects/\(projectId)/primarycategories"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getProjectSecondaryCategories(projectId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "projects/\(projectId)/secondarycategories"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    //  Client
    
    public class func getProjectCompanies(projectId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "projects/\(projectId)/ownerclient"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getProjectContacts(projectId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "projects/\(projectId)/ownerclientcontacts"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    //  Image
    
    public class func getProjectImages(_ projectId: Int, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "projects/\(projectId)/images"
        
        callAPI(type: .get, name: "getProjectImages", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getProjectImage(_ projectId: Int, imageId: Int, type: String, owner: String, info: Any?) {
        let endPoint = SERVER_URL + "images/project/\(projectId)/\(imageId)/\(type)"
        
        callAPI(type: .get, name: "getProjectImage", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: info)
    }
    
    public class func getProjectImages(_ projectId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "projects/\(projectId)/images"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func getProjectImage(_ projectId: Int, imageId: Int, type: String, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "images/project/\(projectId)/\(imageId)/\(type)"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func addProjectImages(_ projectId: Int, parameters: [[String : Any]], success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "projects/\(projectId)/images"
        
        callAPIWithBodyDataInBlock(type: "POST", name: "addProjectImages", endPoint: endPoint, data: parameters, success: success, failure: failure)
    }
    
    public class func updateProjectImages(_ projectId: Int, imageId: Int, parameters: [[String : Any]], success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "projects/\(projectId)/images/\(imageId)"
        
        callAPIWithBodyDataInBlock(type: "PUT", name: "updateProjectImages", endPoint: endPoint, data: parameters, success: success, failure: failure)
    }
    
    public class func deleteProjectImage(_ projectId: Int, imageId: Int, success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "projects/\(projectId)/images/\(imageId)"
        
        callAPIInBlock(type: .delete, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    public class func addProjectImageContent(_ projectId: Int, imageId: Int, parameters: [[String : Any]], success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "images/project/\(projectId)/\(imageId)"
        
        callAPIWithBodyDataInBlock(type: "PUT", name: "addProjectImageContent", endPoint: endPoint, data: parameters, success: success, failure: failure)
    }
    
    ////////////////////////////////
    
    //  Firm Organization
    
    public class func getFirmOrgs(owner: String) {
        let endPoint = SERVER_URL + "firmorgs"
        
        callAPI(type: .get, name: "getFirmOrgs", endPoint: endPoint, parameters: [:], headers: AuthHeader, owner: owner, userInfo: "")
    }
    
    public class func getFirmOrgs(success: @escaping (AnyObject) -> Void, failure: @escaping (AnyObject) -> Void) {
        let endPoint = SERVER_URL + "firmorgs"
        
        callAPIInBlock(type: .get, endPoint: endPoint, parameters: [:], headers: AuthHeader, success: success, failure: failure)
    }
    
    ////////////////////////////////
}
