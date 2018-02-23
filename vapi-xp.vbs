' vapi_tomasz [VBScript]
' Created by Application Lifecycle Management
' 10.01.2018 15:07:56
' ====================================================

' ----------------------------------------------------
' Main Test Function
' Debug - Boolean. Equals to false if running in [Test Mode] : reporting to Application Lifecycle Management
' CurrentTestSet - [OTA COM Library].TestSet.
' CurrentTSTest - [OTA COM Library].TSTest.
' CurrentRun - [OTA COM Library].Run.
' ----------------------------------------------------
Sub Test_Main(Debug, CurrentTestSet, CurrentTSTest, CurrentRun)

  ' *** VBScript Limitation ! ***
  ' "On Error Resume Next" statement suppresses run-time script errors.
  ' To handle run-time error in a right way, you need to put "If Err.Number <> 0 Then"
  ' after each line of code that can cause such a run-time error.
  'On Error Resume Next
  ' {$devices};{$testPath};{$testName};{$testArg1};{$testArg2};{$testArgX}
  CurrentRun.Status = "Passed"
  CurrentTSTest.Status = "Passed"
  TDOutput.Clear

  Arg1 = ""
  Arg2 = ""
  Arg3 = ""
  Arg4 = ""
  Set StepParams = CurrentTSTest.Params
  With StepParams
         For i = 0 To .Count - 1
                intCompare = StrComp(Trim(.ParamName(i)), "testname", vbTextCompare)
                If intCompare = 0 Then
                   Arg1 = Trim(.ParamValue(i))
                End If
                intCompare = StrComp(Trim(.ParamName(i)), "testpath", vbTextCompare)
                If intCompare = 0 Then
                   Arg2 = Trim(.ParamValue(i))
                End If
                intCompare = StrComp(Trim(.ParamName(i)), "testargs", vbTextCompare)
                If intCompare = 0 Then
                   Arg3 = Trim(.ParamValue(i))
                End If
                intCompare = StrComp(Trim(.ParamName(i)), "devices", vbTextCompare)
                If intCompare = 0 Then
                   Arg4 = Trim(.ParamValue(i))
                End If
         Next
  End With


  readParameters( CurrentTSTest )

  argumentList = Arg4 & ";" & Arg2 & ";" & Arg1 & ";" & Arg3

  ' clear output window

