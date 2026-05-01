# TinyQuadDict

英語文章から単語を抽出し、単語それぞれに対して指定した４つの言語の翻訳結果を表示するGUIプログラムです。

ブラウザから翻訳サイトを参照するだけでも負担がかかるRaspberry Pi 3のデスクトップ環境でも快適に英語の学習を行うためにこのプログラムを作成しました。

英語を母国語に翻訳する際に、ついでに他の言語も学べるようにしたいと考えて複数言語への翻訳機能を実装しています。
シングルボードコンピュータのようなリソースに余裕が無い環境でも快適に動作するように、軽量なNim言語とNiGui(Nim GUIライブラリ)で開発を行っています。

翻訳機能はAzure Translatorのフリープランを利用しているため、利用にはAzureアカウントが必要です。
翻訳した結果はファイルに保存するので、2回目以降の翻訳処理ではAzureを経由せず処理時間の短縮が可能です。

https://github.com/user-attachments/assets/84584b1e-e5cb-47ae-8d73-a5b0e794eea5

### How to install

Install [nim](https://nim-lang.org/)

Commands to compile
```
nimble install nigui
nim compile --app:console -d:ssl -d:release AzureTranslator.nim
nim compile --threads:on --app:gui -d:release TinyQuadDict.nim
```

### Get Azure subscription key

以下のサイトを参考に、Azureリソースを追加してサブスクリプションキーを取得して下さい。

[Quickstart: translate text programmatically](https://learn.microsoft.com/azure/ai-services/translator/text-translation/quickstart/rest-api?tabs=csharp)



### Launching TinyQuadDict

```
./TinyQuadDict
```

初回起動時は一番上のボタンをクリックしてサブスクリプションキーを登録して下さい。

### Translating words from the command line

```
./AzureTranslator --from:en --to:ja example
```

(単語"example"を英語から日本語に翻訳する時のコマンド例です。)

[Language code information](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/language-support)



