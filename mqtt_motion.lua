require("credentials")
require("mqttconfig")

-- Connect device to wifi--
wifi.setmode(wifi.STATION)
wifi.sta.config(SSID, Password)

-- A timer that runs 1 once and waits for 10 seconds--
print("Fetching IP Adress..")
tmr.alarm(1,10000, tmr.ALARM_SINGLE, function()
    myip = wifi.sta.getip()
    if myip ~= nil then
        print(myip)
        mqttStart()
    else
        print("Wifi connection error")
    end
end)


-- function to publish whenever motion is detected
function publish_motionDetected()
    m:publish(ENDPOINT_MOTION, "1", 0, 0, function(client)
        print("Motion Detected.. Sent 1 to MQTT")
    end
    )
end

-- keep alive function to send pings to the server, so
-- it wont cut off connection after 120 sec
function publish_keepalive()
    tmr.alarm(1,1000,tmr.ALARM_AUTO, function()
        m:publish("aliveMotion", "alive", 0, 0, function(client)
            print("Kepp alive message")
        end
        )
    end
    )
end


--Motion Detection declarations setup
local motionpin = 1
gpio.mode(motionpin, gpio.INPUT)

function motionDetection()
    tmr.alarm(0,1000,tmr.ALARM_AUTO, function()
        motionStatus = gpio.read(motionpin)
        if motionStatus == 1 then
            publish_motionDetected()
            print("motion detected")
        else 
            print("No motion")
        end
    end
    )
end



-- function to connect to CloudMQTT
function mqttStart()
    -- returns mqtt client
    m = mqtt.Client(CLIENTID1,120,"user1","password")
    -- mqtt.client.connect() connect to broker
    m:connect(HOST,PORT,0,0,function(client)
        print("Connected..")
    end,
    function(client,reason)
        print("Reason.."..reason)
    end
    )

    -- on event to handle messages to cloudmqtt
    m:on("message", function(client,topic,message)
        if message ~= nil then
            print(topic .. " " .. message)
        end
    end
    )

    -- on event for offline , print in offline mode
    m:on("offline", function(client)
        print("In offline mode")
    end
    )

    -- on event for connection
    m:on("connect", function(client)
        print("Connected")
        motionDetection()
        publish_keepalive()
    end
    )

    m:lwt("/lwt", "offline",0,0)
end


