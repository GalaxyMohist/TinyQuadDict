#[
--- Command to compile ---
nim compile -d:ssl AzureTranslator.nim
nim compile --app:console -d:ssl -d:release AzureTranslator.nim

Windows requires casert.pim for ssl
https://nim-lang.org/docs/net.html#ssl-on-windows

Browse Azure products
https://learn.microsoft.com/en-us/azure/?product=ai-machine-learning

Azure AI Translator documentation
https://learn.microsoft.com/en-us/azure/ai-services/translator/
]#

import httpclient, json
import std/parsecfg
import std/strutils
import parseopt
import times
import std/os

# Loading config.ini
let configFilename = "config.ini"
let launguageListName = "languageList.txt"
var config: Config
var subscriptionKey = ""
var paramFrom = "en"
var paramTo = "ja"
var commandError = false

if configFilename.fileExists:
  config = loadConfig(configFilename)
  subscriptionKey = config.getSectionValue("Azure","subscriptionKey")
  paramFrom = config.getSectionValue("Azure","from")
  paramTo = config.getSectionValue("Azure","to")
  if subscriptionKey == "":
    echo "Your Azure subscription key has not been registered."
    echo "Open config.ini and enter your Azure subscription key in the subscriptionKey field."
    quit(0)



# Setup to create a URL to send to Azure
var baseUrl = "https://api.cognitive.microsofttranslator.com"
var modeDictFlag = 1
let modeDictUrl = "/dictionary/lookup?api-version=3.0"
let modeTranUrl = "/translate?api-version=3.0"
var constructedUrl = ""


### Declaration of procedures ###

# 渡された単語(not 文字列)の翻訳結果を返す。Azureの辞書にない単語だと空白が帰ってくる
# Azure communication to translate
proc translate(word: string): string =
  # Create JSON for request to Azure
  let body = %*
    [
      {"Text":word}
    ]
  #echo "body=" & $body

  # Initialization HttpClient
  let client = newHttpClient()
  client.headers = newHttpHeaders(
    { "Ocp-Apim-Subscription-Key": subscriptionKey,
      "Ocp-Apim-Subscription-Region:grobal",
      "Content-type": "application/json",
    }
  )

  let response = client.request(constructedUrl, httpMethod = HttpPost, body = $body)
  #[
  Response = ref object
    version*: string
    status*: string
    headers*: HttpHeaders
    bodyStream*: Stream
  ]#
  #echo response.status

  #Azureからの返答をログファイルに出力
  # Logging Azure responce
  #生ログには信頼度や逆翻訳等の情報が含まれている
  #[
  var outfile = open("azure_responce.log",fmWrite)
  outfile.writeLine("[body]")
  outfile.writeLine($body)
  outfile.writeLine("[response.status]")
  outfile.writeLine(response.status)
  outfile.writeLine("[response.body]")
  outfile.writeLine(response.body)
  outfile.close
  ]#

  # Azure error check
  if response.status != "200 OK":
    result = "Azure response error=[" & response.status & "]" & response.body
    return

  #Create JSON Node for response from Azure
  let jsonNode = parseJson(response.body)

