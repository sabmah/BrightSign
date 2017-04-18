Function deviceInfo_Initialize(msgPort As Object, userVariables As Object, bsp as Object)

    deviceInfo = {}
    deviceInfo.msgPort = msgPort
    deviceInfo.userVariables = userVariables
    deviceInfo.bsp = bsp
    deviceInfo.ProcessEvent=deviceInfo_ProcessEvent

    deviceInfo.name = "deviceInfo"
    deviceInfo.version = 0.1

    ' --------------- Get the Serial Number of the Unit
    player = CreateObject("roDeviceInfo")
    deviceInfo.uniqueId = player.GetDeviceUniqueId()

    ' --------------- Get the Name of the Unit
    registrySection = CreateObject("roRegistrySection", "networking")
    deviceInfo.unitName = registrySection.Read("un")

    ' --------------- Get the IP Address of the Unit
    net = CreateObject("roNetworkConfiguration", 0) 
    if net = invalid then 
        net = CreateObject("roNetworkConfiguration", 1) 
	endif

    deviceInfo.ip = ""

    if net <> invalid then 
        deviceInfo.ip = net.GetCurrentConfig().ip4_address
	endif

    ' --------------- Get the Channel Url
    currentSync = CreateObject("roSyncSpec")
    deviceInfo.channelUrl = ""

    if not currentSync.ReadFromFile("current-sync.xml") then
	    deviceInfo.bsp.diagnostics.printdebug( "### No current sync state available")
    else
        deviceInfo.channelUrl = currentSync.LookupMetadata("client", "base")
	endif

    deviceInfo.bsp.diagnostics.printdebug("deviceInfo Initialized");

  return deviceInfo
End Function



Function deviceInfo_ProcessEvent(event as Object) as boolean
	retval = false
    m.bsp.diagnostics.printdebug( "Type of event is " + type(event))
    
	if type(event) = "roAssociativeArray" then
        if type(event["EventType"]) = "roString"
             if (event["EventType"] = "SEND_PLUGIN_MESSAGE") then
                if event["PluginName"] = "DeviceInfo" then
                    h.bsp.diagnostics.printdebug( "event DeviceInfo")
                    pluginMessage$ = event["PluginMessage"]
                    retval = SendDeviceInfo(pluginMessage$, m)
                endif
            endif
        endif
	endif

	if type(event) = "roDatagramEvent" then
	    msg$ = event
	    retval = SendDeviceInfo(msg, m)
	end if
	return retval
end Function



Function SendDeviceInfo(msg as string, h as Object) as Object

	h.bsp.diagnostics.printdebug("DeviceInfo: " + msg);
    h.bsp.diagnostics.printdebug( "Ip: "+h.ip);
    h.bsp.diagnostics.printdebug( "Name: "+h.unitName);
    h.bsp.diagnostics.printdebug( "Channel: "+h.channelUrl);
    h.bsp.diagnostics.printdebug( "Serial Number: "+ h.uniqueId);

	retval=false

    info = CreateObject("roAssociativeArray")

    info.AddReplace("Ip", h.ip)
    info.AddReplace("Name", h.unitName)
    info.AddReplace("Channel", h.channelUrl)
    info.AddReplace("SerialNumber", h.uniqueId)

	if h.userVariables["DeviceInfo_url"]<>invalid
	    DeviceInfo_url=h.userVariables["DeviceInfo_url"].currentValue$
	else
	    DeviceInfo_url=""
    end if

    if DeviceInfo_url<>""
        deviceInfo.bsp.diagnostics.printdebug(DeviceInfo_url)

		xfer = CreateObject("roUrlTransfer") 
		
		xfer.SetURL(DeviceInfo_url)

		xfer.PostFromString(FormatJson(info, 1)) 

	else
	    h.bsp.diagnostics.printdebug( "No DeviceInfo_url user variable is defined.")
	endif

	return retval
end Function
