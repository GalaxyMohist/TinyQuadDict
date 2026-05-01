## This is Multi-language Dictionary Searching Program
# https://github.com/GalaxyMohist/LetMeTranslate

#これはAzureを利用した多言語辞書一括検索プログラムです。
#高速なnim言語で記述しているため低速なRaspberry Pi等でも快適に動作します。
#This is a multilingual dictionary batch lookup program using Azure.
#It is written in the fast nim language, so it runs well even on a slow Raspberry Pi.

# compile command
# nimble install nigui
# (for debug)
#   nim compile --threads:on --run TinyQuadDict.nim
# (for release)
# nim compile --threads:on --app:gui -d:release TinyQuadDict.nim


# This GUI has been created using NiGui
# https://github.com/trustable-code/NiGui

# You can learn NiGui from examples
# https://github.com/trustable-code/NiGui/tree/master/examples
# git clone https://github.com/simonkrauter/NiGui.git

# nim document generator
# nim doc --threads:on LetMeTranslate.nim
# Only top-level symbols that are marked with an asterisk (*) are exported:

# Azure supports these languages
# https://docs.microsoft.com/en-us/azure/cognitive-services/translator/language-support


# TODO
# 
# Azureキーが間違っていたらエラーポップアップを表示する。
# AzureTransratorのエラー(検索結果ナシ、SSL未対応でコンパイルされている等)もポップアップ表示する
# Translater()の処理に辞書とAzureのモード選択を実装する。
# 中国語にPinyin表示機能を追加
# 翻訳結果を見やすくして、品詞をローカライズする。
#
#AzureTranslatorに翻訳結果を辞書形式で保存する機能を付ける


# module list
import nigui
import nigui/msgbox
import std/[parsecfg, os,times]
import net
import strutils
import osproc

type  
  ButtonEnum = enum
    langNone,langFrom,langTo1, langTo2, langTo3, langTo4

# Indicates where to return the results of the language selection window.
var buttonStatus = langNone

# Sequences of languade code
var
  # language name suported dictionary search
  euroN : seq[string] = @["Danish","English","Finnish","Icelandic","Latvian","Lithuanian","Norwegian","Swedish","Welsh"]
  euroSW : seq[string] = @["Catalan","Dutch","French (Canada)","German","Greek","Maltese","Portuguese (Brazil)","Serbian (Latin)","Spanish"]
  euroE : seq[string] = @["Bosnian (Latin)","Bulgarian","Croatian","Czech","Hungarian","Polish","Romanian","Russian","Slovak","Ukrainian"]
  asiaW : seq[string] = @["Afrikaans","Arabic","Hebrew","Persian","Turkish"]
  asiaE : seq[string] = @["Bangla","Chinese Simplified","Hindi","Hmong Daw","Indonesian","Japanese","Korean","Malay","Swahili","Thai","Tamil","Urdu","Vietnamese"]
  americas : seq[string] = @["English","French (Canada)","Haitian Creole","Klingon","Portuguese (Brazil)"]
  
  # Azure language code
  euroNCode : seq[string] = @["da","en","fi","is","lv","lt","nb","sv","cy"]
  euroSWCode : seq[string] = @["ca","nl","fr","de","el","mt","pt","sr-Latn","es"]
  euroECode : seq[string] = @["bs","bg","hr","cs","hu","pl","ro","ru","sk","uk"]
  asiaWCode : seq[string] = @["af","ar","he","fa","tr"]
  asiaECode : seq[string] = @["bn","zh-Hans","hi","mww","id","ja","ko","ms","sw","th","ta","ur","vi"]
  americasCode : seq[string] = @["en","fr","ht","tlh-Latn","pt"]
  
# set currentDir
var appDir = getAppDir()
var currentDir = getCurrentDir()
if appDir != currentDir:
  setCurrentDir(appDir)


# declare logfile
var logDirName* = "logfiles"
var logFileName* = logDirName & DirSep & getDateStr(now()) & ".txt"
var logFile : File


