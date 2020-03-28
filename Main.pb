; ==============================================================
; Created on:         15.5.2016
; App/Lib-Name:       Ciphersaber
; Author:             Niklas Hennigs
; Version:            1.0
; Compiler:           PureBasic 5.42 LTS (MacOS X - x64)
; ==============================================================

;@@ CFBundleIdentifier = de.nueh.Ciphersaber
;@@ CFBundleVersion = 1.0.0
;@@ CFBundleShortVersionString = 1.0.0
;@@ NSHumanReadableCopyright = © 2016 Niklas Hennigs
;@@ CFBundleIconFile = Ciphersaber
;@R Ciphersaber.icns
;@R Ciphersaber64.png
;@@ DisableDebugWindow

XIncludeFile "AboutWindow.pbf"

ImportC ""
  sel_registerName(str.p-ascii)
EndImport


CompilerIf  #PB_Editor_CreateExecutable
 #ResourceFolder = "Resources/"
CompilerElse
  #ResourceFolder = "/Users/niklas/code/CiphersaberGUI/"
CompilerEndIf


CompilerSelect #PB_Compiler_OS
  CompilerCase #PB_OS_Windows
  #NEWLINE = #CRLF$
  CompilerDefault
  #NEWLINE = #LF$
CompilerEndSelect


