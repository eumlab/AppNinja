//
//  ViewController.swift
//  AppNinja
//
//  Created by YuanZhou on 5/10/15.
//  Copyright (c) 2015 EUMLab. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    var salesItems = [Dictionary<String, AnyObject>]()
    var keys = [String]()
   
    @IBAction func importCSV(sender: AnyObject)
    {
        let panel = NSOpenPanel()
        
        if (panel.runModal()==NSFileHandlingPanelOKButton){
            let fileURL = panel.URL!
            let file = String(contentsOfURL: fileURL, encoding: NSUTF8StringEncoding, error: nil)
            var lines:Array = file!.componentsSeparatedByString("\n") as [String]
            var error: NSErrorPointer = nil
            
            self.salesItems.removeAll(keepCapacity: true)
            self.keys.removeAll(keepCapacity: true);
            for (index, value) in enumerate(lines)
            {
                
                if index == 0
                {
                    self.keys = value.componentsSeparatedByString(",") as [String]
                }else if !value.isEmpty
                {
                    let properties = value.componentsSeparatedByString(",")
                    if properties.count>1
                    {
                        var itemDic = [String:AnyObject]()
                        var i = 0;
                        var j = 0;
                        while i + j < properties.count
                        {
                            var p = properties[i+j]
                            if p.hasPrefix("\"")
                            {
                                var newp = p
                                while !newp.hasSuffix("\"")
                                {
                                    j++
                                    newp += properties[i+j]
                                }
                                let keyName = self.keys[i] as String
                                itemDic[keyName] = newp
                            }else
                            {
                                let keyName = self.keys[i] as String
                                itemDic[keyName] = p
                            }
                            i++
                        }
                        self.salesItems += [itemDic];
                    }
                }
            }
            self.calculateRevenue()
            self.calculateRevenueByCountry()
            
        }
    }
    

    func calculateRevenue()
    {
        var revenue :Float = 0.0
        for item in self.salesItems
        {
            if (item["Amount (Merchant Currency)"] != nil)
            {
                revenue += item["Amount (Merchant Currency)"]!.floatValue
            }
        }
        //println("Total revenue \(revenue) euro")
    }
    
    func calculateRevenueByCountry()
    {
        
        var salesByCountry = [String:Dictionary<String,AnyObject>]()
        for item in self.salesItems
        {
            let countryCode :String = item["Buyer Country"] as! String
            var country = salesByCountry[countryCode] ?? [String:AnyObject]()
            //itemsInCountry.append(item)
            //salesByCountry[countryCode] = itemsInCountry
            if(country.isEmpty)
            {
                country["Google fee"] = 0.0
                country["Charge"] = 0.0
                country["Tax"] = 0.0
            }
            
            
            let type :String = item["Transaction Type"] as! String
            var fee:Float! = country[type] as! Float
            let newFee = item["Amount (Merchant Currency)"]!.floatValue
            fee = fee + newFee
            country[type] = fee
            salesByCountry[countryCode] = country;
            if (countryCode == "")
            {
                println("wrong country")
            }
        }
        
        
        println("Country,Charge,Tax,Google fee,Total received")
        var tfee:Float = 0.0, ttax:Float = 0.0, tcharge:Float = 0.0
        
        var gfee:Float = 0.0, gtax:Float = 0.0, gcharge:Float = 0.0
        for(countryName, fees) in salesByCountry
        {
            let fee = fees["Google fee"]!.floatValue
            let tax = fees["Tax"]!.floatValue
            let charge = fees["Charge"]!.floatValue
            tfee = tfee + fee
            ttax = ttax + tax
            tcharge = tcharge + charge;
            
            if countryName == "DE"
            {
                gfee = fee
                gcharge = charge
                gtax = tax
            }
            let countryFullName = self.convertCountryName(countryName)
            let received = charge+tax+fee
            println("\(countryFullName),\(charge),\(tax),\(fee),\(received)")
        }
        
        
        //统计欧盟整体的
        var europeanSales:[String:Float] = ["Google fee": 0.0, "Tax": 0.0, "Charge": 0.0]
        
        for (countryCode, fees) in salesByCountry
        {
            if (self.isEuropeanCountry(countryCode))
            {
                let fee = fees["Google fee"]!.floatValue
                let tax = fees["Tax"]!.floatValue
                let charge = fees["Charge"]!.floatValue
                var eufee = europeanSales["Google fee"]!
                var eutax = europeanSales["Tax"]!
                var eucharge = europeanSales["Charge"]!
                eufee += fee
                eucharge += charge
                eutax += tax
                europeanSales["Google fee"] = eufee
                europeanSales["Tax"] = eutax
                europeanSales["Charge"] = eucharge
            }
        }
        let efee = europeanSales["Google fee"]!
        let etax = europeanSales["Tax"]!
        let echarge = europeanSales["Charge"]!
        println("Total:,\(tcharge),\(ttax),\(tfee),\(tcharge + tfee + ttax)")
        println("In which:,,,,")
        println("Germany,\(gcharge),\(gtax),\(gfee),\(gcharge+gtax+gfee)");
        println("European countries(excl. Germany),\(echarge),\(etax),\(efee),\(echarge+etax+efee)");
        println("Rest of world,\(tcharge-echarge-gcharge),\(ttax-etax-gtax),\(tfee-gfee-efee),\(tcharge-echarge-gcharge+ttax-etax-gtax+tfee-gfee-efee)")
        

        
        
    }
    
    func isEuropeanCountry(countryCode:String) ->Bool
    {
        
        let europeanCountries = ["AT",
            "BE",
            "BG",
            "HR",
            "CY",
            "CZ",
            "DK",
            "EE",
            "FI",
            "FR",
            "GR",
            "HU",
            "IE",
            "IT",
            "LV",
            "LT",
            "LU",
            "MT",
            "NL",
            "PL",
            "PT",
            "RO",
            "SK",
            "SI",
            "ES",
            "SE",
            "GB"]
        if contains(europeanCountries, countryCode)
        {
            return true
        }
        return false

    }
    
    func convertCountryName(countryName:String) ->String
    {
        let countryNameDic = ["AD":"Andorra",
            "AE":"United Arab Emirates",
            "AF":"Afghanistan",
            "AG":"Antigua and Barbuda",
            "AI":"Anguilla",
            "AL":"Albania",
            "AM":"Armenia",
            "AO":"Angola",
            "AQ":"Antarctica",
            "AR":"Argentina",
            "AS":"American Samoa",
            "AT":"Austria",
            "AU":"Australia",
            "AW":"Aruba",
            "AX":"Åland Islands",
            "AZ":"Azerbaijan",
            "BA":"Bosnia and Herzegovina",
            "BB":"Barbados",
            "BD":"Bangladesh",
            "BE":"Belgium",
            "BF":"Burkina Faso",
            "BG":"Bulgaria",
            "BH":"Bahrain",
            "BI":"Burundi",
            "BJ":"Benin",
            "BL":"Saint Barthélemy",
            "BM":"Bermuda",
            "BN":"Brunei Darussalam",
            "BO":"Bolivia P.S.",
            "BQ":"Bonaire, SEaS",
            "BR":"Brazil",
            "BS":"Bahamas",
            "BT":"Bhutan",
            "BV":"Bouvet Island",
            "BW":"Botswana",
            "BY":"Belarus",
            "BZ":"Belize",
            "CA":"Canada",
            "CC":"Cocos (Keeling) Islands",
            "CD":"Congo D.R.",
            "CF":"Central African Republic",
            "CG":"Congo",
            "CH":"Switzerland",
            "CI":"Côte d'Ivoire",
            "CK":"Cook Islands",
            "CL":"Chile",
            "CM":"Cameroon",
            "CN":"China",
            "CO":"Colombia",
            "CR":"Costa Rica",
            "CS":"Serbia and Montenegro",
            "CU":"Cuba",
            "CV":"Cabo Verde",
            "CW":"Curaçao",
            "CX":"Christmas Island",
            "CY":"Cyprus",
            "CZ":"Czech Republic",
            "DE":"Germany",
            "DJ":"Djibouti",
            "DK":"Denmark",
            "DM":"Dominica",
            "DO":"Dominican Republic",
            "DZ":"Algeria",
            "EC":"Ecuador",
            "EE":"Estonia",
            "EG":"Egypt",
            "EH":"Western Sahara",
            "ER":"Eritrea",
            "ES":"Spain",
            "ET":"Ethiopia",
            "FI":"Finland",
            "FJ":"Fiji",
            "FK":"Falkland Islands (Malvinas)",
            "FM":"Micronesia F.S.",
            "FO":"Faroe Islands",
            "FR":"France",
            "GA":"Gabon",
            "GB":"United Kingdom",
            "GD":"Grenada",
            "GE":"Georgia",
            "GF":"French Guiana",
            "GG":"Guernsey",
            "GH":"Ghana",
            "GI":"Gibraltar",
            "GL":"Greenland",
            "GM":"Gambia",
            "GN":"Guinea",
            "GP":"Guadeloupe",
            "GQ":"Equatorial Guinea",
            "GR":"Greece",
            "GS":"South Georgia and the South Sandwich Islands",
            "GT":"Guatemala",
            "GU":"Guam",
            "GW":"Guinea-Bissau",
            "GY":"Guyana",
            "HK":"Hong Kong",
            "HM":"Heard Island and McDonald Islands",
            "HN":"Honduras",
            "HR":"Croatia",
            "HT":"Haiti",
            "HU":"Hungary",
            "ID":"Indonesia",
            "IE":"Ireland",
            "IL":"Israel",
            "IM":"Isle of Man",
            "IN":"India",
            "IO":"British Indian Ocean Territory",
            "IQ":"Iraq",
            "IR":"Iran I.S.",
            "IS":"Iceland",
            "IT":"Italy",
            "JE":"Jersey",
            "JM":"Jamaica",
            "JO":"Jordan",
            "JP":"Japan",
            "KE":"Kenya",
            "KG":"Kyrgyzstan",
            "KH":"Cambodia",
            "KI":"Kiribati",
            "KM":"Comoros",
            "KN":"Saint Kitts and Nevis",
            "KP":"North Korea",
            "KR":"South Korea",
            "KW":"Kuwait",
            "KY":"Cayman Islands",
            "KZ":"Kazakhstan",
            "LA":"Lao People's Democratic Republic",
            "LB":"Lebanon",
            "LC":"Saint Lucia",
            "LI":"Liechtenstein",
            "LK":"Sri Lanka",
            "LR":"Liberia",
            "LS":"Lesotho",
            "LT":"Lithuania",
            "LU":"Luxembourg",
            "LV":"Latvia",
            "LY":"Libya",
            "MA":"Morocco",
            "MC":"Monaco",
            "MD":"Moldova Republic of",
            "ME":"Montenegro",
            "MF":"Saint Martin (French part)",
            "MG":"Madagascar",
            "MH":"Marshall Islands",
            "MK":"Macedonia the former Yugoslav Republic of",
            "ML":"Mali",
            "MM":"Myanmar",
            "MN":"Mongolia",
            "MO":"Macao",
            "MP":"Northern Mariana Islands",
            "MQ":"Martinique",
            "MR":"Mauritania",
            "MS":"Montserrat",
            "MT":"Malta",
            "MU":"Mauritius",
            "MV":"Maldives",
            "MW":"Malawi",
            "MX":"Mexico",
            "MY":"Malaysia",
            "MZ":"Mozambique",
            "NA":"Namibia",
            "NC":"New Caledonia",
            "NE":"Niger",
            "NF":"Norfolk Island",
            "NG":"Nigeria",
            "NI":"Nicaragua",
            "NL":"Netherlands",
            "NO":"Norway",
            "NP":"Nepal",
            "NR":"Nauru",
            "NU":"Niue",
            "NZ":"New Zealand",
            "OM":"Oman",
            "PA":"Panama",
            "PE":"Peru",
            "PF":"French Polynesia",
            "PG":"Papua New Guinea",
            "PH":"Philippines",
            "PK":"Pakistan",
            "PL":"Poland",
            "PM":"Saint Pierre and Miquelon",
            "PN":"Pitcairn",
            "PR":"Puerto Rico",
            "PS":"Palestine, State of",
            "PT":"Portugal",
            "PW":"Palau",
            "PY":"Paraguay",
            "QA":"Qatar",
            "RE":"Réunion",
            "RO":"Romania",
            "RS":"Serbia",
            "RU":"Russian Federation",
            "RW":"Rwanda",
            "SA":"Saudi Arabia",
            "SB":"Solomon Islands",
            "SC":"Seychelles",
            "SD":"Sudan",
            "SE":"Sweden",
            "SG":"Singapore",
            "SH":"Saint Helena Ascension and Tristan da Cunha",
            "SI":"Slovenia",
            "SJ":"Svalbard and Jan Mayen",
            "SK":"Slovakia",
            "SL":"Sierra Leone",
            "SM":"San Marino",
            "SN":"Senegal",
            "SO":"Somalia",
            "SR":"Suriname",
            "SS":"South Sudan",
            "ST":"Sao Tome and Principe",
            "SV":"El Salvador",
            "SX":"Sint Maarten (Dutch part)",
            "SY":"Syrian Arab Republic",
            "SZ":"Swaziland",
            "TC":"Turks and Caicos Islands",
            "TD":"Chad",
            "TF":"French Southern Territories",
            "TG":"Togo",
            "TH":"Thailand",
            "TJ":"Tajikistan",
            "TK":"Tokelau",
            "TL":"Timor-Leste",
            "TM":"Turkmenistan",
            "TN":"Tunisia",
            "TO":"Tonga",
            "TR":"Turkey",
            "TT":"Trinidad and Tobago",
            "TV":"Tuvalu",
            "TW":"Taiwan (China)",
            "TZ":"Tanzania, United Republic of",
            "UA":"Ukraine",
            "UG":"Uganda",
            "UM":"United States Minor Outlying Islands",
            "US":"United States of America",
            "UY":"Uruguay",
            "UZ":"Uzbekistan",
            "VA":"Holy See",
            "VC":"Saint Vincent and the Grenadines",
            "VE":"Venezuela, Bolivarian Republic of",
            "VG":"British Virgin Islands",
            "VI":"U.S. Virgin Islands",
            "VN":"Viet Nam",
            "VU":"Vanuatu",
            "WF":"Wallis and Futuna",
            "WS":"Samoa",
            "YE":"Yemen",
            "YT":"Mayotte",
            "ZA":"South Africa",
            "ZM":"Zambia",
            "ZW":"Zimbabwe"]
        if  (countryNameDic[countryName] == nil)
        {
            println("country name not found: \(countryName)")
            return countryName
        }
        
        return countryNameDic[countryName]!
        
        
    }
    

}