var config = newConfig()
var configErr = ""
let configFilename = "config.ini"
try:
  config = loadConfig(configFilename)
except CatchableError:
  #"Can't open config.ini"
  configErr = "Error:" & getCurrentExceptionMsg()
var azureKey = config.getSectionValue("Azure","subscriptionKey")

# declare threads

var threadTranslater1*: Thread[tuple[mode,langFrom,langTo, inputWord: string]] 
  ## `threadTranslater1` is thread type for translator proc
  
var threadTranslater2*: Thread[tuple[mode,langFrom,langTo, inputWord: string]] 
  ## `threadTranslater2` is thread type for translator proc
  
var threadTranslater3*: Thread[tuple[mode,langFrom,langTo, inputWord: string]] 
  ## `threadTranslater3` is thread type for translator proc
  
var threadTranslater4*: Thread[tuple[mode,langFrom,langTo, inputWord: string]]
  ## `threadTranslater4` is thread type for translator proc
  
# declare channels

var channel1*: Channel[string] 
  ## This channel contains translated text for 1st language.
  
var channel2*: Channel[string] 
  ## This channel contains translated text for 2nd language.
  
var channel3*: Channel[string] 
  ## This channel contains translated text for 3rd language.
  
var channel4*: Channel[string] 
  ## This channel contains translated text for 4th language.
  
# declare procedures

proc getClipboard*()
  ## copy clipboard to input textarea.

proc translateClipboard*()
  ## translate from input textarea.
  
proc translateClipboard*(ev:ClickEvent)
  ## translate from input textarea. (for ClickEvent)


#AzureTranslaterに「翻訳元言語」「翻訳先言語」「翻訳対象ワード」を渡して実行結果を取得する
#追加：Azureの文章翻訳、辞書翻訳、ローカル辞書翻訳のモード変更を可能とする。 
proc translateCore*(mode: string, langFrom: string, langTo: string, inputWord: string): string
  ## Call AzureTranslater each os process.  

#翻訳処理を行うスレッド関数。翻訳結果は格納チャンネルに送る。
#引数の「翻訳元言語」「翻訳先言語」「翻訳対象ワード」はtranslate関数に渡される。
proc procTranslaterThread1*(args: tuple[mode,langFrom,langTo, inputWord: string]) {.thread.}
  ## thread proc for translate process
  
proc procTranslaterThread2*(args: tuple[mode,langFrom,langTo, inputWord: string]) {.thread.}
  ## thread proc for translate process
  
proc procTranslaterThread3*(args: tuple[mode,langFrom,langTo, inputWord: string]) {.thread.}
  ## thread proc for translate process
  
proc procTranslaterThread4*(args: tuple[mode,langFrom,langTo, inputWord: string]) {.thread.}
  ## thread proc for translate process


proc translate*()
  ## 入力項目の内容をチェックし、空白なら警告表示。\n
  ## 文章を単語に分割する。\n
  ## 翻訳処理を行うスレッド関数(procTranslaterThread1)を４つ作成。引数(inputTransFrom.text, inputTransTo1.text, word)を渡してそれぞれ並行実行する。\n
  ## 各翻訳スレッドの処理結果をチャンネルから取得、画面に表示する。


proc translateButton*(ev:ClickEvent)
  ## 翻訳ボタンのクリックイベントが発生したらtranslate()関数を実行する

proc selectLangButtonFrom*(ev:ClickEvent)
proc selectLangButtonTo1*(ev:ClickEvent)
proc selectLangButtonTo2*(ev:ClickEvent)
proc selectLangButtonTo3*(ev:ClickEvent)
proc selectLangButtonTo4*(ev:ClickEvent)

proc selectLegionEuroN*(ev:ClickEvent)
proc selectLegionEuroSW*(ev:ClickEvent)
proc selectLegionEuroE*(ev:ClickEvent)
proc selectLegionAsiaW*(ev:ClickEvent)
proc selectLegionAsiaE*(ev:ClickEvent)
proc selectLegionAmericas*(ev:ClickEvent)

