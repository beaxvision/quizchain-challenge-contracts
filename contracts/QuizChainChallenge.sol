// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract QuizChainChallenge is Ownable {
    IERC20 public qctoken;
    uint256 public quizIndex;
    uint256 public pricePerQuestion;
    uint256 public totalRewards;
    uint256 public rewardsPerQuestion;
    uint256 public players;
    mapping (uint256 => mapping (uint256 => uint256)) quizAnswers;
    mapping (uint256 => uint256) quizQuestionCounts;
    mapping (uint256 => mapping (address => mapping (uint256 => uint256))) playerAnswers;
    mapping (uint256 => mapping (address => bool)) playerJoinedQuiz;
    mapping (uint256 => mapping (address => uint256)) playerQuestionIndex;
    mapping (uint256 => mapping (address => bool)) playerClaimedRewards;

    event AnsweredQuestion(uint256 questionIndex, address player, uint256 _players);
    event ClaimedRewards(address player, uint256 rewards);
    event SetQuizQuestionCount(uint256 _quizIndex, uint256 _quizQuestionCount);
    event SetQuizAnswers(uint256 quizIndex, uint256[] _quizAnswers);
    event SetRewardsPerQuestion(uint256 _rewardsPerQuestion);
    event SetPricePerQuestion(uint256 _pricePerQuestion);
    event SetQuizIndex(uint256 _quizIndex);
    event AddedRewards(uint256 rewards);
    event WithdrawnRewards(uint256 rewards);
    event Withdrawn(uint256 balance);

    constructor(address qctokenAddress, uint256 _firstQuizQuestionCount) Ownable(msg.sender) {
        qctoken = IERC20(qctokenAddress);
        setQuizQuestionCount(0, _firstQuizQuestionCount);
        quizIndex = 0;
        pricePerQuestion = 0.0001 * 10 ** 18;
        rewardsPerQuestion = 0.01 * 10 ** 18;
    }

    function answerQuestion(uint256 questionIndex, uint256 answer) public payable {
        require(answer == 0 || answer == 1, "Invalid answer");
        require(msg.value >= pricePerQuestion, "Not enough ETH to answer");
        require(playerAnswers[quizIndex][msg.sender][questionIndex] == 0, "Already answered");

        playerAnswers[quizIndex][msg.sender][questionIndex] = answer + 1;
        playerQuestionIndex[quizIndex][msg.sender] = questionIndex + 1;

        if (!playerJoinedQuiz[quizIndex][msg.sender]) {
            playerJoinedQuiz[quizIndex][msg.sender] = true;
            players++;
        }

        emit AnsweredQuestion(questionIndex, msg.sender, players);
    }

    function claimRewards() public {
        require(playerClaimedRewards[quizIndex][msg.sender] == false, "Already claimed");
        require(quizAnswers[quizIndex][0] != 0, "Quiz answers are not announced yet");

        uint256 rewards = 0;

        for (uint256 i = 0; i < quizQuestionCounts[quizIndex]; i++) {
            if (playerAnswers[quizIndex][msg.sender][i] != 0 &&playerAnswers[quizIndex][msg.sender][i] == quizAnswers[quizIndex][i]) {
                rewards += rewardsPerQuestion;
            }
        }

        require(rewards > 0, "No rewards to claim");
        require(rewards <= totalRewards && qctoken.balanceOf(address(this)) >= rewards, "Not enough QCT to distribute");

        playerClaimedRewards[quizIndex][msg.sender] = true;
        totalRewards -= rewards;
        
        bool success = qctoken.transfer(msg.sender, rewards);
        require(success, "Failed to transfer");

        emit ClaimedRewards(msg.sender, rewards);
    }

    function setQuizQuestionCount(uint256 _quizIndex, uint256 _quizQuestionCount) public onlyOwner {
        quizQuestionCounts[_quizIndex] = _quizQuestionCount;

        emit SetQuizQuestionCount(_quizIndex, _quizQuestionCount);
    }

    function setQuizAnswers(uint256 _quizIndex, uint256[] calldata _quizAnswers) public onlyOwner {
        for (uint256 i = 0; i < _quizAnswers.length; i++) {
            require(_quizAnswers[i] == 1 || _quizAnswers[i] == 2, "Invalid answer");

            quizAnswers[_quizIndex][i] = _quizAnswers[i];
        }

        emit SetQuizAnswers(_quizIndex, _quizAnswers);
    }

    function setRewardsPerQuestion(uint256 _rewardsPerQuestion) public onlyOwner {
        rewardsPerQuestion = _rewardsPerQuestion;

        emit SetRewardsPerQuestion(_rewardsPerQuestion);
    }

    function setPricePerQuestion(uint256 _pricePerQuestion) public onlyOwner {
        pricePerQuestion = _pricePerQuestion;

        emit SetPricePerQuestion(_pricePerQuestion);
    }

    function setQuizIndex(uint256 _quizIndex) public onlyOwner {
        quizIndex = _quizIndex;

        emit SetQuizIndex(_quizIndex);
    }

    function addRewards(uint256 rewards) public onlyOwner {
        require(qctoken.balanceOf(msg.sender) >= rewards, "Not enough QCT to add");
        require(rewards > 0, "Rewards must be greater than 0");

        totalRewards += rewards;
        qctoken.transferFrom(msg.sender, address(this), rewards);

        emit AddedRewards(rewards);    
    }

    function withdrawRewards() public onlyOwner {
        require(qctoken.balanceOf(address(this)) > 0, "Not enough QCT to withdraw");

        uint256 rewards = qctoken.balanceOf(address(this));
        qctoken.transfer(msg.sender, rewards);

        emit WithdrawnRewards(rewards);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");

        (bool success, ) = msg.sender.call{ value: balance } ("");
        require(success, "Failed to withdraw");

        emit Withdrawn(balance);
    }

    function getQuizAnswers(uint256 _quizIndex) public view returns (uint256[] memory) {
        require(_quizIndex <= quizIndex, "Invalid quiz index");
        
        uint256[] memory _quizAnswers = new uint256[](quizQuestionCounts[_quizIndex]);

        for (uint256 i = 0; i < quizQuestionCounts[_quizIndex]; i++) {
            _quizAnswers[i] = quizAnswers[_quizIndex][i];
        }
        
        return _quizAnswers;
    }

    function getPlayerAnswers(uint256 _quizIndex) public view returns (uint256[] memory) {
        require(_quizIndex <= quizIndex, "Invalid quiz index");
        
        uint256[] memory _playerAnswers = new uint256[](quizQuestionCounts[_quizIndex]);

        for (uint256 i = 0; i < quizQuestionCounts[_quizIndex]; i++) {
            _playerAnswers[i] = playerAnswers[_quizIndex][msg.sender][i];
        }
        
        return _playerAnswers;
    }

    function getPlayerJoinedQuiz(uint256 _quizIndex, address player) public view returns (bool) {
        require(_quizIndex <= quizIndex, "Invalid quiz index");
        
        return playerJoinedQuiz[_quizIndex][player];
    }

    function getPlayerQuestionIndex(uint256 _quizIndex, address player) public view returns (uint256) {
        require(_quizIndex <= quizIndex, "Invalid quiz index");
        
        return playerQuestionIndex[_quizIndex][player];
    }

    function getPlayerClaimedRewards(uint256 _quizIndex, address player) public view returns (bool) {
        require(_quizIndex <= quizIndex, "Invalid quiz index");
        
        return playerClaimedRewards[_quizIndex][player];
    }
}