Function snapshotUploaderPlugin_Initialize(msgPort As Object, userVariables As Object, bsp as Object)

    snapshotUploaderPlugin = {}

    snapshotUploaderPlugin.msgPort = msgPort
    snapshotUploaderPlugin.userVariables = userVariables
    snapshotUploaderPlugin.bsp = bsp
    snapshotUploaderPlugin.ProcessEvent = snapshotUploaderPlugin_ProcessEvent
    snapshotUploaderPlugin.reg = CreateObject("roRegistrySection", "networking")

    '----- Get user Variable for debug (if any)
	
    if userVariables["Enable_Telnet"] <> invalid
	    enable$ = userVariables["Enable_Telnet"].currentValue$
        if LCase(enable$) = "yes"
            snapshotUploaderPlugin.reg.write("telnet", "23")
            print "@snapshotUploaderPlugin TELNET Enabled."
        else
            snapshotUploaderPlugin.reg.delete("telnet", "23")
            print "@snapshotUploaderPlugin TELNET Disabled."
        end if
    end if

    headers = {}

    headers["Content-Type"] = "image/jpeg"
    headers["Connection"] = "Keep-Alive"

    snapshotUploaderPlugin.headers = headers

    return snapshotUploaderPlugin

End Function

Function snapshotUploaderPlugin_ProcessEvent(event as Object)
    
    retval = false
	
	if type(event) = "roAssociativeArray" then
		if type(event["EventType"]) = "roString" OR type(event["EventType"]) = "String" then
			if event["EventType"] = "SNAPSHOT_CAPTURED" then
			    print "@snapshotUploaderPlugin SNAPSHOT EVENT HIT..."

				snapshotName$ = event["SnapshotName"]
                filePath$ = "snapshots/" + snapshotName$
                fileSize% = 0

                checkFile = CreateObject("roReadFile", filePath$)

                '---- Get File Size
                if (checkFile <> invalid) then
                    checkFile.SeekToEnd()
                    fileSize = checkFile.CurrentPosition()
                    checkFile = invalid
                end if

                '---- Only Send if File has some Content
                if fileSize > 0 then

                    m.headers["Content-Length"] = stri(fileSize%)

                    xfr = CreateObject("roUrlTransfer")

                    ok = xfr.AsyncPostFromFile(filePath$)

                    if ok then
                        print "@snapshotUploaderPlugin Successfully Posted the SnapShot File"; snapshotName$
                        retval = true
                    end if
                end if
			end if
		end if
	end if
		
	return retval

End Function