proc quitWindowLang*(event: CloseClickEvent)

proc quitProcess*(event: CloseClickEvent)

#proc selectLegionEuroNButton(ev:ClickEvent)

#NiGui Coding

#init nigui
app.init()

#Definition of root window
var window=newWindow("Let Me Translate!")
window.width=670
window.height=900
window.x=100
window.y=50
#window.iconPath="image/iconfinder_business-work_8_2377639.png"

# Definition of window for setting Azure subscription key  
var windowSetAzureKey=newWindow("Please input Azure subscription key")
windowSetAzureKey.width=500
windowSetAzureKey.height=50
var containerSetAzureKey = newLayoutContainer(Layout_Horizontal)
var inputAzureKey = newTextBox(azureKey)
inputAzureKey.width = 300
var buttonAzureKeyOK = newButton("OK")
var buttonAzureKeyCancel = newButton("Cancel")
containerSetAzureKey.add(inputAzureKey)
containerSetAzureKey.add(buttonAzureKeyOK)
containerSetAzureKey.add(buttonAzureKeyCancel)
windowSetAzureKey.add(containerSetAzureKey)

#Child Windows
var windowLang=newWindow("Please select language")
windowLang.x=150
windowLang.y=200
windowLang.width=1020
windowLang.height=150



var langContainerEuroN = newLayoutContainer(Layout_Vertical)
langContainerEuroN.width=160
langContainerEuroN.frame = newFrame("North Europe")
var comboboxEuroN=newComboBox(euroN)
var buttonLegionEuroN = newButton("confirm")
langContainerEuroN.add(comboboxEuroN)
langContainerEuroN.add(buttonLegionEuroN)

var langContainerEuroSW = newLayoutContainer(Layout_Vertical)
langContainerEuroSW.width=160
langContainerEuroSW.frame = newFrame("South/Western Europe")
var comboboxEuroSW=newComboBox(euroSW)
var buttonLegionEuroSW = newButton("confirm")
langContainerEuroSW.add(comboboxEuroSW)
langContainerEuroSW.add(buttonLegionEuroSW)

var langContainerEuroE = newLayoutContainer(Layout_Vertical)
langContainerEuroE.width=160
langContainerEuroE.frame = newFrame("Aflica/East Europe")
var comboboxEuroE=newComboBox(euroE)
var buttonLegionEuroE = newButton("confirm")
langContainerEuroE.add(comboboxEuroE)
langContainerEuroE.add(buttonLegionEuroE)

var langContainerAsiaW = newLayoutContainer(Layout_Vertical)
langContainerAsiaW.width=160
langContainerAsiaW.frame = newFrame("Western Asia")
var comboboxAsiaW=newComboBox(asiaW)
var buttonLegionAsiaW = newButton("confirm")
langContainerAsiaW.add(comboboxAsiaW)
langContainerAsiaW.add(buttonLegionAsiaW)

var langContainerAsiaE = newLayoutContainer(Layout_Vertical)
langContainerAsiaE.width=160
langContainerAsiaE.frame= newFrame("East Asia")
var comboboxAsiaE=newComboBox(asiaE)
var buttonLegionAsiaE = newButton("confirm")
langContainerAsiaE.add(comboboxAsiaE)
langContainerAsiaE.add(buttonLegionAsiaE)

var langContainerAmericas = newLayoutContainer(Layout_Vertical)
langContainerAmericas.width=160
langContainerAmericas.frame= newFrame("Americas")
var comboboxAmericas=newComboBox(americas)
var buttonLegionAmericas = newButton("confirm")
langContainerAmericas.add(comboboxAmericas)
langContainerAmericas.add(buttonLegionAmericas)

#langContainer1.frame = newFrame("Row 1: Auto-sized")
var langContainerHorizontal = newLayoutContainer(Layout_Horizontal)
langContainerHorizontal.add(langContainerEuroN)
langContainerHorizontal.add(langContainerEuroSW)
langContainerHorizontal.add(langContainerEuroE)
langContainerHorizontal.add(langContainerAsiaW)
langContainerHorizontal.add(langContainerAsiaE)
langContainerHorizontal.add(langContainerAmericas)
windowLang.add(langContainerHorizontal)

