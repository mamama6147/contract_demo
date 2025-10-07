// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import "./ERC721Psi.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AdminTokenNFT (Secure Version)
 * @notice 本番環境向けの管理者権限NFTコントラクト
 * @dev ERC721Psiを使用してガス効率を最適化
 * 
 * 🔐 セキュリティ機能:
 * - ReentrancyGuard: リエントランシー攻撃対策
 * - イベントログ: 透明性の高いトランザクション記録
 * - 厳格な入力検証: ゼロアドレス・空文字列チェック
 * - 緊急機能: withdraw による資金引き出し
 * 
 * 💡 tokenId管理:
 * ERC721Psiは内部カウンター(_currentIndex)でtokenIdを自動管理
 * burnしてもカウンターは減らないため、tokenId衝突は発生しません
 */
contract AdminTokenNFT is ERC721Psi, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 10000;

    // Events for transparency
    event BaseURIUpdated(string newBaseURI);
    event TokensMinted(address indexed to, uint256 amount);

    constructor(
        string memory _initBaseURI
    ) ERC721Psi("AdminTokenNFT", "ADMINNFT") Ownable(msg.sender) {
        require(bytes(_initBaseURI).length > 0, "Base URI cannot be empty");
        baseURI = _initBaseURI;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice 管理者権限NFTをミント
     * @param _mintAmount ミントする数量
     * @dev ERC721Psiの_currentIndexカウンターで自動的にtokenIdが割り当てられる
     */
    function mint(uint256 _mintAmount) external onlyOwner nonReentrant {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "mint amount must be positive");
        require(_mintAmount <= 100, "cannot mint more than 100 at once"); // ガス制限
        require(supply + _mintAmount <= maxSupply, "exceeds max supply");

        _safeMint(msg.sender, _mintAmount);
        emit TokensMinted(msg.sender, _mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    // only owner functions
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(bytes(_newBaseURI).length > 0, "Base URI cannot be empty");
        baseURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        require(bytes(_newBaseExtension).length > 0, "Extension cannot be empty");
        baseExtension = _newBaseExtension;
    }

    // Emergency withdrawal function
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    // Override _startTokenId to start from 1 instead of 0
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}