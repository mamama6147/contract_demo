// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title AdminTokenNFT (Secure Version)
 * @notice 本番環境向けの管理者権限NFTコントラクト
 * @dev ERC721Enumerableベース + セキュリティ強化
 * 
 * 🔐 セキュリティ機能:
 * - ReentrancyGuard: リエントランシー攻撃対策
 * - Countersライブラリ: tokenId衝突防止
 * - イベントログ: 透明性の高いトランザクション記録
 * - 厳格な入力検証: ゼロアドレス・空文字列チェック
 * - 緊急機能: withdraw による資金引き出し
 * - バッチミント制限: ガス制限対策
 * 
 * 💡 tokenId管理:
 * CountersライブラリでユニークなtokenIdを保証
 * burnしてもカウンターは進むため、tokenId衝突は発生しません
 * 
 * 🆚 通常版との違い:
 * - 通常版: 基本的なセキュリティ
 * - Secure版: ReentrancyGuard + 詳細Event + 厳格な検証
 */
contract AdminTokenNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 10000;
    uint256 public constant MAX_BATCH_MINT = 100; // バッチミント上限

    // Events for transparency
    event BaseURIUpdated(string indexed newBaseURI);
    event BaseExtensionUpdated(string indexed newExtension);
    event TokensMinted(address indexed to, uint256 startTokenId, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);

    constructor(
        string memory _initBaseURI
    ) ERC721("AdminTokenNFT", "ADMINNFT") Ownable(msg.sender) {
        require(bytes(_initBaseURI).length > 0, "Base URI cannot be empty");
        baseURI = _initBaseURI;
        emit BaseURIUpdated(_initBaseURI);
    }

    // Modifiers
    modifier validMintAmount(uint256 _mintAmount) {
        require(_mintAmount > 0, "mint amount must be positive");
        require(_mintAmount <= MAX_BATCH_MINT, "exceeds max batch mint");
        require(totalSupply() + _mintAmount <= maxSupply, "exceeds max supply");
        _;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice 管理者権限NFTをミント
     * @param _mintAmount ミントする数量（1-100）
     * @dev Countersで安全なtokenId管理、ReentrancyGuard適用
     */
    function mint(uint256 _mintAmount) 
        external 
        onlyOwner 
        nonReentrant 
        validMintAmount(_mintAmount) 
    {
        uint256 startTokenId = _tokenIdCounter.current() + 1;

        for (uint256 i = 0; i < _mintAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }

        emit TokensMinted(msg.sender, startTokenId, _mintAmount);
    }

    /**
     * @notice 現在のtokenIdカウンターを取得
     * @return 次にミントされるtokenId
     */
    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireOwned(tokenId);

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    // only owner functions with enhanced validation
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(bytes(_newBaseURI).length > 0, "Base URI cannot be empty");
        baseURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        require(bytes(_newBaseExtension).length > 0, "Extension cannot be empty");
        baseExtension = _newBaseExtension;
        emit BaseExtensionUpdated(_newBaseExtension);
    }

    /**
     * @notice 緊急時のETH引き出し
     * @dev オーナーのみ実行可能
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner(), balance);
    }

    /**
     * @notice コントラクトがETHを受け取れるようにする
     */
    receive() external payable {}

    /**
     * @notice コントラクト情報を一括取得
     * @return _name コントラクト名
     * @return _symbol トークンシンボル
     * @return _totalSupply 現在の総供給量
     * @return _maxSupply 最大供給量
     * @return _currentTokenId 現在のtokenIdカウンター
     * @return _owner コントラクトオーナーアドレス
     */
    function getContractInfo() external view returns (
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _maxSupply,
        uint256 _currentTokenId,
        address _owner
    ) {
        return (
            name(),
            symbol(),
            totalSupply(),
            maxSupply,
            _tokenIdCounter.current(),
            owner()
        );
    }
}