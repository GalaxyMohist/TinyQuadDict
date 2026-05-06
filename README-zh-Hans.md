# TinyQuadDict

[英语ReadMe](README.md)

这是一个GUI程序，可以从用空格分隔的文本中提取单词，例如英语，并以四种指定语言显示每个单词的翻译结果。

[语言支持](https://docs.microsoft.com/azure/cognitive-services/translator/language-support)

- [Language name]		[Language Code]
- Afrikaans 		af
- Arabic 			ar
- Bangla 			bn
- Bosnian (Latin) 	bs
- Bulgarian 		bg
- Catalan 		ca
- Chinese Simplified 	zh-Hans
- Croatian 		hr
- Czech 			cs
- Danish 			da
- Dutch 			nl
- English 		en
- Finnish 		fi
- French 			fr
- German 			de
- Greek 			el
- Haitian Creole 		ht
- Hebrew 			he
- Hmong Daw (Latin) 	mww
- Hungarian 		hu
- Icelandic 		is
- Indonesian 		id
- Italian 		it
- Japanese 		ja
- Klingon 		tlh-Latn
- Korean 			ko
- Latvian 		lv
- Lithuanian 		lt
- Malay (Latin) 		ms
- Maltese 		mt
- Norwegian Bokmål 	nb
- Persian 		fa
- Polish 			pl
- Portuguese (Brazil) 	pt
- Romanian 		ro
- Russian 		ru
- Serbian (Latin) 	sr-Latn
- Slovak 			sk
- Slovenian 		sl
- Spanish 		es
- Swahili (Latin) 	sw
- Swedish 		sv
- Tamil 			ta
- Thai 			th
- Turkish 		tr
- Ukrainian 		uk
- Urdu 			ur
- Vietnamese 		vi
- Welsh 			cy

https://github.com/user-attachments/assets/84584b1e-e5cb-47ae-8d73-a5b0e794eea5

即使是在像树莓派3这样仅通过浏览器访问翻译网站都会造成负担的桌面环境下，为了能够舒适地进行外语学习，我编写了这个程序。

当翻译成任何语言时，我实现了一个多语言翻译功能，这样用户就可以同时学习其他语言。

为了确保即使在单板计算机等资源受限的环境中也能顺利运行，我使用轻量级的Nim语言和NiGui（Nim GUI库）开发了这个程序。

翻译功能使用Azure Translator的免费计划，因此需要Azure帐户才能使用它。
由于翻译结果保存到文件中，因此后续翻译过程不会通过Azure，从而减少了处理时间。


### 如何安装

安装 [nim](https://nim-lang.org/)

要编译的命令
```
nimble install nigui
nim compile --app:console -d:ssl -d:release AzureTranslator.nim
nim compile --threads:on --app:gui -d:release TinyQuadDict.nim
```


### 获取Azure订阅密钥

请参阅以下网站以创建资源并获取订阅密钥。

[快速入门：以编程方式翻译文本](https://learn.microsoft.com/azure/ai-services/translator/text-translation/quickstart/rest-api?tabs=csharp)


### 启动 TinyQuadDict

```
./TinyQuadDict
```

当您首次启动应用程序时，请单击顶部按钮注册您的订阅密钥。


### 从CLI翻译单词

显示语言列表。

```
./AzureTranslator --list
```

将“example”一词从英语翻译成简体中文。

```
./AzureTranslator --from:en --to:zh-Hans example
```