#言語一覧を表示するボタン
#en,ja,ko,zh-Hans,id,ms,pl,pt
#var setFromLang = newButton("From")

# start of container of input text

#Azureキー
#var labelAzureKey=newLabel("Azure Subscription Key")
#labelAzureKey.fontSize=14
#labelAzureKey.width=150
#var textboxAzureKey=newTextBox(azureKey)
#textboxAzureKey.width=300
#textboxAzureKey.visible = false

# Button for setting Azure key
var buttonSetAzureKey=newButton("Set Azure subscription key")

#翻訳元言語指定のテキストボックス
var labelTransFrom=newLabel("Translate from")
labelTransFrom.fontSize=14
labelTransFrom.width=100
var inputTransFrom = newTextBox(config.getSectionValue("LetMeTranslate","from"))
inputTransFrom.width=150

# Add a ComboBox fror Language
var buttonSelectLangFrom=newButton("Select Language")

#TextArea - input text
var textArea1 = newTextArea()
textArea1.widthMode = WidthMode_Expand
#textArea1.heightMode = HeightMode_Expand
#textArea1.width=600
textArea1.height=150
textArea1.fontSize=16

#入力中にエンターキーを押すと翻訳できるようにする
#textArea1.onKeyDown = proc(event: KeyboardEvent) =
#  if $event.key == "Key_Return":
#    translate()
  


#翻訳実行ボタン
#var buttonTranslate=newButton("Translate InputText")
#buttonTranslate.fontSize=16
#buttonTranslate.width=165

# 翻訳実行ボタンのカスタマイズ対応版
# Definition of a custom button
type CustomButton* = ref object of Button
#Custom widgets need to draw themselves
method handleDrawEvent(control: CustomButton, event: DrawEvent) =
  let canvas = event.control.canvas
  canvas.areaColor = rgb(105, 105, 105)
  canvas.textColor = rgb(255, 223, 0)
  canvas.lineColor = rgb(173, 255, 47)
  canvas.drawRectArea(0, 0, control.width, control.height)
  canvas.drawTextCentered(control.text)
  canvas.drawRectOutline(0, 0, control.width, control.height)

# Override nigui.newButton (optional)
proc newCustomButton1*(text = ""): Button =
  result = new CustomButton
  result.init()
  result.text = text
  
var buttonTranslate=newCustomButton1("Translate")
buttonTranslate.fontSize=16
buttonTranslate.width=165

#ボタン間隔調整用の空ラベル
var labelSpace=newLabel("")
labelSpace.width=250

#クリップボードの内容を翻訳対象として読み込むボタン
var buttonLoadClipboard=newButton("Translate Clipboard")
buttonLoadClipboard.fontSize=14
buttonLoadClipboard.width=165

# end of container of input text

# start of container of translate result

#翻訳先言語指定1のテキストボックス
var labelTransTo1=newLabel("Translate to")
labelTransTo1.fontSize=14
labelTransTo1.width=90
var inputTransTo1 = newTextBox(config.getSectionValue("LetMeTranslate","to1"))
inputTransTo1.width=150

var buttonSelectLangTo1=newButton("Select Language")


#翻訳先言語指定2のテキストボックス
var labelTransTo2=newLabel("Translate to")
labelTransTo2.fontSize=14
labelTransTo2.width=90
var inputTransTo2 = newTextBox(config.getSectionValue("LetMeTranslate","to2"))
inputTransTo2.width=150

var buttonSelectLangTo2=newButton("Select Language")

#翻訳先言語指定3のテキストボックス
var labelTransTo3=newLabel("Translate to")
labelTransTo3.fontSize=14
labelTransTo3.width=90
var inputTransTo3 = newTextBox(config.getSectionValue("LetMeTranslate","to3"))
inputTransTo3.width=150

var buttonSelectLangTo3=newButton("Select Language")

