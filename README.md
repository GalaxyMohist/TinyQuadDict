# TinyQuadDict

[中文(简体)ReadMe](README-zh-Hans.md)

[日本語ReadMe](README-ja.md)

This is a GUI program that extracts words from text separated by spaces, such as in English, and displays the translation results for each word in four specified languages.

[Language Support](https://docs.microsoft.com/azure/cognitive-services/translator/language-support)

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

I created this program to enable comfortable English learning even on the desktop environment of a Raspberry Pi 3, where simply accessing translation websites via a browser can be a strain on system resources.

When translating into any language, I implemented a multilingual translation feature so that users could learn other languages at the same time.

To ensure smooth operation even in resource-constrained environments like single-board computers, I developed this program using the lightweight Nim language and NiGui (a Nim GUI library).

The translation feature uses the free plan of Azure Translator, so an Azure account is required to use it.
Since the translation results are saved to a file, subsequent translation processes do not go through Azure, reducing processing time.


### How to install

Install [nim](https://nim-lang.org/)

(Linux Only) Install xsel with your package manager.

Commands to compile
```
nimble install nigui
nimble install libclip
nim compile --app:console -d:ssl -d:release AzureTranslator.nim
nim compile --threads:on --app:gui -d:release TinyQuadDict.nim
```

### Get Azure subscription key

Refer to the following website to create a resource and obtain a subscription key.

[Quickstart: translate text programmatically](https://learn.microsoft.com/azure/ai-services/translator/text-translation/quickstart/rest-api?tabs=csharp)



### Launching TinyQuadDict

```
./TinyQuadDict
```

When you launch the app for the first time, please click the top button to register your subscription key.


### Translating words from the command line

Show list of language.

```
./AzureTranslator --list
```

Translate the word “example” from English to Simplified Chinese.

```
./AzureTranslator --from:en --to:zh-Hans example
```
