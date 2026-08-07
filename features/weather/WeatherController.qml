import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: weather

    property bool active: false
    property string location: Quickshell.env("WEATHER_LOCATION") || "Budapest"
    property string latitude: ""
    property string longitude: ""
    property string temp: "33°"
    property string feels: "Feels like 33°"
    property string description: "Clear Sky"
    property string humidity: "27%"
    property string wind: "8 km/h"
    property string pressure: "992 hPa"
    property string precip: "0%"
    property string sunrise: "04:53"
    property string sunset: "20:47"
    property var forecast: [
        { day: "Today", icon: "☼", temp: "18°/33°" },
        { day: "Tomorrow", icon: "☼", temp: "18°/35°" },
        { day: "Szo", icon: "☼", temp: "19°/37°" },
        { day: "V", icon: "☼", temp: "25°/38°" },
        { day: "H", icon: "☂", temp: "23°/35°" }
    ]

    width: 0
    height: 0
    visible: false

    onActiveChanged: if (active) loadLocation()

    function two(value) {
        return value.toString().padStart(2, "0")
    }

    function weatherIcon(text) {
        var lower = (text || "").toLowerCase()
        if (lower.indexOf("rain") !== -1 || lower.indexOf("shower") !== -1) return "☂"
        if (lower.indexOf("cloud") !== -1 || lower.indexOf("overcast") !== -1) return "☁"
        if (lower.indexOf("snow") !== -1) return "❄"
        if (lower.indexOf("storm") !== -1 || lower.indexOf("thunder") !== -1) return "ϟ"
        return "☼"
    }

    function weatherCondition(code) {
        if (code === 0) return "Sunny"
        if (code === 1 || code === 2) return "Partly Cloudy"
        if (code === 3) return "Cloudy"
        if (code === 45 || code === 48) return "Fog"
        if (code >= 51 && code <= 67) return "Drizzle"
        if (code >= 71 && code <= 77) return "Snow"
        if (code >= 80 && code <= 82) return "Rain Showers"
        if (code >= 95) return "Thunderstorm"
        if (code >= 61 && code <= 65) return "Rain"
        return "Weather"
    }

    function formatWeatherTime(value) {
        if (!value) return "--:--"
        var date = new Date(value)
        if (isNaN(date.getTime())) return "--:--"
        return two(date.getHours()) + ":" + two(date.getMinutes())
    }

    function parseWeather(text) {
        if (!text || text === "") return
        try {
            var data = JSON.parse(text)
            if (data.current && data.daily) {
                var currentWeather = data.current
                var dailyWeather = data.daily
                var code = currentWeather.weather_code || 0
                temp = Math.round(currentWeather.temperature_2m || 0) + "°"
                feels = "Feels like " + Math.round(currentWeather.apparent_temperature || currentWeather.temperature_2m || 0) + "°"
                description = weatherCondition(code)
                humidity = Math.round(currentWeather.relative_humidity_2m || 0) + "%"
                wind = Math.round(currentWeather.wind_speed_10m || 0) + " km/h"
                pressure = Math.round(currentWeather.surface_pressure || 0) + " hPa"
                precip = Math.round(dailyWeather.precipitation_probability_max && dailyWeather.precipitation_probability_max.length > 0 ? dailyWeather.precipitation_probability_max[0] : 0) + "%"
                sunrise = formatWeatherTime(dailyWeather.sunrise && dailyWeather.sunrise.length > 0 ? dailyWeather.sunrise[0] : "")
                sunset = formatWeatherTime(dailyWeather.sunset && dailyWeather.sunset.length > 0 ? dailyWeather.sunset[0] : "")

                var meteoForecast = []
                var meteoDays = dailyWeather.time || []
                for (var m = 0; m < Math.min(meteoDays.length, 5); m++) {
                    meteoForecast.push({
                        day: m === 0 ? "Today" : meteoDays[m].slice(5),
                        icon: weatherIcon(weatherCondition(dailyWeather.weather_code && dailyWeather.weather_code.length > m ? dailyWeather.weather_code[m] : 0)),
                        temp: Math.round(dailyWeather.temperature_2m_min[m] || 0) + "°/" + Math.round(dailyWeather.temperature_2m_max[m] || 0) + "°"
                    })
                }
                if (meteoForecast.length > 0) forecast = meteoForecast
                return
            }

            var current = data.current_condition && data.current_condition.length > 0 ? data.current_condition[0] : null
            if (current) {
                temp = current.temp_C + "°"
                feels = "Feels like " + current.FeelsLikeC + "°"
                description = current.weatherDesc && current.weatherDesc.length > 0 ? current.weatherDesc[0].value : description
                humidity = current.humidity + "%"
                wind = current.windspeedKmph + " km/h"
                pressure = current.pressure + " hPa"
                precip = current.precipMM + " mm"
            }
            var area = data.nearest_area && data.nearest_area.length > 0 ? data.nearest_area[0] : null
            if (area && area.areaName && area.areaName.length > 0) location = area.areaName[0].value
            var days = data.weather || []
            var next = []
            for (var i = 0; i < Math.min(days.length, 5); i++) {
                var hourly = days[i].hourly && days[i].hourly.length > 0 ? days[i].hourly[Math.min(4, days[i].hourly.length - 1)] : null
                var desc = hourly && hourly.weatherDesc && hourly.weatherDesc.length > 0 ? hourly.weatherDesc[0].value : description
                next.push({ day: i === 0 ? "Today" : days[i].date.slice(5), icon: weatherIcon(desc), temp: days[i].mintempC + "°/" + days[i].maxtempC + "°" })
                if (i === 0 && days[i].astronomy && days[i].astronomy.length > 0) {
                    sunrise = days[i].astronomy[0].sunrise
                    sunset = days[i].astronomy[0].sunset
                }
            }
            if (next.length > 0) forecast = next
        } catch (e) {
        }
    }

    function parseGeo(text) {
        if (!text || text === "") return
        try {
            var data = JSON.parse(text)
            var result = data.results && data.results.length > 0 ? data.results[0] : null
            if (!result) return
            location = result.name || location
            latitude = result.latitude.toString()
            longitude = result.longitude.toString()
            fetchWeather()
        } catch (e) {
        }
    }

    function fetchWeather() {
        if (latitude === "" || longitude === "") return
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,surface_pressure,wind_speed_10m&daily=sunrise,sunset,temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max&timezone=auto&forecast_days=5"
        weatherLoader.command = ["curl", "-fsS", "--connect-timeout", "3", "--max-time", "6", "--compressed", url]
        weatherLoader.running = true
    }

    function refresh() {
        var coords = Quickshell.env("WEATHER_COORDS") || ""
        if (coords !== "") {
            var parts = coords.split(",")
            if (parts.length === 2) {
                latitude = parts[0].trim()
                longitude = parts[1].trim()
                fetchWeather()
                return
            }
        }
        geoLoader.command = ["curl", "-fsS", "--connect-timeout", "3", "--max-time", "6", "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(location) + "&count=1&language=en&format=json"]
        geoLoader.running = true
    }

    function loadLocation() {
        locationLoader.command = ["sh", "-c", "base=\"$HOME/.config/quickshell/omi_shell\"; if [ -n \"${WEATHER_LOCATION:-}\" ]; then printf '%s' \"$WEATHER_LOCATION\"; elif [ -r \"$base/current-weather-location\" ]; then sed -n '1p' \"$base/current-weather-location\"; else printf 'Budapest'; fi"]
        locationLoader.running = true
    }

    Process {
        id: weatherLoader
        stdout: StdioCollector { onStreamFinished: weather.parseWeather(this.text || "") }
    }
    Process {
        id: locationLoader
        stdout: StdioCollector {
            onStreamFinished: {
                var nextLocation = (this.text || "").trim()
                weather.location = nextLocation !== "" ? nextLocation : "Budapest"
                weather.latitude = ""
                weather.longitude = ""
                weather.refresh()
            }
        }
    }
    Process {
        id: geoLoader
        stdout: StdioCollector { onStreamFinished: weather.parseGeo(this.text || "") }
    }
}
