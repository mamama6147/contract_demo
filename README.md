# AdminToken & NotALocker NFT Contract Demo

## 📋 概要

このプロジェクトは、階層的権限システムを持つ2つのNFTコントラクトのデモンストレーションです。

### システム構成

- **AdminToken**: 管理者権限を付与するNFTコントラクト
- **NotALocker**: AdminToken保有者が管理できる一般NFTコントラクト

## 🚀 主な機能

### AdminToken (AdminTokenNFT)
- ✅ ERC721標準準拠NFT
- ✅ オーナーのみMint可能
- ✅ 最大10,000枚の供給制限
- ✅ カスタムメタデータベースURI

### NotALocker (notALockerNFT)
- ✅ AdminToken保有者のみアクセス可能
- ✅ 段階的メタデータ公開（Reveal機能）
- ✅ 一時停止機能（Pause/Unpause）
- ✅ Admin権限での他人のNFT転送
- ✅ 条件付きBurn機能
- ✅ WalletOfOwner（所有NFT一覧取得）

## 📁 ファイル構造

```
contract_demo/
├── contracts/
│   ├── AdminToken.sol      # 管理者権限NFT
│   └── NotALocker.sol      # 権限制御NFT
├── docs/
│   └── TESTING_GUIDE.md    # 完全テスト手順書
├── artifacts/              # コンパイル成果物
├── scripts/                # デプロイスクリプト
└── README.md              # このファイル
```

## 🧪 テスト

### 完全テスト手順書
詳細なテスト手順については以下をご覧ください：
**📋 [TESTING_GUIDE.md](./docs/TESTING_GUIDE.md)**

### テスト内容
- ✅ 基本機能テスト（デプロイ、Mint、TokenURI）
- ✅ 権限制御テスト（AdminToken連携）
- ✅ 高度機能テスト（Transfer、Burn、Pause）
- ✅ セキュリティテスト（権限なしアクセス拒否）

## 🛠️ 開発環境

### 推奨環境
- **IDE**: Remix IDE (https://remix.ethereum.org)
- **Solidity**: ^0.8.20
- **OpenZeppelin**: ^4.0.0
- **テスト環境**: Remix VM

### コンパイル設定
- Optimization: 有効
- Runs: 200
- EVM Version: Cancun

## 🚀 デプロイ手順

### 1. AdminToken デプロイ
```solidity
constructor("https://api.example.com/admin/")
```

### 2. NotALocker デプロイ
```solidity
constructor(
    "https://api.example.com/nft/",
    "https://api.example.com/hidden.json"
)
```

### 3. 連携設定
```solidity
notALocker.setAdminContract(adminTokenAddress);
```

## 🔐 セキュリティ機能

### 権限制御システム
- **2層権限**: AdminToken保有者 → NotALocker操作権限
- **アクセス制御**: 各機能に適切な権限チェック実装
- **エラーハンドリング**: 不正アクセスの適切な拒否

### 監査項目
- ✅ onlyOwner修飾子の適切な使用
- ✅ AdminToken保有確認の実装
- ✅ リエントランシー攻撃対策
- ✅ オーバーフロー/アンダーフロー対策

## 📊 使用例

### 基本的な使用フロー
1. AdminTokenをデプロイ・発行
2. NotALockerをデプロイ・連携設定
3. AdminToken保有者がNotALockerをMint
4. 段階的にメタデータを公開
5. 必要に応じてTransfer/Burn操作

## 🎯 活用場面

### 適用可能なユースケース
- **プライベートNFTコレクション**: 限定メンバーのみアクセス
- **段階的リリース**: メタデータの段階的公開
- **コミュニティ管理**: 管理者による柔軟なNFT操作
- **ゲーミングNFT**: 管理者権限での特殊操作が必要な場合

## 🤝 貢献

### 改善提案・バグレポート
Issuesセクションでお気軽に報告・提案してください。

### 開発貢献
Pull Requestを歓迎します。以下の点にご留意ください：
- テスト手順書に従った動作確認
- 適切なコメント・ドキュメント更新
- セキュリティ観点での検証

## 📝 ライセンス

MIT License

## 🙋‍♂️ 作成者

Created by mamama6147

---

**🎉 Happy Coding!** 

質問やサポートが必要でしたら、お気軽にIssueを作成してください。