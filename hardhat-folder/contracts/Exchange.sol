//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20{
  
   address public cryptoDevTokenAddress;

   constructor(address _CryptoDevToken) ERC20("CryptoDevLPToken" , "CDLP"){
    require(_CryptoDevToken != address(0) , "Address can't be NULL");
    cryptoDevTokenAddress = _CryptoDevToken;
    }

   function getReserve()public view returns(uint){
       return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
   }
   
   function addLiquidity(uint _amount)public payable returns(uint){
       uint liquidity;
       uint ethBalance = address(this).balance;
       uint tokenReserve = getReserve();
       ERC20 token = ERC20(cryptoDevTokenAddress);

           if (tokenReserve == 0) {
               token.transferFrom(msg.sender, address(this), _amount);
               liquidity = ethBalance;
               _mint(msg.sender, liquidity);
           } 
           else {
               uint ethReserve = ethBalance - msg.value;
               uint tokenAmount = (msg.value * tokenReserve) / (ethReserve);
               require(_amount >= tokenAmount ,"Add more tokens to proceed");
               token.transferFrom(msg.sender, address(this), tokenAmount);
               liquidity = (totalSupply() * msg.value) / (ethReserve);
               _mint(msg.sender, liquidity);
            }

    return liquidity;
    }

   
    function removeLiquidity(uint _amount) public returns (uint , uint) {
         require(_amount > 0 , "amount can't be ");
         uint ethReserve = address(this).balance;
         uint _totalSupplyLP = totalSupply();
         
         uint ethAmount = (_amount * ethReserve) / _totalSupplyLP;
         uint tokenAmount =(getReserve() * _amount) / _totalSupplyLP;
         _burn(msg.sender,_amount);
         payable(msg.sender).transfer(ethAmount);
         ERC20(cryptoDevTokenAddress).transfer(msg.sender , tokenAmount);
     
         return (ethAmount,tokenAmount);
    }
    
    
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        uint256 inputAmountWithFee = inputAmount * 99;

        // so the final formulae is Δy = (y*Δx)/(x + Δx);
        // Δy in our case is `tokens to be recieved`
        // Δx = ((input amount)*99)/100, x = inputReserve, y = outputReserve
        // So by putting the values in the formulae you can get the numerator and denominator

        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }
    

    
    function ethToCryptoDevToken(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );
    
        require(tokensBought >= _minTokens, "insufficient output amount");
        // Transfer the `Crypto Dev` tokens to the user
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, tokensBought);
    }


   
    function cryptoDevTokenToEth(uint _tokensSold, uint _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _minEth, "insufficient output amount");
        // Transfer `Crypto Dev` tokens from the user's address to the contract
        ERC20(cryptoDevTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        // send the `ethBought` to the user from the contract
        payable(msg.sender).transfer(ethBought);
    }

}