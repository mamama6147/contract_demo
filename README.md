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
- ✅ ERC721Enumerable + Countersライブラリ
- ✅ シンプルで理解しやすい実装
- ✅ tokenId衝突問題を解決（Counters使用）
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
- ✅ ERC721Enumerable + Countersライブラリ（通常版と同じ基盤）
- ✅ **ReentrancyGuard実装**（リエントランシー攻撃対策）
- ✅ **詳細なEvent logging**（透明性向上）
- ✅ **Modifierによるコード整理**（可読性・保守性向上）
- ✅ **厳格な入力検証**（セキュリティ強化）
- ✅ **Emergency機能**（緊急停止・資金引き出し）
- ✅ **フロントエンド連携用View関数**
- ✅ tokenId衝突問題を解決（Counters使用）

**推奨用途:**
- メインネットデプロイ
- 本番環境での運用
- セキュリティが重要なプロジェクト

**⚠️ 注意:**
- Secure版も標準OpenZeppelinライブラリのみ使用
- 外部依存なしでRemixで直接使用可能
- 通常版より高度なセキュリティ機能を提供

## 🆚 バージョン比較表

| 項目 | 通常版 | Secure版 |
|------|--------|----------|
| **ERC721実装** | ERC721Enumerable | ERC721Enumerable |
| **tokenId管理** | Counters | Counters |
| **ReentrancyGuard** | ❌ | ✅ |
| **詳細Event** | 基本的 | 充実 |
| **Modifier整理** | ❌ | ✅ |
| **厳格な検証** | 基本的 | 強化版 |
| **Emergency機能** | ❌ | ✅ |
| **View関数** | 基本的 | フロントエンド連携用追加 |
| **学習向け** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **本番向け** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **外部依存** | なし | なし |
| **Remix使用** | ✅ | ✅ |

## 🚀 主な機能

### AdminToken (AdminTokenNFT)
- ✅ ERC721標準準拠NFT
- ✅ オーナーのみMint可能
- ✅ 最大10,000枚の供給制限
- ✅ カスタムメタデータベースURI
- ✅ Countersでtokenid衝突防止

### NotALocker (notALockerNFT)
- ✅ AdminToken保有者のみアクセス可能
- ✅ 段階的メタデータ公開（Reveal機能）
- ✅ 一時停止機能（Pause/Unpause）
- ✅ Admin権限での他人のNFT転送
- ✅ 条件付きBurn機能
- ✅ WalletOfOwner（所有NFT一覧取得）
- ✅ **tokenId衝突問題を解決済み**（Counters使用）

## 📁 ファイル構造

```
contract_demo/
├── contracts/
│   ├── AdminToken.sol              # 通常版: 管理者権限NFT
│   ├── NotALocker.sol              # 通常版: 権限制御NFT
│   ├── AdminToken_Secure.sol       # Secure版: 本番環境向け
│   └── NotALocker_Secure.sol       # Secure版: 本番環境向け
├── docs/
│   └── TESTING_GUIDE.md            # 完全テスト手順書
├── artifacts/                      # コンパイル成果物
├── scripts/                        # デプロイスクリプト
└── README.md                       # このファイル
```

## 🔧 最近の修正

### v1.2.0 - Secure版をERC721Enumerableベースに変更
**変更内容:**
- ERC721Psi → ERC721Enumerable + Counters
- 外部依存を完全削除
- 標準OpenZeppelinライブラリのみ使用
- Remixで直接使用可能に

**メリット:**
- ✅ インポートエラーの解消
- ✅ 保守性の向上
- ✅ 学習しやすい実装
- ✅ セキュリティ機能は維持・強化

### v1.1.0 - tokenId管理の改善
**問題:** burnでtokenIdを削除すると、totalSupply()が減少し、次のmint時にtokenId衝突が発生

**解決策:** 
- Countersライブラリを使用した専用カウンター実装
- burnしてもカウンターは進むため衝突なし
- より安全で予測可能なtokenId管理

**修正ファイル:**
- `contracts/NotALocker.sol`
- `contracts/NotALocker_Secure.sol`

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
- **Solidity**: >=0.8.20 <0.9.0
- **OpenZeppelin**: ^5.0.0（Remixで自動インポート）
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
// 通常版・Secure版共通
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
- ✅ リエントランシー攻撃対策（Secure版: ReentrancyGuard）
- ✅ オーバーフロー/アンダーフロー対策（Solidity 0.8+）
- ✅ tokenId衝突対策（両版: Counters使用）

### Secure版の追加セキュリティ
- ✅ **ReentrancyGuard**: 全ての状態変更関数に適用
- ✅ **Modifier**: 権限チェックの一元管理
- ✅ **Event**: 全操作のログ記録
- ✅ **厳格な検証**: ゼロアドレス・空文字列チェック
- ✅ **Emergency機能**: 緊急停止・資金引き出し

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

**💡 ヒント:** 
- 初めての方は通常版から始めることをお勧めします！
- 両バージョンともRemixで直接使用可能です
- 外部依存なし、標準OpenZeppelinライブラリのみ使用