#[
dictionary mode response(example)
[{
"normalizedSource":"throat",
"displaySource":"throat",
"translations":[
  {"normalizedTarget":"喉",
   "displayTarget":"喉",
   "posTag":"NOUN",
   "confidence":0.5014,
   "prefixWord":"",
   "backTranslations":[
      {"normalizedText":"throat",
       "displayText":"throat",
       "numExamples":15,
       "frequencyCount":2237},
      {"normalizedText":"sore throat",
       "displayText":"sore throat",
       "numExamples":5,"frequencyCount":210}
  ]},
  {"normalizedTarget":"咽喉",
   "displayTarget":"咽喉",
   "posTag":"NOUN",
   "confidence":0.2236,
   "prefixWord":"",
   "backTranslations":[
      {"normalizedText":"throat",
       "displayText":"throat",
       "numExamples":4,
       "frequencyCount":190},
      {"normalizedText":"sore throat",
       "displayText":"sore throat",
       "numExamples":0,"frequencyCount":10}
  ]},
  {"normalizedTarget":"のど",
   "displayTarget":"のど",
   "posTag":"NOUN",
   "confidence":0.1994,
   "prefixWord":"",
   "backTranslations":[
      {"normalizedText":"any",
       "displayText":"any",
       "numExamples":15,"frequencyCount":2385},
      {"normalizedText":"throat",
       "displayText":"throat",
       "numExamples":15,
       "frequencyCount":660}
  ]},
  {"normalizedTarget":"咽頭",
   "displayTarget":"咽頭",
   "posTag":"NOUN",
   "confidence":0.0756,
   "prefixWord":"",
   "backTranslations":[
      {"normalizedText":"pharynx",
       "displayText":"pharynx",
       "numExamples":2,"frequencyCount":116},
      {"normalizedText":"pharyngeal",
       "displayText":"pharyngeal",
       "numExamples":3,"frequencyCount":91},
      {"normalizedText":"throat",
       "displayText":"throat",
       "numExamples":0,
       "frequencyCount":36},
      {"normalizedText":"gag",
       "displayText":"gag",
       "numExamples":0,
       "frequencyCount":16},
      {"normalizedText":"sore throats",
       "displayText":"sore throats",
       "numExamples":0,
       "frequencyCount":10},
      {"normalizedText":"oropharynx",
       "displayText":"oropharynx",
       "numExamples":0,
       "frequencyCount":5}
    ]}
]
}]
]#

  if modeDictFlag==1:
    # A word can have multiple meanings and parts of speech.
    # translatedList stores meaning(translation Result)
    # postagList stores POS(Part of speech)tag corresponding to meaning(translation result)
    var translatedList: seq[string]
    var postagList: seq[string]

    var count = 0

    #splitLinesによって分割された行ごとに処理を実行する。
    #https://nim-lang.org/docs/strutils.html#splitLines.i,string

    #nimにおいてfor文はiteratorsの一種として実装されている
    #https://nim-lang.org/docs/manual.html#iterators-and-the-for-statement
    for line in splitLines(pretty(jsonNode)):
      var keyValue = line.split(": ")

      if keyValue[0].contains("\"displayTarget\""):
        keyValue[1].removePrefix("\"")
        keyValue[1].removeSuffix("\",")
        #echo keyValue[1],"(contains displayTarget)"
        translatedList.add(keyValue[1])
      elif keyValue[0].contains("\"posTag\""):
        keyValue[1].removePrefix("\"")
        keyValue[1].removeSuffix("\",")
        #echo keyValue[1],"(contains posTag)"

        #今は品詞が英語になっているので日本語にする処理を入れる
        #名詞
        #Noun
        #代名詞
        #Pronoun
        #動詞result = $postagList
        #Verb
        #形容詞
        #Adjective(adj)
        #副詞
        #Adverb(adv)
        #前置詞
        #Preposition
        #接続詞
        #Conjunction
        #間投詞
        #Interjection


        #posTag配列へ追加
        postagList.add("(" & keyValue[1] & ")" & translatedList[count])
        count = count + 1

    #result = "translatedList=" & $translatedList & "postagList=" & $postagList



    #seqのlengthが0だったら検索結果ゼロのメッセージに置き換える。
    #辞書モードで駄目なら翻訳モードでリトライする処理を実装予定
    if postagList.len == 0:
      result = "No data found"
    else:
      #seqを文字化した際の@[と]を削る
      var resultText = $postagList
      resultText = resultText.replace("\"","")
      result = resultText.substr(2,high(resultText)-1)

  # not Dictionary mode
  elif modeDictFlag==0:

    # raw response(dictionary mode)
    # """{"normalizedSource":"throat","displaySource":"throat","translations":[{"normalizedTarget":"喉","displayTarget":"喉","posTag":"NOUN","confidence":0.5014,"prefixWord":"","backTranslations":[{"normalizedText":"throat","displayText":"throat","numExamples":15,"frequencyCount":2237},{"normalizedText":"sore throat","displayText":"sore throat","numExamples":5,"frequencyCount":210}]},{"normalizedTarget":"咽喉","displayTarget":"咽喉","posTag":"NOUN","confidence":0.2236,"prefixWord":"","backTranslations":[{"normalizedText":"throat","displayText":"throat","numExamples":4,"frequencyCount":190},{"normalizedText":"sore throat","displayText":"sore throat","numExamples":0,"frequencyCount":10}]},{"normalizedTarget":"のど","displayTarget":"のど","posTag":"NOUN","confidence":0.1994,"prefixWord":"","backTranslations":[{"normalizedText":"any","displayText":"any","numExamples":15,"frequencyCount":2385},{"normalizedText":"throat","displayText":"throat","numExamples":15,"frequencyCount":660}]},{"normalizedTarget":"咽頭","displayTarget":"咽頭","posTag":"NOUN","confidence":0.0756,"prefixWord":"","backTranslations":[{"normalizedText":"pharynx","displayText":"pharynx","numExamples":2,"frequencyCount":116},{"normalizedText":"pharyngeal","displayText":"pharyngeal","numExamples":3,"frequencyCount":91},{"normalizedText":"throat","displayText":"throat","numExamples":0,"frequencyCount":36},{"normalizedText":"gag","displayText":"gag","numExamples":0,"frequencyCount":16},{"normalizedText":"sore throats","displayText":"sore throats","numExamples":0,"frequencyCount":10},{"normalizedText":"oropharynx","displayText":"oropharynx","numExamples":0,"frequencyCount":5}]}]}]"""
    # raw response(translate mode)
    # """[{"translations":[{"text":"Komunikasi radio","to":"id"}]}]

    for items in jsonNode:
      #echo "items=" & $items
      # """items={"translations":[{"text":"羡慕","to":"zh-Hans"}]}

      var translationsNode = items["translations"]
      #echo "translationsNode=" & $translationsNode
      # """translations=[{"text":"羡慕","to":"zh-Hans"}]

      for pairs in translationsNode:
        #echo "pairs" & $pairs["text"]
        #echo "pairs" & $pairs["to"]
        result = $pairs["text"]

