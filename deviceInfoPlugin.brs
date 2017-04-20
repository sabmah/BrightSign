Function deviceInfoPlugin_Initialize(msgPort As Object, userVariables As Object, bsp as Object)

    deviceInfoPlugin = {}
    deviceInfoPlugin.msgPort = msgPort
    deviceInfoPlugin.userVariables = userVariables
    deviceInfoPlugin.bsp = bsp
    deviceInfoPlugin.ProcessEvent = deviceInfoPlugin_ProcessEvent
	deviceInfoPlugin.info = newDeviceInfo(userVariables)
	deviceInfoPlugin.timer = CreateObject("roTimer")
    deviceInfoPlugin.reg = CreateObject("roRegistrySection", "networking")
    deviceInfoPlugin.uploadTimerInSeconds = 60

    '----- Get user Variable for debug (if any)
	
    if userVariables["Enable_Telnet"] <> invalid
	    enable$ = userVariables["Enable_Telnet"].currentValue$
        if LCase(enable$) = "yes"
            deviceInfoPlugin.reg.write("telnet", "23")
            print "@deviceInfoPlugin TELNET Enabled."
        else
            deviceInfoPlugin.reg.delete("telnet", "23")
            print "@deviceInfoPlugin TELNET Disabled."
        end if
    end if

    '----- Get user Variable for uplaod Time (if any)
	
    if userVariables["DeviceInfo_Upload_Timer_Value"] <> invalid
	    userVarelapsedTimeInSeconds$ = userVariables["DeviceInfo_Upload_Timer_Value"].currentValue$
        deviceInfoPlugin.uploadTimerInSeconds = userVarelapsedTimeInSeconds$.toint()
        print "@deviceInfoPlugin Upload Timer Set To "; deviceInfoPlugin.uploadTimerInSeconds; " Seconds"
    end if

    '----- Create Message Port and Set Timer
    
    deviceInfoPlugin.timer.SetPort(deviceInfoPlugin.msgPort)
	
	deviceInfoPlugin.timer.SetUserData("SEND_DEVICEINFO")

    deviceInfoPlugin.timer.SetElapsed(deviceInfoPlugin.uploadTimerInSeconds, 0)

    deviceInfoPlugin.timer.Start()

    return deviceInfoPlugin

End Function

Function deviceInfoPlugin_ProcessEvent(event as Object)
	
	retval = false
	
	if type(event) = "roTimerEvent" then
		if event.GetUserData() <> invalid then
			if event.GetUserData() = "SEND_DEVICEINFO" then
				print "#### SENDING DEVICE INFO"
				retval = true
			end if
		end if
	end if
	
	m.timer.Start()
	
	return retval
	
End Function

Function newDeviceInfo(userVariables As Object)
	
    player = CreateObject("roDeviceInfo")
    registrySection = CreateObject("roRegistrySection", "networking")
    net = CreateObject("roNetworkConfiguration", 1)

    deviceInfo = {}

    deviceInfo.UniqueId = player.GetDeviceUniqueId()
    deviceInfo.Model = player.GetModel()
    deviceInfo.UpTime = player.GetDeviceUptime()
    deviceInfo.Firmware = player.GetVersion()
    deviceInfo.BootVersion = player.GetBootVersion()
    deviceInfo.UnitName = registrySection.Read("un")
    deviceInfo.Ip = net.GetCurrentConfig().ip4_address
	deviceInfo.Channel = ""
	
    if (userVariables.Channel <> invalid) then 
		deviceInfo.Channel = userVariables.Channel.currentValue$ 
	end if

    return deviceInfo

End Function

