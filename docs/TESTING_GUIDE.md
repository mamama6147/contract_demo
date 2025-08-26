# AdminToken & NotALocker NFTコントラクト テスト手順書

## 📋 概要

この手順書は、AdminTokenNFT と notALockerNFT の2つのスマートコントラクトをRemix IDEでテストする完全な手順を説明します。

### システム構成
- **AdminToken**: 管理者権限を付与するNFT
- **NotALocker**: AdminToken保有者が管理できる一般NFT
- **階層的権限システム**: AdminToken保有者はNotALockerを無制限に操作可能

---

## 🔧 事前準備

### 必要なもの
- ✅ Remix IDE（https://remix.ethereum.org）
- ✅ AdminToken.sol ファイル
- ✅ NotALocker.sol ファイル
- ✅ Webブラウザ（Chrome推奨）

### 環境設定
1. **Remix IDE**を開く
2. **Solidity Compiler**タブで以下を設定：
   - **Optimization**: ✅ 有効
   - **Runs**: 200（デフォルト）
   - **Solidity Version**: 0.8.20以上

---

## 📁 ファイル準備

### ファイル構成
```
contracts/
├── AdminToken.sol
└── NotALocker.sol
```

1. `contracts` フォルダを作成
2. 各ファイルをアップロードまたはコピー&ペースト
3. コンパイルエラーがないことを確認

---

## 🚀 フェーズ1: AdminToken テスト

### ステップ1: AdminToken デプロイ

1. **Deploy & Run Transactions** タブを開く
2. **Environment**: `Remix VM (Cancun)` を選択
3. **Account**: Account 0（デフォルト）を使用
4. **Contract**: `AdminTokenNFT` を選択
5. **Constructor**に入力:
   ```
   _INITBASEURI: "https://api.example.com/admin/"
   ```
6. **Deploy** をクリック
7. **成功確認**: "creation of AdminTokenNFT successful" メッセージ

### ステップ2: 基本情報テスト

**Deployed Contracts** で `ADMINTOKEN` を展開し、以下を実行：

| 関数 | 期待値 | テスト内容 |
|------|--------|------------|
| `maxSupply()` | `10000` | 最大供給量確認 |
| `totalSupply()` | `0` | 初期供給量確認 |
| `name()` | `"AdminTokenNFT"` | コレクション名確認 |
| `symbol()` | `"ADMINNFT"` | シンボル確認 |
| `owner()` | `あなたのアドレス` | 所有者確認 |

### ステップ3: Mint機能テスト

```javascript
// Mintテスト
mint: 3          // 3を入力してtransact

// 結果確認
totalSupply()    // → 3
balanceOf: あなたのアドレス  // → 3
tokenURI: 1      // → "https://api.example.com/admin/1.json"
tokenURI: 2      // → "https://api.example.com/admin/2.json" 
tokenURI: 3      // → "https://api.example.com/admin/3.json"
```

### ✅ AdminToken テスト完了チェックリスト
- [ ] デプロイ成功
- [ ] 基本情報正常（maxSupply: 10000, name: "AdminTokenNFT"）
- [ ] Mint機能正常（3つのトークン作成）
- [ ] TokenURI正常（正しいURLを返す）

---

## 🔐 フェーズ2: NotALocker テスト

### ステップ4: NotALocker デプロイ

1. **Contract**: `notALockerNFT` を選択
2. **Constructor**に入力:
   ```
   _INITBASEURI: "https://api.example.com/nft/"
   _INITNOTREVEALEDURI: "https://api.example.com/hidden.json"
   ```
3. **Deploy** をクリック
4. **成功確認**: デプロイ成功メッセージ

### ステップ5: AdminContract 設定

**⚠️ 重要**: この設定なしでは連携動作しません

1. **AdminToken のアドレスをコピー**:
   - `Deployed Contracts` → `ADMINTOKEN` → アドレスをクリックしてコピー

2. **NotALocker で設定**:
   ```javascript
   setAdminContract: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4  // 実際のアドレス
   ```
3. **transact** をクリック

### ステップ6: 基本情報テスト

| 関数 | 期待値 | テスト内容 |
|------|--------|------------|
| `maxSupply()` | `10000` | 最大供給量確認 |
| `revealed()` | `false` | 非公開状態確認 |
| `paused()` | `false` | 非停止状態確認 |
| `maxMintAmount()` | `10000` | 最大Mint数確認 |
| `adminContract()` | `AdminTokenアドレス` | 連携確認 |

### ステップ7: Mint機能テスト

```javascript
// AdminToken保有者としてのMint
mint: 2          // 2を入力してtransact

// 結果確認
totalSupply()    // → 2
balanceOf: あなたのアドレス  // → 2
```

### ステップ8: Reveal機能テスト