Procedure.l getHexSize(hex$)
  hex$ = RemoveString(hex$, " ")
  hex$ = RemoveString(hex$, Chr(9)) ; TAB
  hex$ = RemoveString(hex$, #CR$)
  hex$ = RemoveString(hex$, #LF$)

  ProcedureReturn Len(hex$)
EndProcedure


Procedure.s memoryToHex(address, length)
  Protected result$, i
  For i = 0 To length - 1
    result$ + RSet(LCase(Hex(PeekB(address + i), #PB_Byte)), 2, "0") + " "
    If ((i + 1) % 22) = 0
      result$ = result$ + #NEWLINE
    EndIf
  Next
  ProcedureReturn RTrim(result$)
EndProcedure


Procedure hexToMemory(address, hex$)
  Protected i, pos, len
  hex$ = RemoveString(hex$, " ")
  hex$ = RemoveString(hex$, Chr(9)) ; TAB
  hex$ = RemoveString(hex$, #CR$)
  hex$ = RemoveString(hex$, #LF$)
  len  = Len(hex$)
  For i = 1 To len Step 2
    PokeB(address + pos, Val("$" + Mid(hex$, i, 2)))
    pos + 1
  Next
EndProcedure


Procedure encrypt(*input.Ascii, inputLen, *output.Ascii, *key.Ascii, keyLen, rounds = 20)

  ; max key length of 246 bytes
  If keyLen > 246
    keyLen = 246
  EndIf

  ; define state array and key array (S2)
  Dim S.a(255)
  Dim S2.a(255)

  ; setup index variables
  i.u = 0
  j.u = 0
  n.u = 0

  ; generate random 10 byte initialization vector (IV) (conveniently at the beginning of output)
  OpenCryptRandom()
  CryptRandomData(*output, 10)

  ; put first 246 bytes of key into S2 array
  CopyMemory(*key, @S2(), keyLen)

  ; copy IV (first 10 bytes of output) to end of user key in S2 array
  CopyMemory(*output, @S2(keyLen), 10)
  *output = *output + 10

  ; fill the array repeating key and IV
  For i = keyLen + 10 To 255
    S2(i) = S2(i - keyLen - 10)
  Next

  ; set up state array
  For i = 0 To 255
    S(i) = i
  Next

  ; mix up the state array
  j = 0
  For n = 1 To rounds
    For i = 0 To 255
      j    = (j + S(i) + S2(i)) % 256
      Swap S(i), S(j)
    Next
  Next

  ; ciphering operation
  j = 0
  i = 0
  n = 0

  While inputLen
    i = (i + 1) % 256
    j = (j + S(i)) % 256
    Swap S(i), S(j)
    n         = (S(i) + S(j)) % 256
    *output\a = *input\a ! S(n)
    *input + 1
    *output + 1
    inputLen - 1
  Wend

EndProcedure


Procedure decrypt(*input.Ascii, inputLen, *output.Ascii, *key.Ascii, keyLen, rounds = 20)

  ; max key length of 246 bytes
  If keyLen > 246
    keyLen = 246
  EndIf

  ; define state array (S) and key array (S2)
  Dim S.a(255)
  Dim S2.a(255)

  ; setup index variables
  i.i = 0
  j.u = 0
  n.u = 0

  ; put first 246 bytes of key into S2 array
  CopyMemory(*key, @S2(), keyLen)

  ; copy initialization vector (IV) from beginning of input to the end of user key in S2 array
  CopyMemory(*input, @S2(keyLen), 10)

  ; move input pointer (*input) ten bytes to start of content
  *input = *input + 10

  ; fill the array repeating key and IV
  For i = keyLen + 10 To 255
    S2(i) = S2(i - keyLen - 10)
  Next

  ; set up state array
  For i = 0 To 255
    S(i) = i
  Next

  ; mix up the state array
  j = 0
  For n = 1 To rounds
    For i = 0 To 255
      j = (j + S(i) + S2(i)) % 256
      Swap S(i), S(j)
    Next
  Next

  ; ciphering operation
  j = 0
  i = 0
  n = 0

  While inputLen
    i = (i + 1) % 256
    j = (j + S(i)) % 256
    Swap S(i), S(j)
    n         = (S(i) + S(j)) % 256
    *output\a = *input\a ! S(n)
    *input + 1
    *output + 1
    inputLen - 1
  Wend

EndProcedure


; -------------------------------------| Window About |----------------------------------------
ExamineDesktops()

x = DesktopWidth(0) / 2 - 150
y = 150

; UsePNGImageDecoder()
; 
; LoadFont(0,".AppleSystemUIFont", 14, #PB_Font_Bold)
; LoadFont(1,".AppleSystemUIFont", 10)
; 
; Window_About = OpenWindow(#PB_Any, x, y, 300, 280, "About Ciphersaber")
; 
; Img_About   = LoadImage(#PB_Any, #ResourceFolder + "Ciphersaber64.png")
; Image_About = ImageGadget(#PB_Any, 86, 0, 128, 128, ImageID(Img_About))
; Text_Title = TextGadget(#PB_Any, 0, 86, 286, 34, "Ciphersaber", #PB_Text_Center)
; SetGadgetFont(Text_Title, FontID(0))
; Text_Version = TextGadget(#PB_Any, 0, 123, 286, 24, "Version 1.0 (23)", #PB_Text_Center)
; SetGadgetFont(Text_Version, FontID(1))
; Text_Copyright = TextGadget(#PB_Any, 0, 152, 286, 32, "Copyright © 2016 Niklas Hennigs. All rights reversed.", #PB_Text_Center)
; SetGadgetFont(Text_Copyright, FontID(1))

OpenWindow_About(x, y, 310, 210)
HideWindow(Window_About, #True)


; --------------------------------------| Window Main |----------------------------------------
Window_Main = OpenWindow(#PB_Any, 0, 0, 554, 610, "Ciphersaber", #PB_Window_SystemMenu |
#PB_Window_MinimizeGadget |
#PB_Window_ScreenCentered)
String_Input      = EditorGadget(#PB_Any, 20, 20, 514, 250)
EnableGadgetDrop(String_Input, #PB_Drop_Text, #PB_Drag_Copy)
CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  CocoaMessage(0, GadgetID(String_Input), "setAllowsUndo:", #YES) ; allow UNDO
CompilerEndIf
GadgetToolTip(String_Input, "Input the input!")

String_Output     = EditorGadget(#PB_Any, 20, 340, 514, 250, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
LoadFont(1, "Menlo", 12)
SetGadgetFont(String_Output, FontID(1))
SetGadgetFont(String_Input, FontID(1))

String_Passphrase = StringGadget(#PB_Any, 109, 276, 425, 22, "")
GadgetToolTip(String_Passphrase, "Maximum of 246 bytes i.e. characters")

Text_Passphrase   = TextGadget(#PB_Any, 23, 278, 77, 17, "Passphrase:", #PB_Text_Right)

Text_Rounds       = TextGadget(#PB_Any, 40, 311, 56, 17, "Rounds:", #PB_Text_Right)

Combo_Rounds      = ComboBoxGadget(#PB_Any, 109, 306, 58, 26, #PB_ComboBox_Editable)
AddGadgetItem(Combo_Rounds, 0, "1")
AddGadgetItem(Combo_Rounds, 1, "10")
AddGadgetItem(Combo_Rounds, 2, "20")
AddGadgetItem(Combo_Rounds, 3, "100")
AddGadgetItem(Combo_Rounds, 4, "1000")
SetGadgetState(Combo_Rounds, 2)

Button_Encrypt = ButtonGadget(#PB_Any, 372, 305, 81, 32, "Encrypt")
Button_Decrypt = ButtonGadget(#PB_Any, 457, 305, 81, 32, "Decrypt")

DisableGadget(Button_Encrypt, 1)
DisableGadget(Button_Decrypt, 1)


; -----------------------------------------| Menu |--------------------------------------------
If CreateMenu(0, WindowID(Window_Main))
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    MenuItem(#PB_Menu_About, "About Ciphersaber")
  CompilerEndIf  

  MenuTitle("File")
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    MenuItem(0, "Open…" + Chr(9) + "Cmd+O")
  CompilerElseIf #PB_Compiler_OS = #PB_OS_Windows
    AddKeyboardShortcut(Window_Main, #PB_Shortcut_Control | #PB_Shortcut_O, 0)
  CompilerEndIf
  MenuItem(1, "Close Window" + Chr(9) + "Cmd+W")
  MenuTitle("Edit")
  
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    MenuTitle("Help")
    MenuItem(666, "About Ciphersaber")
  CompilerEndIf 
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  ; Find menu title "Edit" and add functionality
  MenuArray = MenuID(0)
  Idx       = CocoaMessage(0, MenuArray, "count") - 1
  While Idx >= 0
    TopMenu = CocoaMessage(0, MenuArray, "objectAtIndex:", Idx)
    If CocoaMessage(0, CocoaMessage(0, TopMenu, "title"), "isEqualToString:$", @"Edit")
      CocoaMessage(0, TopMenu, "addItemWithTitle:$", @"Undo", "action:", sel_registerName("undo:"), "keyEquivalent:$", @"z")
      CocoaMessage(0, TopMenu, "addItemWithTitle:$", @"Redo", "action:", sel_registerName("redo:"), "keyEquivalent:$", @"Z")
      CocoaMessage(0, TopMenu, "addItem:", CocoaMessage(0, 0, "NSMenuItem separatorItem"))
      CocoaMessage(0, TopMenu, "addItemWithTitle:$", @"Cut", "action:", sel_registerName("cut:"), "keyEquivalent:$", @"x")
      CocoaMessage(0, TopMenu, "addItemWithTitle:$", @"Copy", "action:", sel_registerName("copy:"), "keyEquivalent:$", @"c")
      CocoaMessage(0, TopMenu, "addItemWithTitle:$", @"Paste", "action:", sel_registerName("paste:"), "keyEquivalent:$", @"v")
      CocoaMessage(0, TopMenu, "addItemWithTitle:$", @"Select All", "action:", sel_registerName("selectAll:"), "keyEquivalent:$", @"a")
      While WindowEvent() : Wend
      Idx = CocoaMessage(0, TopMenu, "numberOfItems") - 1
      While Idx >= 7
        CocoaMessage(0, TopMenu, "removeItemAtIndex:", Idx)
        Idx - 1
      Wend
      Break
    EndIf
    Idx - 1
  Wend
  CompilerEndIf

EndIf

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  #NSRoundedBezelStyle = 1
  CocoaMessage(0, GadgetID(Button_Encrypt), "setBezelStyle:", #NSRoundedBezelStyle)
  CocoaMessage(0, GadgetID(Button_Decrypt), "setBezelStyle:", #NSRoundedBezelStyle)

  ; ButtonCell = CocoaMessage(0, GadgetID(Button_Encrypt), "cell")
  ; CocoaMessage(0, WindowID(Window_Main), "setDefaultButtonCell:", ButtonCell)
CompilerEndIf

Repeat
  Event = WaitWindowEvent()

  Select Event
      
      Case #PB_Event_GadgetDrop
        Select EventGadget()
          Case String_Input
            Text$ = EventDropText()
            SetGadgetText(String_Input, Text$)
        EndSelect
        
    Case #PB_Event_Menu
      Select EventMenu()
          
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          Case #PB_Menu_About
            HideWindow(Window_About, #False)
        CompilerEndIf
              
        CompilerIf #PB_Compiler_OS = #PB_OS_Windows
          Case 666
            HideWindow(Window_About, #False)
        CompilerEndIf 

      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS  
        Case #PB_Menu_Quit : End
      CompilerEndIf
      

        Case 0
          File$ = OpenFileRequester("Open text file", "", "Text (*.txt)|*.txt", 0)
          If ReadFile(0, File$)
            FileContent$ = ReadString(0, #PB_File_IgnoreEOL)
            SetGadgetText(String_Input, FileContent$)
          EndIf

        Case 1
          If GetActiveWindow() = Window_About
            HideWindow(Window_About, #True)
            SetActiveWindow(Window_Main)
          Else
            End
          EndIf

      EndSelect

    Case #PB_Event_Gadget
      Select EventGadget()

        Case String_Input  
          Select EventType()
              
            Case #PB_EventType_Change              
                If GetGadgetText(String_Input) <> "" And GetGadgetText(String_Passphrase) <> ""
                  DisableGadget(Button_Encrypt, #False)
                  DisableGadget(Button_Decrypt, #False)
                Else
                  DisableGadget(Button_Encrypt, #True)
                  DisableGadget(Button_Decrypt, #True)
                EndIf

          EndSelect

        Case String_Passphrase
          Select EventType()
              
            Case #PB_EventType_Change            
                If GetGadgetText(String_Input) <> "" And GetGadgetText(String_Passphrase) <> ""
                  DisableGadget(Button_Encrypt, #False)
                  DisableGadget(Button_Decrypt, #False)
                Else
                  DisableGadget(Button_Encrypt, #True)
                  DisableGadget(Button_Decrypt, #True)
                EndIf

          EndSelect


        Case Button_Encrypt

          Define key.s   = GetGadgetText(String_Passphrase)
          Define *key
          Define rounds  = Val(GetGadgetText(Combo_Rounds))
          Define *output
          Define *input
          Define length = Len(GetGadgetText(String_Input))

          *output = AllocateMemory(length + 10)
          *input  = AllocateMemory(length)

          PokeS(*input, GetGadgetText(String_Input), -1, #PB_Ascii | #PB_String_NoZero)

          *key   = AllocateMemory(Len(key))
          PokeS(*key, key, -1, #PB_Ascii | #PB_String_NoZero)

          encrypt(*input, length, *output, *key, Len(key), rounds)
          ;           CreateThread(@encryptHelper(), 23)

          SetGadgetText(String_Output, memoryToHex(*output, MemorySize(*output)))

        Case Button_Decrypt
          
          Define key.s   = GetGadgetText(String_Passphrase)
          Define *key
          Define rounds  = Val(GetGadgetText(Combo_Rounds))
          Define *output
          Define *input
          Define length = Len(GetGadgetText(String_Input))

          *output = AllocateMemory(length)
          *input  = AllocateMemory(length)

          input.s = GetGadgetText(String_Input)

          *key   = AllocateMemory(Len(key))
          PokeS(*key, key, -1, #PB_Ascii | #PB_String_NoZero)

          Define *temp = AllocateMemory(getHexSize(input) / 2)
          hexToMemory(*temp, input)
          CopyMemory(*temp, *input, MemorySize(*temp))
          decrypt(*input, MemorySize(*temp) - 10, *output, *key, Len(key), rounds)

          ;           SetGadgetText(String_Output, PeekS(*output, -1, #PB_Ascii))
          ;           oder
          SetGadgetText(String_Output, PeekS(*output, MemorySize(*temp), #PB_Ascii))
      EndSelect
    EndSelect

    Select EventWindow()
      Case Window_Main
        If Event = #PB_Event_CloseWindow
          End
        EndIf

      Case Window_About
        If Event = #PB_Event_CloseWindow
          HideWindow(Window_About, #True)
          SetActiveWindow(Window_Main)
        EndIf

    EndSelect

  ForEver
; IDE Options = PureBasic 5.71 LTS (MacOS X - x64)
; CursorPosition = 240
; FirstLine = 229
; Folding = ---
; EnableXP
; CompileSourceDirectory
; EnableExeConstant
; EnableUnicode