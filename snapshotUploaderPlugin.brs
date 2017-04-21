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

    '---- Get Player Unit Id
    player = CreateObject("roDeviceInfo")
    snapshotUploaderPlugin.unitId = player.GetDeviceUniqueId()

    '---- Set Headers for Snapshot Upload
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

                snapshotUploadUrl$ = ""
                unitId$ = m.unitId
				snapshotName$ = event["SnapshotName"]
                filePath$ = "snapshots/" + snapshotName$
                fileSize% = 0

			    print "@snapshotUploaderPlugin SNAPSHOT filename is :"; snapshotName$

                if m.userVariables["snapshot_upload_url"]<>invalid then
                    snapshotUploadUrl = m.userVariables["snapshot_upload_url"].currentValue$
                end if

                '---- Send SnapShot
                if snapshotUploadUrl <> "" AND unitId <> "" then

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
                        xfr.SetUrl(snapshotUploadUrl$ + unitId)

                        ok = xfr.AsyncPostFromFile(filePath$)

                        if ok then
                            print "@snapshotUploaderPlugin Successfully Posted the SnapShot File!"; snapshotName$
                            retval = true
                        else
                            print "@snapshotUploaderPlugin Cannot Post the SnapShot File!"
                        end if
                    else
                        print "@snapshotUploaderPlugin Snapshot is an empty file"
                    end if      

                end if
			end if
		end if
	end if
		
	return retval

End Function

