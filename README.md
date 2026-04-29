# TinyQuadDict

This is a GUI program that extracts words from English text and displays translations into four specified languages for each word.

I created this program to enable comfortable English learning even on the desktop environment of a Raspberry Pi 3, where simply accessing translation websites via a browser can be a strain on system resources.
When translating into English, we implemented a multilingual translation feature so that users could learn other languages at the same time.
To ensure smooth operation even in resource-constrained environments like single-board computers, I developed this program using the lightweight Nim language and NiGui (a Nim GUI library).

The translation feature uses the free plan of Azure Translator, so an Azure account is required to use it.
Since the translation results are saved to a file, subsequent translation processes do not go through Azure, reducing processing time.

https://github.com/user-attachments/assets/84584b1e-e5cb-47ae-8d73-a5b0e794eea5

### how to install

Install [nim](https://nim-lang.org/)

Commands to compile
```
nimble install nigui
nim compile --app:console -d:ssl -d:release AzureTranslator.nim
nim compile --threads:on --app:gui -d:release TinyQuadDict.nim
```

### get Azure subscription key

Refer to the following website to create a resource and obtain a subscription key.
[Quickstart: translate text programmatically](https://learn.microsoft.com/azure/ai-services/translator/text-translation/quickstart/rest-api?tabs=csharp)



### Launching TinyQuadDict

```
./TinyQuadDict
```

When you launch the app for the first time, please click the top button to register your subscription key.


### Translating words from the command line

```
./AzureTranslator --from:en --to:zh-Hans example
```

(Translate the word “example” from English to Simplified Chinese.)

[Language code information](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/language-support)


