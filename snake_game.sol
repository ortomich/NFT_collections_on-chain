// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./erc721a/contracts/ERC721A.sol";

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

library colorGenerator {

    function getColors(address _address) internal pure returns (string memory color){

        color = getSlice(3, 8, toString(abi.encodePacked(_address)));        
    }

    function getSlice(uint256 begin, uint256 end, string memory text) internal pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

}

contract Snake is ERC721A {

    modifier onlyOwner() {
        require(owner == msg.sender, "OW1");
        _;
    }

    address public owner;
    uint256 public immutable maxSupply = 20;
    uint256 public numClaimed = 0;
    bool public sale;
    mapping(address => uint8) public numOfMintedByWallet;

    function generateHTMLandSVG(address _address) internal pure returns (string memory, string memory) {

        return(
            string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350"><rect x="27" y="120" width="300" height="60" style="fill:#', colorGenerator.getColors(_address),';" /><rect x="312" y="120" width="15" height="15" style="fill:#000000;" /><rect x="312" y="165" width="15" height="15" style="fill:#000000;" /><text x="31" y="240" style="font-size:23px; font-family:Arial" >Open to play the NFT game</text></svg> ')),
            string(abi.encodePacked('<!DOCTYPE html> <html lang="en"> <body> <style> html, body { height: 100%; margin: 0; } body { --size: 15px; --color: #', colorGenerator.getColors(_address),'; color: var(--color); background-color: #000000; } @media (min-height: 425px) { body { --size: 25px; } footer { height: 40px; font-size: 1em; } } .container { display: flex; flex-direction: column; justify-content: center; align-items: center; height: 100%; } header { display: flex; justify-content: space-between; width: calc(var(--size) * 17); font-size: 2em; font-weight: 900; } .grid { display: grid; grid-template-columns: repeat(15, auto); grid-template-rows: repeat(15, auto); border: var(--size) solid var(--color); } .tile { position: relative; width: var(--size); height: var(--size); } .content { position: absolute; width: 100%; height: 100%; } footer { margin-top: 20px; max-width: calc(var(--size) * 17); text-align: center; } footer a:visited { color: inherit; } </style> <div class="container"> <header> <div class="score">0</div> </header> <div class="grid"></div> <footer>Press an arrow key or space to start! </div> <script> window.addEventListener("DOMContentLoaded", function (event) { window.focus(); let snakePositions; let applePosition; let startTimestamp; let lastTimestamp; let stepsTaken; let score; let inputs; let gameStarted = false; const width = 15; const height = 15; const speed = 200; const color = "#', colorGenerator.getColors(_address), '"; const grid = document.querySelector(".grid"); for (let i = 0; i < width * height; i++) { const content = document.createElement("div"); content.setAttribute("class", "content"); content.setAttribute("id", i); const tile = document.createElement("div"); tile.setAttribute("class", "tile"); tile.appendChild(content); grid.appendChild(tile); } const tiles = document.querySelectorAll(".grid .tile .content"); const containerElement = document.querySelector(".container"); const noteElement = document.querySelector("footer"); const scoreElement = document.querySelector(".score"); resetGame(); function resetGame() { snakePositions = [168, 169, 170, 171]; applePosition = 100; startTimestamp = undefined; lastTimestamp = undefined; stepsTaken = -1; score = 0; inputs = []; scoreElement.innerText = score; for (const tile of tiles) setTile(tile); setTile(tiles[applePosition], { "background-color": color, "border-radius": "50%" }); for (const i of snakePositions.slice(1)) { const snakePart = tiles[i]; snakePart.style.backgroundColor = color; if (i == snakePositions[snakePositions.length - 1]) snakePart.style.left = 0; if (i == snakePositions[0]) snakePart.style.right = 0; } } window.addEventListener("keydown", function (event) { if ( ![ "ArrowLeft", "ArrowUp", "ArrowRight", "ArrowDown", " ", ].includes(event.key) ) return; event.preventDefault(); if (event.key == " ") { resetGame(); startGame(); return; } if ( event.key == "ArrowLeft" && inputs[inputs.length - 1] != "left" && headDirection() != "right" ) { inputs.push("left"); if (!gameStarted) startGame(); return; } if ( event.key == "ArrowUp" && inputs[inputs.length - 1] != "up" && headDirection() != "down" ) { inputs.push("up"); if (!gameStarted) startGame(); return; } if ( event.key == "ArrowRight" && inputs[inputs.length - 1] != "right" && headDirection() != "left" ) { inputs.push("right"); if (!gameStarted) startGame(); return; } if ( event.key == "ArrowDown" && inputs[inputs.length - 1] != "down" && headDirection() != "up" ) { inputs.push("down"); if (!gameStarted) startGame(); return; } }); function startGame() { gameStarted = true; noteElement.style.opacity = 0; window.requestAnimationFrame(main); } function main(timestamp) { try { if (startTimestamp === undefined) startTimestamp = timestamp; const totalElapsedTime = timestamp - startTimestamp; const timeElapsedSinceLastCall = timestamp - lastTimestamp; const stepsShouldHaveTaken = Math.floor(totalElapsedTime / speed); const percentageOfStep = (totalElapsedTime % speed) / speed; if (stepsTaken != stepsShouldHaveTaken) { stepAndTransition(percentageOfStep); const headPosition = snakePositions[snakePositions.length - 1]; if (headPosition == applePosition) { score++; scoreElement.innerText = score; addNewApple(); } stepsTaken++; } else { transition(percentageOfStep); } window.requestAnimationFrame(main); } catch (error) { const pressSpaceToStart = "Press space to reset the game."; noteElement.innerHTML = `${error.message}. ${pressSpaceToStart}`; noteElement.style.opacity = 1; containerElement.style.opacity = 1; } lastTimestamp = timestamp; } function stepAndTransition(percentageOfStep) { const newHeadPosition = getNextPosition(); snakePositions.push(newHeadPosition); const previousTail = tiles[snakePositions[0]]; setTile(previousTail); if (newHeadPosition != applePosition) { snakePositions.shift(); const tail = tiles[snakePositions[0]]; const tailDi = tailDirection(); const tailValue = `${100 - percentageOfStep * 100}%`; if (tailDi == "right") setTile(tail, { left: 0, width: tailValue, "background-color": color }); if (tailDi == "left") setTile(tail, { right: 0, width: tailValue, "background-color": color }); if (tailDi == "down") setTile(tail, { top: 0, height: tailValue, "background-color": color }); if (tailDi == "up") setTile(tail, { bottom: 0, height: tailValue, "background-color": color }); } const previousHead = tiles[snakePositions[snakePositions.length - 2]]; setTile(previousHead, { "background-color": color }); const head = tiles[newHeadPosition]; const headDi = headDirection(); const headValue = `${percentageOfStep * 100}%`; if (headDi == "right") setTile(head, { left: 0, width: headValue, "background-color": color, "border-radius": 0 }); if (headDi == "left") setTile(head, { right: 0, width: headValue, "background-color": color, "border-radius": 0 }); if (headDi == "down") setTile(head, { top: 0, height: headValue, "background-color": color, "border-radius": 0 }); if (headDi == "up") setTile(head, { bottom: 0, height: headValue, "background-color": color, "border-radius": 0 }); } function transition(percentageOfStep) { const head = tiles[snakePositions[snakePositions.length - 1]]; const headDi = headDirection(); const headValue = `${percentageOfStep * 100}%`; if (headDi == "right" || headDi == "left") head.style.width = headValue; if (headDi == "down" || headDi == "up") head.style.height = headValue; const tail = tiles[snakePositions[0]]; const tailDi = tailDirection(); const tailValue = `${100 - percentageOfStep * 100}%`; if (tailDi == "right" || tailDi == "left") tail.style.width = tailValue; if (tailDi == "down" || tailDi == "up") tail.style.height = tailValue; } function getNextPosition() { const headPosition = snakePositions[snakePositions.length - 1]; const snakeDirection = inputs.shift() || headDirection(); switch (snakeDirection) { case "right": { const nextPosition = headPosition + 1; if (nextPosition % width == 0) throw Error("The snake hit the wall"); if (snakePositions.slice(1).includes(nextPosition)) throw Error("The snake bit itself"); return nextPosition; } case "left": { const nextPosition = headPosition - 1; if (nextPosition % width == width - 1 || nextPosition < 0) throw Error("The snake hit the wall"); if (snakePositions.slice(1).includes(nextPosition)) throw Error("The snake bit itself"); return nextPosition; } case "down": { const nextPosition = headPosition + width; if (nextPosition > width * height - 1) throw Error("The snake hit the wall"); if (snakePositions.slice(1).includes(nextPosition)) throw Error("The snake bit itself"); return nextPosition; } case "up": { const nextPosition = headPosition - width; if (nextPosition < 0) throw Error("The snake hit the wall"); if (snakePositions.slice(1).includes(nextPosition)) throw Error("The snake bit itself"); return nextPosition; } } } function headDirection() { const head = snakePositions[snakePositions.length - 1]; const neck = snakePositions[snakePositions.length - 2]; return getDirection(head, neck); } function tailDirection() { const tail1 = snakePositions[0]; const tail2 = snakePositions[1]; return getDirection(tail1, tail2); } function getDirection(first, second) { if (first - 1 == second) return "right"; if (first + 1 == second) return "left"; if (first - width == second) return "down"; if (first + width == second) return "up"; throw Error("the two tile are not connected"); } function addNewApple() { let newPosition; do { newPosition = Math.floor(Math.random() * width * height); } while (snakePositions.includes(newPosition)); setTile(tiles[newPosition], { "background-color": color, "border-radius": "50%" }); applePosition = newPosition; } function setTile(element, overrides = {}) { const defaults = { width: "100%", height: "100%", top: "auto", right: "auto", bottom: "auto", left: "auto", "background-color": "transparent" }; const cssProperties = { ...defaults, ...overrides }; element.style.cssText = Object.entries(cssProperties) .map(([key, value]) => `${key}: ${value};`) .join(" "); } }); </script> </body> </html>'))
        );

    }


    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        (string memory svg, string memory html) = generateHTMLandSVG(ownerOf(tokenId));

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "Snake | ", _toString(tokenId),"",
                                '", "description":"Your favorite game!", "image":"', string(abi.encodePacked("data:image/svg+xml;base64,",Base64.encode(bytes(string(abi.encodePacked(svg)))))),
                                '", "animation_url":"', string(abi.encodePacked("data:text/html;base64,", Base64.encode(bytes(string(abi.encodePacked(html)))))),'"}'
                            )
                        )
                    )
                )
            );
    }

    function setSale(bool _set) public onlyOwner {
        sale = _set;
    }

    function setOwner(address _address) public onlyOwner {
        owner = _address;
    }

    function mint() public {
        require(numOfMintedByWallet[msg.sender] == 0, "RE");
        require(tx.origin == msg.sender, "BOT");
        require(numClaimed < maxSupply, "IC");
        require(sale == true, "ST");

        numOfMintedByWallet[msg.sender]++;
        numClaimed += 1;
        _safeMint(msg.sender, 1);
    }
    
    constructor() ERC721A("Ortomich Snake", "0S") {
        owner = msg.sender;
    }
}