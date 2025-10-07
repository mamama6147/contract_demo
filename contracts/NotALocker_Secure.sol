// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import "./ERC721Psi.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC721AdminContract {
    function balanceOf(address addr) external view returns (uint256 holds);
}

/**
 * @title notALockerNFT (Secure Version)
 * @notice 本番環境向けのAdminToken連携NFTコントラクト
 * @dev ERC721Psiを使用してガス効率を最適化
 * 
 * 🔐 セキュリティ機能:
 * - ReentrancyGuard: リエントランシー攻撃対策
 * - Modifierによる権限チェック: hasAdminToken, whenNotPaused
 * - イベントログ: 全ての重要な操作を記録
 * - 厳格な入力検証: ゼロアドレス・無効な値のチェック
 * - Emergency機能: emergencyPause, withdraw
 * 
 * 💡 tokenId管理:
 * ERC721Psiは内部カウンター(_currentIndex)でtokenIdを自動管理
 * ✅ burnしてもカウンターは減らないため、tokenId衝突は発生しません
 * ✅ 通常版(NotALocker.sol)はCountersライブラリを使用して同じ効果を実現
 * 
 * 🆚 通常版との違い:
 * - 通常版: ERC721Enumerable + Countersライブラリ
 * - Secure版: ERC721Psi（ガス最適化、内部カウンター）
 * 両方ともburn後のtokenId衝突問題を解決済み
 */
contract notALockerNFT is ERC721Psi, Ownable, ReentrancyGuard {
    using Strings for uint256;

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
    event BaseURIUpdated(string newBaseURI);
    event MaxMintAmountUpdated(uint256 newAmount);
    event TokensMinted(address indexed to, uint256 amount);
    event TokenBurned(uint256 indexed tokenId);
    event TokenTransferred(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721Psi("notALockerNFT", "NOTALOCKERNFT") Ownable(msg.sender) {
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
        require(_exists(tokenId), "Token does not exist");
        _;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Override _startTokenId to start from 1 instead of 0
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice NFTをミント（AdminToken保有者のみ）
     * @param _mintAmount ミントする数量
     * @dev ERC721Psiの_currentIndexカウンターで自動的にtokenIdが割り当てられる
     * burnしてもカウンターは減らないため、tokenId衝突は発生しない
     */
    function mint(uint256 _mintAmount) 
        external 
        hasAdminToken 
        whenNotPaused 
        nonReentrant 
    {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "mint amount must be positive");
        require(_mintAmount <= maxMintAmount, "exceeds max mint amount");
        require(supply + _mintAmount <= maxSupply, "exceeds max supply");

        _safeMint(msg.sender, _mintAmount);
        emit TokensMinted(msg.sender, _mintAmount);
    }

    // 修正版 walletOfOwner - セキュア&ガス効率化
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
        uint256 currentIndex = 0;
        uint256 totalTokens = totalSupply();
        
        // ガス制限対策：最大500トークンまでスキャン
        uint256 maxScan = totalTokens > 500 ? 500 : totalTokens;
        
        for (uint256 i = _startTokenId(); i <= maxScan && currentIndex < ownerTokenCount; i++) {
            if (_exists(i) && ownerOf(i) == _owner) {
                tokenIds[currentIndex] = i;
                currentIndex++;
            }
        }
        
        // 実際に見つかった分だけの配列を返す
        uint256[] memory result = new uint256[](currentIndex);
        for (uint256 i = 0; i < currentIndex; i++) {
            result[i] = tokenIds[i];
        }
        
        return result;
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

    // 修正版 transferToken - 安全性大幅向上
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
     * @dev ERC721Psiの_currentIndexは減らないため、burn後も新規mintで衝突しない
     */
    function burn(uint256 tokenId) 
        external 
        hasAdminToken 
        validTokenId(tokenId)
        nonReentrant 
    {
        require(ownerOf(tokenId) == msg.sender, "caller is not owner");
        
        _burn(tokenId);
        emit TokenBurned(tokenId);
    }

    // Emergency functions
    function emergencyPause() external onlyOwner {
        paused = true;
        emit Paused(true);
    }

    // ETH withdrawal function
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    // View functions for frontend integration
    function canMint(address user, uint256 amount) external view returns (bool) {
        if (paused) return false;
        if (address(adminContract) == address(0)) return false;
        if (adminContract.balanceOf(user) == 0) return false;
        if (amount == 0 || amount > maxMintAmount) return false;
        if (totalSupply() + amount > maxSupply) return false;
        return true;
    }

    function getContractInfo() external view returns (
        uint256 _totalSupply,
        uint256 _maxSupply,
        uint256 _maxMintAmount,
        bool _paused,
        bool _revealed,
        address _adminContract
    ) {
        return (
            totalSupply(),
            maxSupply,
            maxMintAmount,
            paused,
            revealed,
            address(adminContract)
        );
    }
}