#翻訳先言語指定4のテキストボックス
var labelTransTo4=newLabel("Translate to")
labelTransTo4.fontSize=14
labelTransTo4.width=90
var inputTransTo4 = newTextBox(config.getSectionValue("LetMeTranslate","to4"))
inputTransTo4.width=150

var buttonSelectLangTo4=newButton("Select Language")

#TextArea - output text 1
var textAreaOutput1 = newTextArea()
textAreaOutput1.widthMode = WidthMode_Expand
textAreaOutput1.heightMode = HeightMode_Expand
#textAreaOutput1.width=600
#textAreaOutput1.height=100
textAreaOutput1.fontSize=16

#TextArea - output text 2
var textAreaOutput2 = newTextArea()
textAreaOutput2.widthMode = WidthMode_Expand
textAreaOutput2.heightMode = HeightMode_Expand
#textAreaOutput2.width=600
#textAreaOutput2.height=100
textAreaOutput2.fontSize=16

#TextArea - output text 3
var textAreaOutput3 = newTextArea()
textAreaOutput3.widthMode = WidthMode_Expand
textAreaOutput3.heightMode = HeightMode_Expand
#textAreaOutput3.width=600
#textAreaOutput3.height=100
textAreaOutput3.fontSize=16

#TextArea - output text 4
var textAreaOutput4 = newTextArea()
textAreaOutput4.widthMode = WidthMode_Expand
textAreaOutput4.heightMode = HeightMode_Expand
#textAreaOutput4.width=600
#textAreaOutput4.height=100
textAreaOutput4.fontSize=16

# end of container of translate result

#横配列コンテナ(Azureキー)
var conTransAzure = newLayoutContainer(Layout_Horizontal)
#conTransAzure.add(labelAzureKey)
#conTransAzure.add(textboxAzureKey)
conTransAzure.add(buttonSetAzureKey)

#横配列コンテナ(翻訳元言語コード)
var conTransFromLangCode = newLayoutContainer(Layout_Horizontal)
conTransFromLangCode.add(labelTransFrom)
conTransFromLangCode.add(inputTransFrom)
#langage button
conTransFromLangCode.add(buttonSelectLangFrom)

#横配列コンテナ(翻訳ボタン)
var conTransButtons = newLayoutContainer(Layout_Horizontal)
conTransButtons.widthMode = WidthMode_Expand
conTransButtons.xAlign = XAlign_Spread
conTransButtons.add(buttonLoadClipboard)
conTransButtons.add(labelSpace)
conTransButtons.add(buttonTranslate)

#縦コンテナ(翻訳元情報)
var conTransFrom = newLayoutContainer(Layout_Vertical)
conTransFrom.frame = newFrame("Input Text")
conTransFrom.add(conTransAzure)
conTransFrom.add(conTransFromLangCode)
conTransFrom.add(textArea1)
conTransFrom.add(conTransButtons)



#縦コンテナ(翻訳結果)
var conTranslateResult = newLayoutContainer(Layout_Vertical)
conTranslateResult.frame = newFrame("Translate Result")

#output text 1
var container1 = newLayoutContainer(Layout_Horizontal)
container1.add(labelTransTo1)
container1.add(inputTransTo1)
container1.add(buttonSelectLangTo1)

conTranslateResult.add(container1)
conTranslateResult.add(textAreaOutput1)

#output text 2
var container2 = newLayoutContainer(Layout_Horizontal)
container2.add(labelTransTo2)
container2.add(inputTransTo2)
container2.add(buttonSelectLangTo2)

conTranslateResult.add(container2)
conTranslateResult.add(textAreaOutput2)

#output text 3
var container3 = newLayoutContainer(Layout_Horizontal)
container3.add(labelTransTo3)
container3.add(inputTransTo3)
container3.add(buttonSelectLangTo3)

conTranslateResult.add(container3)
conTranslateResult.add(textAreaOutput3)

#output text 4
var container4 = newLayoutContainer(Layout_Horizontal)
container4.add(labelTransTo4)
container4.add(inputTransTo4)
container4.add(buttonSelectLangTo4)

