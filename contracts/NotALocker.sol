// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

interface balanceOfInterface {
    function balanceOf(address addr) external view returns (uint256 holds);
}

contract notALockerNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 10000;
  bool public paused = false;
  bool public revealed = false;
  string public notRevealedUri;
  balanceOfInterface public adminContract;

  constructor(
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721("notALockerNFT", "NOTALOCKERNFT") Ownable(msg.sender) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public {
    require(
        address(adminContract) != address(0) && adminContract.balanceOf(msg.sender) > 0,
        "caller doesn't have admin token"
    );

    uint256 supply = totalSupply();
    require(!paused, "minting is paused");
    require(_mintAmount > 0, "mint amount must be positive");
    require(_mintAmount <= maxMintAmount, "exceeds max mint amount");
    require(supply + _mintAmount <= maxSupply, "exceeds max supply");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    _requireOwned(tokenId);

    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setAdminContract(address _adminContract) public onlyOwner {
    adminContract = balanceOfInterface(_adminContract);
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function transferToken(address from, address to, uint256 tokenId) public {
    require(
        ownerOf(tokenId) == msg.sender || (address(adminContract) != address(0) && adminContract.balanceOf(msg.sender) > 0),
        "caller is not eligible"
    );
    _transfer(from, to, tokenId);
  }

  function burn(uint256 tokenId) public {
    require(
        ownerOf(tokenId) == msg.sender,
        "caller is not owner"
    );
    require(
        address(adminContract) != address(0) && adminContract.balanceOf(msg.sender) > 0,
        "caller doesn't have admin token"
    );
    _burn(tokenId);
  }
}