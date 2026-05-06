# TinyQuadDict

英語のようなスペースで単語が区切られた文章から単語を抽出し、単語それぞれに対して指定した４つの言語の翻訳結果を表示するGUIプログラムです。

[対応言語](https://docs.microsoft.com/azure/cognitive-services/translator/language-support)

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

ブラウザから翻訳サイトを参照するだけでも負担がかかるRaspberry Pi 3のようなデスクトップ環境でも、快適に語学の学習を行うために私はこのプログラムを作成しました。

英語を母国語に翻訳する際に、ついでに他の言語も学べるようにしたいと考えて複数言語への翻訳機能を実装しています。
シングルボードコンピュータのようなリソースに余裕が無い環境でも快適に動作するように、軽量なNim言語とNiGui(Nim GUIライブラリ)で開発を行っています。

翻訳機能はAzure Translatorのフリープランを利用しているため、利用にはAzureアカウントが必要です。
翻訳した結果はファイルに保存するので、2回目以降の翻訳処理ではAzureを経由せず処理時間の短縮が可能です。

### インストール方法

[nim](https://nim-lang.org/)をインストールして下さい。

コンパイルコマンド
```
nimble install nigui
nim compile --app:console -d:ssl -d:release AzureTranslator.nim
nim compile --threads:on --app:gui -d:release TinyQuadDict.nim
```

### Azureサブスクリプションキーの取得

以下のサイトを参考に、Azureリソースを追加してサブスクリプションキーを取得して下さい。

[Quickstart: translate text programmatically](https://learn.microsoft.com/azure/ai-services/translator/text-translation/quickstart/rest-api?tabs=csharp)



### TinyQuadDictを起動

```
./TinyQuadDict
```

初回起動時は一番上のボタンをクリックしてサブスクリプションキーを登録して下さい。

### CLIから単語の翻訳を行うコマンド

対応言語の一覧を表示

```
./AzureTranslator --list
```

単語"example"を英語から日本語に翻訳。

```
./AzureTranslator --from:en --to:ja example
```
