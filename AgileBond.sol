pragma solidity ^0.4.11;

contract AgileBond
{
    //STATE VARIABLES:
    address public Issuer;
    address public Lender;
    uint256 private Amount;
    uint256 private twentyPercent;
    uint256 private couponPayments;
    uint private creationTime = now;
    bool public issuerLock;
    bool public lenderLock;
    
    //MAPPING:
    mapping(address => uint) balances;
    
    //EVENTS:
    event txnOccured(string _msg, address user, uint amount);
    event killContract(string _msg);
    
    /*
    event lenderPaid(string _msg, address user, uint amount);
    event lenderWithdrewFail(string _msg, address user, uint amount);
    event lenderWithdrewSuccess(string _msg, address user, uint amount);
    event issuerRepaid(string _msg, address user, uint amount);
    event issuerWithdrew(string _msg, address user, uint amount);
    event couponDeposited(string _msg, address user, uint amount);
    event couponWithdrew(string _msg, address user, uint amount);
     */
     
    //MODIFIERS:
    modifier onlyIssuer()
    {
        require(msg.sender == Issuer);_;
    }
    
        modifier onlyLender()
    {
        require(msg.sender == Lender);_;
    }
    
    modifier noCouponPaymentsDue()
    {
        require(couponPayments == 0);_;
    }
    
    modifier notPaid() 
    {
        if(now >= creationTime + 10 seconds)
        {
        balances[Lender] += twentyPercent;
        _;
        }
        else throw;
    }
    
    modifier issuerLocked()
    {
        require(issuerLock== false);_;
    }
    
    modifier lenderLocked()
    {
        require(lenderLock== false);_;
    }
    
    //PAYABLE FUNCTION:
    function Issuer20() payable issuerLocked
    {
        if(msg.sender !=Lender)
        {
        issuerLock = true;
        Issuer = msg.sender;
        twentyPercent = msg.value; 
        Amount = 5*(this.balance);
        txnOccured('Issuer deposited 20% into the contract', Issuer, msg.value);
        }
        else throw;
    }
    
    function lenderBond() payable lenderLocked returns(uint256 IssuerBal)
    {
        if(msg.sender != Issuer)
        { 
            require(msg.value == Amount);
            lenderLock = true;
            Lender = msg.sender;
            balances[Issuer] += msg.value;
            txnOccured('Lender deposited loan into the contract', Lender, msg.value);
            return balances[Issuer];
        }
        else throw;
    }
    
    function issuerRepayment() payable onlyIssuer returns(uint256 lenderBal)
    {
        balances[Lender] += msg.value;
        txnOccured('Issuer repayed the loan', Issuer, msg.value);
        return balances[Lender];
    }
    
    //CALL IF THE ISSUER WANTS TO PAY INTEREST PAYMENT
    function couponPayment() payable onlyIssuer public returns(uint256 couponBal)
    {
        couponPayments += msg.value;
        txnOccured('Issuer deposited coupon payment', Issuer, msg.value);
        return couponPayments;
    }
    
    //WITHDRAW FUNCTIONS:
    function issuerWithdraw(uint withdrawAmount) onlyIssuer public returns (uint256 issuerBal) {
            if(balances[Issuer] >= withdrawAmount) {
                balances[Issuer] -= withdrawAmount;

                Issuer.transfer(withdrawAmount);
                
                txnOccured('Issuer withdrew money from the contract', Issuer, withdrawAmount);
            
            }
            return balances[Issuer];
    }
    
    //CALL IF ISSUER REPAYS THE DEBT
    function lenderWithdrawSuccess(uint withdrawAmount) onlyLender noCouponPaymentsDue public returns (uint256 lenderBal) {
        if(balances[Lender] == withdrawAmount) {
            
            balances[Lender] -= withdrawAmount;
            balances[Issuer] += twentyPercent;
            
            Lender.transfer(withdrawAmount);
            txnOccured('Lender withdrew repayment. 20% unlocked for Issuer', Lender, withdrawAmount);
        }

        return balances[Lender];
    }
    
    //CALL IF THE ISSUER DOES NOT REPAY THE DEBT
    function lenderWithdrawFail(uint withdrawAmount) onlyLender notPaid public returns (uint256 lenderBal) {
        if(balances[Lender] >= withdrawAmount) {
            balances[Lender] -= withdrawAmount;
            
            Lender.transfer(withdrawAmount);
            txnOccured('Issuer did not repay loan, therefore lender withdrew the 20%', Lender, withdrawAmount);
        }
        return balances[Lender];
    }
    
    //CALL IF LENDER WITHDRAWS COUPON PAYMENT
    function couponWithdraw(uint withdrawAmount) onlyLender public returns (uint256 couponBal) {
        if(couponPayments == withdrawAmount) {
            couponPayments -= withdrawAmount;
            
            Lender.transfer(withdrawAmount);
            txnOccured('Lender withdrew coupon payment', Lender, withdrawAmount);
        }

        return couponPayments;
    }
    
    /*
    function suicideContract()
    {
    suicide()
    killContract('Contract has been killed');
    }
    */
    
    //GETTERS:
    function getBalance() constant returns(uint256)
    {
        return this.balance;
    }
    function getIssuer() constant returns(uint256)
    {
        return balances[Issuer];
    }
}