conTranslateResult.add(container4)
conTranslateResult.add(textAreaOutput4)

#Definition of Main Layout Container
var container=newLayoutContainer(Layout_Vertical)
container.add(conTransFrom)
container.add(conTranslateResult)
#container.setPosition(10,10)
window.add(container)

#Container focus setting
focus(textArea1)

#画面部品定義　終了




# define procedures

# Clipboard Getter
proc getClipboard() =
  var clipboardText = ""

  case hostOS
  of "windows":
    let (outp, errC) = execCmdEx("getClipboard.exe", options = {poDaemon})
    clipboardText = $outp
    if(errC == 1):
      return
  #of "linux":
    #clipboardText = app.clipboardText()
  else:
    clipboardText = app.clipboardText()
        
  textArea1.text = clipboardText

# translate form Clipboard
proc translateClipboard() =
  getClipboard()
  translate()


#Definition of Event when button click
proc translateClipboard(ev:ClickEvent)=
  # copy clipboard to input textarea. (for ClickEvent)
  
  translateClipboard()
  



#AzureTranslaterや辞書引き等の翻訳処理を実行する関数

#百度のアカウントが取れたら翻訳APIが使える。パラメータ名称等が参考になる。
#https://fanyi-api.baidu.com/product/113

#Azure speech services(大変そう)
#https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/
#https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/spx-basics?tabs=linuxinstall

proc translateCore(mode: string, langFrom: string, langTo: string, inputWord: string): string =
  ## Call AzureTranslater each os process.

  var azureCommand: string
  var translatedText = ""

  #echo "inputWord:" & inputWord
  #let sanitizedWord = inputWord.replace("\"", "\\\"").replace("`", "\\`")
  let sanitizedWord = "\"" & inputWord.replace("\"", "\\\"") & "\""
  #echo "sanitizedWord:" & sanitizedWord

  let args = @["--from=" & langFrom, "--to=" & langTo, sanitizedWord]

  try:
    case hostOS
    of "windows":
      azureCommand = "AzureTranslator.exe " & args.join(" ")
      let (outp, errC) = execCmdEx(azureCommand, options = {poDaemon})
      if errC != 0:
        return "[Error: AzureTranslator failed with code " & $errC & "]"
      translatedText = $outp
    of "linux":
      azureCommand = "./AzureTranslator " & args.join(" ")
      let (outp, errC) = execCmdEx(azureCommand)
      if errC != 0:
        return "[Error: AzureTranslator failed with code " & $errC & "]"
      translatedText = $outp
    else:
      azureCommand = "./AzureTranslator " & args.join(" ")
      let (outp, errC) = execCmdEx(azureCommand)
      if errC != 0:
        return "[Error: AzureTranslator failed with code " & $errC & "]"
      translatedText = $outp
  except CatchableError:
    return "[Error: " & getCurrentExceptionMsg() & "]"

  result = translatedText


proc procTranslaterThread1(args: tuple[mode,langFrom,langTo, inputWord: string]) {.thread.} =
  channel1.send(translateCore(args.mode,args.langFrom,args.langTo,args.inputWord))
proc procTranslaterThread2(args: tuple[mode,langFrom,langTo, inputWord: string]) {.thread.} =
  channel2.send(translateCore(args.mode,args.langFrom,args.langTo,args.inputWord))
proc procTranslaterThread3(args: tuple[mode,langFrom,langTo, inputWord: string]) {.thread.} =
  channel3.send(translateCore(args.mode,args.langFrom,args.langTo,args.inputWord))  
proc procTranslaterThread4(args: tuple[mode,langFrom,langTo, inputWord: string]) {.thread.} =
  channel4.send(translateCore(args.mode,args.langFrom,args.langTo,args.inputWord))


  