' set variables
  Set objShell = CreateObject("WScript.Shell")
  comspec = objShell.ExpandEnvironmentStrings("%comspec%")
  execute_path = objShell.ExpandEnvironmentStrings("%ALM_TEST_RUNNER%")
  executed_command = comspec & " /C ""python " & execute_path & "\ALMTestRunner.py " & argumentList & """"
  TDOutput.Print executed_command

' ////////////////////////////////////////////////////////

     Set objExec = objShell.Exec(executed_command)
     Do
          stdoutLine = objExec.StdOut.ReadLine()

          If InStr(1, stdoutLine, "{u'testStart") = 1 Then
              'JSON result parsing
              jsonString = stdoutLine
              TDOutput.Print "Json detected"
              TDOutput.Print stdoutLine
          ElseIf InStr(1, stdoutLine, "{") = 1 Then
              jsonStepsString = stdoutLine
              TDOutput.Print "Json Steps detected"
              TDOutput.Print stdoutLine
              Set step = parseJSON(jsonStepsString, 2)

              Set ss = TDHelper.AddStepToRun( step("name") , step("desc"), step("expected")  ,Replace(step("actual"),"\n",vbCrLf) , step("status") )

          Else
              TDOutput.Print stdoutLine
          End If

     Loop While Not objExec.Stdout.atEndOfStream

     ' parsing of JSON received


     'extract JSON steps
     'stepsPos = InStr(1, jsonString, "STEPS JSON:{")
     'stepsPosEnd = InStr(1,jsonString, "u'command'")
     'If stepsPos <> 0 Then
     '     TDOutput.Print Len("STEPS JSON:{")
     '     stepsString = Mid(Trim(jsonString), stepsPos + Len("STEPS JSON:"), Len(Trim(jsonString)) - Len("STEPS JSON:")  )
     '     jsonString0a = Mid(Trim(jsonString), 1 , stepsPos + Len("STEPS JSON") -1 )
     '     jsonString0b = Mid(Trim(jsonString), stepsPosEnd , Len(Trim(jsonString)) - stepsPosEnd)
     '     jsonString0 = jsonString0a & "<processed>, " & jsonString0b
     '     TDOutput.Print "STEPS: " & stepsString
     '
     '     TDOutput.Print jsonString0
     'Else
         jsonString0 = jsonString
     'End If
     Set result = parseJSON(jsonString0, 1)

     'check the result
     outcome = "Passed"
     intCompare = StrComp(result("success"), "True", vbTextCompare)
     If intCompare <> 0 Then
         CurrentRun.Status = "Failed"
         CurrentTSTest.Status = "Failed"
         outcome = "Failed"
     End If
     'create a step with python test execution
      Set s0 = TDHelper.AddStepToRun( "Python Test Execution" , "Test started: " & result("testStart") & vbCrLf & "Test ended: " & result("testEnd") & vbCrLf & "Test command: " & result("command") & vbCrLf & Replace(result("stdout"), "\n", vbCrLf), "", result("stderr"), outcome )

     ' standard output handling
     ' TDOutput.Print objExec.StdOut.ReadAll
     stdout = TDOutput.Text

     ' error from test script handling
     TDOutput.Clear
     errorLine = objExec.StdErr.ReadLine()

     intCompare = StrComp(errorLine, "", vbTextCompare)
     If intCompare = 0 Then
         Set s1 = TDHelper.AddStepToRun( "get Python Runner output" , Replace(stdout, "\n", vbCrLf), "no exceptions", "no exceptions", "Passed" )
     Else
         Set s1 = TDHelper.AddStepToRun( "get Python Runner output" , Replace(stdout, "\n", vbCrLf), "no exceptions", "exception!", "Failed" )
         TDOutput.Print errorLine
     End If

     Do
       TDOutput.Print objExec.StdErr.ReadLine()
     Loop While Not objExec.StdErr.atEndOfStream
     If intCompare = 0 Then
         Set s2 = TDHelper.AddStepToRun( "get Python Runner error" , TDOutput.Text, "empty", "empty", "Passed" )
     Else
         Set s2 = TDHelper.AddStepToRun( "get Python Runner error" , TDOutput.Text, "empty", "not empty", "Failed" )
         CurrentRun.Status = "Failed"
         CurrentTSTest.Status = "Failed"
         TDOutput.Print "Failed"
     End If
  ' varification for the result
  If Not Debug Then
     'some code
  End If

  ' handle run-time errors
  If Err.Number <> 0 Then

    TDOutput.Print "Run-time error [" & Err.Number & "] : " & Err.Description
    Set s3 = TDHelper.AddStepToRun( "get ALM exceptions" , "Run-time error [" & Err.Number & "] : " & Err.Description, "", Err.Description  , "Failed" )
    ' update execution status in "Test" mode
    If Not Debug Then
      CurrentRun.Status = "Failed"
      CurrentTSTest.Status = "Failed"
    End If
  Else
    Set s3 = TDHelper.AddStepToRun( "get ALM exceptions" , "", "no exceptions", "no exceptions", "Passed" )
  End If
End Sub

Sub readParameters(CurrentTSTest)
    With CurrentTSTest.Params
        For i = 0 To .Count - 1
                TDOutput.Print Trim(.ParamName(i)) & " = " & Trim(.ParamValue(i))
        Next
    End With
End Sub

Function parseJSON(jsonString0, keys)
     Set result = CreateObject("Scripting.Dictionary")
     If keys = 1 Then
          With result
               .Item("testStart") = ""
               .Item("testEnd") = ""
               .Item("stderr") = ""
               .Item("stdout") = ""
               .Item("success") = ""
               .Item("command") = ""
          End With
     ElseIf keys = 2 Then
          With result
               .Item("status") = ""
               .Item("actual") = ""
               .Item("expected") = ""
               .Item("name") = ""
               .Item("warnings") = ""
               .Item("desc") = ""
          End With
     End If
     'remove first 3 chars "{ '" and last 1
     jsonString2 = Mid(Trim(jsonString0), 4, Len(Trim(jsonString0)) - 4 )

     ' split for key : value pairs
     pairs=Split(jsonString2 , ", u'" )
     for each x in pairs

         'if pair string contain string value
         If InStr(1, x, ": u'") > 0 Then
            'TDOutput.Print x
            parts=Split(x , ": u'" )
            keyS = Mid(parts(0), 1 , Len(parts(0)) - 1)
            valueS = Mid(parts(1), 1 , Len(parts(1)) - 1)
            'TDOutput.Print keyS & " => " & valueS
            result.Item(keyS) = valueS
         'if pair string contains some not unicode string value
         Else
            parts=Split(x , ": " )
            keyS = Mid(parts(0), 1 , Len(parts(0)) - 1)
            valueS = Mid(parts(1), 1 , Len(parts(1)) )
            result.Item(keyS) = valueS
            'TDOutput.Print keyS & " => " & valueS
         End If
     next

     Set parseJSON = result
End Function