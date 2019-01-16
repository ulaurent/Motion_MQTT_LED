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


-- function LED to subscribe to motion is detected
function subscribe_motionDetected()
        m:subscribe(ENDPOINT_MOTION,0,function(client)
            print("Subscribe to topic motion detected")
    end
    )
end

-- keep alive function to send pings to the server, so
-- it wont cut off connection after 120 sec
function publish_keepalive()
    tmr.alarm(1,1000,tmr.ALARM_AUTO, function()
        m:publish("aliveLED", "alive", 0, 0, function(client)
            print("Kepp alive message")
        end
        )
    end
    )
end


--LED declarations setup
local ledpin = 7
gpio.mode(ledpin, gpio.OUTPUT)
local status = gpio.LOW
gpio.write(ledpin,status)

function ledState(message)
    if message == "1" then
      status = gpio.HIGH
      gpio.write(ledpin,status)
      -- Timer to determine how long you want the led to remain on after motion detected
      tmr.alarm(0,3000,tmr.ALARM_AUTO,function()
          status = gpio.LOW
          gpio.write(ledpin, status)
      end
      )
    end
end



-- function to connect to CloudMQTT
function mqttStart()
    -- returns mqtt client
    m = mqtt.Client(CLIENTID2,120,"user1","password")
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
            ledState(message)
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
        subscribe_motionDetected()
        publish_keepalive()
    end
    )

    m:lwt("/lwt", "offline",0,0)
end