```javascript
// Reveal前のTokenURI
tokenURI: 1      // → "https://api.example.com/hidden.json"
tokenURI: 2      // → "https://api.example.com/hidden.json"

// Reveal実行
reveal()         // transact をクリック

// 状態確認
revealed()       // → true

// Reveal後のTokenURI
tokenURI: 1      // → "https://api.example.com/nft/1.json"
tokenURI: 2      // → "https://api.example.com/nft/2.json"
```

### ステップ9: Pause機能テスト

```javascript
// 一時停止テスト
pause: true      // transact
paused()         // → true
mint: 1          // → "minting is paused" エラー確認

// 停止解除テスト
pause: false     // transact
paused()         // → false
mint: 1          // → 成功（tokenId: 3作成）
totalSupply()    // → 3
```

---

## 🎛️ フェーズ3: 高度な機能テスト

### ステップ10: Transfer機能テスト

```javascript
// Admin権限でのTransfer
transferToken:
- from: あなたのアドレス
- to: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2  // 適当な他のアドレス
- tokenId: 1

// 結果確認
ownerOf: 1       // → 転送先アドレス
```

### ステップ11: WalletOfOwner テスト

```javascript
// 所有Token一覧確認
walletOfOwner: あなたのアドレス  
// → [2, 3] （token1は転送済み）

walletOfOwner: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// → [1] （転送されたtoken）
```

### ステップ12: Burn機能テスト

```javascript
// Burn実行
burn: 2          // tokenId 2を焼却

// 結果確認
totalSupply()    // → 2 （1つ減少）
ownerOf: 2       // → エラー（token削除済み）
walletOfOwner: あなたのアドレス  // → [3]
```

---

## 🛡️ フェーズ4: 権限制御テスト

### ステップ13: 非Admin権限テスト

1. **Account を変更**: Account 1 などの別アドレスに切り替え

2. **権限なしテスト**（全て失敗するはず）:
   ```javascript
   mint: 1          // → "caller doesn't have admin token" エラー
   
   transferToken:   // → "caller is not eligible" エラー  
   - from: 元のアドレス
   - to: 現在のアドレス
   - tokenId: 3
   ```

### ステップ14: 最終確認

1. **Account を元に戻す**: 最初のアカウント（AdminToken保有者）
2. **最終状態確認**:
   ```javascript
   totalSupply()    // → 2
   balanceOf: あなたのアドレス  // → 1
   walletOfOwner: あなたのアドレス  // → [3]
   paused()         // → false
   revealed()       // → true
   ```

---

## ✅ 完全テスト成功チェックリスト

### AdminToken
- [ ] デプロイ成功
- [ ] 基本情報正常（maxSupply, name, symbol）
- [ ] Owner権限Mint成功
- [ ] TokenURI正常動作

### NotALocker
- [ ] デプロイ成功  
- [ ] AdminContract設定成功
- [ ] AdminToken保有者のみMint可能
- [ ] Reveal機能正常（hidden → 実際のメタデータ）
- [ ] Pause/Unpause機能正常
- [ ] Admin権限Transfer成功（他人のNFTも転送可能）
- [ ] Burn機能成功（条件：AdminToken保有 + NFT所有）
- [ ] WalletOfOwner機能正常

### セキュリティ
- [ ] AdminToken非保有者のMint拒否
- [ ] 権限なしTransfer拒否
- [ ] 適切なエラーメッセージ表示

### 統合動作
- [ ] AdminToken ⇔ NotALocker 連携正常
- [ ] 階層的権限システム動作
- [ ] 全機能が期待通りに動作

---

## 🚨 よくあるエラーと対処法

### Contract creation failed
**原因**: ガス不足、コンパイルエラー  
**解決**: Gas Limit増加（3000000）、コンパイル確認

### "caller doesn't have admin token"
**原因**: setAdminContract()未設定  
**解決**: AdminTokenアドレスを正しく設定

### "minting is paused"  
**原因**: Pause状態でのMint実行  
**解決**: pause(false)で解除

### TokenURI が表示されない
**原因**: token未作成、無効なtokenId  
**解決**: mintが成功しているか、tokenIdが正しいか確認

---

## 🎯 テスト完了後の次ステップ

### A. テストネットデプロイ
- Sepolia/Goerliでの実証テスト
- 実際のガス費用計測

### B. メインネットデプロイ準備
- セキュリティ監査検討
- ガス最適化最終確認

### C. フロントエンド開発
- Web3.js/Ethers.js連携
- ユーザーインターフェース開発

---

## 📞 サポート

テスト中に問題が発生した場合：

1. **エラーメッセージを確認**
2. **チェックリストで進行状況確認**
3. **Environment/Account設定確認**
4. **必要に応じて手順を最初からやり直し**

---

**🎉 テスト成功おめでとうございます！**

この手順書に従うことで、AdminTokenとNotALockerの完全な動作テストが可能です。

---

*作成日: 2025年8月*  
*対象: AdminTokenNFT & notALockerNFT v1.0*  
*テスト環境: Remix IDE + Remix VM*