// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IERC721AdminContract {
    function balanceOf(address addr) external view returns (uint256 holds);
}

/**
 * @title notALockerNFT (Secure Version)
 * @notice 本番環境向けのAdminToken連携NFTコントラクト
 * @dev ERC721Enumerableベース + セキュリティ強化
 * 
 * 🔐 セキュリティ機能:
 * - ReentrancyGuard: リエントランシー攻撃対策
 * - Countersライブラリ: tokenId衝突防止
 * - Modifierによる権限チェック: hasAdminToken, whenNotPaused
 * - イベントログ: 全ての重要な操作を記録
 * - 厳格な入力検証: ゼロアドレス・無効な値のチェック
 * - Emergency機能: emergencyPause, withdraw
 * 
 * 💡 tokenId管理:
 * CountersライブラリでユニークなtokenIdを保証
 * ✅ burnしてもカウンターは進むため、tokenId衝突は発生しません
 * 
 * 🆚 通常版との違い:
 * - 通常版: 基本的なセキュリティ
 * - Secure版: ReentrancyGuard + 詳細Event + Modifier + 厳格な検証
 * 両方ともburn後のtokenId衝突問題を解決済み
 */
contract notALockerNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 10000;
    bool public paused = false;
    bool public revealed = false;
    string public notRevealedUri;
    IERC721AdminContract public adminContract;

    // Events for transparency
    event AdminContractUpdated(address indexed oldContract, address indexed newContract);
    event Paused(bool isPaused);
    event Revealed();
    event BaseURIUpdated(string indexed newBaseURI);
    event BaseExtensionUpdated(string indexed newExtension);
    event MaxMintAmountUpdated(uint256 newAmount);
    event TokensMinted(address indexed to, uint256 startTokenId, uint256 amount);
    event TokenBurned(uint256 indexed tokenId, address indexed burner);
    event TokenTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event FundsWithdrawn(address indexed to, uint256 amount);

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721("notALockerNFT", "NOTALOCKERNFT") Ownable(msg.sender) {
        require(bytes(_initBaseURI).length > 0, "Base URI cannot be empty");
        require(bytes(_initNotRevealedUri).length > 0, "Not revealed URI cannot be empty");
        
        baseURI = _initBaseURI;
        notRevealedUri = _initNotRevealedUri;
    }

    // Modifiers
    modifier hasAdminToken() {
        require(address(adminContract) != address(0), "Admin contract not set");
        require(adminContract.balanceOf(msg.sender) > 0, "caller doesn't have admin token");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "minting is paused");
        _;
    }

    modifier validTokenId(uint256 tokenId) {
        _requireOwned(tokenId);
        _;
    }

    modifier validMintAmount(uint256 _mintAmount) {
        require(_mintAmount > 0, "mint amount must be positive");
        require(_mintAmount <= maxMintAmount, "exceeds max mint amount");
        require(totalSupply() + _mintAmount <= maxSupply, "exceeds max supply");
        _;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice NFTをミント（AdminToken保有者のみ）
     * @param _mintAmount ミントする数量
     * @dev Countersで安全なtokenId管理、burnしても衝突しない
     */
    function mint(uint256 _mintAmount) 
        external 
        hasAdminToken 
        whenNotPaused 
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

    /**
     * @notice 特定のアドレスが所有する全NFTのtokenIdを取得
     * @param _owner 所有者のアドレス
     * @return tokenIdの配列
     */
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        if (ownerTokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        validTokenId(tokenId)
        returns (string memory)
    {
        if (!revealed) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    //only owner functions with enhanced security
    function reveal() external onlyOwner {
        require(!revealed, "Already revealed");
        revealed = true;
        emit Revealed();
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
        require(_newMaxMintAmount > 0, "Max mint amount must be greater than 0");
        require(_newMaxMintAmount <= maxSupply, "Cannot exceed max supply");
        maxMintAmount = _newMaxMintAmount;
        emit MaxMintAmountUpdated(_newMaxMintAmount);
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        require(bytes(_notRevealedURI).length > 0, "URI cannot be empty");
        notRevealedUri = _notRevealedURI;
    }

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

    function setAdminContract(address _adminContract) external onlyOwner {
        require(_adminContract != address(0), "Admin contract cannot be zero address");
        
        // コントラクトアドレスかチェック
        uint256 size;
        assembly {
            size := extcodesize(_adminContract)
        }
        require(size > 0, "Admin contract must be a contract address");

        address oldContract = address(adminContract);
        adminContract = IERC721AdminContract(_adminContract);
        emit AdminContractUpdated(oldContract, _adminContract);
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
        emit Paused(_state);
    }

    /**
     * @notice 緊急一時停止
     * @dev オーナーのみ実行可能
     */
    function emergencyPause() external onlyOwner {
        paused = true;
        emit Paused(true);
    }

    /**
     * @notice NFTを転送（所有者またはAdminToken保有者）
     * @param from 送信元アドレス
     * @param to 送信先アドレス
     * @param tokenId 転送するtokenId
     */
    function transferToken(address from, address to, uint256 tokenId) 
        external 
        validTokenId(tokenId)
        nonReentrant 
    {
        require(to != address(0), "Transfer to zero address");
        require(from != address(0), "Transfer from zero address");
        require(from != to, "Cannot transfer to same address");
        
        bool isOwner = (ownerOf(tokenId) == msg.sender);
        bool hasAdminPrivilege = (address(adminContract) != address(0) && 
                                  adminContract.balanceOf(msg.sender) > 0);
        
        require(isOwner || hasAdminPrivilege, "caller is not eligible");
        
        _transfer(from, to, tokenId);
        emit TokenTransferred(from, to, tokenId);
    }

    /**
     * @notice NFTをburn（AdminToken保有者かつ所有者のみ）
     * @param tokenId 焼却するtokenId
     * @dev Countersは減らないため、burn後も新規mintで衝突しない
     */
    function burn(uint256 tokenId) 
        external 
        hasAdminToken 
        validTokenId(tokenId)
        nonReentrant 
    {
        require(ownerOf(tokenId) == msg.sender, "caller is not owner");
        
        _burn(tokenId);
        emit TokenBurned(tokenId, msg.sender);
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
     * @notice ユーザーがミント可能かチェック
     * @param user チェックするユーザーアドレス
     * @param amount ミント数量
     * @return ミント可能かどうか
     */
    function canMint(address user, uint256 amount) external view returns (bool) {
        if (paused) return false;
        if (address(adminContract) == address(0)) return false;
        if (adminContract.balanceOf(user) == 0) return false;
        if (amount == 0 || amount > maxMintAmount) return false;
        if (totalSupply() + amount > maxSupply) return false;
        return true;
    }

    /**
     * @notice コントラクト情報を一括取得
     * @return _totalSupply 現在の総供給量
     * @return _maxSupply 最大供給量
     * @return _maxMintAmount 1回の最大ミント数
     * @return _currentTokenId 現在のtokenIdカウンター
     * @return _paused 一時停止状態
     * @return _revealed 公開状態
     * @return _adminContract AdminContractアドレス
     */
    function getContractInfo() external view returns (
        uint256 _totalSupply,
        uint256 _maxSupply,
        uint256 _maxMintAmount,
        uint256 _currentTokenId,
        bool _paused,
        bool _revealed,
        address _adminContract
    ) {
        return (
            totalSupply(),
            maxSupply,
            maxMintAmount,
            _tokenIdCounter.current(),
            paused,
            revealed,
            address(adminContract)
        );
    }
}