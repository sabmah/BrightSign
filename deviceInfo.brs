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
	    print "### No current sync state available"
    else
        deviceInfo.channelUrl = currentSync.LookupMetadata("client", "base")
	endif


  return deviceInfo
End Function



Function deviceInfo_ProcessEvent(event as Object) as boolean
	retval = false
    print "Type of event is ";type(event)
    
	if type(event) = "roAssociativeArray" then
        if type(event["EventType"]) = "roString"
             if (event["EventType"] = "SEND_PLUGIN_MESSAGE") then
                if event["PluginName"] = "DeviceInfo" then
                    print "event DeviceInfo"
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

	print "DeviceInfo: ";msg;
    print "Ip: ";deviceInfo.ip;
    print "Name: ";deviceInfo.unitName;
    print "Channel: ";deviceInfo.channelUrl;
    print "Serial Number: "; deviceInfo.uniqueId;

	retval=false

    info = CreateObject("roAssociativeArray")

    info.AddReplace("Ip", deviceInfo.ip)
    info.AddReplace("Name", deviceInfo.unitName)
    info.AddReplace("Channel", deviceInfo.channelUrl)
    info.AddReplace("SerialNumber", deviceInfo.uniqueId)

	if deviceInfo.userVariables["DeviceInfo_url"]<>invalid
	    DeviceInfo_url=deviceInfo.userVariables["DeviceInfo_url"].currentValue$
	else
	    DeviceInfo_url=""
    end if

    if DeviceInfo_url<>""
        print DeviceInfo_url

		xfer = CreateObject("roUrlTransfer") 
		
		xfer.SetURL(DeviceInfo_url)

		xfer.PostFromString(FormatJson(info, 1)) 

	else
	    print "No DeviceInfo_url user variable is defined."
	endif

	return retval
end Function