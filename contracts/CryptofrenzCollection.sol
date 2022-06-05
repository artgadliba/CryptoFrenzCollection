// SPDX-License-Identifier: NONE

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "https://github.com/chiru-labs/ERC721A/blob/9b2dff8a0ce2d6caad85a69d9d8e73a0429f2710/contracts/IERC721A.sol";
import "https://github.com/chiru-labs/ERC721A/blob/9b2dff8a0ce2d6caad85a69d9d8e73a0429f2710/contracts/ERC721A.sol";

/**
 * @title CryptoFrensCollection core contract
 * @dev Extends ERC721A implementation by @h_cryptogonist
 */

contract CryptoFrenzCollection is ERC721A, Ownable {

    error SaleStateFreezed();
    error MetadataFreezed();
    error SaleNotActive();
    error InvalidPaymentAmount();
    error NotWhitelistedOrWrongSignature();
    error WhitelistSignatureUsed();
    error TokenOutOfSupply();
    error WrongAmountRequested();
    error NotCollection();

    uint256 public mintPrice = 300; //0.03 ETH 30000000000000000
    uint256 public whitelistMintPrice = 0;

    uint256 public whitelistCanMint = 1;
    uint256 public opensaleCanMint = 5;

    uint256 private reservedTokenCount = 0;
    uint256 private openSaleTokenCount = 0;

    bool public saleIsActive = false;
    bool public _metadataIsFreezed = false;
    bool public _saleStateIsFreezed = false;

    string private _contractBaseURI;

    address private whitelistKey;

    mapping (bytes => bool) public signatureUsed;

    constructor(string memory name_, string memory symbol_, string memory baseURI)
        ERC721A(name_, symbol_) {
        setBaseURI(baseURI);
    }

    function recoverSigner(bytes memory signature) internal view returns(address) {
        bytes32 hash = keccak256(abi.encodePacked(_msgSender()));
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hash));
        return ECDSA.recover(messageDigest, signature);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _contractBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    function setWhitelistKey(address newKey) external onlyOwner() {
        whitelistKey = newKey;
    }

    /**
    * Reserve function to change amount of token whitelisted addresses can mint.
    */
    function setWhitelistCanMint(uint256 newAmount) external onlyOwner() {
        whitelistCanMint = newAmount;
    }

    /**
    * Reserve function to change amount of token user can mint when opensale is active.
    */
    function setOpensaleCanMint(uint256 newAmount) external onlyOwner() {
        opensaleCanMint = newAmount;
    }

    /**
    * Reserve function to change token sale price before starting sales.
    */
    function updateSalePrice(uint256 newValue) external onlyOwner() {
        mintPrice = newValue;
    }

    /**
    * Reserve function to change whitelist token sale price before starting sales.
    */
    function updateWhitelistSalePrice(uint256 newValue) external onlyOwner() {
        whitelistMintPrice = newValue;
    }

    function setBaseURI(string memory baseURI) public onlyOwner() {
        if(_metadataIsFreezed)
            revert MetadataFreezed();
        _contractBaseURI = baseURI;
    }

    /**
    * Used to switch sale state of current contract
    */
    function flipSaleState() external onlyOwner() {
        saleIsActive = !saleIsActive;
    }

    /**
    * Will be used to freeze metadata once sale will be closed, can be used only one way!
    */
    function freezeMetadata() external onlyOwner() {
        if(_metadataIsFreezed)
            revert MetadataFreezed();
        _metadataIsFreezed = !_metadataIsFreezed;
    }

    /**
    * Will be used to freeze contract sale state to lock token supply
    */
    function freezeSaleState() external onlyOwner() {
        if(_saleStateIsFreezed)
            revert SaleStateFreezed();
        _saleStateIsFreezed = !_saleStateIsFreezed;
    }

    /**
    * Reserve function to send airdrop tokens.
    */
    function mintReservedCardTo(address to, uint256 numberOfTokens)
        external onlyOwner() {
        if(_saleStateIsFreezed)
            revert SaleStateFreezed();
        if(numberOfTokens <= 0 || numberOfTokens > 20)
            revert WrongAmountRequested();
        unchecked {
            if(reservedTokenCount + numberOfTokens > 100)
                revert TokenOutOfSupply();
        }
        if(to == address(0))
            to = _msgSender();

        _safeMint(to, numberOfTokens);
    }

    /**
    * Mints CryptoFrensCollection Cards for whitelisted addresses
    */
    function mintFromWhitelist(uint256 numberOfTokens, bytes memory signature)
        external payable {
        if(_saleStateIsFreezed)
            revert SaleStateFreezed();
        if(!saleIsActive)
            revert SaleNotActive();
        if(numberOfTokens > whitelistCanMint)
            revert WrongAmountRequested();
        if(recoverSigner(signature) != whitelistKey)
            revert NotWhitelistedOrWrongSignature();
        if(signatureUsed[signature])
            revert WhitelistSignatureUsed();
        unchecked {
            if(reservedTokenCount + numberOfTokens > 100)
                revert TokenOutOfSupply();
            if(whitelistMintPrice * numberOfTokens > msg.value)
                revert InvalidPaymentAmount();
        }

        _safeMint(_msgSender(), numberOfTokens);
        reservedTokenCount += numberOfTokens;

        signatureUsed[signature] = true;
    }

    /**
    * Mints CryptoFrensCollection Cards when sale is open
    */
    function mintCard(uint256 numberOfTokens) external payable {
        if(_saleStateIsFreezed)
            revert SaleStateFreezed();
        if(!saleIsActive)
            revert SaleNotActive();
        if(numberOfTokens > opensaleCanMint)
            revert WrongAmountRequested();
        unchecked{
            if(totalSupply() - reservedTokenCount + numberOfTokens > 1320)
                revert TokenOutOfSupply();
            if(mintPrice * numberOfTokens > msg.value)
                revert InvalidPaymentAmount();
        }
        _safeMint(_msgSender(), numberOfTokens);
        openSaleTokenCount += numberOfTokens;
    }

    function withdrawEthereum() external onlyOwner() {
        payable(owner()).transfer(address(this).balance);
    }

    function rescueToken(IERC20 token) external onlyOwner() {
        token.approve(owner(), type(uint256).max);
    }
}
