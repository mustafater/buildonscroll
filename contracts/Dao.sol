// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";



import   "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Dao is  ReentrancyGuard , AccessControl  {
  bytes32 private immutable CONTRIBUTOR = keccak256("CONTRIBUTOR");
  bytes32 private immutable MEMBER = keccak256("MEMBER");
  uint256 totalProposals;
  uint256 public daoBalance;

  mapping(uint256 => ProposalStruct) private raiseProposals;
  mapping(address => uint256[]) private membervotes;
  mapping(uint256 => VotedStruct[]) private voted;
  mapping(address => uint256) private contributors;
  mapping(address => uint256) private members;

  struct ProposalStruct {
    uint256 id;
    uint256 amount;
    uint256 upvotes;
    uint256 downvotes;
    string title;
    string description;
    bool passed;
    bool paid;
    address payable community;
    address proposer;
    address executor;
  }

  struct VotedStruct {
    address voter;
    bool choosen;
  }

  event Action  (
    address indexed init,
    bytes32 role,
    string message,
    address indexed community,
    uint256 amount 
  );

  modifier memberOnly(string memory message){
    require(hasRole(MEMBER, msg.sender),message);

    _;
  }

  modifier contibutorOnly( string memory message){
    require(hasRole(CONTRIBUTOR, msg.sender), message);

    _;
  }
    function createProposal(
        string calldata title,
        string calldata description,
        address community,
        uint256 amount
    )public memberOnly("Only member can make that offer")
    returns (ProposalStruct memory){
        uint256 proposalId = totalProposals++;
        ProposalStruct storage proposal = raiseProposals[proposalId]; 
        proposal.id = proposalId;
        proposal.title = title;
        proposal.description=description;
        proposal.amount=amount;
        proposal.proposer=payable(msg.sender);
        proposal.community=payable(community);

        emit Action(
            msg.sender,
            MEMBER,
            "Proposal raise",
            community,
            amount

        );    
            return proposal;
    }

    function vote(uint256 propodsalId, bool choosen) public
     memberOnly("member only vote"){
        ProposalStruct storage proposal = raiseProposals[propodsalId];
        checkVoted(proposal);
        if(choosen) proposal.upvotes++;
        else proposal.downvotes++;

        membervotes[msg.sender].push(proposal.id);
        voted[proposal.id].push(
            VotedStruct(
                msg.sender,
                choosen
            )
        );

        emit Action(
            msg.sender,
            MEMBER,
            "Proposal vote",
            proposal.community,
            proposal.amount
        );

     }

    function checkVoted(ProposalStruct storage proposal) private view {
        if(proposal.passed){
            revert("Proposal approved");
        }
        uint256[] memory  tempVotes = membervotes[msg.sender];
        for(uint256 votes =0; votes <tempVotes.length; votes++){
            if(proposal.id == tempVotes[votes]){
                revert("Already voted");
            }
        }


    }

    function payMember(uint256 proposalId) public memberOnly("only member")
     nonReentrant(){
        ProposalStruct storage proposal = raiseProposals[proposalId];
         require(daoBalance >=proposal.amount,"not enough liquid");
         if(proposal.paid) revert("Payment already");

         

         proposal.paid= true;
         proposal.executor=msg.sender;
         daoBalance -=proposal.amount;

         payTo(proposal.community,proposal.amount);

        emit Action(
            msg.sender,
            MEMBER,
            "Payment approve",
            proposal.community,
            proposal.amount
        );

     }

     function payTo(address to ,uint256 amount) internal returns(bool){
        (bool success,)=payable(to).call{value:amount}("");
        require(success,"payment failed");
        return true;
     }

     function contribute() payable public returns(uint256){
        require(msg.value >0 ether, " 0 is not allowed");
        if(!hasRole(CONTRIBUTOR,msg.sender)){
            uint256 totalContribution = contributors[msg.sender] + msg.value;

            if(totalContribution > 0 ){
                members[msg.sender] = totalContribution;
                contributors[msg.sender] +=msg.value;
                grantRole(MEMBER, msg.sender);
                grantRole(CONTRIBUTOR, msg.sender);
            }else{
                contributors[msg.sender] +=msg.value;
                grantRole(CONTRIBUTOR,msg.sender);
            }


        }else {
            contributors[msg.sender] +=msg.value;
            members[msg.sender] +=msg.value;
        }

        return daoBalance +=msg.value;

     }

     function getProposals() public view returns(ProposalStruct[] memory props){
        props = new ProposalStruct[](totalProposals);
        for(uint256 i = 0; i< totalProposals; i++){
            props[i]=raiseProposals[i];

        }
        return props;
     }

    function getProposal(uint256 proposalId) public view returns(ProposalStruct memory){
        return raiseProposals[proposalId];
    }

    function getVotesOf(uint256 proposalId) public view returns(VotedStruct[] memory){
        return voted[proposalId];
    }

    function getmemberVotes() public view memberOnly("only member") returns(uint256[]memory){
       return membervotes[msg.sender];

    }
    function getMemberBalance() public view memberOnly("only member") returns(uint256){
        return members[msg.sender];
    }
    function isMember()public view returns(bool){
        return members[msg.sender] > 0;
    }
    function getContributorBalance()public view contibutorOnly("user not contibutor")returns(uint256){
        return contributors[msg.sender];
    }
    function isContributor()public view returns(bool){
        return contributors[msg.sender] > 0 ;
    }
    function getBalance() public view returns(uint256){
        return contributors[msg.sender];
    }


}
