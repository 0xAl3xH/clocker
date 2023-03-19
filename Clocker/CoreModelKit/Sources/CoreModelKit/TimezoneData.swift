// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit

struct ModelConstants {
    static let customLabel = "customLabel"
    static let timezoneName = "formattedAddress"
    static let placeIdentifier = "place_id"
    static let timezoneID = "timezoneID"
    static let emptyString = ""
    static let latitude = "latitude"
    static let longitude = "longitude"
    static let note = "note"
}

public enum DateFormat {
    public static let twelveHour = "h:mm a"
    public static let twelveHourWithSeconds = "h:mm:ss a"
    public static let twentyFourHour = "HH:mm"
    public static let twentyFourHourWithSeconds = "HH:mm:ss"
    public static let twelveHourWithZero = "hh:mm a"
    public static let twelveHourWithZeroSeconds = "hh:mm:ss a"
    public static let twelveHourWithoutSuffix = "hh:mm"
    public static let twelveHourWithoutSuffixAndSeconds = "hh:mm:ss"
    public static let epochTime = "epoch"
}

// Non-class type cannot conform to NSCoding!
public class TimezoneData: NSObject, NSCoding {
    public enum SelectionType: Int {
        case city
        case timezone
    }

    public enum DateDisplayType: Int {
        case panel
        case menu
    }

    public enum TimezoneOverride: Int {
        case globalFormat = 0
        case twelveHourFormat = 1
        case twentyFourFormat = 2
        case twelveHourWithSeconds = 4
        case twentyHourWithSeconds = 5
        case twelveHourPrecedingZero = 7
        case twelveHourPrecedingZeroSeconds = 8
        case twelveHourWithoutSuffix = 10
        case twelveHourWithoutSuffixAndSeconds = 11
        case epochTime = 12
    }

    static let values = [
        NSNumber(integerLiteral: 0): DateFormat.twelveHour,
        NSNumber(integerLiteral: 1): DateFormat.twentyFourHour,

        // Seconds
        NSNumber(integerLiteral: 3): DateFormat.twelveHourWithSeconds,
        NSNumber(integerLiteral: 4): DateFormat.twentyFourHourWithSeconds,

        // Preceding Zero
        NSNumber(integerLiteral: 6): DateFormat.twelveHourWithZero,
        NSNumber(integerLiteral: 7): DateFormat.twelveHourWithZeroSeconds,

        // Suffix
        NSNumber(integerLiteral: 9): DateFormat.twelveHourWithoutSuffix,
        NSNumber(integerLiteral: 10): DateFormat.twelveHourWithoutSuffixAndSeconds,
        NSNumber(integerLiteral: 11): DateFormat.epochTime,
    ]

    public var customLabel: String?
    public var formattedAddress: String?
    public var placeID: String?
    public var timezoneID: String? = ModelConstants.emptyString
    public var latitude: Double?
    public var longitude: Double?
    public var note: String? = ModelConstants.emptyString
    public var nextUpdate: Date? = Date()
    public var sunriseTime: Date?
    public var sunsetTime: Date?
    public var isFavourite: Int = 0
    public var isSunriseOrSunset = false
    public var selectionType: SelectionType = .city
    public var isSystemTimezone = false
    public var overrideFormat: TimezoneOverride = .globalFormat
    public var temp: Double?
    public var weatherIcon: String = "❓"

    private var weatherIcons = ["sunny":"☀️", "cloudy":"🌤", "rain":"☔️", "snow":"❄️", "fog":"🌫", "thunder":"⛈", "unknown":"❓"]

    override public init() {
        selectionType = .timezone
        isFavourite = 0
        note = ModelConstants.emptyString
        isSystemTimezone = false
        overrideFormat = .globalFormat
        placeID = UUID().uuidString
    }

    public init(with dictionary: [String: Any]) {
        customLabel = dictionary[ModelConstants.customLabel] as? String
        timezoneID = (dictionary[ModelConstants.timezoneID] as? String) ?? "Error"
        latitude = dictionary[ModelConstants.latitude] as? Double ?? -0.0
        longitude = dictionary[ModelConstants.longitude] as? Double ?? -0.0
        placeID = (dictionary[ModelConstants.placeIdentifier] as? String) ?? "Error"
        formattedAddress = (dictionary[ModelConstants.timezoneName] as? String) ?? "Error"
        isFavourite = 0
        selectionType = .city
        note = (dictionary[ModelConstants.note] as? String) ?? ModelConstants.emptyString
        isSystemTimezone = false
        overrideFormat = .globalFormat
    }

