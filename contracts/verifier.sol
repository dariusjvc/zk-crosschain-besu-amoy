// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x290903ff3a502075fcd3db76733b75bb472708f4c732e23e005e6c24937fddbc), uint256(0x0f628530146cd708280b2b8f62101f12eb63af557800b59011f8571716355db4));
        vk.beta = Pairing.G2Point([uint256(0x010e1e7388e00473c488a717a58f985ce6fc66b32e62ee64809a467c9142a63c), uint256(0x2a3c5a256c7e25a0d20db5903a70c76ef3d7aa3ce8d38270b2c605f49648fa9e)], [uint256(0x23677f6c2049d081e53e3e34f8379a61d4ddec9231817299685b369dd525f2dd), uint256(0x177609294e5082ef55e357c5cb2df1b9f40a80305171f909bfe2b2f0d43584c0)]);
        vk.gamma = Pairing.G2Point([uint256(0x2e749b7a84548b0015d5d3780f7419c9b3ee51c237674aa04df7d272092ef361), uint256(0x2b3e21e921f872716f1ea1fb5bd0907c2db665405c40c8c37d126ddb47540049)], [uint256(0x251368470faae7e937ea11bce214bc9bb6f11fb2ce212af8c47111f7f86194c6), uint256(0x0ac62c227ed14c680a64f3dd0abeb57f6dc2086cce7d6cefb472d16d838d9e94)]);
        vk.delta = Pairing.G2Point([uint256(0x1baba6ab11ac4c4482b46320150589b8ec6466905ed9dd4dd275c5d352d8a463), uint256(0x15c8e9527dd93363a738ecac62b192639acda45df5d7c15ba72c531043c05f13)], [uint256(0x2dad1fbd5c8d972b54890849224f91d2f54ea78cf58addf7c6a4db6fd37ebf2b), uint256(0x2b019d67ae6dafa643d5423c66ff86b177e1e368de17b3632053590f53f85870)]);
        vk.gamma_abc = new Pairing.G1Point[](10);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x2c8bab07218f9cb5e43497564ee6b730177da7dea51d9fa50312e03d805c1dd5), uint256(0x1cf29b4b66130317e0607f587bbf2a68ece348656b6efe6372582b0d0af0337f));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1072b5a6846aa29045a0fd93d653b73f329c763644f707b421eec039c8c99c30), uint256(0x11eda5ba6ba56630c6a4da20ffbce44946e2f3e3dbbcb1efceea4c2f27b1804d));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x00f3cfd7a80098cd37ed9f7f6446d64bd8a56dc3754c2eb67d4d69c4b3ebb6d3), uint256(0x18ed347b4faeae96b5066ec31808f3abf7d481bed8d4ece3c6f131215eecb493));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0687b2a2c9a0d10b6f95edd3339b721ee33c967bcdce49d6969317c48287ba15), uint256(0x2fb83d6a7c18699ee6a59ef5ab8ad391507f9ada0890e86b55c096d204118ff4));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x19c41c5d914733215a68bc93cc732624531af70df603f6be23ea03d546e201f2), uint256(0x181d202d4a62caaa662a46ed385bedec66cd6ea4c8e48d81d599803176ee14c0));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0ade7609bbef40f8be3e93d5de076e8d301013d3b04231cdddeee05a039c210f), uint256(0x199518d93771eaf892c11b84ea75b09d23db768919bcb6b9ede93894ae8e2e32));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x091631b3c5164be5aa8c50cd1d0f47c90756225067c30965e8c1efaf8a7989c1), uint256(0x30620376c5ed2f8b44e1e1d5f2c862bf0cf96dc650180f5169f93f0998c04b0e));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x271195ada9f8b881f421b4031da7a7cea59a01b81bce62361010ade2fd4e0f08), uint256(0x2c7e6d55fc7932e35e38cd5459d72a5073682aa7fa7eb1cd92401ff01b619a26));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2e882bb20f21a6772f16c923c38d9d15dd8b98e0743ac1bad7b2e62c3457cd8e), uint256(0x24530a16a328d035c5a17b4e9274a765f4cce4ae6cccd4dad19eb635d10a698b));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x1bae86ce960f388ef8bea0d20c912cacb85c1d061d8ddc2aa366129271fe1772), uint256(0x2555f3b8aaa3aa1db1018651b825bc6362fc5a4b087da9feba60a29a1649dcc2));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[9] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](9);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