### メイン処理
### Main procedure

#./AzureTranslator_translate --from=en --to=ja --key=27490b835c6a487886691f1c297fb820 throat slit apparently corner
#./AzureTranslator_translate --from=ja --to=zh-Hans --key=27490b835c6a487886691f1c297fb820 羨ましい
#var opt1="--from=ja --to=en --key=27490b835c6a487886691f1c297fb820 I can't wait this"

### 設定ファイル
var targetText = ""
#subscriptionKey
#paramFrom
#paramTo

# Analyze input command. 
# Display an error and sample commands if no arguments are provided.
# If there is only one argument, it is regarded as the search string, and which language to be translated into any language is supplemented from 'config.ini'.

#let appDir = getAppDir()
#echo "getAppDir(): " & appDir
#setCurrentDir(appDir)
#echo "setCurrentDir(" & appDir & ")"

var parser = initOptParser()
var seqArgs = parser.remainingArgs
var argsLength=seqArgs.len

while true:
  parser.next()
  case parser.kind
  of cmdEnd:
    break
  of cmdShortOption, cmdLongOption:
    if parser.key == "list":
      if launguageListName.fileExists:
        let fileLanguage = open(launguageListName)
        echo readAll(fileLanguage)
      else:
        echo launguageListName & " not found. Try download this program again."
      quit(0)
    elif parser.key == "key":
      subscriptionKey = parser.val
      #echo "subscriptionKey = ", parser.val
    elif parser.key == "from":
      paramFrom = parser.val
      #echo "paramFrom = ", parser.val
    elif parser.key == "to":
      paramTo = parser.val
      #echo "paramTo = ", parser.val
    elif parser.key == "":
      discard
    else:
      discard
  of cmdArgument:
    #echo "Argument: ", parser.key
    targetText = targetText & parser.key & " "
    
#parseopt
#let launguageListName = "launguageList.txt"
#if launguageListName.FileExists:
#echo readAll("launguageList.txt")

targetText.removeSuffix(' ')
targetText = targetText.strip
#echo "input text=" & targetText


# Construction of params for Azure
if targetText == "":
  commandError = true
  echo "Input word is empty."