#翻訳処理
proc translate() =
#同様の処理をエンターキーイベントにも実装する
 
  if inputTransTo1.text == "" and inputTransTo2.text == "" and inputTransTo3.text == "" and inputTransTo4.text == "":
    #window.alert("言語指定(Translate to)が全て空白です。最低でも一つは入力して下さい。")
    window.alert("All language selections (Translate to) are blank. Please enter at least one.")
  else:  
    var inputString = $textArea1.text
    var
      output1: string
      output2: string
      output3: string
      output4: string
    #echo "inputString[", inputString,"]"
    
    # update config.ini
    config.setSectionKey("Azure", "subscriptionKey", azureKey)
    config.setSectionKey("LetMeTranslate", "from", inputTransFrom.text)
    config.setSectionKey("LetMeTranslate", "to1", inputTransTo1.text)
    config.setSectionKey("LetMeTranslate", "to2", inputTransTo2.text)
    config.setSectionKey("LetMeTranslate", "to3", inputTransTo3.text)
    config.setSectionKey("LetMeTranslate", "to4", inputTransTo4.text)
    config.writeConfig(configFilename)
    
    #文字列をスペースで区切って単語に分割する
    for word in inputString.splitWhitespace(maxsplit = -1):
      #echo "split result:",word  
      #translateモジュールの結果が改行付きで返って来るのでaddLineではなくaddTextを使う
      
      #各翻訳スレッドを開始
      if inputTransTo1.text != "":
        createThread(threadTranslater1, procTranslaterThread1, ("mode_azure",inputTransFrom.text, inputTransTo1.text, word))        
      if inputTransTo2.text != "":
        createThread(threadTranslater2, procTranslaterThread2, ("mode_azure",inputTransFrom.text, inputTransTo2.text, word))
      if inputTransTo3.text != "":
        createThread(threadTranslater3, procTranslaterThread3, ("mode_azure",inputTransFrom.text, inputTransTo3.text, word))
      if inputTransTo4.text != "":
        createThread(threadTranslater4, procTranslaterThread4, ("mode_azure",inputTransFrom.text, inputTransTo4.text, word))
        
      #各翻訳スレッドの処理結果を取得
      if inputTransTo1.text != "":
        joinThread(threadTranslater1)
        output1 = channel1.recv()
        textAreaOutput1.addText(output1)
        textAreaOutput1.scrollToBottom()
        #logFile.writeLine(inputTransFrom.text & ">" & inputTransTo1.text & ": " & output1)
      if inputTransTo2.text != "":
        joinThread(threadTranslater2)        
        output2 = channel2.recv()
        textAreaOutput2.addText(output2)
        textAreaOutput2.scrollToBottom()
        #logFile.writeLine(inputTransFrom.text & ">" & inputTransTo2.text & ": " & output2)
      if inputTransTo3.text != "":
        joinThread(threadTranslater3)        
        output3 = channel3.recv()
        textAreaOutput3.addText(output3)
        textAreaOutput3.scrollToBottom()
        #logFile.writeLine(inputTransFrom.text & ">" & inputTransTo3.text & ": " & output3)
      if inputTransTo4.text != "":
        joinThread(threadTranslater4)        
        output4 = channel4.recv()
        textAreaOutput4.addText(output4)
        textAreaOutput4.scrollToBottom()
        #logFile.writeLine(inputTransFrom.text & ">" & inputTransTo4.text & ": " & output4)
    
    #clear inputText
    textArea1.text=""


#Definition of Translate Button
proc openWindowAzureKey(ev:ClickEvent) =
  windowSetAzureKey.show()

proc setAzureKeyOK(ev:ClickEvent) =
  azureKey = inputAzureKey.text
  config.setSectionKey("Azure", "subscriptionKey", azureKey)
  config.writeConfig(configFilename)
  windowSetAzureKey.hide()
  
proc setAzureKeyCancel(ev:ClickEvent) =
  windowSetAzureKey.hide()

proc translateButton(ev:ClickEvent) =
  translate()
  
proc selectLangButtonFrom(ev:ClickEvent) =
  windowLang.show()
  buttonStatus = langFrom
  
proc selectLangButtonTo1(ev:ClickEvent) =
  windowLang.show()
  buttonStatus = langTo1
  
