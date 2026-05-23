# Pixela Viewer

[Pixela](https://pixe.la/) のグラフを閲覧するための iOS / iPadOS アプリです。

## スクリーンショット

*(準備中)*

## 機能

- 複数の Pixela アカウントを登録・管理
- 全アカウントのグラフを統合して一覧表示
- グラフの SVG 画像をインライン表示（ダークモード対応）
- グラフの統計情報を表示（今日・昨日・最大・最小・平均）
- グラフをタップすると Safari でグラフページを開く
- グラフのピン留め（ピン留めしたグラフを一覧の上部に固定）
- グラフの非表示 / 再表示
- プルリフレッシュ

## 動作環境

- iOS / iPadOS 17.0 以上
- iPhone・iPad 両対応

## 技術スタック

- Swift 6
- SwiftUI
- Keychain（ユーザートークンの安全な保存）
- WKWebView（SVG レンダリング）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## セットアップ

### 必要なもの

- Xcode 16 以上
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

### ビルド手順

```bash
git clone https://github.com/a-know/pixela-viewer-swift.git
cd pixela-viewer-swift
xcodegen generate
open PixelaViewer.xcodeproj
```

Xcode でターゲットデバイスを選択してビルド・実行してください。

## 使い方

1. 右上の人物アイコンからアカウント管理画面を開く
2. Pixela のユーザー名とユーザートークンを入力してアカウントを追加
3. 登録されたアカウントのグラフが一覧表示される

## ライセンス

[LICENSE](LICENSE) を参照してください。