    public required init?(coder aDecoder: NSCoder) {
        customLabel = aDecoder.decodeObject(forKey: "customLabel") as? String
        formattedAddress = aDecoder.decodeObject(forKey: "formattedAddress") as? String
        placeID = aDecoder.decodeObject(forKey: "place_id") as? String
        timezoneID = aDecoder.decodeObject(forKey: "timezoneID") as? String
        latitude = aDecoder.decodeObject(forKey: "latitude") as? Double
        longitude = aDecoder.decodeObject(forKey: "longitude") as? Double
        note = aDecoder.decodeObject(forKey: "note") as? String
        nextUpdate = aDecoder.decodeObject(forKey: "nextUpdate") as? Date
        sunriseTime = aDecoder.decodeObject(forKey: "sunriseTime") as? Date
        sunsetTime = aDecoder.decodeObject(forKey: "sunsetTime") as? Date
        isFavourite = aDecoder.decodeInteger(forKey: "isFavourite")
        let selection = aDecoder.decodeInteger(forKey: "selectionType")
        selectionType = SelectionType(rawValue: selection)!
        isSystemTimezone = aDecoder.decodeBool(forKey: "isSystemTimezone")
        let override = aDecoder.decodeInteger(forKey: "overrideFormat")
        overrideFormat = TimezoneOverride(rawValue: override)!
    }

    public class func customObject(from encodedData: Data?) -> TimezoneData? {
        guard let dataObject = encodedData else {
            return TimezoneData()
        }

        if let timezoneObject = NSKeyedUnarchiver.unarchiveObject(with: dataObject) as? TimezoneData {
            return timezoneObject
        }

        return nil
    }

    private func getWeatherCondition(code: Int) -> String{
        switch code {
            case 1000:
                return "sunny"
            case 1003, 1006, 1009:
                return "cloudy"
            case 1030, 1135, 1147:
                return "fog"
            case 1063, 1072, 1150, 1153, 1168, 1171, 1180, 1183, 1186, 1189, 1192, 1195, 1198, 1201, 1204, 1207, 1240, 1243, 1246, 1249, 1252:
                return "rain"
            case 1066, 1069, 1114, 1117, 1210, 1213, 1216, 1219, 1222, 1225, 1237, 1255, 1258, 1261, 1264, 1279, 1282:
                return "snow"
            case 1087, 1273, 1276:
                return "thunder"
            default:
                return "unknown"
        }
    }