elif argsLength > 0 :
  var params = "&from=" & paramFrom & "&to=" & paramTo

  # "Dictionary mode" support English only.
  # Other Language use "Translation mode" insteat of "Dictionary mode".
  if paramFrom == "en" :
    constructedUrl = baseUrl & modeDictUrl & params
  elif paramTo == "en":
    constructedUrl = baseUrl & modeDictUrl & params
  else:
    modeDictFlag = 0
    constructedUrl = baseUrl & modeTranUrl & params

  #echo constructedUrl



  # output logs
  let logDirName = "logfiles"
  createDir(logDirName)
  #var logFileName = logDirName & DirSep & getDateStr(now()) & ".txt"
  let logFileName = logDirName & DirSep & paramFrom & "_" & paramTo & ".txt"
  var logFile : File
  var fileLimitCount : File
  let fileLimitCountName = logDirName & DirSep & "azure_LimitOfTlanslation.txt"

  #1分あたり約33,300文字を超えないようにする
  #無料プランでは1時間あたり200万文字の制限がある。
  #60分の間、1分に33300文字を翻訳し続けても1998000文字なので200万文字にはならない。
  #前回の実行時から1分以内に33300文字を翻訳した時にエラーを出す。
  var timeLastExecute = ""
  var limitCount = 0
  var needResetCountTime = false
  var fileLimitCountExists = fileLimitCountName.fileExists
  
  if fileLimitCountExists:
    #ar outfile = open("azure_responce.log",fmWrite)
    fileLimitCount = open(fileLimitCountName,fmRead)
    timeLastExecute = fileLimitCount.readLine()
    limitCount = parseInt(fileLimitCount.readLine())
    #echo timeLastExecute
  
    #len(targetText)
    fileLimitCount.close()
    
    #let dt = dateTime(2000, mJan, 01, 00, 00, 00, 00, utc())
    #doAssert dt == parse("2000-01-01", "yyyy-MM-dd", utc())
    
    #let timeLast = parse("2026-04-24 08:52:37","yyyy-MM-dd HH:mm:ss")
    let timeLast = parse(timeLastExecute,"yyyy-MM-dd HH:mm:ss")
    #echo "[timeLast]" & timeLast.format("yyyy-MM-dd HH:mm:ss")
    let timeNow = now()
    #echo "[timeNow]" & timeNow.format("yyyy-MM-dd HH:mm:ss")
    #let time1HourAgo = timeNow - 1.hours
    let time1minAgo = timeNow -  1.minutes
    
    if timeLast < time1minAgo:
      #echo "Over 1min. LimitCount will reset."
      needResetCountTime = true
    else:
      discard
      #echo "Current LimitCount:" & $limitCount
    
  #let between = between(timeLast,timeNow)
  #echo $between
  #if between > initTimeInterval(hours = 1):
  #  echo "over 1 hour.Count is reseted."
  #else:
  #  echo "counting"
  #echo $between.inMinutes
  #echo $between.minutes
  
  
  
  #echo time_now.format
  #2026-04-24T08:52:37+09:00

  # Check if the translation results are saved
  var resultExist = false
  var resultText = ""
  if fileExists(logFileName):
    #logFile = open(logFileName,fmRead)
    for line in logFileName.lines:
      if line.startsWith(targetText):
        #echo "[ResultLog: Match] " & line
        resultExist = true
        resultText = line
        break
      #else:
        #echo "[ResultLog: No Match] " & line
    logFile.close()

  # If the translation results aren't saved, run the API
  if resultExist == false:
    # Get result of traslate procedure
    #var tranlateResult = targetText.strip & "=" & translate(targetText)
    if limitCount + len(targetText) > 33300:
      #echo "一分内に33300文字以上を翻訳することは出来ません。一分毎にカウントはリセットされるのでお待ち下さい。"
      echo "With the Azure Free Tier, you cannot translate more than 33,300 characters within a minute. The count resets every minute, so please wait."
      quit()
    
    let tranlateResult = targetText & "=" & translate(targetText)
    resultText = tranlateResult
    
    fileLimitCount = open(fileLimitCountName,fmWrite)
    if needResetCountTime or fileLimitCountExists == false :
      fileLimitCount.writeLine(now().format("yyyy-MM-dd HH:mm:ss"))
      fileLimitCount.writeLine($len(targetText))
    else:
      fileLimitCount.writeLine(timeLastExecute)
      #echo "limitCount:" & $limitCount
      #echo "targetText:" & targetText & ",length:" & $len(targetText)
      limitCount = limitCount + len(targetText)
      #echo "new limitCount:" & $limitCount
      fileLimitCount.writeLine($limitCount)
    fileLimitCount.close()

    if fileExists(logFileName):
      logFile = open(logFileName,fmAppend)
    else:
      logFile = open(logFileName,fmWrite)

    logFile.writeLine(tranlateResult)
    logFile.close()

  # output result of translattion
  echo resultText
  


#else:
if commandError:
  echo "command is not correct."
  echo """(command example) ./AzureTranslator --from:en --to:zh-Hans example"""
  echo """(show Language List) ./AzureTranslator --list"""
