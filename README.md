# AdminToken & NotALocker NFT Contract Demo

## 📋 概要

このプロジェクトは、階層的権限システムを持つ2つのNFTコントラクトのデモンストレーションです。

### システム構成

- **AdminToken**: 管理者権限を付与するNFTコントラクト
- **NotALocker**: AdminToken保有者が管理できる一般NFTコントラクト

## 🎯 バージョンについて

このリポジトリには**2つのバージョン**のコントラクトが含まれています：

### 📘 通常版（学習・テスト用）
**ファイル:**
- `contracts/AdminToken.sol`
- `contracts/NotALocker.sol`

**特徴:**
- ✅ ERC721Enumerable使用
- ✅ シンプルで理解しやすい実装
- ✅ CountersライブラリでtokenId管理（burn対応）
- ✅ **学習・テスト環境に最適**
- ✅ コードの可読性重視

**推奨用途:**
- Remix IDEでの学習
- テストネットでの実験
- スマートコントラクトの学習教材

### 🔐 Secure版（本番環境向け）
**ファイル:**
- `contracts/AdminToken_Secure.sol`
- `contracts/NotALocker_Secure.sol`

**特徴:**
- ✅ ERC721Psi使用（ガス最適化）
- ✅ ReentrancyGuard実装
- ✅ 詳細なEvent logging
- ✅ 厳格な入力検証
- ✅ Emergency機能（緊急停止・資金引き出し）
- ✅ Modifierによるコード整理
- ✅ フロントエンド連携用View関数

**推奨用途:**
- メインネットデプロイ
- 本番環境での運用
- 大量mintが必要な場合

**⚠️ 注意:**
- ERC721Psiは独自のtokenId管理を行うため、通常版とは実装が異なります
- より高度なSolidityの知識が必要です

## 🆚 バージョン比較表

| 項目 | 通常版 | Secure版 |
|------|--------|----------|
| **ERC721実装** | ERC721Enumerable | ERC721Psi |
| **ガス効率** | 標準 | 最適化済み |
| **セキュリティ** | 基本的 | 強化版 |
| **複雑度** | シンプル | 高度 |
| **学習向け** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **本番向け** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **tokenId管理** | Counters | ERC721Psi内蔵 |
| **ReentrancyGuard** | ❌ | ✅ |
| **Emergency機能** | ❌ | ✅ |

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
- ✅ **tokenId衝突問題を修正済み**（通常版）

## 📁 ファイル構造

```
contract_demo/
├── contracts/
│   ├── AdminToken.sol              # 通常版: 管理者権限NFT
│   ├── NotALocker.sol              # 通常版: 権限制御NFT（Counters使用）
│   ├── AdminToken_Secure.sol       # Secure版: 本番環境向け
│   └── NotALocker_Secure.sol       # Secure版: 本番環境向け
├── docs/
│   └── TESTING_GUIDE.md            # 完全テスト手順書
├── artifacts/                      # コンパイル成果物
├── scripts/                        # デプロイスクリプト
└── README.md                       # このファイル
```

## 🔧 最近の修正

### v1.1.0 - tokenId管理の改善（通常版）
**問題:** burnでtokenIdを削除すると、totalSupply()が減少し、次のmint時にtokenId衝突が発生

**解決策:** 
- Countersライブラリを使用した専用カウンター実装
- burnしてもカウンターは進むため衝突なし
- より安全で予測可能なtokenId管理

**修正ファイル:**
- `contracts/NotALocker.sol`

## 🧪 テスト

### 完全テスト手順書
詳細なテスト手順については以下をご覧ください：
**📋 [TESTING_GUIDE.md](./docs/TESTING_GUIDE.md)**

### テスト内容
- ✅ 基本機能テスト（デプロイ、Mint、TokenURI）
- ✅ 権限制御テスト（AdminToken連携）
- ✅ 高度機能テスト（Transfer、Burn、Pause）
- ✅ セキュリティテスト（権限なしアクセス拒否）
- ✅ tokenId衝突テスト（burn後のmint）

## 🛠️ 開発環境

### 推奨環境
- **IDE**: Remix IDE (https://remix.ethereum.org)
- **Solidity**: ^0.8.20
- **OpenZeppelin**: ^4.0.0
- **テスト環境**: Remix VM または Sepolia Testnet

### コンパイル設定
- Optimization: 有効
- Runs: 200
- EVM Version: Cancun

## 🚀 デプロイ手順

### どちらのバージョンを使うべきか？

**🎓 学習・テストの場合:**
→ **通常版（AdminToken.sol / NotALocker.sol）**を使用

**🏭 本番環境の場合:**
→ **Secure版（AdminToken_Secure.sol / NotALocker_Secure.sol）**を使用

### 1. AdminToken デプロイ
```solidity
// 通常版
constructor("https://api.example.com/admin/")

// Secure版
constructor("https://api.example.com/admin/")
```

### 2. NotALocker デプロイ
```solidity
// 通常版・Secure版共通
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
- ✅ リエントランシー攻撃対策（Secure版）
- ✅ オーバーフロー/アンダーフロー対策
- ✅ tokenId衝突対策（通常版: Counters使用）

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

## 📚 参考リンク

- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Remix IDE](https://remix.ethereum.org)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [ERC721 Standard](https://eips.ethereum.org/EIPS/eip-721)

---

**🎉 Happy Coding!** 

質問やサポートが必要でしたら、お気軽にIssueを作成してください。

**💡 ヒント:** 初めての方は通常版から始めることをお勧めします！