    public func fetchWeather(lat: Double, long: Double) -> Double {
        struct WeatherCondition: Decodable {
            let code: Int
        }
        struct WeatherCurrent: Decodable {
            let temp_f: Double
            let condition: WeatherCondition
        }
        struct WeatherResponse: Decodable {
            let current: WeatherCurrent
        }
        // latitude + longitude
        let latitude = String(lat);
        let longitude = String(long);
        let api = "http://api.weatherapi.com/v1/current.json?key=630d5be7e02f46cc9d9164723231603&q="
        let url = URL(string: api + latitude + "," + longitude)!

        print(lat, long, url)

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
    
            // Check if Error took place 
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            // Read HTTP Response Status code 
            if let response = response as? HTTPURLResponse {
                print("Response HTTP Status code: \(response.statusCode)")
            }
            
            // Convert HTTP Response Data to a simple String 
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Response data string:\n \(dataString)")
                let json = try! JSONDecoder().decode(WeatherResponse.self, from:data) 
                self.temp = json.current.temp_f
                self.weatherIcon = self.weatherIcons[self.getWeatherCondition(code: json.current.condition.code)]!
                print("@!", self.weatherIcon, self.weatherIcons["unknown"])
            }
        
        }

        task.resume()

        return 0.0
    }


    public func encode(with aCoder: NSCoder) {
        aCoder.encode(placeID, forKey: "place_id")
        aCoder.encode(formattedAddress, forKey: "formattedAddress")
        aCoder.encode(customLabel, forKey: "customLabel")
        aCoder.encode(timezoneID, forKey: "timezoneID")
        aCoder.encode(nextUpdate, forKey: "nextUpdate")
        aCoder.encode(latitude, forKey: "latitude")
        aCoder.encode(longitude, forKey: "longitude")
        aCoder.encode(isFavourite, forKey: "isFavourite")
        aCoder.encode(sunriseTime, forKey: "sunriseTime")
        aCoder.encode(sunsetTime, forKey: "sunsetTime")
        aCoder.encode(selectionType.rawValue, forKey: "selectionType")
        aCoder.encode(note, forKey: "note")
        aCoder.encode(isSystemTimezone, forKey: "isSystemTimezone")
        aCoder.encode(overrideFormat.rawValue, forKey: "overrideFormat")
    }

    public func formattedTimezoneLabel() -> String {
        // First check if there's an user preferred custom label set
        if let label = customLabel, !label.isEmpty {
            return label
        }

        // No custom label, return the formatted address/timezone
        if let address = formattedAddress, !address.isEmpty {
            return address
        }

        // No formatted address, return the timezoneID
        if let timezone = timezoneID, !timezone.isEmpty {
            let hashSeperatedString = timezone.components(separatedBy: "/")

            // Return the second component!
            if let first = hashSeperatedString.first {
                return first
            }

            // Second component not available, return the whole thing!
            return timezone
        }

        // Return error
        return "Error"
    }

    public func setLabel(_ label: String) {
        customLabel = !label.isEmpty ? label : ModelConstants.emptyString
    }

    public func setShouldOverrideGlobalTimeFormat(_ shouldOverride: Int) {
        if shouldOverride == 0 {
            overrideFormat = .globalFormat
        } else if shouldOverride == 1 {
            overrideFormat = .twelveHourFormat
        } else if shouldOverride == 2 {
            overrideFormat = .twentyFourFormat
        } else if shouldOverride == 4 {
            overrideFormat = .twelveHourWithSeconds
        } else if shouldOverride == 5 {
            overrideFormat = .twentyHourWithSeconds
        } else if shouldOverride == 7 {
            overrideFormat = .twelveHourPrecedingZero
        } else if shouldOverride == 8 {
            overrideFormat = .twelveHourPrecedingZeroSeconds
        } else if shouldOverride == 10 {
            overrideFormat = .twelveHourWithoutSuffix
        } else if shouldOverride == 11 {
            overrideFormat = .twelveHourWithoutSuffixAndSeconds
        } else if shouldOverride == 12 {
            overrideFormat = .epochTime
        } else {
            Logger.info("Chosen a wrong timezone format: \(shouldOverride)")
        }
    }

    public func timezone() -> String {
        if isSystemTimezone {
            timezoneID = TimeZone.autoupdatingCurrent.identifier
            formattedAddress = TimeZone.autoupdatingCurrent.identifier
            return TimeZone.autoupdatingCurrent.identifier
        }

        if let timezone = timezoneID {
            return timezone
        }

        return TimeZone.autoupdatingCurrent.identifier
    }

    public func timezoneFormat(_ currentFormat: NSNumber) -> String {
        let chosenDefault = currentFormat
        let timeFormat = TimezoneData.values[chosenDefault] ?? DateFormat.twelveHour

        switch overrideFormat {
        case .globalFormat:
            return timeFormat
        case .twelveHourFormat:
            return DateFormat.twelveHour
        case .twentyFourFormat:
            return DateFormat.twentyFourHour
        case .twelveHourWithSeconds:
            return DateFormat.twelveHourWithSeconds
        case .twentyHourWithSeconds:
            return DateFormat.twentyFourHourWithSeconds
        case .twelveHourPrecedingZero:
            return DateFormat.twelveHourWithZero
        case .twelveHourPrecedingZeroSeconds:
            return DateFormat.twelveHourWithZeroSeconds
        case .twelveHourWithoutSuffix:
            return DateFormat.twelveHourWithoutSuffix
        case .twelveHourWithoutSuffixAndSeconds:
            return DateFormat.twelveHourWithoutSuffixAndSeconds
        case .epochTime:
            return DateFormat.epochTime
        }
    }

    public func shouldShowSeconds(_ currentFormat: NSNumber) -> Bool {
        if overrideFormat == .globalFormat {
            let formatInString = TimezoneData.values[currentFormat] ?? DateFormat.twelveHour
            return formatInString.contains("ss")
        }

        // We subtract 1 because the timezone format in the dropdown contains 1 extra row for "Respecting global preferences"
        let key = NSNumber(integerLiteral: overrideFormat.rawValue - 1)
        let formatInString = TimezoneData.values[key] ?? DateFormat.twelveHour
        return formatInString.contains("ss")
    }
    
    public func isDaylightSavings() -> Bool {
        guard let timezone = TimeZone(abbreviation: timezone()) else {
            return false
        }
        
        return timezone.isDaylightSavingTime(for: Date())
    }

    override public var hash: Int {
        guard let placeIdentifier = placeID, let timezone = timezoneID else {
            return -1
        }

        return placeIdentifier.hashValue ^ timezone.hashValue
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let compared = object as? TimezoneData else {
            return false
        }

        // Plain timezones might have similar placeID. Adding another check for timezone identifier.
        return placeID == compared.placeID && timezoneID == compared.timezoneID
    }
}

public extension TimezoneData {
    override var description: String {
        return objectDescription()
    }

    override var debugDescription: String {
        return objectDescription()
    }

    private func objectDescription() -> String {
        let customString = """
        TimezoneID: \(String(describing: timezoneID))
        Formatted Address: \(formattedAddress ?? "Error")
        Custom Label: \(customLabel ?? "Error")
        Latitude: \(latitude ?? -0.0)
        Longitude: \(longitude ?? -0.0)
        Place Identifier: \(String(describing: placeID))
        Is Favourite: \(isFavourite)
        Sunrise Time: \(String(describing: sunriseTime))
        Sunset Time: \(String(describing: sunsetTime))
        Selection Type: \(selectionType.rawValue)
        Note: \(String(describing: note))
        Is System Timezone: \(isSystemTimezone)
        Override: \(overrideFormat)
        """

        return customString
    }
}
