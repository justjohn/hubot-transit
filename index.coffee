transitAPI = require "transit-api"
_ = require "underscore"

mbta = new transitAPI.MBTA
railData = mbta.subways()

index = _.memoize () ->
    return railData.then (data) ->
        idx = {}

        for key,line of data
            for i,stop of line
                idx[stop.PlatformKey] = stop

        return idx

matchSearch = (search, stop) ->
    search = search.toLowerCase().split " "

    terms = stop.PlatformName.toLowerCase().split " "
    terms.push stop.PlatformKey.toLowerCase()

    weight = 0

    for searchTerm in search
        weight += terms.indexOf(searchTerm) >= 0 ? 1 : 0

    return weight >= search.length

module.exports = (robot) ->
    robot.respond /SUBWAY ([^ ]+) ?(.*)$/i, (msg) ->
        line = msg.match[1]
        search = msg.match[2]

        if line == "lines"
            mbta.lines.then (lines) ->
                msg.send lines
        else
            msg.send "The " + line + " line is delayed (obviously) - but I'll check anyway..."

            index().then (idx) ->
                mbta.predictions(line).then (resp) ->
                    found = {}
                    resp.forEach (stopRt) ->
                        stop = idx[stopRt.PlatformKey]
                        if !search || matchSearch(search, stop)
                            if !found[stop.PlatformName]
                                found[stop.PlatformName] = []

                            found[stop.PlatformName].push stopRt.TimeRemaining

                    if found.length == 0
                        msg.send "Sorry, couldn't find a stop for " + search + " on the " + line + " line"
                    else
                        for name, times of found
                            times.sort()
                            msg.send name + ": " + times.join ", "