proc selectLangButtonTo2(ev:ClickEvent) =
  windowLang.show()
  buttonStatus = langTo2
  
proc selectLangButtonTo3(ev:ClickEvent) =
  windowLang.show()
  buttonStatus = langTo3
  
proc selectLangButtonTo4(ev:ClickEvent) =
  windowLang.show()
  buttonStatus = langTo4

proc cleanup() =
  #if not logFile.isNil:
  #  logFile.close()
  channel1.close()
  channel2.close()
  channel3.close()
  channel4.close()
  
proc quitWindowLang(event: CloseClickEvent) =
  windowLang.hide()


proc quitProcess(event: CloseClickEvent) =
  case window.msgBox("Do you want to quit?", "Quit?","Quit","Cancel")
  of 1:
    if windowLang != nil:
      windowLang.dispose()
    window.dispose()
    cleanup()
    quit()
  of 2:
    discard
  else:
    discard
    
  
proc selectLangFromRegion*(code: string, ev: ClickEvent) =
  case buttonStatus
  of langFrom:
    inputTransFrom.text = code
  of langTo1:
    inputTransTo1.text = code
  of langTo2:
    inputTransTo2.text = code
  of langTo3:
    inputTransTo3.text = code
  of langTo4:
    inputTransTo4.text = code
  else:
    discard
  buttonStatus = langNone
  windowLang.hide()

proc selectLegionEuroN*(ev: ClickEvent) =
  selectLangFromRegion(euroNCode[comboboxEuroN.index], ev)

proc selectLegionEuroSW*(ev: ClickEvent) =
  selectLangFromRegion(euroSWCode[comboboxEuroSW.index], ev)

proc selectLegionEuroE*(ev: ClickEvent) =
  selectLangFromRegion(euroECode[comboboxEuroE.index], ev)

proc selectLegionAsiaW*(ev: ClickEvent) =
  selectLangFromRegion(asiaWCode[comboboxAsiaW.index], ev)

proc selectLegionAsiaE*(ev: ClickEvent) =
  selectLangFromRegion(asiaECode[comboboxAsiaE.index], ev)

proc selectLegionAmericas*(ev: ClickEvent) =
  selectLangFromRegion(americasCode[comboboxAmericas.index], ev)


#Button Click Event
buttonSetAzureKey.onClick=openWindowAzureKey
buttonAzureKeyOK.onClick=setAzureKeyOK
buttonAzureKeyCancel.onClick=setAzureKeyCancel

buttonSelectLangFrom.onClick=selectLangButtonFrom
buttonSelectLangTo1.onClick=selectLangButtonTo1
buttonSelectLangTo2.onClick=selectLangButtonTo2
buttonSelectLangTo3.onClick=selectLangButtonTo3
buttonSelectLangTo4.onClick=selectLangButtonTo4

buttonLegionEuroN.onClick=selectLegionEuroN
buttonLegionEuroSW.onClick=selectLegionEuroSW
buttonLegionEuroE.onClick=selectLegionEuroE
buttonLegionAsiaW.onClick=selectLegionAsiaW
buttonLegionAsiaE.onClick=selectLegionAsiaE
buttonLegionAmericas.onClick=selectLegionAmericas

buttonLoadClipboard.onClick=translateClipboard
buttonTranslate.onClick=translateButton

windowLang.onCloseClick=quitWindowLang
window.onCloseClick=quitProcess 


# main process



# log output process
createDir(logDirName)
if fileExists(logFileName):
  logFile = open(logFileName,fmAppend)
else:
  logFile = open(logFileName,fmWrite)



#NIguiにApp.clipboardText:Stringがある。
#textArea1.text = app.clipboardText()
getClipboard()

#these channels catch result of translation thread
channel1.open()
channel2.open()
channel3.open()
channel4.open()

# initialize GUI
window.show()

if configErr!="":
  window.alert(configErr)
  cleanup()
else:
  try:
    app.run()
  finally:
    cleanup()

# end of process

