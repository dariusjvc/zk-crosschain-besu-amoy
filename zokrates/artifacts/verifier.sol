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
        vk.alpha = Pairing.G1Point(uint256(0x077c4ed0b48594e157ff15d36631c76c7a581543de8f9b98e55f291d63f395de), uint256(0x02157e9c25e4d09d7bb4badde4877228866409c619563fe6fb706a942f88e789));
        vk.beta = Pairing.G2Point([uint256(0x1aa05290c1ccc5f66fcc4fc94232319573fd72ee6f3b6bf77ed1fc44f61fd21b), uint256(0x301e3e71fabc0086096ee2722489254c8fb2445b0407f54ba6b8a821166710bb)], [uint256(0x2be24443bc8d2ceb808b8f65c287acae7a3a6e9f515d6f773b37fc4fbda543aa), uint256(0x145b9bfafc735d8143ff1d83857b0df4b35b0e1e8c203dfa3f3657a4a98105ec)]);
        vk.gamma = Pairing.G2Point([uint256(0x2823dbf51b376e66d493597e1d5e4bbfa06d7d7bbcafb7a3d8a0e46d0893b1d0), uint256(0x2b783538e9838a6e5a8122900781b975922bbb4de5218ef36fb8e882935acd16)], [uint256(0x126efe0427caf638f3fbc881f3a9edba59405556eb87cee29434c21f0a58c439), uint256(0x1ca7d7cd2f0a687b0aec785f66314c85dc553d62abb3bbcae7f92e980173bfee)]);
        vk.delta = Pairing.G2Point([uint256(0x0031e3794010ee63ae9af318ec1112dba09b2a42538e7b16a4f194b0d7508929), uint256(0x19fc2b656bd61861ba7573c374317bd5f31854bf5e1403e1383ce31778511a92)], [uint256(0x09c1853f2ae2f4c883b0a69df77fca7f99c027e967c62f84d9a720d93e2b68a1), uint256(0x0d18dfae45e7a3b4cd8981573ed40429bf97082721d4d268c5317e967f507a8a)]);
        vk.gamma_abc = new Pairing.G1Point[](10);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x263c19302a1088cb80987847301d086900beee0bb7d4f47d9b78b3cba05193eb), uint256(0x2336f92892cb06b21f98bd3add28d2e9186e8f2e61935defa5959e4147ae8263));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x12f54103a551337ac0ea3b995601b6a029365ec4b7ef121a021fba1bebe0495a), uint256(0x0b8e836a05f706424be61c5d7c68438e0e93d6345b569a18092032c6e8974a88));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x18263a5a6deb412c35fc90b30db2ac474df9121aeba3c65838b798af5f5e2753), uint256(0x15d71f2afecac6bee01563c8cc273524ed527e6362340a0c253467c034da85ed));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x07c0680e643eac59c4618af6fc0279dcd48eafdd209d0aa0f651a1d56534483f), uint256(0x003832174cbcce0a615d4532a375c2e0ea81c0e8a1b90ce270c3ecc9e384c890));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x068cbdea871137c1da426d31cd610928b3a16ddacd0698d45803c6c500d9f358), uint256(0x15a1bc6dcd1217428b00a6abf4e38e163ef5af28509fbf0973de604620b6d548));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x148c321ca10e6bb6fe56f7f33f90a12775b7334a784aa7c5ecca7c5d0bc15190), uint256(0x034d2d630f507d37fa5e746c183a82ffb094ec3b45ef7275eadcade79ae118d2));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2bcccb5f86a81a3bb8a703bee7f7bb89457098f47a8754ab9d5605e6a26a0e0b), uint256(0x1f7d0ac43321d84bcc75fe2237fb7538b7643e756ad3e6f8d89d1102b75b3cbe));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x08139d9c3f66b6b22ce2196beda80cbe3205b7e3b3c67813256f9aedaa69615c), uint256(0x177d0d21190fbfb3b8a542b8b3db5b1f3e8004d674ffdd40977de48c9bfe56d7));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x153a431363b57b533961674bfa84c33d2b6789966cb2c78182dbb4141351761f), uint256(0x05782bfbfa45335b6d3b0435ede5e516025bfe9c9deee7e1b53c3ae409355823));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x07afda38d017f3a9846cc60decf4660b138c3ac23dbfa6932b45f3bbfdb25ba4), uint256(0x237e6be94ff912edc6721ed2c0ab34bba08ada20aa83eac1596ebc75babc5017));
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
